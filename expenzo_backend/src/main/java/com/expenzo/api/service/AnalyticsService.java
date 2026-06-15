package com.expenzo.api.service;

import com.expenzo.api.model.Budget;
import com.expenzo.api.model.Expense;
import com.expenzo.api.repository.BudgetRepository;
import com.expenzo.api.repository.ExpenseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AnalyticsService {

    @Autowired
    private ExpenseRepository expenseRepository;

    @Autowired
    private BudgetRepository budgetRepository;

    public Map<String, Object> getMonthlyComparison(Long userId, int year, int month) {
        YearMonth currentYm = YearMonth.of(year, month);
        YearMonth previousYm = currentYm.minusMonths(1);

        double currentTotal = getMonthTotal(userId, currentYm);
        double previousTotal = getMonthTotal(userId, previousYm);

        double diffPercent = 0.0;
        if (previousTotal > 0) {
            diffPercent = ((currentTotal - previousTotal) / previousTotal) * 100;
        }

        Map<String, Double> currentCatTotals = getCategoryTotals(userId, currentYm);
        Map<String, Double> previousCatTotals = getCategoryTotals(userId, previousYm);

        List<Map<String, Object>> catComparison = new ArrayList<>();
        Set<String> allCategories = new HashSet<>();
        allCategories.addAll(currentCatTotals.keySet());
        allCategories.addAll(previousCatTotals.keySet());

        for (String cat : allCategories) {
            double curr = currentCatTotals.getOrDefault(cat, 0.0);
            double prev = previousCatTotals.getOrDefault(cat, 0.0);
            double diff = curr - prev;
            double pct = prev > 0 ? (diff / prev) * 100 : 0.0;

            Map<String, Object> item = new HashMap<>();
            item.put("category", cat);
            item.put("currentAmount", curr);
            item.put("previousAmount", prev);
            item.put("difference", diff);
            item.put("percentageChange", pct);
            catComparison.add(item);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("currentMonthTotal", currentTotal);
        result.put("previousMonthTotal", previousTotal);
        result.put("percentageChange", diffPercent);
        result.put("categoryComparison", catComparison);
        return result;
    }

    public List<String> generateInsights(Long userId) {
        List<String> insights = new ArrayList<>();
        YearMonth currentYm = YearMonth.now();
        YearMonth previousYm = currentYm.minusMonths(1);

        double currentTotal = getMonthTotal(userId, currentYm);
        double previousTotal = getMonthTotal(userId, previousYm);

        // General total insight
        if (previousTotal > 0) {
            double pct = ((currentTotal - previousTotal) / previousTotal) * 100;
            if (Math.abs(pct) >= 5) {
                insights.add(String.format("Total spending %s by %.1f%% compared to last month.",
                        pct > 0 ? "increased" : "decreased", Math.abs(pct)));
            } else {
                insights.add("Total spending remains stable compared to last month.");
            }
        }

        // Category insights
        Map<String, Double> currentCatTotals = getCategoryTotals(userId, currentYm);
        Map<String, Double> previousCatTotals = getCategoryTotals(userId, previousYm);

        for (String cat : currentCatTotals.keySet()) {
            double currVal = currentCatTotals.get(cat);
            double prevVal = previousCatTotals.getOrDefault(cat, 0.0);
            if (prevVal > 0) {
                double pct = ((currVal - prevVal) / prevVal) * 100;
                if (pct >= 20) {
                    insights.add(String.format("%s spending increased by %.0f%% this month.", cat, pct));
                } else if (pct <= -20) {
                    insights.add(String.format("%s spending reduced by %.0f%% this month.", cat, Math.abs(pct)));
                }
            } else if (currVal > 500) {
                insights.add(String.format("New spending detected in %s: spent \u20B9%.0f.", cat, currVal));
            }
        }

        // Budget warnings
        List<Budget> budgets = budgetRepository.findByUserIdAndIsDeletedFalse(userId);
        for (Budget b : budgets) {
            if (b.getMonth() == currentYm.getMonthValue() && b.getYear() == currentYm.getYear()) {
                double spent = currentCatTotals.getOrDefault(b.getCategory(), 0.0);
                double pct = (spent / b.getAmountLimit()) * 100;
                if (pct >= 100) {
                    insights.add(String.format("\u26A0\ufe0f Budget Exceeded! You spent \u20B9%.0f of your \u20B9%.0f budget on %s.", spent, b.getAmountLimit(), b.getCategory()));
                } else if (pct >= 90) {
                    insights.add(String.format("\u26A0\ufe0f Danger! You are at %.0f%% of your %s budget.", pct, b.getCategory()));
                } else if (pct >= 80) {
                    insights.add(String.format("\ud83d\udcdd Alert: You have used %.0f%% of your %s budget.", pct, b.getCategory()));
                }
            }
        }

        if (insights.isEmpty()) {
            insights.add("Keep logging your expenses to unlock more smart insights!");
        }

        return insights;
    }

    public List<String> detectRecurring(Long userId) {
        List<String> suggestions = new ArrayList<>();
        // Get all expenses for last 90 days
        LocalDateTime start = LocalDateTime.now().minusDays(90);
        List<Expense> expenses = expenseRepository.findByUserIdAndCreatedAtBetweenAndIsDeletedFalse(userId, start, LocalDateTime.now());

        // Group by description and amount (normalize description by trimming/lowercasing)
        Map<String, List<Expense>> grouped = expenses.stream()
                .collect(Collectors.groupingBy(e -> e.getDescription().toLowerCase().trim() + "|" + e.getAmount()));

        for (Map.Entry<String, List<Expense>> entry : grouped.entrySet()) {
            List<Expense> list = entry.getValue();
            if (list.size() >= 3) {
                // Check if the dates are roughly 30 days apart
                list.sort(Comparator.comparing(Expense::getCreatedAt));
                boolean fitsMonthlyPattern = true;
                for (int i = 1; i < list.size(); i++) {
                    long daysBetween = Duration.between(list.get(i - 1).getCreatedAt(), list.get(i).getCreatedAt()).toDays();
                    if (daysBetween < 25 || daysBetween > 35) {
                        fitsMonthlyPattern = false;
                        break;
                    }
                }

                if (fitsMonthlyPattern) {
                    Expense sample = list.get(0);
                    suggestions.add(String.format("Recurring expense detected: %s (amount \u20B9%.2f)", sample.getDescription(), sample.getAmount()));
                }
            }
        }
        return suggestions;
    }

    private double getMonthTotal(Long userId, YearMonth ym) {
        LocalDateTime start = ym.atDay(1).atStartOfDay();
        LocalDateTime end = ym.atEndOfMonth().atTime(LocalTime.MAX);
        return expenseRepository.findByUserIdAndCreatedAtBetweenAndIsDeletedFalse(userId, start, end).stream()
                .mapToDouble(Expense::getAmount)
                .sum();
    }

    private Map<String, Double> getCategoryTotals(Long userId, YearMonth ym) {
        LocalDateTime start = ym.atDay(1).atStartOfDay();
        LocalDateTime end = ym.atEndOfMonth().atTime(LocalTime.MAX);
        List<Expense> expenses = expenseRepository.findByUserIdAndCreatedAtBetweenAndIsDeletedFalse(userId, start, end);
        return expenses.stream()
                .collect(Collectors.groupingBy(Expense::getCategory, Collectors.summingDouble(Expense::getAmount)));
    }
}
