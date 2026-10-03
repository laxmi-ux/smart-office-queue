package handlers

import (
	"encoding/json"
	"net/http"

	"smart-office-queue/backend/services"
)

type AuthHandler struct {
	AuthService *services.AuthService
}

func NewAuthHandler(
	authService *services.AuthService,
) *AuthHandler {
	return &AuthHandler{
		AuthService: authService,
	}
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) Login(
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

	var request LoginRequest

	err := json.NewDecoder(r.Body).Decode(&request)
	if err != nil {
		http.Error(
			w,
			"Invalid request body",
			http.StatusBadRequest,
		)
		return
	}

	if request.Email == "" || request.Password == "" {
		http.Error(
			w,
			"Email and password are required",
			http.StatusBadRequest,
		)
		return
	}

	result, err := h.AuthService.Login(
		r.Context(),
		request.Email,
		request.Password,
	)

	if err != nil {
		http.Error(
			w,
			err.Error(),
			http.StatusUnauthorized,
		)
		return
	}

	w.Header().Set(
		"Content-Type",
		"application/json",
	)

	json.NewEncoder(w).Encode(map[string]interface{}{
		"message": "Login successful",
		"token":   result.Token,
		"user":    result.User,
	})
}
