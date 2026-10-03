package middleware

import (
	"context"
	"net/http"
	"os"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

type contextKey string

const (
	UserIDKey contextKey = "user_id"
	RoleKey   contextKey = "role"
)

func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		authHeader := r.Header.Get("Authorization")

		if authHeader == "" {
			http.Error(
				w,
				"Authorization header is required",
				http.StatusUnauthorized,
			)
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)

		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(
				w,
				"Invalid Authorization header",
				http.StatusUnauthorized,
			)
			return
		}

		tokenString := parts[1]

		jwtSecret := os.Getenv("JWT_SECRET")

		if jwtSecret == "" {
			http.Error(
				w,
				"JWT_SECRET is not configured",
				http.StatusInternalServerError,
			)
			return
		}

		token, err := jwt.Parse(
			tokenString,
			func(token *jwt.Token) (interface{}, error) {

				if token.Method != jwt.SigningMethodHS256 {
					return nil, jwt.ErrSignatureInvalid
				}

				return []byte(jwtSecret), nil
			},
		)

		if err != nil || !token.Valid {
			http.Error(
				w,
				"Invalid or expired token",
				http.StatusUnauthorized,
			)
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			http.Error(
				w,
				"Invalid token claims",
				http.StatusUnauthorized,
			)
			return
		}

		ctx := context.WithValue(
			r.Context(),
			UserIDKey,
			claims["user_id"],
		)

		ctx = context.WithValue(
			ctx,
			RoleKey,
			claims["role"],
		)

		next.ServeHTTP(
			w,
			r.WithContext(ctx),
		)
	})
}

func RequireRole(allowedRoles ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

			role := r.Context().Value(RoleKey)

			if role == nil {
				http.Error(
					w,
					"User role not found",
					http.StatusForbidden,
				)
				return
			}

			userRole, ok := role.(string)

			if !ok {
				http.Error(
					w,
					"Invalid user role",
					http.StatusForbidden,
				)
				return
			}

			for _, allowedRole := range allowedRoles {
				if userRole == allowedRole {
					next.ServeHTTP(w, r)
					return
				}
			}

			http.Error(
				w,
				"Access denied",
				http.StatusForbidden,
			)
		})
	}
}