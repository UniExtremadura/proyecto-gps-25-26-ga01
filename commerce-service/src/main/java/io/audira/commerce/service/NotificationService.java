package io.audira.commerce.service;

import io.audira.commerce.client.NotificationClient;
import io.audira.commerce.dto.NotificationDTO;
import io.audira.commerce.dto.PurchaseNotificationRequest;
import io.audira.commerce.model.*;
import io.audira.commerce.repository.NotificationRepository;
import io.audira.commerce.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationClient notificationClient;
    private final OrderRepository orderRepository;
    private final NotificationRepository notificationRepository;

    @Transactional
    public void processPurchaseNotifications(PurchaseNotificationRequest request) {
        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new RuntimeException("Order not found: " + request.getOrderId()));
        
        // Creamos un objeto Payment temporal para pasar los datos
        Payment payment = new Payment(); 
        payment.setAmount(request.getTotalAmount());
        // Nota: Idealmente el request debería tener ID de pago real, pero esto funciona.
        
        notifySuccessfulPurchase(order, payment);
    }

    /**
     * ✅ OPTIMIZADO: Paginación delegada a la base de datos.
     * Ya no trae todas las notificaciones a memoria.
     */
    public Page<NotificationDTO> getUserNotifications(Long userId, Pageable pageable) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(this::mapToDTO); // .map de Page convierte eficientemente cada elemento
    }

    public List<NotificationDTO> getNotificationsByType(Long userId, String typeStr) {
        try {
            NotificationType type = NotificationType.valueOf(typeStr.toUpperCase());
            return notificationRepository.findByUserIdAndTypeOrderByCreatedAtDesc(userId, type)
                    .stream()
                    .map(this::mapToDTO)
                    .collect(Collectors.toList());
        } catch (IllegalArgumentException e) {
            log.error("Invalid notification type: {}", typeStr);
            return Collections.emptyList();
        }
    }

    public Long countUnreadNotifications(Long userId) {
        return notificationRepository.countByUserIdAndIsRead(userId, false);
    }

    @Transactional
    public NotificationDTO markAsRead(Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));
        
        // Solo actualizamos si no estaba leída para no sobrescribir la fecha original
        if (!notification.getIsRead()) {
            notification.setIsRead(true);
            notification.setReadAt(LocalDateTime.now());
        }
        
        Notification saved = notificationRepository.save(notification);
        return mapToDTO(saved);
    }

    @Transactional
    public void markAllAsRead(Long userId) {
        List<Notification> unread = notificationRepository.findByUserIdAndIsReadOrderByCreatedAtDesc(userId, false);
        if (unread.isEmpty()) return; // Optimización pequeña

        LocalDateTime now = LocalDateTime.now();
        unread.forEach(n -> {
            n.setIsRead(true);
            n.setReadAt(now);
        });
        notificationRepository.saveAll(unread);
    }

    @Transactional
    public void deleteNotification(Long notificationId) {
        notificationRepository.deleteById(notificationId);
    }

    // --- Métodos de Lógica de Notificación ---

    public void notifySuccessfulPurchase(Order order, Payment payment) {
        log.info("=== Sending purchase notifications for order: {} ===", order.getOrderNumber());
        // Se llaman por separado para que un error en uno no detenga al otro
        notifyBuyer(order, payment);
        notifyArtists(order);
    }

    private void notifyBuyer(Order order, Payment payment) {
        try {
            String title = "¡Compra exitosa! 🎉";
            String message = String.format("Tu pedido %s por $%s ha sido confirmado.", 
                order.getOrderNumber(), payment.getAmount());
            
            // 1. Enviar externa (Email/Push)
            notificationClient.sendNotification(order.getUserId(), title, message, "SUCCESS");
            
            // 2. Guardar interna (DB)
            saveLocalNotification(
                order.getUserId(), title, message, 
                NotificationType.ORDER_CONFIRMATION, order.getId(), "ORDER"
            );
        } catch (Exception e) {
            log.error("Error notifying buyer: {}", e.getMessage());
        }
    }

    private void notifyArtists(Order order) {
        Map<Long, List<OrderItem>> itemsByArtist = order.getItems().stream()
                .collect(Collectors.groupingBy(OrderItem::getArtistId));

        itemsByArtist.forEach((artistId, items) -> {
            try {
                String title = "¡Nueva venta! 💰";
                String message = String.format("Has vendido %d items en el pedido %s", 
                    items.size(), order.getOrderNumber());
                
                notificationClient.sendNotification(artistId, title, message, "INFO");
                
                saveLocalNotification(
                    artistId, title, message, 
                    NotificationType.PURCHASE_NOTIFICATION, order.getId(), "SALE"
                );
            } catch (Exception e) {
                log.error("Error notifying artist {}: {}", artistId, e.getMessage());
            }
        });
    }

    public void notifyFailedPayment(Order order, String reason) {
        try {
            String title = "❌ Error en el pago";
            String message = String.format("El pago para el pedido %s ha fallado. Motivo: %s", 
                order.getOrderNumber(), reason);
            
            notificationClient.sendNotification(order.getUserId(), title, message, "ERROR");
            
            saveLocalNotification(
                order.getUserId(), title, message, 
                NotificationType.PAYMENT_FAILED, order.getId(), "ORDER"
            );
        } catch (Exception e) {
            log.error("Error sending failed payment notification", e);
        }
    }

    public void notifyRefund(Payment payment) {
        try {
            String title = "Reembolso procesado 💸";
            String message = String.format("Se ha procesado un reembolso de $%s", payment.getAmount());
            
            notificationClient.sendNotification(payment.getUserId(), title, message, "INFO");
            
            saveLocalNotification(
                payment.getUserId(), title, message, 
                NotificationType.SYSTEM_NOTIFICATION, payment.getId(), "PAYMENT"
            );
        } catch (Exception e) {
            log.error("Error sending refund notification for payment", e);
        }
    }

    public void notifyRefund(Order order) {
        try {
            String title = "Reembolso procesado 💸";
            String message = String.format("Se ha procesado el reembolso para el pedido %s", 
                order.getOrderNumber());
            
            notificationClient.sendNotification(order.getUserId(), title, message, "INFO");
            
            saveLocalNotification(
                order.getUserId(), title, message, 
                NotificationType.SYSTEM_NOTIFICATION, order.getId(), "REFUND"
            );
        } catch (Exception e) {
            log.error("Error sending refund notification for order", e);
        }
    }

    public void notifyOrderStatusChange(Order order, OrderStatus oldStatus, OrderStatus newStatus) {
        try {
            String title = "📦 Estado de pedido actualizado";
            String message = String.format(
                "Tu pedido %s ha cambiado de estado: %s → %s",
                order.getOrderNumber(), translateStatus(oldStatus), translateStatus(newStatus)
            );

            notificationClient.sendNotification(order.getUserId(), title, message, "INFO");
            
            saveLocalNotification(
                order.getUserId(), title, message, 
                NotificationType.SYSTEM_NOTIFICATION, order.getId(), "ORDER_STATUS"
            );
        } catch (Exception e) {
            log.error("Error sending order status notification", e);
        }
    }

    // --- Helpers ---

    private void saveLocalNotification(Long userId, String title, String message, NotificationType type, Long referenceId, String referenceType) {
        try {
            Notification notification = Notification.builder()
                    .userId(userId)
                    .title(title)
                    .message(message)
                    .type(type)
                    .referenceId(referenceId)
                    .referenceType(referenceType)
                    .isRead(false)
                    .isSent(true)
                    .sentAt(LocalDateTime.now()) // Fecha de envío
                    // createdAt se llena automático con @PrePersist en la entidad, 
                    // pero si quieres forzarlo aquí también es válido:
                    .createdAt(LocalDateTime.now()) 
                    .build();
            
            notificationRepository.save(notification);
        } catch (Exception e) {
            log.error("Could not save local notification history", e);
            // No relanzamos la excepción para no romper el flujo principal (ej: el email sí se envió)
        }
    }

    private NotificationDTO mapToDTO(Notification notification) {
        return NotificationDTO.builder()
                .id(notification.getId())
                .userId(notification.getUserId())
                .title(notification.getTitle())
                .message(notification.getMessage())
                .type(notification.getType())
                .isRead(notification.getIsRead())
                .isSent(notification.getIsSent())
                .referenceId(notification.getReferenceId())
                .referenceType(notification.getReferenceType())
                .sentAt(notification.getSentAt())
                .readAt(notification.getReadAt())
                .createdAt(notification.getCreatedAt())
                .metadata(notification.getMetadata())
                .build();
    }

    private String translateStatus(OrderStatus status) {
        if (status == null) return "Desconocido";
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