package com.expenzo.api.dto;

import lombok.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NlpParseResult {
    private String description;
    private Double amount;
    private String category;
    private LocalDateTime createdAt;
}
