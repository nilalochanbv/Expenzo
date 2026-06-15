package com.expenzo.api.repository;

import com.expenzo.api.model.RecurringRule;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface RecurringRuleRepository extends JpaRepository<RecurringRule, String> {
    List<RecurringRule> findByUserIdAndIsDeletedFalse(Long userId);
    List<RecurringRule> findByUserIdAndLastUpdatedAfter(Long userId, LocalDateTime timestamp);
    Optional<RecurringRule> findByUserIdAndDescriptionPatternIgnoreCaseAndIsDeletedFalse(Long userId, String descriptionPattern);
}
