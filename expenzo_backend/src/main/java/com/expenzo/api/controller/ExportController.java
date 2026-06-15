package com.expenzo.api.controller;

import com.expenzo.api.service.ExportService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reports")
public class ExportController {

    @Autowired
    private ExportService exportService;

    @GetMapping("/pdf")
    public ResponseEntity<byte[]> downloadPdf(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        byte[] pdfBytes = exportService.exportPdf(userId);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        headers.setContentDispositionFormData("attachment", "expenzo-report.pdf");

        return ResponseEntity.ok()
                .headers(headers)
                .body(pdfBytes);
    }

    @GetMapping("/excel")
    public ResponseEntity<byte[]> downloadExcel(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        byte[] excelBytes = exportService.exportExcel(userId);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
        headers.setContentDispositionFormData("attachment", "expenzo-report.xlsx");

        return ResponseEntity.ok()
                .headers(headers)
                .body(excelBytes);
    }
}
