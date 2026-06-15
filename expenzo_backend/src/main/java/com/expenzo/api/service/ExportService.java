package com.expenzo.api.service;

import com.expenzo.api.model.Expense;
import com.expenzo.api.repository.ExpenseRepository;

// OpenPDF imports (for PDF) - no wildcards to prevent name clashes
import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;

// Apache POI imports (for Excel)
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.IndexedColors;
import org.apache.poi.ss.usermodel.FillPatternType;
import org.apache.poi.ss.usermodel.HorizontalAlignment;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class ExportService {

    @Autowired
    private ExpenseRepository expenseRepository;

    public byte[] exportPdf(Long userId) {
        List<Expense> expenses = expenseRepository.findByUserIdAndIsDeletedFalse(userId);
        expenses.sort((e1, e2) -> e2.getCreatedAt().compareTo(e1.getCreatedAt())); // Newest first

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4, 36, 36, 54, 36);

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            // Font styles
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 24, new Color(108, 77, 255));
            Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12, Color.WHITE);
            Font normalFont = FontFactory.getFont(FontFactory.HELVETICA, 10, Color.BLACK);
            Font boldFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10, Color.BLACK);

            // Document Header
            Paragraph title = new Paragraph("Expenzo - Expense Report", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(20);
            document.add(title);

            // Summary
            double total = expenses.stream().mapToDouble(Expense::getAmount).sum();
            Paragraph summary = new Paragraph(String.format("Total Recorded Expenses: \u20B9%,.2f\nTotal Transactions: %d\n\n", total, expenses.size()), boldFont);
            document.add(summary);

            // Table setup
            PdfPTable table = new PdfPTable(4);
            table.setWidthPercentage(100);
            table.setWidths(new float[]{25, 35, 20, 20});

            // Table Headers
            String[] headers = {"Date", "Description", "Category", "Amount"};
            for (String header : headers) {
                PdfPCell cell = new PdfPCell(new Phrase(header, headerFont));
                cell.setBackgroundColor(new Color(17, 24, 39)); // Dark background matching cards
                cell.setPadding(8);
                cell.setHorizontalAlignment(Element.ALIGN_CENTER);
                table.addCell(cell);
            }

            // Table Data
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd-MMM-yyyy HH:mm");
            for (Expense e : expenses) {
                PdfPCell dateCell = new PdfPCell(new Phrase(e.getCreatedAt().format(formatter), normalFont));
                dateCell.setPadding(6);
                table.addCell(dateCell);

                PdfPCell descCell = new PdfPCell(new Phrase(e.getDescription(), normalFont));
                descCell.setPadding(6);
                table.addCell(descCell);

                PdfPCell catCell = new PdfPCell(new Phrase(e.getCategory(), normalFont));
                catCell.setPadding(6);
                catCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                table.addCell(catCell);

                PdfPCell amountCell = new PdfPCell(new Phrase(String.format("\u20B9%,.2f", e.getAmount()), normalFont));
                amountCell.setPadding(6);
                amountCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
                table.addCell(amountCell);
            }

            document.add(table);
            document.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        return out.toByteArray();
    }

    public byte[] exportExcel(Long userId) {
        List<Expense> expenses = expenseRepository.findByUserIdAndIsDeletedFalse(userId);
        expenses.sort((e1, e2) -> e2.getCreatedAt().compareTo(e1.getCreatedAt()));

        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Expenses");

            // Setup Header Style
            CellStyle headerStyle = workbook.createCellStyle();
            org.apache.poi.ss.usermodel.Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerFont.setColor(IndexedColors.WHITE.getIndex());
            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(IndexedColors.DARK_BLUE.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            headerStyle.setAlignment(HorizontalAlignment.CENTER);

            // Setup Amount Style
            CellStyle amountStyle = workbook.createCellStyle();
            amountStyle.setDataFormat(workbook.createDataFormat().getFormat("\u20B9#,##0.00"));
            amountStyle.setAlignment(HorizontalAlignment.RIGHT);

            // Setup Date Style
            CellStyle dateStyle = workbook.createCellStyle();
            dateStyle.setDataFormat(workbook.createDataFormat().getFormat("yyyy-mm-dd hh:mm"));

            // Create Headers Row
            Row headerRow = sheet.createRow(0);
            String[] headers = {"ID", "Date", "Description", "Category", "Amount"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            // Write Data Rows
            int rowIdx = 1;
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
            for (Expense e : expenses) {
                Row row = sheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(e.getId());
                
                Cell dateCell = row.createCell(1);
                dateCell.setCellValue(e.getCreatedAt().format(formatter));
                
                row.createCell(2).setCellValue(e.getDescription());
                row.createCell(3).setCellValue(e.getCategory());
                
                Cell amountCell = row.createCell(4);
                amountCell.setCellValue(e.getAmount());
                amountCell.setCellStyle(amountStyle);
            }

            // Total Row
            Row totalRow = sheet.createRow(rowIdx);
            Cell totalLabelCell = totalRow.createCell(3);
            totalLabelCell.setCellValue("TOTAL");
            
            CellStyle boldLabelStyle = workbook.createCellStyle();
            org.apache.poi.ss.usermodel.Font boldFont = workbook.createFont();
            boldFont.setBold(true);
            boldLabelStyle.setFont(boldFont);
            boldLabelStyle.setAlignment(HorizontalAlignment.RIGHT);
            totalLabelCell.setCellStyle(boldLabelStyle);

            Cell totalCell = totalRow.createCell(4);
            totalCell.setCellFormula("SUM(E2:E" + rowIdx + ")");
            
            CellStyle totalValStyle = workbook.createCellStyle();
            totalValStyle.setFont(boldFont);
            totalValStyle.setDataFormat(workbook.createDataFormat().getFormat("\u20B9#,##0.00"));
            totalValStyle.setAlignment(HorizontalAlignment.RIGHT);
            totalCell.setCellStyle(totalValStyle);

            // Auto-size columns
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }

            workbook.write(out);
            return out.toByteArray();
        } catch (Exception e) {
            e.printStackTrace();
            return new byte[0];
        }
    }
}
