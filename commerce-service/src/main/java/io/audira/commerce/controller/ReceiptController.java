package io.audira.commerce.controller;

import io.audira.commerce.dto.ReceiptDTO;
import io.audira.commerce.service.ReceiptService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/receipts")
@RequiredArgsConstructor
public class ReceiptController {

    private final ReceiptService receiptService;

    @GetMapping("/payment/{paymentId}")
    public ResponseEntity<ReceiptDTO> getReceiptByPaymentId(@PathVariable Long paymentId) {
        try {
            return ResponseEntity.ok(receiptService.getReceiptByPaymentId(paymentId));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/transaction/{transactionId}")
    public ResponseEntity<ReceiptDTO> getReceiptByTransactionId(@PathVariable String transactionId) {
        try {
            return ResponseEntity.ok(receiptService.getReceiptByTransactionId(transactionId));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/generate/{paymentId}")
    public ResponseEntity<ReceiptDTO> generateReceipt(@PathVariable Long paymentId) {
        try {
            return ResponseEntity.ok(receiptService.generateReceipt(paymentId));
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
}

