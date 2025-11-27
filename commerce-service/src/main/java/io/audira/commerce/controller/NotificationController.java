package io.audira.commerce.controller;

import io.audira.commerce.dto.NotificationDTO;
import io.audira.commerce.dto.PurchaseNotificationRequest;
import io.audira.commerce.service.NotificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class NotificationController {

    private final NotificationService notificationService;

    /**
     * Endpoint general para recibir notificaciones de otros servicios
     */
    @PostMapping
    public ResponseEntity<Map<String, String>> sendNotification(@RequestBody Map<String, Object> notificationRequest) {
        try {
            Long userId = ((Number) notificationRequest.get("userId")).longValue();
            String title = (String) notificationRequest.get("title");
            String message = (String) notificationRequest.get("message");
            String typeStr = (String) notificationRequest.get("type");

            log.info("Received notification for user {}: {}", userId, title);

            io.audira.commerce.model.NotificationType type;
            try {
                type = io.audira.commerce.model.NotificationType.valueOf(typeStr);
            } catch (IllegalArgumentException e) {
                type = io.audira.commerce.model.NotificationType.SYSTEM_NOTIFICATION;
            }

            notificationService.createNotification(userId, title, message, type, null, null);
            return ResponseEntity.ok(Map.of("message", "Notification created successfully"));
        } catch (Exception e) {
            log.error("Error creating notification: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to create notification: " + e.getMessage()));
        }
    }

    /**
     * Endpoint interno para procesar notificaciones de compra
     * Llamado por otros servicios o webhooks
     */
    @PostMapping("/purchase")
    public ResponseEntity<Map<String, String>> processPurchaseNotification(
            @Valid @RequestBody PurchaseNotificationRequest request) {
        try {
            log.info("Received purchase notification request for order: {}", request.getOrderId());
            notificationService.processPurchaseNotifications(request);
            return ResponseEntity.ok(Map.of("message", "Purchase notifications processed successfully"));
        } catch (Exception e) {
            log.error("Error processing purchase notification: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to process notification: " + e.getMessage()));
        }
    }

    /**
     * Obtener todas las notificaciones de un usuario (Paginado)
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<Page<NotificationDTO>> getUserNotifications(
            @PathVariable Long userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        
        Pageable pageable = PageRequest.of(page, size);
        return ResponseEntity.ok(notificationService.getUserNotifications(userId, pageable));
    }

    /**
     * Obtener notificaciones por tipo (Lista simple)
     */
    @GetMapping("/user/{userId}/type/{type}")
    public ResponseEntity<List<NotificationDTO>> getNotificationsByType(
            @PathVariable Long userId, 
            @PathVariable String type) {
        
        List<NotificationDTO> notifications = notificationService.getNotificationsByType(userId, type);
        return ResponseEntity.ok(notifications);
    }

    /**
     * Contar notificaciones no leídas
     */
    @GetMapping("/user/{userId}/unread/count")
    public ResponseEntity<Map<String, Long>> countUnreadNotifications(@PathVariable Long userId) {
        Long count = notificationService.countUnreadNotifications(userId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * Marcar una notificación específica como leída
     */
    @PatchMapping("/{notificationId}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long notificationId) {
        try {
            NotificationDTO notification = notificationService.markAsRead(notificationId);
            return ResponseEntity.ok(notification);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(Map.of("error", "Notification not found"));
        }
    }

    /**
     * Marcar todas las notificaciones de un usuario como leídas
     */
    @PatchMapping("/user/{userId}/read-all")
    public ResponseEntity<Map<String, String>> markAllAsRead(@PathVariable Long userId) {
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(Map.of("message", "All notifications marked as read"));
    }

    /**
     * Eliminar una notificación
     */
    @DeleteMapping("/{notificationId}")
    public ResponseEntity<Void> deleteNotification(@PathVariable Long notificationId) {
        try {
            notificationService.deleteNotification(notificationId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            // Si falla porque no existe, igual devolvemos no content o not found
            return ResponseEntity.notFound().build();
        }
    }
}