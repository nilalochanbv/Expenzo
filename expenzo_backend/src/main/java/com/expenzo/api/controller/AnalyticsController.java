package com.expenzo.api.controller;

import com.expenzo.api.service.AnalyticsService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/insights")
public class AnalyticsController {

    @Autowired
    private AnalyticsService analyticsService;

    @GetMapping
    public ResponseEntity<List<String>> getInsights(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return ResponseEntity.ok(analyticsService.generateInsights(userId));
    }

    @GetMapping("/comparison")
    public ResponseEntity<Map<String, Object>> getComparison(
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year,
            HttpServletRequest request) {
        
        Long userId = (Long) request.getAttribute("userId");
        int targetMonth = (month != null) ? month : LocalDate.now().getMonthValue();
        int targetYear = (year != null) ? year : LocalDate.now().getYear();

        return ResponseEntity.ok(analyticsService.getMonthlyComparison(userId, targetYear, targetMonth));
    }

    @GetMapping("/recurring")
    public ResponseEntity<List<String>> getRecurringSuggestions(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return ResponseEntity.ok(analyticsService.detectRecurring(userId));
    }
}
