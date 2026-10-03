package services

import (
	"context"
	"fmt"

	"golang.org/x/crypto/bcrypt"

	"smart-office-queue/backend/models"
	"smart-office-queue/backend/repository"
	"smart-office-queue/backend/utils"
)

type AuthService struct {
	UserRepository *repository.UserRepository
}

func NewAuthService(
	userRepository *repository.UserRepository,
) *AuthService {
	return &AuthService{
		UserRepository: userRepository,
	}
}

type LoginResult struct {
	User  *models.User `json:"user"`
	Token string       `json:"token"`
}

func (s *AuthService) Login(
	ctx context.Context,
	email string,
	password string,
) (*LoginResult, error) {

	user, err := s.UserRepository.GetUserByEmail(
		ctx,
		email,
	)

	if err != nil {
		return nil, fmt.Errorf("invalid email or password")
	}

	if !user.IsActive {
		return nil, fmt.Errorf("user account is inactive")
	}

	err = bcrypt.CompareHashAndPassword(
		[]byte(user.PasswordHash),
		[]byte(password),
	)

	if err != nil {
		return nil, fmt.Errorf("invalid email or password")
	}

	token, err := utils.GenerateToken(
		user.ID,
		user.Role,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to generate authentication token")
	}

	return &LoginResult{
		User:  user,
		Token: token,
	}, nil
}
