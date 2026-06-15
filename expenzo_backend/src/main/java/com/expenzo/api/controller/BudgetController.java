package com.expenzo.api.controller;

import com.expenzo.api.model.Budget;
import com.expenzo.api.service.BudgetService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/budgets")
public class BudgetController {

    @Autowired
    private BudgetService budgetService;

    @GetMapping
    public ResponseEntity<List<Budget>> getAllBudgets(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return ResponseEntity.ok(budgetService.getAllBudgets(userId));
    }

    @PostMapping
    public ResponseEntity<Budget> createOrUpdateBudget(@RequestBody Budget budget, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return ResponseEntity.ok(budgetService.saveBudget(budget, userId));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteBudget(@PathVariable String id, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        budgetService.deleteBudget(id, userId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{category}/spent")
    public ResponseEntity<?> getBudgetSpentStatus(
            @PathVariable String category,
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year,
            HttpServletRequest request) {
        
        Long userId = (Long) request.getAttribute("userId");
        int targetMonth = (month != null) ? month : LocalDate.now().getMonthValue();
        int targetYear = (year != null) ? year : LocalDate.now().getYear();

        double spent = budgetService.getSpentForCategory(userId, category, targetMonth, targetYear);
        return ResponseEntity.ok(Map.of(
                "category", category,
                "month", targetMonth,
                "year", targetYear,
                "spent", spent
        ));
    }
}
