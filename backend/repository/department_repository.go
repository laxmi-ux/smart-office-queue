package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"

	"smart-office-queue/backend/models"
)

type DepartmentRepository struct {
	DB *pgx.Conn
}

func NewDepartmentRepository(db *pgx.Conn) *DepartmentRepository {
	return &DepartmentRepository{
		DB: db,
	}
}

func (r *DepartmentRepository) GetAllDepartments(ctx context.Context) ([]models.Department, error) {

	query := `
	SELECT
		id,
		name,
		code,
		is_paused
	FROM departments
	ORDER BY id
`

	rows, err := r.DB.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var departments []models.Department

	for rows.Next() {
		var department models.Department

		err := rows.Scan(
			&department.ID,
			&department.Name,
			&department.Code,
			&department.IsPaused,
		)
		if err != nil {
			return nil, err
		}

		departments = append(departments, department)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return departments, nil
}

func (r *DepartmentRepository) SetDepartmentPause(
	ctx context.Context,
	departmentID int,
	paused bool,
) error {

	query := `
		UPDATE departments
		SET is_paused = $1
		WHERE id = $2
	`

	result, err := r.DB.Exec(
		ctx,
		query,
		paused,
		departmentID,
	)

	if err != nil {
		return err
	}

	if result.RowsAffected() == 0 {
		return fmt.Errorf("department not found")
	}

	return nil
}
