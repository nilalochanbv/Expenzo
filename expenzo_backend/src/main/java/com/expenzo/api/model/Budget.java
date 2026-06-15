package com.expenzo.api.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "budgets")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Budget {
    @Id
    private String id;

    @Column(nullable = false)
    private String category;

    @Column(name = "amount_limit", nullable = false)
    private Double amountLimit;

    @Column(name = "budget_month", nullable = false)
    private Integer month;

    @Column(name = "budget_year", nullable = false)
    private Integer year;

    @Column(name = "last_updated", nullable = false)
    private LocalDateTime lastUpdated;

    @Column(name = "is_deleted", nullable = false)
    private boolean isDeleted;

    @Column(name = "user_id", nullable = false)
    private Long userId;
}
