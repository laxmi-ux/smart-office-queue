package services

import (
	"context"

	"smart-office-queue/backend/repository"
)

type DashboardService struct {
	DashboardRepository *repository.DashboardRepository
}

func NewDashboardService(
	dashboardRepository *repository.DashboardRepository,
) *DashboardService {
	return &DashboardService{
		DashboardRepository: dashboardRepository,
	}
}

func (s *DashboardService) GetDashboardStats(
	ctx context.Context,
	departmentID int,
) (*repository.DashboardStats, error) {

	return s.DashboardRepository.GetDashboardStats(
		ctx,
		departmentID,
	)
}
