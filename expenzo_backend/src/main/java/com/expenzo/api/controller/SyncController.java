package com.expenzo.api.controller;

import com.expenzo.api.dto.SyncRequest;
import com.expenzo.api.dto.SyncResponse;
import com.expenzo.api.model.Budget;
import com.expenzo.api.model.Expense;
import com.expenzo.api.model.RecurringRule;
import com.expenzo.api.repository.BudgetRepository;
import com.expenzo.api.repository.ExpenseRepository;
import com.expenzo.api.repository.RecurringRuleRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/sync")
public class SyncController {

    @Autowired
    private ExpenseRepository expenseRepository;

    @Autowired
    private BudgetRepository budgetRepository;

    @Autowired
    private RecurringRuleRepository recurringRuleRepository;

    @PostMapping
    public ResponseEntity<SyncResponse> sync(@RequestBody SyncRequest request, HttpServletRequest servletRequest) {
        Long userId = (Long) servletRequest.getAttribute("userId");
        LocalDateTime now = LocalDateTime.now();

        // 1. Process incoming expenses
        if (request.getExpenses() != null) {
            for (Expense incoming : request.getExpenses()) {
                incoming.setUserId(userId);
                Optional<Expense> existingOpt = expenseRepository.findById(incoming.getId());
                if (existingOpt.isPresent()) {
                    Expense existing = existingOpt.get();
                    if (incoming.getLastUpdated().isAfter(existing.getLastUpdated())) {
                        expenseRepository.save(incoming);
                    }
                } else {
                    expenseRepository.save(incoming);
                }
            }
        }

        // 2. Process incoming budgets
        if (request.getBudgets() != null) {
            for (Budget incoming : request.getBudgets()) {
                incoming.setUserId(userId);
                Optional<Budget> existingOpt = budgetRepository.findById(incoming.getId());
                if (existingOpt.isPresent()) {
                    Budget existing = existingOpt.get();
                    if (incoming.getLastUpdated().isAfter(existing.getLastUpdated())) {
                        budgetRepository.save(incoming);
                    }
                } else {
                    budgetRepository.save(incoming);
                }
            }
        }

        // 3. Process incoming recurring rules
        if (request.getRecurringRules() != null) {
            for (RecurringRule incoming : request.getRecurringRules()) {
                incoming.setUserId(userId);
                Optional<RecurringRule> existingOpt = recurringRuleRepository.findById(incoming.getId());
                if (existingOpt.isPresent()) {
                    RecurringRule existing = existingOpt.get();
                    if (incoming.getLastUpdated().isAfter(existing.getLastUpdated())) {
                        recurringRuleRepository.save(incoming);
                    }
                } else {
                    recurringRuleRepository.save(incoming);
                }
            }
        }

        // 4. Fetch server changes since lastSyncTime
        LocalDateTime lastSync = request.getLastSyncTime();
        List<Expense> serverExpenses;
        List<Budget> serverBudgets;
        List<RecurringRule> serverRules;

        if (lastSync == null) {
            serverExpenses = expenseRepository.findByUserIdAndIsDeletedFalse(userId);
            serverBudgets = budgetRepository.findByUserIdAndIsDeletedFalse(userId);
            serverRules = recurringRuleRepository.findByUserIdAndIsDeletedFalse(userId);
        } else {
            // Subtract a small buffer (e.g. 2 seconds) to account for clock skew during sync
            LocalDateTime syncBufferTime = lastSync.minusSeconds(2);
            serverExpenses = expenseRepository.findByUserIdAndLastUpdatedAfter(userId, syncBufferTime);
            serverBudgets = budgetRepository.findByUserIdAndLastUpdatedAfter(userId, syncBufferTime);
            serverRules = recurringRuleRepository.findByUserIdAndLastUpdatedAfter(userId, syncBufferTime);
        }

        SyncResponse response = SyncResponse.builder()
                .serverSyncTime(now)
                .expenses(serverExpenses)
                .budgets(serverBudgets)
                .recurringRules(serverRules)
                .build();

        return ResponseEntity.ok(response);
    }
}
