package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"smart-office-queue/backend/repository"
	"smart-office-queue/backend/services"
)

type DepartmentHandler struct {
	Repository        *repository.DepartmentRepository
	DepartmentService *services.DepartmentService
}

func NewDepartmentHandler(
	departmentRepository *repository.DepartmentRepository,
	departmentService *services.DepartmentService,
) *DepartmentHandler {
	return &DepartmentHandler{
		Repository:        departmentRepository,
		DepartmentService: departmentService,
	}
}

func (h *DepartmentHandler) GetDepartments(
	w http.ResponseWriter,
	r *http.Request,
) {

	departments, err := h.Repository.GetAllDepartments(context.Background())

	if err != nil {
		http.Error(
			w,
			"Failed to fetch departments",
			http.StatusInternalServerError,
		)
		return
	}

	w.Header().Set(
		"Content-Type",
		"application/json",
	)

	json.NewEncoder(w).Encode(departments)
}

func (h *DepartmentHandler) SetDepartmentPause(
	w http.ResponseWriter,
	r *http.Request,
) {

	if r.Method != http.MethodPost {
		http.Error(
			w,
			"Method not allowed",
			http.StatusMethodNotAllowed,
		)
		return
	}

	departmentID := r.URL.Query().Get("department_id")
	paused := r.URL.Query().Get("paused")

	if departmentID == "" || paused == "" {
		http.Error(
			w,
			"department_id and paused are required",
			http.StatusBadRequest,
		)
		return
	}

	var departmentIDInt int

	_, err := fmt.Sscanf(
		departmentID,
		"%d",
		&departmentIDInt,
	)

	if err != nil {
		http.Error(
			w,
			"Invalid department_id",
			http.StatusBadRequest,
		)
		return
	}

	var pausedBool bool

	if paused == "true" {
		pausedBool = true
	} else if paused == "false" {
		pausedBool = false
	} else {
		http.Error(
			w,
			"paused must be true or false",
			http.StatusBadRequest,
		)
		return
	}

	err = h.DepartmentService.SetDepartmentPause(
		r.Context(),
		departmentIDInt,
		pausedBool,
	)

	if err != nil {
		http.Error(
			w,
			err.Error(),
			http.StatusInternalServerError,
		)
		return
	}

	w.Header().Set(
		"Content-Type",
		"application/json",
	)

	fmt.Fprintf(
		w,
		`{"message":"Department pause status updated successfully","department_id":%d,"is_paused":%t}`,
		departmentIDInt,
		pausedBool,
	)
}
