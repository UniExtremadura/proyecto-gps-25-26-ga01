package io.audira.commerce.service;

import io.audira.commerce.client.NotificationClient;
import io.audira.commerce.client.UserClient;
import io.audira.commerce.dto.UserDTO;
import io.audira.commerce.model.*;
import io.audira.commerce.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Servicio de notificaciones para Commerce Service
 * Maneja el envío de notificaciones relacionadas con compras, pagos y reembolsos
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationClient notificationClient;
    private final UserClient userClient;
    private final OrderRepository orderRepository;

    /**
     * Notifica sobre una compra exitosa
     * - Al comprador: confirmación de compra
     * - A los artistas: notificación de venta
     */
    public void notifySuccessfulPurchase(Order order, Payment payment) {
        log.info("=== Sending purchase notifications for order: {} ===", order.getOrderNumber());

        try {
            // 1. Notificar al comprador
            notifyBuyer(order, payment);

            // 2. Notificar a los artistas
            notifyArtists(order);

            log.info("=== Purchase notifications completed for order: {} ===", order.getOrderNumber());

        } catch (Exception e) {
            log.error("Error sending purchase notifications for order {}: {}", 
                order.getOrderNumber(), e.getMessage(), e);
        }
    }

    /**
     * Notifica al comprador sobre su compra exitosa
     */
    private void notifyBuyer(Order order, Payment payment) {
        try {
            log.info("Notifying buyer (user {}) about successful purchase", order.getUserId());

            boolean sent = notificationClient.notifyUserPurchaseSuccess(
                order.getUserId(),
                order.getOrderNumber(),
                payment.getAmount().doubleValue()
            );

            if (sent) {
                log.info("Buyer notification sent successfully");
            } else {
                log.warn("Failed to send buyer notification");
            }

        } catch (Exception e) {
            log.error("Error notifying buyer: {}", e.getMessage());
        }
    }

    /**
     * Notifica a los artistas sobre nuevas ventas
     * Agrupa las compras por artista para enviar una notificación consolidada
     */
    private void notifyArtists(Order order) {
        try {
            // Obtener información del comprador
            UserDTO buyer = userClient.getUserById(order.getUserId());
            String buyerName = buyer.getFirstName() + " " + buyer.getLastName();

            // Agrupar items por artista
            Map<Long, List<OrderItem>> itemsByArtist = groupItemsByArtist(order);

            log.info("Notifying {} artist(s) about new sales", itemsByArtist.size());

            // Notificar a cada artista
            for (Map.Entry<Long, List<OrderItem>> entry : itemsByArtist.entrySet()) {
                Long artistId = entry.getKey();
                List<OrderItem> items = entry.getValue();

                notifyArtistAboutSale(artistId, items, buyerName, order.getOrderNumber());
            }

        } catch (Exception e) {
            log.error("Error notifying artists: {}", e.getMessage(), e);
        }
    }

    /**
     * Agrupa los items del pedido por artista
     * Nota: En un sistema real, deberíamos obtener el artistId desde catalog-service
     * Por ahora, usamos un sistema simplificado
     */
    private Map<Long, List<OrderItem>> groupItemsByArtist(Order order) {
       
        Map<Long, List<OrderItem>> grouped = new HashMap<>();
        
        for (OrderItem item : order.getItems()) {
            // Simulación: usar itemId como artistId (cambiar cuando se integre catalog-service)
            Long artistId = item.getItemId(); 
            grouped.computeIfAbsent(artistId, k -> new ArrayList<>()).add(item);
        }
        
        return grouped;
    }

    /**
     * Notifica a un artista específico sobre sus ventas
     */
    private void notifyArtistAboutSale(Long artistId, List<OrderItem> items, 
                                       String buyerName, String orderNumber) {
        try {
            log.info("Notifying artist {} about {} item(s) sold", artistId, items.size());

            // Si es un solo item, usar notificación simple
            if (items.size() == 1) {
                OrderItem item = items.get(0);
                notificationClient.notifyArtistPurchase(
                    artistId,
                    item.getItemType().toString(),
                    "Item #" + item.getItemId(), // TODO: obtener título real desde catalog-service
                    buyerName,
                    item.getPrice().multiply(java.math.BigDecimal.valueOf(item.getQuantity())).doubleValue(),
                    orderNumber
                );
            } else {
                // Múltiples items: crear notificación consolidada
                double totalAmount = items.stream()
                    .mapToDouble(i -> i.getPrice().multiply(
                        java.math.BigDecimal.valueOf(i.getQuantity())).doubleValue())
                    .sum();

                String itemsList = items.stream()
                    .map(i -> i.getItemType() + " #" + i.getItemId())
                    .collect(Collectors.joining(", "));

                String title = "🎉 Nueva compra realizada";
                String message = String.format(
                    "%s ha comprado %d productos tuyos por $%.2f: %s. Pedido: %s",
                    buyerName,
                    items.size(),
                    totalAmount,
                    itemsList,
                    orderNumber
                );

                notificationClient.sendNotification(artistId, title, message, "SUCCESS");
            }

            log.info("Artist {} notified successfully", artistId);

        } catch (Exception e) {
            log.error("Error notifying artist {}: {}", artistId, e.getMessage());
        }
    }

    /**
     * Notifica sobre un pago fallido
     */
    public void notifyFailedPayment(Order order, String errorMessage) {
        log.info("=== Sending failed payment notification for order: {} ===", order.getOrderNumber());

        try {
            notificationClient.notifyUserPurchaseFailed(
                order.getUserId(),
                order.getOrderNumber(),
                errorMessage
            );

            log.info("Failed payment notification sent successfully");

        } catch (Exception e) {
            log.error("Error sending failed payment notification: {}", e.getMessage());
        }
    }

    /**
     * Notifica sobre un reembolso
     * - Al comprador: confirmación de reembolso
     * - A los artistas: aviso de reembolso
     */
    public void notifyRefund(Payment payment) {
        log.info("=== Sending refund notifications for payment: {} ===", payment.getTransactionId());

        try {
            Order order = orderRepository.findById(payment.getOrderId())
                .orElseThrow(() -> new RuntimeException("Order not found"));

            // 1. Notificar al comprador
            notificationClient.notifyUserRefund(
                order.getUserId(),
                order.getOrderNumber(),
                payment.getAmount().doubleValue()
            );

            // 2. Notificar a los artistas
            Map<Long, List<OrderItem>> itemsByArtist = groupItemsByArtist(order);
            
            for (Map.Entry<Long, List<OrderItem>> entry : itemsByArtist.entrySet()) {
                Long artistId = entry.getKey();
                List<OrderItem> items = entry.getValue();

                for (OrderItem item : items) {
                    notificationClient.notifyArtistRefund(
                        artistId,
                        item.getItemType() + " #" + item.getItemId(),
                        order.getOrderNumber()
                    );
                }
            }

            log.info("=== Refund notifications completed ===");

        } catch (Exception e) {
            log.error("Error sending refund notifications: {}", e.getMessage(), e);
        }
    }

    /**
     * Notifica sobre un cambio en el estado del pedido
     */
    public void notifyOrderStatusChange(Order order, OrderStatus oldStatus, OrderStatus newStatus) {
        log.info("Notifying order status change: {} -> {} for order {}", 
            oldStatus, newStatus, order.getOrderNumber());

        try {
            String title = "📦 Estado de pedido actualizado";
            String message = String.format(
                "Tu pedido %s ha cambiado de estado: %s → %s",
                order.getOrderNumber(),
                translateStatus(oldStatus),
                translateStatus(newStatus)
            );

            notificationClient.sendNotification(order.getUserId(), title, message, "INFO");

            log.info("Order status change notification sent successfully");

        } catch (Exception e) {
            log.error("Error sending order status notification: {}", e.getMessage());
        }
    }

    /**
     * Traduce el estado del pedido a un mensaje amigable
     */
    private String translateStatus(OrderStatus status) {
        switch (status) {
            case PENDING: return "Pendiente";
            case PROCESSING: return "Procesando";
            case SHIPPED: return "Enviado";
            case DELIVERED: return "Entregado";
            case CANCELLED: return "Cancelado";
            default: return status.toString();
        }
    }
}