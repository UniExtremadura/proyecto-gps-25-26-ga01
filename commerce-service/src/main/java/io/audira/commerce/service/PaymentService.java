package io.audira.commerce.service;

import io.audira.commerce.dto.*;
import io.audira.commerce.model.*;
import io.audira.commerce.repository.OrderRepository;
import io.audira.commerce.repository.PaymentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Random;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PaymentService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final Random random = new Random();

    @Transactional
    public PaymentResponse processPayment(ProcessPaymentRequest request) {
        log.info("Processing payment for order: {}, method: {}",
                request.getOrderId(), request.getPaymentMethod());

        // Simulate payment processing
        try {
            // Generate transaction ID
            String transactionId = "TXN-" + UUID.randomUUID().toString();

            // Create payment record
            Payment payment = Payment.builder()
                    .transactionId(transactionId)
                    .orderId(request.getOrderId())
                    .userId(request.getUserId())
                    .paymentMethod(request.getPaymentMethod())
                    .amount(request.getAmount())
                    .status(PaymentStatus.PROCESSING)
                    .retryCount(0)
                    .build();

            payment = paymentRepository.save(payment);

            // Simulate payment gateway processing
            boolean paymentSuccessful = simulatePaymentGateway(request);

            if (paymentSuccessful) {
                payment.setStatus(PaymentStatus.COMPLETED);
                payment.setCompletedAt(LocalDateTime.now());
                payment = paymentRepository.save(payment);

                // Update order status
                updateOrderStatus(request.getOrderId(), OrderStatus.PROCESSING);

                log.info("Payment completed successfully: {}", transactionId);

                return PaymentResponse.builder()
                        .success(true)
                        .transactionId(transactionId)
                        .status(PaymentStatus.COMPLETED)
                        .message("Payment processed successfully")
                        .payment(mapToDTO(payment))
                        .build();
            } else {
                payment.setStatus(PaymentStatus.FAILED);
                payment.setErrorMessage("Payment declined by gateway");
                payment = paymentRepository.save(payment);

                log.warn("Payment failed for order: {}", request.getOrderId());

                return PaymentResponse.builder()
                        .success(false)
                        .transactionId(transactionId)
                        .status(PaymentStatus.FAILED)
                        .message("Payment was declined. Please try again or use a different payment method.")
                        .payment(mapToDTO(payment))
                        .build();
            }

        } catch (Exception e) {
            log.error("Error processing payment for order: {}", request.getOrderId(), e);
            return PaymentResponse.builder()
                    .success(false)
                    .status(PaymentStatus.FAILED)
                    .message("An error occurred while processing your payment: " + e.getMessage())
                    .build();
        }
    }

    @Transactional
    public PaymentResponse retryPayment(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        if (payment.getStatus() != PaymentStatus.FAILED) {
            throw new RuntimeException("Only failed payments can be retried");
        }

        payment.setRetryCount(payment.getRetryCount() + 1);
        payment.setStatus(PaymentStatus.PROCESSING);
        payment.setErrorMessage(null);
        payment = paymentRepository.save(payment);

        // Create a new payment request
        ProcessPaymentRequest request = ProcessPaymentRequest.builder()
                .orderId(payment.getOrderId())
                .userId(payment.getUserId())
                .paymentMethod(payment.getPaymentMethod())
                .amount(payment.getAmount())
                .build();

        return processPayment(request);
    }

    public List<PaymentDTO> getPaymentsByUserId(Long userId) {
        return paymentRepository.findByUserId(userId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public List<PaymentDTO> getPaymentsByOrderId(Long orderId) {
        return paymentRepository.findByOrderId(orderId).stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public PaymentDTO getPaymentByTransactionId(String transactionId) {
        Payment payment = paymentRepository.findByTransactionId(transactionId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return mapToDTO(payment);
    }

    public PaymentDTO getPaymentById(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return mapToDTO(payment);
    }

    @Transactional
    public PaymentResponse refundPayment(Long paymentId) {
        Payment payment = paymentRepository.findById(paymentId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));

        if (payment.getStatus() != PaymentStatus.COMPLETED) {
            throw new RuntimeException("Only completed payments can be refunded");
        }

        payment.setStatus(PaymentStatus.REFUNDED);
        payment = paymentRepository.save(payment);

        // Update order status
        updateOrderStatus(payment.getOrderId(), OrderStatus.CANCELLED);

        return PaymentResponse.builder()
                .success(true)
                .transactionId(payment.getTransactionId())
                .status(PaymentStatus.REFUNDED)
                .message("Payment refunded successfully")
                .payment(mapToDTO(payment))
                .build();
    }

    // Simulate payment gateway - 90% success rate
    private boolean simulatePaymentGateway(ProcessPaymentRequest request) {
        // Simulate network delay
        try {
            Thread.sleep(1000 + random.nextInt(2000)); // 1-3 seconds
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }

        // Validate payment details
        if (request.getPaymentDetails() != null) {
            String cardNumber = request.getPaymentDetails().get("cardNumber");
            if (cardNumber != null && cardNumber.startsWith("4000")) {
                // Test card that always fails
                return false;
            }
        }

        // 90% success rate
        return random.nextInt(100) < 90;
    }

    private void updateOrderStatus(Long orderId, OrderStatus status) {
        orderRepository.findById(orderId).ifPresent(order -> {
            order.setStatus(status);
            orderRepository.save(order);
        });
    }

    private PaymentDTO mapToDTO(Payment payment) {
        return PaymentDTO.builder()
                .id(payment.getId())
                .transactionId(payment.getTransactionId())
                .orderId(payment.getOrderId())
                .userId(payment.getUserId())
                .paymentMethod(payment.getPaymentMethod())
                .status(payment.getStatus())
                .amount(payment.getAmount())
                .errorMessage(payment.getErrorMessage())
                .retryCount(payment.getRetryCount())
                .metadata(payment.getMetadata())
                .createdAt(payment.getCreatedAt())
                .updatedAt(payment.getUpdatedAt())
                .completedAt(payment.getCompletedAt())
                .build();
    }
}
