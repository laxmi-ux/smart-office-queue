package main

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"smart-office-queue/backend/database"
	"smart-office-queue/backend/handlers"
	"smart-office-queue/backend/middleware"
	"smart-office-queue/backend/repository"
	"smart-office-queue/backend/services"
)

func main() {

	// Connect to PostgreSQL
	db, err := database.Connect()
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close(context.Background())

	// ---------------------------------
	// Department repository and service
	// ---------------------------------

	departmentRepository := repository.NewDepartmentRepository(db)

	departmentService := services.NewDepartmentService(
		departmentRepository,
	)

	departmentHandler := handlers.NewDepartmentHandler(
		departmentRepository,
		departmentService,
	)

	// ---------------------------------
	// Authentication repository, service and handler
	// ---------------------------------

	userRepository := repository.NewUserRepository(db)

	authService := services.NewAuthService(
		userRepository,
	)

	authHandler := handlers.NewAuthHandler(
		authService,
	)

	// ---------------------------------
	// Token repository, service and handler
	// ---------------------------------

	tokenRepository := repository.NewTokenRepository(db)

	tokenService := services.NewTokenService(
		tokenRepository,
	)

	tokenHandler := handlers.NewTokenHandler(
		tokenService,
	)

	// ---------------------------------
	// Dashboard repository, service and handler
	// ---------------------------------

	dashboardRepository := repository.NewDashboardRepository(db)

	dashboardService := services.NewDashboardService(
		dashboardRepository,
	)

	dashboardHandler := handlers.NewDashboardHandler(
		dashboardService,
	)

	// ---------------------------------
	// Routes
	// ---------------------------------

	// Authentication
	http.HandleFunc(
		"/api/auth/login",
		authHandler.Login,
	)

	// ---------------------------------
	// Public department routes
	// ---------------------------------

	http.HandleFunc(
		"/api/departments",
		departmentHandler.GetDepartments,
	)

	// ---------------------------------
	// Public visitor routes
	// ---------------------------------

	http.HandleFunc(
		"/api/tokens",
		tokenHandler.CreateToken,
	)

	http.HandleFunc(
		"/api/queue",
		tokenHandler.GetWaitingQueue,
	)

	// ---------------------------------
	// Dashboard route
	// ---------------------------------

	http.Handle(
		"/api/dashboard",
		middleware.AuthMiddleware(
			middleware.RequireRole("ADMIN", "STAFF")(
				http.HandlerFunc(
					dashboardHandler.GetDashboardStats,
				),
			),
		),
	)
	// ---------------------------------
	// Protected staff/admin routes
	// ---------------------------------

	http.Handle(
		"/api/departments/pause",
		middleware.AuthMiddleware(
			middleware.RequireRole("ADMIN")(
				http.HandlerFunc(
					departmentHandler.SetDepartmentPause,
				),
			),
		),
	)

	http.Handle(
		"/api/queue/next",
		middleware.AuthMiddleware(
			middleware.RequireRole("ADMIN", "STAFF")(
				http.HandlerFunc(
					tokenHandler.CallNext,
				),
			),
		),
	)

	http.Handle(
		"/api/queue/complete",
		middleware.AuthMiddleware(
			middleware.RequireRole("ADMIN", "STAFF")(
				http.HandlerFunc(
					tokenHandler.CompleteToken,
				),
			),
		),
	)

	http.Handle(
		"/api/queue/no-show",
		middleware.AuthMiddleware(
			middleware.RequireRole("ADMIN", "STAFF")(
				http.HandlerFunc(
					tokenHandler.NoShowToken,
				),
			),
		),
	)

	http.Handle(
		"/api/queue/transfer",
		middleware.AuthMiddleware(
			middleware.RequireRole("ADMIN", "STAFF")(
				http.HandlerFunc(
					tokenHandler.TransferToken,
				),
			),
		),
	)

	http.HandleFunc(
		"/api/queue/cancel",
		tokenHandler.CancelToken,
	)

	http.HandleFunc(
		"/api/tokens/status",
		tokenHandler.GetTokenStatus,
	)
	// ---------------------------------
	// Start server
	// ---------------------------------

	fmt.Println("Server running on http://localhost:8080")

	handler := corsMiddleware(http.DefaultServeMux)

	err = http.ListenAndServe(":8080", handler)
	if err != nil {
		log.Fatal(err)
	}
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set(
			"Access-Control-Allow-Methods",
			"GET, POST, PUT, DELETE, OPTIONS",
		)
		w.Header().Set(
			"Access-Control-Allow-Headers",
			"Content-Type, Authorization",
		)

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}
