package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"smart-office-queue/backend/services"
)

type TokenHandler struct {
	TokenService *services.TokenService
}

func NewTokenHandler(tokenService *services.TokenService) *TokenHandler {
	return &TokenHandler{
		TokenService: tokenService,
	}
}

type CreateTokenRequest struct {
	DepartmentID int    `json:"department_id"`
	VisitorName  string `json:"visitor_name"`
	Priority     bool   `json:"priority"`
}

func (h *TokenHandler) CreateToken(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var request CreateTokenRequest

	err := json.NewDecoder(r.Body).Decode(&request)
	if err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if request.DepartmentID <= 0 {
		http.Error(w, "Department ID is required", http.StatusBadRequest)
		return
	}

	token, err := h.TokenService.CreateToken(
		context.Background(),
		request.DepartmentID,
		request.VisitorName,
		request.Priority,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)

	json.NewEncoder(w).Encode(token)
}

func (h *TokenHandler) GetWaitingQueue(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	departmentID := r.URL.Query().Get("department_id")

	if departmentID == "" {
		http.Error(w, "department_id is required", http.StatusBadRequest)
		return
	}

	var id int

	_, err := fmt.Sscanf(departmentID, "%d", &id)
	if err != nil || id <= 0 {
		http.Error(w, "Invalid department_id", http.StatusBadRequest)
		return
	}

	tokens, err := h.TokenService.GetWaitingQueue(
		r.Context(),
		id,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	json.NewEncoder(w).Encode(tokens)
}

func (h *TokenHandler) CallNext(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	departmentID := r.URL.Query().Get("department_id")

	if departmentID == "" {
		http.Error(w, "department_id is required", http.StatusBadRequest)
		return
	}

	var id int

	_, err := fmt.Sscanf(departmentID, "%d", &id)
	if err != nil || id <= 0 {
		http.Error(w, "Invalid department_id", http.StatusBadRequest)
		return
	}

	token, err := h.TokenService.CallNext(
		r.Context(),
		id,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(token)
}

func (h *TokenHandler) CompleteToken(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tokenID := r.URL.Query().Get("token_id")

	if tokenID == "" {
		http.Error(w, "token_id is required", http.StatusBadRequest)
		return
	}

	var id int64

	_, err := fmt.Sscanf(tokenID, "%d", &id)
	if err != nil || id <= 0 {
		http.Error(w, "Invalid token_id", http.StatusBadRequest)
		return
	}

	token, err := h.TokenService.CompleteToken(
		r.Context(),
		id,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(token)
}

func (h *TokenHandler) NoShowToken(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tokenID := r.URL.Query().Get("token_id")

	if tokenID == "" {
		http.Error(w, "token_id is required", http.StatusBadRequest)
		return
	}

	var id int64

	_, err := fmt.Sscanf(tokenID, "%d", &id)
	if err != nil || id <= 0 {
		http.Error(w, "Invalid token_id", http.StatusBadRequest)
		return
	}

	token, err := h.TokenService.NoShowToken(
		r.Context(),
		id,
	)

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(token)
}

func (h *TokenHandler) TransferToken(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	tokenID := r.URL.Query().Get("token_id")
	toDepartmentID := r.URL.Query().Get("to_department_id")

	if tokenID == "" || toDepartmentID == "" {
		http.Error(
			w,
			"token_id and to_department_id are required",
			http.StatusBadRequest,
		)
		return
	}

	var tokenIDInt int64
	var departmentIDInt int

	_, err := fmt.Sscanf(tokenID, "%d", &tokenIDInt)
	if err != nil {
		http.Error(
			w,
			"Invalid token_id",
			http.StatusBadRequest,
		)
		return
	}

	_, err = fmt.Sscanf(toDepartmentID, "%d", &departmentIDInt)
	if err != nil {
		http.Error(
			w,
			"Invalid to_department_id",
			http.StatusBadRequest,
		)
		return
	}

	token, err := h.TokenService.TransferToken(
		r.Context(),
		tokenIDInt,
		departmentIDInt,
	)

	if err != nil {
		http.Error(
			w,
			err.Error(),
			http.StatusInternalServerError,
		)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	json.NewEncoder(w).Encode(token)
}

func (h *TokenHandler) CancelToken(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(
			w,
			"Method not allowed",
			http.StatusMethodNotAllowed,
		)
		return
	}

	tokenID := r.URL.Query().Get("token_id")

	if tokenID == "" {
		http.Error(
			w,
			"token_id is required",
			http.StatusBadRequest,
		)
		return
	}

	var tokenIDInt int64

	_, err := fmt.Sscanf(tokenID, "%d", &tokenIDInt)

	if err != nil {
		http.Error(
			w,
			"Invalid token_id",
			http.StatusBadRequest,
		)
		return
	}

	token, err := h.TokenService.CancelToken(
		r.Context(),
		tokenIDInt,
	)

	if err != nil {
		http.Error(
			w,
			err.Error(),
			http.StatusInternalServerError,
		)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	json.NewEncoder(w).Encode(token)
}

func (h *TokenHandler) GetTokenStatus(w http.ResponseWriter, r *http.Request) {
	tokenIDStr := r.URL.Query().Get("token_id")

	if tokenIDStr == "" {
		http.Error(w, "token_id is required", http.StatusBadRequest)
		return
	}

	tokenID, err := strconv.ParseInt(tokenIDStr, 10, 64)
	if err != nil {
		http.Error(w, "invalid token_id", http.StatusBadRequest)
		return
	}

	token, err := h.TokenService.GetTokenByID(
		r.Context(),
		tokenID,
	)

	if err != nil {
		http.Error(w, "token not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")

	if err := json.NewEncoder(w).Encode(token); err != nil {
		http.Error(
			w,
			"failed to encode response",
			http.StatusInternalServerError,
		)
	}
}
