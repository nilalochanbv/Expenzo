package com.expenzo.api.service;

import com.expenzo.api.dto.NlpParseResult;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class NlpParserService {

    private static final Map<String, String> KEYWORD_TO_CATEGORY = new HashMap<>();

    static {
        // Petrol / Transport
        String catPetrol = "Petrol";
        KEYWORD_TO_CATEGORY.put("petrol", catPetrol);
        KEYWORD_TO_CATEGORY.put("diesel", catPetrol);
        KEYWORD_TO_CATEGORY.put("fuel", catPetrol);
        KEYWORD_TO_CATEGORY.put("gas", catPetrol);
        KEYWORD_TO_CATEGORY.put("cab", catPetrol);
        KEYWORD_TO_CATEGORY.put("cabs", catPetrol);
        KEYWORD_TO_CATEGORY.put("uber", catPetrol);
        KEYWORD_TO_CATEGORY.put("ola", catPetrol);
        KEYWORD_TO_CATEGORY.put("auto", catPetrol);
        KEYWORD_TO_CATEGORY.put("bus", catPetrol);
        KEYWORD_TO_CATEGORY.put("train", catPetrol);
        KEYWORD_TO_CATEGORY.put("metro", catPetrol);
        KEYWORD_TO_CATEGORY.put("flight", catPetrol);
        KEYWORD_TO_CATEGORY.put("ticket", catPetrol);
        KEYWORD_TO_CATEGORY.put("travel", catPetrol);

        // Groceries
        String catGroceries = "Groceries";
        KEYWORD_TO_CATEGORY.put("milk", catGroceries);
        KEYWORD_TO_CATEGORY.put("vegetables", catGroceries);
        KEYWORD_TO_CATEGORY.put("vegetable", catGroceries);
        KEYWORD_TO_CATEGORY.put("fruits", catGroceries);
        KEYWORD_TO_CATEGORY.put("fruit", catGroceries);
        KEYWORD_TO_CATEGORY.put("grocery", catGroceries);
        KEYWORD_TO_CATEGORY.put("groceries", catGroceries);
        KEYWORD_TO_CATEGORY.put("supermarket", catGroceries);
        KEYWORD_TO_CATEGORY.put("mart", catGroceries);
        KEYWORD_TO_CATEGORY.put("egg", catGroceries);
        KEYWORD_TO_CATEGORY.put("eggs", catGroceries);
        KEYWORD_TO_CATEGORY.put("bread", catGroceries);
        KEYWORD_TO_CATEGORY.put("butter", catGroceries);
        KEYWORD_TO_CATEGORY.put("cheese", catGroceries);
        KEYWORD_TO_CATEGORY.put("paneer", catGroceries);

        // Food / Dining Out
        String catFood = "Food";
        KEYWORD_TO_CATEGORY.put("food", catFood);
        KEYWORD_TO_CATEGORY.put("restaurant", catFood);
        KEYWORD_TO_CATEGORY.put("dinner", catFood);
        KEYWORD_TO_CATEGORY.put("lunch", catFood);
        KEYWORD_TO_CATEGORY.put("breakfast", catFood);
        KEYWORD_TO_CATEGORY.put("cafe", catFood);
        KEYWORD_TO_CATEGORY.put("coffee", catFood);
        KEYWORD_TO_CATEGORY.put("tea", catFood);
        KEYWORD_TO_CATEGORY.put("starbucks", catFood);
        KEYWORD_TO_CATEGORY.put("pizza", catFood);
        KEYWORD_TO_CATEGORY.put("burger", catFood);
        KEYWORD_TO_CATEGORY.put("swiggy", catFood);
        KEYWORD_TO_CATEGORY.put("zomato", catFood);
        KEYWORD_TO_CATEGORY.put("snacks", catFood);

        // Entertainment
        String catEntertainment = "Entertainment";
        KEYWORD_TO_CATEGORY.put("movie", catEntertainment);
        KEYWORD_TO_CATEGORY.put("movies", catEntertainment);
        KEYWORD_TO_CATEGORY.put("cinema", catEntertainment);
        KEYWORD_TO_CATEGORY.put("theater", catEntertainment);
        KEYWORD_TO_CATEGORY.put("netflix", catEntertainment);
        KEYWORD_TO_CATEGORY.put("spotify", catEntertainment);
        KEYWORD_TO_CATEGORY.put("game", catEntertainment);
        KEYWORD_TO_CATEGORY.put("gaming", catEntertainment);
        KEYWORD_TO_CATEGORY.put("concert", catEntertainment);
        KEYWORD_TO_CATEGORY.put("show", catEntertainment);
        KEYWORD_TO_CATEGORY.put("bookmyshow", catEntertainment);

        // Rent / Housing
        String catRent = "Rent";
        KEYWORD_TO_CATEGORY.put("rent", catRent);
        KEYWORD_TO_CATEGORY.put("house rent", catRent);
        KEYWORD_TO_CATEGORY.put("maintenance", catRent);
        KEYWORD_TO_CATEGORY.put("pg", catRent);
        KEYWORD_TO_CATEGORY.put("hostel", catRent);

        // Bills / Utilities
        String catBills = "Bills";
        KEYWORD_TO_CATEGORY.put("electricity", catBills);
        KEYWORD_TO_CATEGORY.put("water", catBills);
        KEYWORD_TO_CATEGORY.put("wifi", catBills);
        KEYWORD_TO_CATEGORY.put("internet", catBills);
        KEYWORD_TO_CATEGORY.put("broadband", catBills);
        KEYWORD_TO_CATEGORY.put("recharge", catBills);
        KEYWORD_TO_CATEGORY.put("mobile bill", catBills);
        KEYWORD_TO_CATEGORY.put("phone bill", catBills);
        KEYWORD_TO_CATEGORY.put("insurance", catBills);
        KEYWORD_TO_CATEGORY.put("subscription", catBills);

        // Shopping
        String catShopping = "Shopping";
        KEYWORD_TO_CATEGORY.put("shopping", catShopping);
        KEYWORD_TO_CATEGORY.put("clothes", catShopping);
        KEYWORD_TO_CATEGORY.put("shirt", catShopping);
        KEYWORD_TO_CATEGORY.put("pant", catShopping);
        KEYWORD_TO_CATEGORY.put("shoes", catShopping);
        KEYWORD_TO_CATEGORY.put("dress", catShopping);
        KEYWORD_TO_CATEGORY.put("amazon", catShopping);
        KEYWORD_TO_CATEGORY.put("flipkart", catShopping);
        KEYWORD_TO_CATEGORY.put("myntra", catShopping);

        // Education
        String catEducation = "Education";
        KEYWORD_TO_CATEGORY.put("book", catEducation);
        KEYWORD_TO_CATEGORY.put("books", catEducation);
        KEYWORD_TO_CATEGORY.put("course", catEducation);
        KEYWORD_TO_CATEGORY.put("udemy", catEducation);
        KEYWORD_TO_CATEGORY.put("fees", catEducation);
        KEYWORD_TO_CATEGORY.put("school", catEducation);
        KEYWORD_TO_CATEGORY.put("college", catEducation);
        KEYWORD_TO_CATEGORY.put("tuition", catEducation);

        // Health
        String catHealth = "Health";
        KEYWORD_TO_CATEGORY.put("doctor", catHealth);
        KEYWORD_TO_CATEGORY.put("medicine", catHealth);
        KEYWORD_TO_CATEGORY.put("medicines", catHealth);
        KEYWORD_TO_CATEGORY.put("pharmacy", catHealth);
        KEYWORD_TO_CATEGORY.put("hospital", catHealth);
        KEYWORD_TO_CATEGORY.put("clinic", catHealth);
        KEYWORD_TO_CATEGORY.put("gym", catHealth);
        KEYWORD_TO_CATEGORY.put("workout", catHealth);
    }

    public NlpParseResult parse(String text) {
        if (text == null || text.trim().isEmpty()) {
            return new NlpParseResult("Expense", 0.0, "Others", LocalDateTime.now());
        }

        String cleaned = text.trim();
        
        // 1. Extract amount (first matching number, integer or decimal)
        Pattern numberPattern = Pattern.compile("(?<!\\d)\\d+(?:\\.\\d+)?(?!\\d)");
        Matcher matcher = numberPattern.matcher(cleaned);
        
        double amount = 0.0;
        String amountStr = "";
        if (matcher.find()) {
            amountStr = matcher.group();
            amount = Double.parseDouble(amountStr);
        }

        // 2. Remove amount and currency indicators from text
        String textWithoutAmount = cleaned.replaceFirst(Pattern.quote(amountStr), "");
        // Remove common currency symbols and words
        textWithoutAmount = textWithoutAmount.replaceAll("(?i)\\b(rs|rupees|inr|usd|eur|\\$|₹|spent|paid|for|at|on)\\b", "");
        // Clean double spaces
        textWithoutAmount = textWithoutAmount.replaceAll("\\s+", " ").trim();

        // 3. Determine Date
        LocalDateTime createdAt = LocalDateTime.now();
        String lowercaseText = textWithoutAmount.toLowerCase();
        
        if (lowercaseText.contains("yesterday")) {
            createdAt = LocalDateTime.of(LocalDate.now().minusDays(1), LocalTime.now());
            textWithoutAmount = textWithoutAmount.replaceAll("(?i)\\byesterday\\b", "").trim();
        } else if (lowercaseText.contains("today")) {
            textWithoutAmount = textWithoutAmount.replaceAll("(?i)\\btoday\\b", "").trim();
        }

        // 4. Determine Category & Description
        String description = textWithoutAmount.replaceAll("\\s+", " ").trim();
        if (description.isEmpty()) {
            description = "Expense";
        }

        // Find category by scanning keywords
        String category = "Others";
        String[] words = description.toLowerCase().split("\\s+");
        for (String word : words) {
            if (KEYWORD_TO_CATEGORY.containsKey(word)) {
                category = KEYWORD_TO_CATEGORY.get(word);
                break;
            }
        }

        // Special check: if description starts with a known category, use it
        if (category.equals("Others")) {
            for (String key : KEYWORD_TO_CATEGORY.keySet()) {
                if (description.toLowerCase().contains(key)) {
                    category = KEYWORD_TO_CATEGORY.get(key);
                    break;
                }
            }
        }

        // Capitalize description first letter
        if (description.length() > 0) {
            description = description.substring(0, 1).toUpperCase() + description.substring(1);
        }

        return NlpParseResult.builder()
                .amount(amount)
                .category(category)
                .description(description)
                .createdAt(createdAt)
                .build();
    }
}
