package models

type Department struct {
	ID       int    `json:"id"`
	Name     string `json:"name"`
	Code     string `json:"code"`
	IsPaused bool   `json:"is_paused"`
}
