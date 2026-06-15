package com.expenzo.api.service;

import com.expenzo.api.dto.NlpParseResult;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDate;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class NlpParserServiceTest {

    @Autowired
    private NlpParserService nlpParserService;

    @Test
    public void testParsePetrol() {
        NlpParseResult result = nlpParserService.parse("petrol 1000");
        assertEquals(1000.0, result.getAmount());
        assertEquals("Petrol", result.getCategory());
        assertEquals("Petrol", result.getDescription());
    }

    @Test
    public void testParseMilk() {
        NlpParseResult result = nlpParserService.parse("milk 120");
        assertEquals(120.0, result.getAmount());
        assertEquals("Groceries", result.getCategory());
        assertEquals("Milk", result.getDescription());
    }

    @Test
    public void testParseRentWithPrepositions() {
        NlpParseResult result = nlpParserService.parse("spent 15000 on rent");
        assertEquals(15000.0, result.getAmount());
        assertEquals("Rent", result.getCategory());
        assertEquals("Rent", result.getDescription());
    }

    @Test
    public void testParseYesterday() {
        NlpParseResult result = nlpParserService.parse("movie 350 yesterday");
        assertEquals(350.0, result.getAmount());
        assertEquals("Entertainment", result.getCategory());
        assertEquals("Movie", result.getDescription());
        assertEquals(LocalDate.now().minusDays(1), result.getCreatedAt().toLocalDate());
    }

    @Test
    public void testParseInvalidInput() {
        NlpParseResult result = nlpParserService.parse("");
        assertEquals(0.0, result.getAmount());
        assertEquals("Others", result.getCategory());
        assertEquals("Expense", result.getDescription());
    }
}
