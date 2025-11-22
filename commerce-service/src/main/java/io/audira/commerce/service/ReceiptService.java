package io.audira.commerce.service;

import io.audira.commerce.client.UserClient;
import io.audira.commerce.dto.*;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderItem;
import io.audira.commerce.model.Payment;
import io.audira.commerce.model.PaymentStatus;
import io.audira.commerce.repository.OrderRepository;
import io.audira.commerce.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
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
    private final UserClient userClient;

    // Tasa de IVA (debe coincidir con el frontend)
    private static final BigDecimal TAX_RATE = new BigDecimal("0.21");

    public ReceiptDTO generateReceipt(Long paymentId) {
        log.info("=== Generating receipt for payment ID: {} ===", paymentId);

        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> {
                    log.error("Payment not found with ID: {}", paymentId);
                    return new RuntimeException("Payment not found with ID: " + paymentId);
                });

        log.info("Payment found: transactionId={}, orderId={}, userId={}, status={}, amount={}",
                payment.getTransactionId(), payment.getOrderId(), payment.getUserId(), 
                payment.getStatus(), payment.getAmount());

        if (payment.getStatus() != PaymentStatus.COMPLETED) {
            log.warn("Cannot generate receipt for payment {} with status: {}", paymentId, payment.getStatus());
            throw new RuntimeException("Receipt can only be generated for completed payments. Current status: " +
                    payment.getStatus());
        }

        Order order = orderRepository.findById(payment.getOrderId())
                .orElseThrow(() -> {
                    log.error("Order not found with ID: {}", payment.getOrderId());
                    return new RuntimeException("Order not found with ID: " + payment.getOrderId());
                });

        log.info("Order found: orderNumber={}, itemsCount={}, orderTotal={}",
                order.getOrderNumber(), order.getItems().size(), order.getTotalAmount());

        String receiptNumber = "RCP-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        // El monto del pago YA incluye el IVA (viene del frontend)
        BigDecimal total = payment.getAmount();
        
        // Calcular subtotal e IVA a partir del total con IVA
        // total = subtotal * (1 + TAX_RATE)
        // subtotal = total / (1 + TAX_RATE)
        BigDecimal divisor = BigDecimal.ONE.add(TAX_RATE);
        BigDecimal subtotal = total.divide(divisor, 2, RoundingMode.HALF_UP);
        BigDecimal tax = total.subtract(subtotal);

        log.info("Price breakdown - Subtotal: {}, Tax ({}%): {}, Total: {}", 
                subtotal, TAX_RATE.multiply(new BigDecimal("100")), tax, total);

        List<ReceiptItemDTO> items = order.getItems().stream()
                .map(this::mapToReceiptItem)
                .collect(Collectors.toList());

        PaymentDTO paymentDTO = paymentService.getPaymentById(paymentId);
        OrderDTO orderDTO = orderService.getOrderById(order.getId());

        UserDTO user = userClient.getUserById(order.getUserId());
        String customerName = user.getFirstName() + " " + user.getLastName();
        String customerEmail = user.getEmail();

        ReceiptDTO receipt = ReceiptDTO.builder()
                .receiptNumber(receiptNumber)
                .payment(paymentDTO)
                .order(orderDTO)
                .customerName(customerName)
                .customerEmail(customerEmail)
                .subtotal(subtotal)
                .tax(tax)
                .total(total)
                .issuedAt(LocalDateTime.now())
                .items(items)
                .build();

        log.info("=== Receipt generated successfully: {} ===", receiptNumber);
        return receipt;
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
        return item.getItemType() + " #" + item.getItemId();
    }
}