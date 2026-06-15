package com.expenzo.api.repository;

import com.expenzo.api.model.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, String> {
    List<Expense> findByUserIdAndIsDeletedFalse(Long userId);
    List<Expense> findByUserIdAndLastUpdatedAfter(Long userId, LocalDateTime timestamp);
    List<Expense> findByUserIdAndCreatedAtBetweenAndIsDeletedFalse(Long userId, LocalDateTime start, LocalDateTime end);
    List<Expense> findByUserIdAndDescriptionContainingIgnoreCaseAndIsDeletedFalse(Long userId, String query);
    List<Expense> findByUserIdAndCategoryAndIsDeletedFalse(Long userId, String category);
}
