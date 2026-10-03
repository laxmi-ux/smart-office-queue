package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"

	"smart-office-queue/backend/models"
)

type UserRepository struct {
	DB interface {
		QueryRow(context.Context, string, ...interface{}) pgx.Row
	}
}

func NewUserRepository(db interface {
	QueryRow(context.Context, string, ...interface{}) pgx.Row
}) *UserRepository {
	return &UserRepository{
		DB: db,
	}
}

func (r *UserRepository) GetUserByEmail(
	ctx context.Context,
	email string,
) (*models.User, error) {

	query := `
		SELECT
			id,
			name,
			email,
			password_hash,
			role,
			department_id,
			is_active,
			created_at
		FROM users
		WHERE email = $1
	`

	var user models.User

	err := r.DB.QueryRow(
		ctx,
		query,
		email,
	).Scan(
		&user.ID,
		&user.Name,
		&user.Email,
		&user.PasswordHash,
		&user.Role,
		&user.DepartmentID,
		&user.IsActive,
		&user.CreatedAt,
	)

	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}

		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}
