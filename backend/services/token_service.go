package services

import (
	"context"
	"fmt"

	"smart-office-queue/backend/models"
	"smart-office-queue/backend/repository"
)

type TokenService struct {
	TokenRepository *repository.TokenRepository
}

func NewTokenService(
	tokenRepository *repository.TokenRepository,
) *TokenService {
	return &TokenService{
		TokenRepository: tokenRepository,
	}
}

func (s *TokenService) CreateToken(
	ctx context.Context,
	departmentID int,
	visitorName string,
	priority bool,
) (*models.Token, error) {

	// Find the selected department
	department, err := s.TokenRepository.GetDepartmentByID(
		ctx,
		departmentID,
	)
	if err != nil {
		return nil, fmt.Errorf("department not found: %w", err)
	}

	// Create the token
	token := &models.Token{
		DepartmentID: department.ID,
		VisitorName:  visitorName,
		Priority:     priority,
	}

	err = s.TokenRepository.CreateToken(
		ctx,
		token,
		department.Code,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create token: %w", err)
	}

	return token, nil
}

func (s *TokenService) GetWaitingQueue(
	ctx context.Context,
	departmentID int,
) ([]models.Token, error) {

	tokens, err := s.TokenRepository.GetWaitingQueue(
		ctx,
		departmentID,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to get waiting queue: %w", err)
	}

	return tokens, nil
}

func (s *TokenService) CallNext(
	ctx context.Context,
	departmentID int,
) (*models.Token, error) {

	token, err := s.TokenRepository.CallNext(
		ctx,
		departmentID,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to call next token: %w", err)
	}

	return token, nil
}

func (s *TokenService) CompleteToken(
	ctx context.Context,
	tokenID int64,
) (*models.Token, error) {

	token, err := s.TokenRepository.CompleteToken(
		ctx,
		tokenID,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to complete token: %w", err)
	}

	return token, nil
}

func (s *TokenService) NoShowToken(
	ctx context.Context,
	tokenID int64,
) (*models.Token, error) {

	token, err := s.TokenRepository.NoShowToken(
		ctx,
		tokenID,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to mark token as no-show: %w", err)
	}

	return token, nil
}

func (s *TokenService) TransferToken(
	ctx context.Context,
	tokenID int64,
	toDepartmentID int,
) (*models.Token, error) {

	token, err := s.TokenRepository.TransferToken(
		ctx,
		tokenID,
		toDepartmentID,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to transfer token: %w", err)
	}

	return token, nil
}

func (s *TokenService) CancelToken(
	ctx context.Context,
	tokenID int64,
) (*models.Token, error) {

	token, err := s.TokenRepository.CancelToken(
		ctx,
		tokenID,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to cancel token: %w", err)
	}

	return token, nil
}

func (s *TokenService) GetTokenByID(
	ctx context.Context,
	tokenID int64,
) (*models.Token, error) {

	return s.TokenRepository.GetTokenByID(ctx, tokenID)
}
