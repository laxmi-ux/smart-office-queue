package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"

	"smart-office-queue/backend/models"
)

type TokenRepository struct {
	DB *pgx.Conn
}

func NewTokenRepository(db *pgx.Conn) *TokenRepository {
	return &TokenRepository{
		DB: db,
	}
}

func (r *TokenRepository) GetDepartmentByID(
	ctx context.Context,
	departmentID int,
) (*models.Department, error) {

	var department models.Department

	query := `
		SELECT id, name, code
		FROM departments
		WHERE id = $1
	`

	err := r.DB.QueryRow(ctx, query, departmentID).Scan(
		&department.ID,
		&department.Name,
		&department.Code,
	)

	if err != nil {
		return nil, err
	}

	return &department, nil
}

func (r *TokenRepository) CreateToken(
	ctx context.Context,
	token *models.Token,
	departmentCode string,
) error {

	// Check whether the department is paused.
	var isPaused bool

	pauseQuery := `
		SELECT is_paused
		FROM departments
		WHERE id = $1
	`

	err := r.DB.QueryRow(
		ctx,
		pauseQuery,
		token.DepartmentID,
	).Scan(&isPaused)

	if err != nil {
		return fmt.Errorf(
			"failed to check department status: %w",
			err,
		)
	}

	if isPaused {
		return fmt.Errorf(
			"department is currently paused",
		)
	}

	// Get the next token number safely using the counter table.
	var sequence int

	counterQuery := `
		INSERT INTO department_token_counters (
			department_id,
			queue_date,
			last_number
		)
		VALUES ($1, CURRENT_DATE, 1)
		ON CONFLICT (department_id, queue_date)
		DO UPDATE SET
			last_number = department_token_counters.last_number + 1
		RETURNING last_number
	`

	err = r.DB.QueryRow(
		ctx,
		counterQuery,
		token.DepartmentID,
	).Scan(&sequence)

	if err != nil {
		return fmt.Errorf(
			"failed to generate token number: %w",
			err,
		)
	}

	// Create the token number.
	token.TokenNumber = fmt.Sprintf(
		"%s-%03d",
		departmentCode,
		sequence,
	)

	// Insert the token into the database.
	insertQuery := `
		INSERT INTO tokens (
			token_number,
			department_id,
			visitor_name,
			priority,
			status,
			no_show_count,
			queue_date
		)
		VALUES ($1, $2, $3, $4, 'WAITING', 0, CURRENT_DATE)
		RETURNING id, queue_date, created_at, updated_at
	`

	err = r.DB.QueryRow(
		ctx,
		insertQuery,
		token.TokenNumber,
		token.DepartmentID,
		token.VisitorName,
		token.Priority,
	).Scan(
		&token.ID,
		&token.QueueDate,
		&token.CreatedAt,
		&token.UpdatedAt,
	)

	if err != nil {
		return err
	}

	token.Status = "WAITING"
	token.NoShowCount = 0

	return nil
}

