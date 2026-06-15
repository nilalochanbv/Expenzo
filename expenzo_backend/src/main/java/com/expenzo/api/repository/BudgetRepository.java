package com.expenzo.api.repository;

import com.expenzo.api.model.Budget;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface BudgetRepository extends JpaRepository<Budget, String> {
    List<Budget> findByUserIdAndIsDeletedFalse(Long userId);
    List<Budget> findByUserIdAndLastUpdatedAfter(Long userId, LocalDateTime timestamp);
    Optional<Budget> findByUserIdAndCategoryAndMonthAndYearAndIsDeletedFalse(Long userId, String category, Integer month, Integer year);
}
