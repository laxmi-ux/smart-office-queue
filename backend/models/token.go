package models

import "time"

type Token struct {
	ID           int64      `json:"id"`
	TokenNumber  string     `json:"token_number"`
	DepartmentID int        `json:"department_id"`
	VisitorName  string     `json:"visitor_name"`
	Priority     bool       `json:"priority"`
	Status       string     `json:"status"`
	NoShowCount  int        `json:"no_show_count"`
	QueueDate    time.Time  `json:"queue_date"`
	CreatedAt    time.Time  `json:"created_at"`
	CalledAt     *time.Time `json:"called_at,omitempty"`
	UpdatedAt time.Time `json:"updated_at"`
	CompletedAt  *time.Time `json:"completed_at,omitempty"`
	CancelledAt  *time.Time `json:"cancelled_at,omitempty"`

	QueuePosition int `json:"queue_position"`
	ETA           int `json:"eta_minutes"`
}