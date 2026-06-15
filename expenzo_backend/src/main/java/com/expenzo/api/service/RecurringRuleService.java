package com.expenzo.api.service;

import com.expenzo.api.model.RecurringRule;
import com.expenzo.api.repository.RecurringRuleRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class RecurringRuleService {

    @Autowired
    private RecurringRuleRepository recurringRuleRepository;

    public List<RecurringRule> getAllRules(Long userId) {
        return recurringRuleRepository.findByUserIdAndIsDeletedFalse(userId);
    }

    public List<RecurringRule> getRulesSince(Long userId, LocalDateTime timestamp) {
        return recurringRuleRepository.findByUserIdAndLastUpdatedAfter(userId, timestamp);
    }

    public RecurringRule saveRule(RecurringRule rule, Long userId) {
        rule.setUserId(userId);
        rule.setLastUpdated(LocalDateTime.now());
        return recurringRuleRepository.save(rule);
    }

    public void deleteRule(String id, Long userId) {
        Optional<RecurringRule> optionalRule = recurringRuleRepository.findById(id);
        if (optionalRule.isPresent()) {
            RecurringRule rule = optionalRule.get();
            if (rule.getUserId().equals(userId)) {
                rule.setDeleted(true);
                rule.setLastUpdated(LocalDateTime.now());
                recurringRuleRepository.save(rule);
            }
        }
    }
}
