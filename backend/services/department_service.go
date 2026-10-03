package services

import (
	"context"
	"fmt"

	"smart-office-queue/backend/repository"
)

type DepartmentService struct {
	DepartmentRepository *repository.DepartmentRepository
}

func NewDepartmentService(
	departmentRepository *repository.DepartmentRepository,
) *DepartmentService {
	return &DepartmentService{
		DepartmentRepository: departmentRepository,
	}
}

func (s *DepartmentService) SetDepartmentPause(
	ctx context.Context,
	departmentID int,
	paused bool,
) error {

	err := s.DepartmentRepository.SetDepartmentPause(
		ctx,
		departmentID,
		paused,
	)

	if err != nil {
		return fmt.Errorf(
			"failed to update department pause status: %w",
			err,
		)
	}

	return nil
}
