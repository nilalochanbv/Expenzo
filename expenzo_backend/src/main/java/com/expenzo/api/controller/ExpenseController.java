package com.expenzo.api.controller;

import com.expenzo.api.dto.NlpParseResult;
import com.expenzo.api.model.Expense;
import com.expenzo.api.service.ExpenseService;
import com.expenzo.api.service.NlpParserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/expenses")
public class ExpenseController {

    @Autowired
    private ExpenseService expenseService;

    @Autowired
    private NlpParserService nlpParserService;

    @GetMapping
    public ResponseEntity<List<Expense>> getAllExpenses(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return ResponseEntity.ok(expenseService.getAllExpenses(userId));
    }

    @PostMapping
    public ResponseEntity<Expense> createExpense(@RequestBody Expense expense, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return ResponseEntity.ok(expenseService.saveExpense(expense, userId));
    }

    @PostMapping("/parse")
    public ResponseEntity<NlpParseResult> parseExpense(@RequestBody Map<String, String> body) {
        String text = body.get("text");
        return ResponseEntity.ok(nlpParserService.parse(text));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteExpense(@PathVariable String id, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        expenseService.deleteExpense(id, userId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/search")
    public ResponseEntity<List<Expense>> searchExpenses(@RequestParam String query, HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return ResponseEntity.ok(expenseService.searchExpenses(userId, query));
    }
}
