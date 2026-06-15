package com.expenzo.api.service;

import com.expenzo.api.model.Budget;
import com.expenzo.api.model.Expense;
import com.expenzo.api.repository.BudgetRepository;
import com.expenzo.api.repository.ExpenseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.List;
import java.util.Optional;

@Service
public class BudgetService {

    @Autowired
    private BudgetRepository budgetRepository;

    @Autowired
    private ExpenseRepository expenseRepository;

    public List<Budget> getAllBudgets(Long userId) {
        return budgetRepository.findByUserIdAndIsDeletedFalse(userId);
    }

    public List<Budget> getBudgetsSince(Long userId, LocalDateTime timestamp) {
        return budgetRepository.findByUserIdAndLastUpdatedAfter(userId, timestamp);
    }

    public Budget saveBudget(Budget budget, Long userId) {
        budget.setUserId(userId);
        budget.setLastUpdated(LocalDateTime.now());
        return budgetRepository.save(budget);
    }

    public void deleteBudget(String id, Long userId) {
        Optional<Budget> optionalBudget = budgetRepository.findById(id);
        if (optionalBudget.isPresent()) {
            Budget budget = optionalBudget.get();
            if (budget.getUserId().equals(userId)) {
                budget.setDeleted(true);
                budget.setLastUpdated(LocalDateTime.now());
                budgetRepository.save(budget);
            }
        }
    }

    public double getSpentForCategory(Long userId, String category, int month, int year) {
        YearMonth ym = YearMonth.of(year, month);
        LocalDateTime start = ym.atDay(1).atStartOfDay();
        LocalDateTime end = ym.atEndOfMonth().atTime(LocalTime.MAX);
        
        List<Expense> expenses = expenseRepository.findByUserIdAndCreatedAtBetweenAndIsDeletedFalse(userId, start, end);
        return expenses.stream()
                .filter(e -> e.getCategory().equalsIgnoreCase(category))
                .mapToDouble(Expense::getAmount)
                .sum();
    }
}
