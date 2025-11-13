package io.audira.commerce.service;

import io.audira.commerce.dto.*;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderItem;
import io.audira.commerce.model.Payment;
import io.audira.commerce.repository.OrderRepository;
import io.audira.commerce.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final OrderService orderService;

    public ReceiptDTO generateReceipt(Long paymentId) {
        log.info("Generating receipt for payment ID: {}", paymentId);

        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        Order order = orderRepository.findById(payment.getOrderId())
                .orElseThrow(() -> new RuntimeException("Order not found"));

        // Generate receipt number
        String receiptNumber = "RCP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // Calculate tax (10% for example)
        BigDecimal subtotal = order.getTotalAmount();
        BigDecimal taxRate = new BigDecimal("0.10");
        BigDecimal tax = subtotal.multiply(taxRate);
        BigDecimal total = subtotal.add(tax);

        // Map order items to receipt items
        List<ReceiptItemDTO> items = order.getItems().stream()
                .map(this::mapToReceiptItem)
                .collect(Collectors.toList());

        PaymentDTO paymentDTO = paymentService.getPaymentById(paymentId);
        OrderDTO orderDTO = orderService.getOrderById(order.getId());

        return ReceiptDTO.builder()
                .receiptNumber(receiptNumber)
                .payment(paymentDTO)
                .order(orderDTO)
                .customerName("Customer " + order.getUserId()) // In real app, fetch from user service
                .customerEmail("customer" + order.getUserId() + "@example.com")
                .subtotal(subtotal)
                .tax(tax)
                .total(total)
                .issuedAt(LocalDateTime.now())
                .items(items)
                .build();
    }

    public ReceiptDTO getReceiptByPaymentId(Long paymentId) {
        return generateReceipt(paymentId);
    }

    public ReceiptDTO getReceiptByTransactionId(String transactionId) {
        Payment payment = paymentRepository.findByTransactionId(transactionId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return generateReceipt(payment.getId());
    }

    private ReceiptItemDTO mapToReceiptItem(OrderItem item) {
        BigDecimal totalPrice = item.getPrice().multiply(new BigDecimal(item.getQuantity()));

        return ReceiptItemDTO.builder()
                .itemName(getItemName(item))
                .itemType(item.getItemType().toString())
                .quantity(item.getQuantity())
                .unitPrice(item.getPrice())
                .totalPrice(totalPrice)
                .build();
    }

    private String getItemName(OrderItem item) {
        // In a real application, you would fetch the actual item name from the respective service
        return item.getItemType() + " #" + item.getItemId();
    }
}