func (r *TokenRepository) GetWaitingQueue(
	ctx context.Context,
	departmentID int,
) ([]models.Token, error) {

	// Get the average service time for this department first.
	var avgServiceMinutes int

	settingsQuery := `
		SELECT avg_service_minutes
		FROM department_settings
		WHERE department_id = $1
	`

	err := r.DB.QueryRow(
		ctx,
		settingsQuery,
		departmentID,
	).Scan(&avgServiceMinutes)

	if err != nil {
		return nil, fmt.Errorf(
			"failed to get average service time: %w",
			err,
		)
	}

	// Get the waiting queue.
	query := `
		SELECT
			id,
			token_number,
			department_id,
			visitor_name,
			priority,
			status,
			no_show_count,
			queue_date,
			created_at,
			updated_at,
			called_at,
			completed_at,
			cancelled_at
		FROM tokens
		WHERE department_id = $1
  AND queue_date = CURRENT_DATE
  AND status IN ('WAITING', 'SERVING')
		ORDER BY
    CASE WHEN no_show_count > 0 THEN 1 ELSE 0 END ASC,
    priority DESC,
    created_at ASC
	`

	rows, err := r.DB.Query(
		ctx,
		query,
		departmentID,
	)

	if err != nil {
		return nil, err
	}

	defer rows.Close()

	var tokens []models.Token

	position := 1

	for rows.Next() {

		var token models.Token

		err := rows.Scan(
			&token.ID,
			&token.TokenNumber,
			&token.DepartmentID,
			&token.VisitorName,
			&token.Priority,
			&token.Status,
			&token.NoShowCount,
			&token.QueueDate,
			&token.CreatedAt,
			&token.UpdatedAt,
			&token.CalledAt,
			&token.CompletedAt,
			&token.CancelledAt,
		)

		if err != nil {
			return nil, err
		}

		// Calculate live queue position and ETA.
		token.QueuePosition = position
		token.ETA = position * avgServiceMinutes

		tokens = append(tokens, token)

		position++
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return tokens, nil
}

func (r *TokenRepository) CallNext(
	ctx context.Context,
	departmentID int,
) (*models.Token, error) {

	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Check if a token is already being served.
	var servingCount int

	err = tx.QueryRow(
		ctx,
		`
    SELECT COUNT(*)
    FROM tokens
    WHERE department_id = $1
      AND queue_date = CURRENT_DATE
      AND status = 'SERVING'
    `,
		departmentID,
	).Scan(&servingCount)

	if err != nil {
		return nil, err
	}

	if servingCount > 0 {
		return nil, fmt.Errorf(
			"a token is already being served in this department",
		)
	}

	query := `
		SELECT
			id,
			token_number,
			department_id,
			visitor_name,
			priority,
			status,
			no_show_count,
			queue_date,
			created_at,
			called_at,
			completed_at,
			cancelled_at
		FROM tokens
		WHERE department_id = $1
		  AND queue_date = CURRENT_DATE
		  AND status = 'WAITING'
		ORDER BY
			CASE WHEN no_show_count > 0 THEN 1 ELSE 0 END ASC,
			priority DESC,
			created_at ASC
		FOR UPDATE SKIP LOCKED
		LIMIT 1
	`

	var token models.Token

	err = tx.QueryRow(
		ctx,
		query,
		departmentID,
	).Scan(
		&token.ID,
		&token.TokenNumber,
		&token.DepartmentID,
		&token.VisitorName,
		&token.Priority,
		&token.Status,
		&token.NoShowCount,
		&token.QueueDate,
		&token.CreatedAt,
		&token.CalledAt,
		&token.CompletedAt,
		&token.CancelledAt,
	)

	if err != nil {
		return nil, err
	}

	updateQuery := `
		UPDATE tokens
		SET
			status = 'SERVING',
			called_at = CURRENT_TIMESTAMP,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
		RETURNING
			called_at,
			updated_at
	`

	err = tx.QueryRow(
		ctx,
		updateQuery,
		token.ID,
	).Scan(
		&token.CalledAt,
		&token.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	token.Status = "SERVING"

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &token, nil
}

func (r *TokenRepository) CompleteToken(
	ctx context.Context,
	tokenID int64,
) (*models.Token, error) {

	query := `
		UPDATE tokens
		SET
			status = 'COMPLETED',
			completed_at = CURRENT_TIMESTAMP,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
		  AND status = 'SERVING'
		RETURNING
    id,
    token_number,
    department_id,
    visitor_name,
    priority,
    status,
    no_show_count,
    queue_date,
    created_at,
    called_at,
    completed_at,
    cancelled_at,
    updated_at
	`

	var token models.Token

	err := r.DB.QueryRow(
		ctx,
		query,
		tokenID,
	).Scan(
		&token.ID,
		&token.TokenNumber,
		&token.DepartmentID,
		&token.VisitorName,
		&token.Priority,
		&token.Status,
		&token.NoShowCount,
		&token.QueueDate,
		&token.CreatedAt,
		&token.CalledAt,
		&token.CompletedAt,
		&token.CancelledAt,
		&token.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &token, nil
}

func (r *TokenRepository) NoShowToken(
	ctx context.Context,
	tokenID int64,
) (*models.Token, error) {

	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Get the current token
	var token models.Token

	selectQuery := `
		SELECT
			id,
			token_number,
			department_id,
			visitor_name,
			priority,
			status,
			no_show_count,
			queue_date,
			created_at,
			called_at,
			completed_at,
			cancelled_at,
			updated_at
		FROM tokens
		WHERE id = $1
		FOR UPDATE
	`

	err = tx.QueryRow(ctx, selectQuery, tokenID).Scan(
		&token.ID,
		&token.TokenNumber,
		&token.DepartmentID,
		&token.VisitorName,
		&token.Priority,
		&token.Status,
		&token.NoShowCount,
		&token.QueueDate,
		&token.CreatedAt,
		&token.CalledAt,
		&token.CompletedAt,
		&token.CancelledAt,
		&token.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	// First No Show → send token back to waiting queue
	if token.NoShowCount == 0 {

		updateQuery := `
			UPDATE tokens
			SET
				status = 'WAITING',
				no_show_count = 1,
				called_at = NULL,
				updated_at = CURRENT_TIMESTAMP,
				created_at = CURRENT_TIMESTAMP
			WHERE id = $1
			RETURNING
				no_show_count,
				status,
				updated_at
		`

		err = tx.QueryRow(
			ctx,
			updateQuery,
			tokenID,
		).Scan(
			&token.NoShowCount,
			&token.Status,
			&token.UpdatedAt,
		)

		if err != nil {
			return nil, err
		}

		token.CalledAt = nil

	} else {

		// Second No Show → automatically cancel
		updateQuery := `
			UPDATE tokens
			SET
				status = 'CANCELLED',
				no_show_count = no_show_count + 1,
				cancelled_at = CURRENT_TIMESTAMP,
				updated_at = CURRENT_TIMESTAMP
			WHERE id = $1
			RETURNING
				no_show_count,
				status,
				cancelled_at,
				updated_at
		`

		err = tx.QueryRow(
			ctx,
			updateQuery,
			tokenID,
		).Scan(
			&token.NoShowCount,
			&token.Status,
			&token.CancelledAt,
			&token.UpdatedAt,
		)

		if err != nil {
			return nil, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &token, nil
}

func (r *TokenRepository) TransferToken(
	ctx context.Context,
	tokenID int64,
	toDepartmentID int,
) (*models.Token, error) {

	tx, err := r.DB.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	// Get the current token and lock it.
	var token models.Token

	selectQuery := `
		SELECT
			id,
			token_number,
			department_id,
			visitor_name,
			priority,
			status,
			no_show_count,
			queue_date,
			created_at,
			called_at,
			completed_at,
			cancelled_at
		FROM tokens
		WHERE id = $1
		FOR UPDATE
	`

	err = tx.QueryRow(ctx, selectQuery, tokenID).Scan(
		&token.ID,
		&token.TokenNumber,
		&token.DepartmentID,
		&token.VisitorName,
		&token.Priority,
		&token.Status,
		&token.NoShowCount,
		&token.QueueDate,
		&token.CreatedAt,
		&token.CalledAt,
		&token.CompletedAt,
		&token.CancelledAt,
	)

	if err != nil {
		return nil, err
	}

	// Save the original department before changing the token.
	fromDepartmentID := token.DepartmentID

	// Get the destination department and check whether it is paused.
	var destination models.Department
	var destinationPaused bool

	departmentQuery := `
	SELECT
		id,
		name,
		code,
		is_paused
	FROM departments
	WHERE id = $1
`

	err = tx.QueryRow(
		ctx,
		departmentQuery,
		toDepartmentID,
	).Scan(
		&destination.ID,
		&destination.Name,
		&destination.Code,
		&destinationPaused,
	)

	if err != nil {
		return nil, err
	}

	if destinationPaused {
		return nil, fmt.Errorf(
			"destination department is currently paused",
		)
	}

	// Generate the next token number using the department counter.
	var sequence int

	counterQuery := `
		INSERT INTO department_token_counters (
			department_id,
			queue_date,
			last_number
		)
		VALUES ($1, CURRENT_DATE, 1)
		ON CONFLICT (department_id, queue_date)
		DO UPDATE SET
			last_number = department_token_counters.last_number + 1
		RETURNING last_number
	`

	err = tx.QueryRow(
		ctx,
		counterQuery,
		toDepartmentID,
	).Scan(&sequence)

	if err != nil {
		return nil, fmt.Errorf(
			"failed to generate transfer token number: %w",
			err,
		)
	}

	newTokenNumber := fmt.Sprintf(
		"%s-%03d",
		destination.Code,
		sequence,
	)

	// Move the token to the new department.
	updateQuery := `
		UPDATE tokens
		SET
			department_id = $1,
			token_number = $2,
			status = 'WAITING',
			called_at = NULL,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $3
		RETURNING
			department_id,
			token_number,
			status,
			called_at,
			updated_at
	`

	err = tx.QueryRow(
		ctx,
		updateQuery,
		toDepartmentID,
		newTokenNumber,
		tokenID,
	).Scan(
		&token.DepartmentID,
		&token.TokenNumber,
		&token.Status,
		&token.CalledAt,
		&token.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	// Record the transfer.
	// Use fromDepartmentID because token.DepartmentID now contains
	// the destination department.
	eventQuery := `
		INSERT INTO token_events (
			token_id,
			event_type,
			from_department_id,
			to_department_id,
			notes
		)
		VALUES (
			$1,
			'TRANSFER',
			$2,
			$3,
			'Token transferred to another department'
		)
	`

	_, err = tx.Exec(
		ctx,
		eventQuery,
		tokenID,
		fromDepartmentID,
		toDepartmentID,
	)

	if err != nil {
		return nil, err
	}

	// Commit the transaction.
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}

	return &token, nil
}

func (r *TokenRepository) CancelToken(
	ctx context.Context,
	tokenID int64,
) (*models.Token, error) {

	query := `
		UPDATE tokens
		SET
			status = 'CANCELLED',
			cancelled_at = CURRENT_TIMESTAMP,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
		  AND status = 'WAITING'
		RETURNING
			id,
			token_number,
			department_id,
			visitor_name,
			priority,
			status,
			no_show_count,
			queue_date,
			created_at,
			called_at,
			completed_at,
			cancelled_at,
			updated_at
	`

	var token models.Token

	err := r.DB.QueryRow(
		ctx,
		query,
		tokenID,
	).Scan(
		&token.ID,
		&token.TokenNumber,
		&token.DepartmentID,
		&token.VisitorName,
		&token.Priority,
		&token.Status,
		&token.NoShowCount,
		&token.QueueDate,
		&token.CreatedAt,
		&token.CalledAt,
		&token.CompletedAt,
		&token.CancelledAt,
		&token.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &token, nil
}

func (r *TokenRepository) GetTokenByID(
	ctx context.Context,
	tokenID int64,
) (*models.Token, error) {

	query := `
		SELECT
			id,
			token_number,
			department_id,
			visitor_name,
			priority,
			status,
			no_show_count,
			queue_date,
			created_at,
			updated_at,
			called_at,
			completed_at,
			cancelled_at
		FROM tokens
		WHERE id = $1
	`

	var token models.Token

	err := r.DB.QueryRow(
		ctx,
		query,
		tokenID,
	).Scan(
		&token.ID,
		&token.TokenNumber,
		&token.DepartmentID,
		&token.VisitorName,
		&token.Priority,
		&token.Status,
		&token.NoShowCount,
		&token.QueueDate,
		&token.CreatedAt,
		&token.UpdatedAt,
		&token.CalledAt,
		&token.CompletedAt,
		&token.CancelledAt,
	)

	if err != nil {
		return nil, err
	}

	return &token, nil
}
