package com.expenzo.api.dto;

import com.expenzo.api.model.Budget;
import com.expenzo.api.model.Expense;
import com.expenzo.api.model.RecurringRule;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SyncRequest {
    private LocalDateTime lastSyncTime;
    private List<Expense> expenses;
    private List<Budget> budgets;
    private List<RecurringRule> recurringRules;
}
