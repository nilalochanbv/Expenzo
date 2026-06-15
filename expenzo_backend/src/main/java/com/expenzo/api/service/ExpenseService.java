package com.expenzo.api.service;

import com.expenzo.api.model.Expense;
import com.expenzo.api.repository.ExpenseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ExpenseService {

    @Autowired
    private ExpenseRepository expenseRepository;

    public List<Expense> getAllExpenses(Long userId) {
        return expenseRepository.findByUserIdAndIsDeletedFalse(userId);
    }

    public List<Expense> getExpensesSince(Long userId, LocalDateTime timestamp) {
        return expenseRepository.findByUserIdAndLastUpdatedAfter(userId, timestamp);
    }

    public Expense saveExpense(Expense expense, Long userId) {
        expense.setUserId(userId);
        if (expense.getCreatedAt() == null) {
            expense.setCreatedAt(LocalDateTime.now());
        }
        expense.setLastUpdated(LocalDateTime.now());
        return expenseRepository.save(expense);
    }

    public void deleteExpense(String id, Long userId) {
        Optional<Expense> optionalExpense = expenseRepository.findById(id);
        if (optionalExpense.isPresent()) {
            Expense expense = optionalExpense.get();
            if (expense.getUserId().equals(userId)) {
                expense.setDeleted(true);
                expense.setLastUpdated(LocalDateTime.now());
                expenseRepository.save(expense);
            }
        }
    }

    public List<Expense> searchExpenses(Long userId, String query) {
        return expenseRepository.findByUserIdAndDescriptionContainingIgnoreCaseAndIsDeletedFalse(userId, query);
    }

    public List<Expense> getExpensesByCategory(Long userId, String category) {
        return expenseRepository.findByUserIdAndCategoryAndIsDeletedFalse(userId, category);
    }
}
