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

/**
 * Controlador REST para manejar la bandeja de entrada de notificaciones y la recepción
 * de eventos de notificación de otros microservicios.
 * <p>
 * Los endpoints base se mapean a {@code /api/notifications}. Permite crear, consultar,
 * y gestionar el estado (leído/no leído) de las notificaciones de los usuarios.
 * </p>
 *
 * @author Grupo GA01
 * @see NotificationService
 * 
 */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class NotificationController {

    /**
     * Servicio de lógica de negocio para la gestión de notificaciones.
     */
    private final NotificationService notificationService;

    /**
     * Endpoint general para recibir solicitudes de notificación de otros servicios.
     * <p>
     * Crea una nueva notificación en la base de datos del usuario y gestiona el envío push asociado.
     * Mapeo: {@code POST /api/notifications}
     * </p>
     *
     * @param notificationRequest Cuerpo de la solicitud {@link RequestBody} que debe contener:
     * <ul>
     * <li>{@code userId} (Long): ID del usuario destinatario.</li>
     * <li>{@code title} (String): Título de la notificación.</li>
     * <li>{@code message} (String): Mensaje de la notificación.</li>
     * <li>{@code type} (String): Tipo de notificación (ej. "SYSTEM_NOTIFICATION").</li>
     * </ul>
     * @return {@link ResponseEntity} con un mensaje de éxito (200 OK) o un mensaje de error (500 INTERNAL SERVER ERROR).
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
     * Endpoint interno para procesar notificaciones de eventos de compra.
     * <p>
     * Este endpoint se utiliza para manejar eventos complejos de compra (ej. éxito, fallo, reembolso)
     * y disparar las notificaciones push y de bandeja de entrada asociadas.
     * Mapeo: {@code POST /api/notifications/purchase}
     * </p>
     *
     * @param request Objeto {@link PurchaseNotificationRequest} validado, conteniendo los detalles de la orden de compra.
     * @return {@link ResponseEntity} con un mensaje de éxito (200 OK) o un mensaje de error (500 INTERNAL SERVER ERROR).
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
     * Obtiene una lista paginada de todas las notificaciones de un usuario.
     * <p>
     * Mapeo: {@code GET /api/notifications/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyas notificaciones se desean obtener.
     * @param page Número de página solicitado (por defecto: 0).
     * @param size Tamaño de la página (número de elementos, por defecto: 20).
     * @return {@link ResponseEntity} que contiene un objeto {@link Page} de {@link NotificationDTO} con estado HTTP 200 (OK).
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
     * Obtiene una lista simple (no paginada) de notificaciones de un usuario filtradas por tipo.
     * <p>
     * Mapeo: {@code GET /api/notifications/user/{userId}/type/{type}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyas notificaciones se desean obtener.
     * @param type El tipo de notificación (String) por el cual filtrar.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link NotificationDTO} con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}/type/{type}")
    public ResponseEntity<List<NotificationDTO>> getNotificationsByType(
            @PathVariable Long userId, 
            @PathVariable String type) {
        
        List<NotificationDTO> notifications = notificationService.getNotificationsByType(userId, type);
        return ResponseEntity.ok(notifications);
    }

    /**
     * Cuenta el número total de notificaciones no leídas para un usuario.
     * <p>
     * Mapeo: {@code GET /api/notifications/user/{userId}/unread/count}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) para el que se realizará el conteo.
     * @return {@link ResponseEntity} que contiene un mapa con la clave {@code count} y el número de notificaciones no leídas.
     */
    @GetMapping("/user/{userId}/unread/count")
    public ResponseEntity<Map<String, Long>> countUnreadNotifications(@PathVariable Long userId) {
        Long count = notificationService.countUnreadNotifications(userId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * Marca una notificación específica como leída.
     * <p>
     * Mapeo: {@code PATCH /api/notifications/{notificationId}/read}
     * </p>
     *
     * @param notificationId El ID de la notificación (tipo {@link Long}) a marcar como leída.
     * @return {@link ResponseEntity} que contiene el objeto {@link NotificationDTO} actualizado (200 OK) o un error si no se encuentra (404 NOT FOUND).
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
     * Marca todas las notificaciones de un usuario como leídas.
     * <p>
     * Mapeo: {@code PATCH /api/notifications/user/{userId}/read-all}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyas notificaciones se marcarán como leídas.
     * @return {@link ResponseEntity} con un mensaje de éxito (200 OK).
     */
    @PatchMapping("/user/{userId}/read-all")
    public ResponseEntity<Map<String, String>> markAllAsRead(@PathVariable Long userId) {
        notificationService.markAllAsRead(userId);
        return ResponseEntity.ok(Map.of("message", "All notifications marked as read"));
    }

    /**
     * Elimina una notificación específica.
     * <p>
     * Mapeo: {@code DELETE /api/notifications/{notificationId}}
     * </p>
     *
     * @param notificationId El ID de la notificación (tipo {@link Long}) a eliminar.
     * @return {@link ResponseEntity} con estado HTTP 204 (NO CONTENT) si la eliminación es exitosa, o 404 (NOT FOUND) si no existe.
     */
    @DeleteMapping("/{notificationId}")
    public ResponseEntity<Void> deleteNotification(@PathVariable Long notificationId) {
        try {
            notificationService.deleteNotification(notificationId);
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            // Manejamos la excepción para retornar 404 si el servicio no encuentra el recurso
            return ResponseEntity.notFound().build();
        }
    }
}