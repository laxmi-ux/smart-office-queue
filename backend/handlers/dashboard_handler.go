package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"smart-office-queue/backend/services"
)

type DashboardHandler struct {
	DashboardService *services.DashboardService
}

func NewDashboardHandler(
	dashboardService *services.DashboardService,
) *DashboardHandler {
	return &DashboardHandler{
		DashboardService: dashboardService,
	}
}

func (h *DashboardHandler) GetDashboardStats(
	w http.ResponseWriter,
	r *http.Request,
) {
	if r.Method != http.MethodGet {
		http.Error(
			w,
			"Method not allowed",
			http.StatusMethodNotAllowed,
		)
		return
	}

	departmentIDString := r.URL.Query().Get("department_id")

	if departmentIDString == "" {
		http.Error(
			w,
			"department_id is required",
			http.StatusBadRequest,
		)
		return
	}

	departmentID, err := strconv.Atoi(departmentIDString)

	if err != nil {
		http.Error(
			w,
			"Invalid department_id",
			http.StatusBadRequest,
		)
		return
	}

	stats, err := h.DashboardService.GetDashboardStats(
		r.Context(),
		departmentID,
	)

	if err != nil {
		http.Error(
			w,
			"Failed to get dashboard statistics",
			http.StatusInternalServerError,
		)
		return
	}

	w.Header().Set(
		"Content-Type",
		"application/json",
	)

	json.NewEncoder(w).Encode(stats)
}
