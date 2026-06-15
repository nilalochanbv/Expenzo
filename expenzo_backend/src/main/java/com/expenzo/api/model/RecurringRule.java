package com.expenzo.api.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "recurring_rules")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RecurringRule {
    @Id
    private String id;

    @Column(name = "description_pattern", nullable = false)
    private String descriptionPattern;

    @Column(nullable = false)
    private Double amount;

    @Column(nullable = false)
    private String category;

    @Column(nullable = false)
    private String frequency; // e.g. "MONTHLY"

    @Column(name = "is_active", nullable = false)
    private boolean isActive;

    @Column(name = "last_updated", nullable = false)
    private LocalDateTime lastUpdated;

    @Column(name = "is_deleted", nullable = false)
    private boolean isDeleted;

    @Column(name = "user_id", nullable = false)
    private Long userId;
}
