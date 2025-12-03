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

/**
 * Servicio de lógica de negocio responsable de la generación de Recibos de Pago (Receipts) y de la consolidación de datos transaccionales.
 * <p>
 * Se encarga de calcular el desglose de precios (Subtotal e IVA) a partir del monto total de pago y de integrar
 * información de la orden, el pago y los detalles del usuario obtenidos a través de clientes de microservicios.
 * </p>
 *
 * @author Grupo GA01
 * @see PaymentRepository
 * @see OrderRepository
 * @see UserClient
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptService {

    private final PaymentRepository paymentRepository;
    private final OrderRepository orderRepository;
    private final PaymentService paymentService;
    private final OrderService orderService;
    private final UserClient userClient;

    /**
     * Tasa de Impuesto al Valor Agregado (IVA) utilizada para el cálculo del desglose de precios (21%).
     */
    private static final BigDecimal TAX_RATE = new BigDecimal("0.21");

    /**
     * Genera un nuevo recibo de pago completo a partir de un ID de pago.
     * <p>
     * Pasos clave:
     * <ul>
     * <li>Verifica que el pago exista y su estado sea {@link PaymentStatus#COMPLETED}.</li>
     * <li>Obtiene la orden asociada.</li>
     * <li>Calcula el Subtotal y el IVA a partir del monto total pagado.</li>
     * <li>Consulta los detalles del usuario a través de {@link UserClient}.</li>
     * </ul>
     * </p>
     *
     * @param paymentId El ID del registro de pago (tipo {@link Long}).
     * @return El objeto {@link ReceiptDTO} generado.
     * @throws RuntimeException si el pago o la orden no se encuentran, o si el pago no está completado.
     */
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
        // Fórmula: subtotal = total / (1 + TAX_RATE)
        BigDecimal divisor = BigDecimal.ONE.add(TAX_RATE);
        BigDecimal subtotal = total.divide(divisor, 2, RoundingMode.HALF_UP);
        BigDecimal tax = total.subtract(subtotal);

        log.info("Price breakdown - Subtotal: {}, Tax ({}%): {}, Total: {}", 
                subtotal, TAX_RATE.multiply(new BigDecimal("100")), tax, total);

        // Mapeo de ítems a líneas de recibo
        List<ReceiptItemDTO> items = order.getItems().stream()
                .map(this::mapToReceiptItem)
                .collect(Collectors.toList());

        // Obtención de DTOs para consolidación de datos
        PaymentDTO paymentDTO = paymentService.getPaymentById(paymentId);
        OrderDTO orderDTO = orderService.getOrderById(order.getId());

        // Obtención de datos del cliente desde el microservicio
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

    /**
     * Obtiene un recibo por el ID de pago asociado.
     * <p>
     * Método auxiliar que simplemente llama a {@link #generateReceipt(Long)}.
     * </p>
     *
     * @param paymentId El ID del registro de pago.
     * @return El {@link ReceiptDTO}.
     */
    public ReceiptDTO getReceiptByPaymentId(Long paymentId) {
        return generateReceipt(paymentId);
    }

    /**
     * Obtiene un recibo por el ID de transacción de la pasarela de pago.
     * <p>
     * Primero busca el registro de pago ({@link Payment}) asociado al ID de transacción.
     * </p>
     *
     * @param transactionId El ID de transacción (String).
     * @return El {@link ReceiptDTO}.
     * @throws RuntimeException si el pago no se encuentra.
     */
    public ReceiptDTO getReceiptByTransactionId(String transactionId) {
        Payment payment = paymentRepository.findByTransactionId(transactionId)
                .orElseThrow(() -> new RuntimeException("Payment not found"));
        return generateReceipt(payment.getId());
    }

    /**
     * Mapea un {@link OrderItem} a un {@link ReceiptItemDTO}, calculando el precio total de la línea.
     * <p>
     * Método auxiliar privado.
     * </p>
     *
     * @param item El artículo de la orden de compra.
     * @return El {@link ReceiptItemDTO} resultante.
     */
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

    /**
     * Genera un nombre de artículo simple para el recibo.
     * <p>
     * Método auxiliar privado.
     * </p>
     *
     * @param item El artículo de la orden.
     * @return Una cadena que contiene el tipo y el ID del artículo.
     */
    private String getItemName(OrderItem item) {
        return item.getItemType() + " #" + item.getItemId();
    }
}