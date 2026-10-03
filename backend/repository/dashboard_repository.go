package repository

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5"
)

type DashboardStats struct {
	WaitingCount       int     `json:"waiting_count"`
	ServingCount       int     `json:"serving_count"`
	CompletedCount     int     `json:"completed_count"`
	NoShowCount        int     `json:"no_show_count"`
	AverageWaitingTime float64 `json:"average_waiting_time_minutes"`
}

type DashboardRepository struct {
	DB interface {
		QueryRow(context.Context, string, ...interface{}) pgx.Row
	}
}

func NewDashboardRepository(db interface {
	QueryRow(context.Context, string, ...interface{}) pgx.Row
}) *DashboardRepository {
	return &DashboardRepository{
		DB: db,
	}
}

func (r *DashboardRepository) GetDashboardStats(
	ctx context.Context,
	departmentID int,
) (*DashboardStats, error) {

	query := `
		SELECT
			COUNT(*) FILTER (
				WHERE status = 'WAITING'
			) AS waiting_count,

			COUNT(*) FILTER (
				WHERE status = 'SERVING'
			) AS serving_count,

			COUNT(*) FILTER (
				WHERE status = 'COMPLETED'
			) AS completed_count,

			COUNT(*) FILTER (WHERE no_show_count > 0) AS no_show_count,

			COALESCE(
    AVG(
        EXTRACT(EPOCH FROM (called_at - created_at)) / 60
    ) FILTER (
        WHERE called_at IS NOT NULL
        AND queue_date = CURRENT_DATE
        AND status IN ('SERVING', 'COMPLETED')
    ),
    0
) AS average_waiting_time

		FROM tokens
		WHERE department_id = $1
		  AND queue_date = CURRENT_DATE
	`

	var stats DashboardStats

	err := r.DB.QueryRow(
		ctx,
		query,
		departmentID,
	).Scan(
		&stats.WaitingCount,
		&stats.ServingCount,
		&stats.CompletedCount,
		&stats.NoShowCount,
		&stats.AverageWaitingTime,
	)

	if err != nil {
		return nil, fmt.Errorf(
			"failed to get dashboard statistics: %w",
			err,
		)
	}

	return &stats, nil
}
