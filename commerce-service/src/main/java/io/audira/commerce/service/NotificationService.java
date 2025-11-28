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

/**
 * Servicio de lógica de negocio responsable de la gestión de notificaciones de usuario y la orquestación
 * del envío de mensajes push y la persistencia en la bandeja de entrada (inbox).
 * <p>
 * Centraliza la lógica para notificar sobre eventos clave (compras, errores de pago, cambios de estado).
 * </p>
 *
 * @author Grupo GA01
 * @see NotificationRepository
 * @see NotificationClient
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationClient notificationClient;
    private final OrderRepository orderRepository;
    private final NotificationRepository notificationRepository;
    private final io.audira.commerce.client.MusicCatalogClient musicCatalogClient;

    /**
     * Procesa una solicitud de notificación de compra exitosa recibida desde otro servicio.
     * <p>
     * Se encarga de recuperar la {@link Order} asociada y llama a los métodos de notificación del comprador y los artistas.
     * </p>
     *
     * @param request La solicitud {@link PurchaseNotificationRequest} con los detalles de la compra.
     * @throws RuntimeException si la orden referenciada no existe.
     */
    @Transactional
    public void processPurchaseNotifications(PurchaseNotificationRequest request) {
        Order order = orderRepository.findById(request.getOrderId())
                .orElseThrow(() -> new RuntimeException("Order not found: " + request.getOrderId()));
        
        // Creamos un objeto Payment temporal para pasar los datos
        Payment payment = new Payment(); 
        payment.setAmount(request.getTotalAmount());
        
        notifySuccessfulPurchase(order, payment);
    }

    /**
     * Obtiene una lista paginada de todas las notificaciones para un usuario, ordenadas de la más reciente a la más antigua.
     * <p>
     * La paginación se delega a la base de datos (repositorio) para optimización.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param pageable El objeto {@link Pageable} con los parámetros de paginación.
     * @return Un objeto {@link Page} de {@link NotificationDTO}.
     */
    public Page<NotificationDTO> getUserNotifications(Long userId, Pageable pageable) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(this::mapToDTO);
    }

    /**
     * Obtiene una lista de notificaciones de un usuario filtradas por un tipo específico.
     *
     * @param userId El ID del usuario.
     * @param typeStr El tipo de notificación (String) a buscar.
     * @return Una {@link List} de {@link NotificationDTO} del tipo especificado. Retorna una lista vacía si el tipo es inválido.
     */
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

    /**
     * Cuenta el número total de notificaciones no leídas para un usuario.
     *
     * @param userId El ID del usuario.
     * @return El conteo total (tipo {@code Long}).
     */
    public Long countUnreadNotifications(Long userId) {
        return notificationRepository.countByUserIdAndIsRead(userId, false);
    }

    /**
     * Marca una notificación específica como leída y registra la fecha de lectura.
     *
     * @param notificationId El ID de la notificación a actualizar.
     * @return La {@link NotificationDTO} actualizada.
     * @throws RuntimeException si la notificación no se encuentra.
     */
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

    /**
     * Marca todas las notificaciones no leídas de un usuario como leídas.
     *
     * @param userId El ID del usuario.
     */
    @Transactional
    public void markAllAsRead(Long userId) {
        List<Notification> unread = notificationRepository.findByUserIdAndIsReadOrderByCreatedAtDesc(userId, false);
        if (unread.isEmpty()) return;

        LocalDateTime now = LocalDateTime.now();
        unread.forEach(n -> {
            n.setIsRead(true);
            n.setReadAt(now);
        });
        notificationRepository.saveAll(unread);
    }

    /**
     * Elimina un registro de notificación específico.
     *
     * @param notificationId El ID de la notificación a eliminar.
     */
    @Transactional
    public void deleteNotification(Long notificationId) {
        notificationRepository.deleteById(notificationId);
    }

    /**
     * Crea y persiste una nueva notificación en la base de datos.
     * <p>
     * Utilizado para guardar el historial localmente. Asume que el envío push ya se ha manejado.
     * </p>
     *
     * @param userId ID del usuario.
     * @param title Título.
     * @param message Mensaje.
     * @param type Tipo de notificación.
     * @param referenceId ID de referencia (opcional).
     * @param referenceType Tipo de referencia (opcional).
     * @return La {@link NotificationDTO} creada.
     */
    @Transactional
    public NotificationDTO createNotification(Long userId, String title, String message,
                                              NotificationType type, Long referenceId, String referenceType) {
        Notification notification = Notification.builder()
                .userId(userId)
                .title(title)
                .message(message)
                .type(type)
                .referenceId(referenceId)
                .referenceType(referenceType)
                .isRead(false)
                .isSent(true)
                .sentAt(LocalDateTime.now())
                .createdAt(LocalDateTime.now()) 
                .build();

        Notification saved = notificationRepository.save(notification);
        return mapToDTO(saved);
    }

    // --- Métodos de Lógica de Notificación ---

    /**
     * Orquesta el envío de notificaciones (push y local) tras un pago exitoso.
     * <p>
     * Llama por separado a {@link #notifyBuyer(Order, Payment)} y {@link #notifyArtists(Order)}
     * para asegurar que el fallo de una no detenga a las demás.
     * </p>
     *
     * @param order La orden completada.
     * @param payment El pago asociado.
     */
    public void notifySuccessfulPurchase(Order order, Payment payment) {
        log.info("=== Sending purchase notifications for order: {} ===", order.getOrderNumber());
        notifyBuyer(order, payment);
        notifyArtists(order);
    }

    /**
     * Notifica al comprador sobre el éxito de su compra.
     *
     * @param order La orden completada.
     * @param payment El pago asociado.
     */
    private void notifyBuyer(Order order, Payment payment) {
        try {
            // Obtener nombres de productos comprados
            List<String> productNames = new ArrayList<>();
            for (OrderItem item : order.getItems()) {
                String productName = getProductName(item);
                if (productName != null) {
                    productNames.add(productName);
                }
            }

            String productsText = productNames.isEmpty()
                ? "tus productos"
                : String.join(", ", productNames);

            String title = "Compra exitosa";
            String message = String.format("Compra de %s exitosa", productsText);

            // 1. Enviar externa (Email/Push)
            notificationClient.sendNotification(order.getUserId(), title, message, "SUCCESS");

            // 2. Guardar interna (DB)
            saveLocalNotification(
                order.getUserId(), title, message,
                NotificationType.PAYMENT_SUCCESS, order.getId(), "ORDER"
            );
        } catch (Exception e) {
            log.error("Error notifying buyer: {}", e.getMessage());
        }
    }

    /**
     * Notifica a cada artista/vendedor involucrado en la orden sobre la venta de sus productos.
     * <p>
     * Los ítems de la orden se agrupan por {@code artistId} para enviar una sola notificación por artista.
     * Los ítems sin {@code artistId} (nulo) se filtran automáticamente para evitar excepciones.
     * </p>
     *
     * @param order La orden completada.
     */
    private void notifyArtists(Order order) {
        try {
            // Filtrar items sin artistId antes de agrupar para evitar NullPointerException
            Map<Long, List<OrderItem>> itemsByArtist = order.getItems().stream()
                    .filter(item -> item.getArtistId() != null)
                    .collect(Collectors.groupingBy(OrderItem::getArtistId));

            if (itemsByArtist.isEmpty()) {
                log.warn("No items with valid artistId found in order {}", order.getOrderNumber());
                return;
            }

        itemsByArtist.forEach((artistId, items) -> {
            try {
                // Obtener nombres de productos vendidos
                List<String> productNames = new ArrayList<>();
                for (OrderItem item : items) {
                    String productName = getProductName(item);
                    if (productName != null) {
                        productNames.add(productName);
                    }
                }

                String productsText = productNames.isEmpty()
                    ? "productos"
                    : String.join(", ", productNames);

                String title = "Nueva venta";
                String message = String.format("Se ha comprado una copia digital de %s", productsText);

                // 1. Enviar externa (Push/Email)
                notificationClient.sendNotification(artistId, title, message, "INFO");

                // 2. Guardar interna (DB)
                saveLocalNotification(
                    artistId, title, message,
                    NotificationType.PURCHASE_NOTIFICATION, order.getId(), "SALE"
                );
            } catch (Exception e) {
                log.error("Error notifying artist {}: {}", artistId, e.getMessage());
            }
        });
        } catch (Exception e) {
            log.error("Failed to send purchase notifications for order: {}", order.getOrderNumber(), e);
        }
    }

    /**
     * Envía una notificación al usuario sobre un fallo de pago.
     *
     * @param order La orden asociada.
     * @param reason El motivo del fallo (ej. "Tarjeta rechazada").
     */
    public void notifyFailedPayment(Order order, String reason) {
        try {
            String title = "❌ Error en el pago";
            String message = String.format("El pago para el pedido %s ha fallado. Motivo: %s", 
                order.getOrderNumber(), reason);
            
            // 1. Enviar externa
            notificationClient.sendNotification(order.getUserId(), title, message, "ERROR");
            
            // 2. Guardar interna
            saveLocalNotification(
                order.getUserId(), title, message, 
                NotificationType.PAYMENT_FAILED, order.getId(), "ORDER"
            );
        } catch (Exception e) {
            log.error("Error sending failed payment notification", e);
        }
    }

    /**
     * Envía una notificación al usuario sobre un reembolso procesado, utilizando los datos del pago.
     *
     * @param payment El registro de pago asociado al reembolso.
     */
    public void notifyRefund(Payment payment) {
        try {
            String title = "Reembolso procesado 💸";
            String message = String.format("Se ha procesado un reembolso de $%s", payment.getAmount());
            
            // 1. Enviar externa
            notificationClient.sendNotification(payment.getUserId(), title, message, "INFO");
            
            // 2. Guardar interna
            saveLocalNotification(
                payment.getUserId(), title, message, 
                NotificationType.SYSTEM_NOTIFICATION, payment.getId(), "PAYMENT"
            );
        } catch (Exception e) {
            log.error("Error sending refund notification for payment", e);
        }
    }

    /**
     * Envía una notificación al usuario sobre un reembolso procesado, utilizando los datos de la orden.
     *
     * @param order La orden asociada al reembolso.
     */
    public void notifyRefund(Order order) {
        try {
            String title = "Reembolso procesado 💸";
            String message = String.format("Se ha procesado el reembolso para el pedido %s", 
                order.getOrderNumber());
            
            // 1. Enviar externa
            notificationClient.sendNotification(order.getUserId(), title, message, "INFO");
            
            // 2. Guardar interna
            saveLocalNotification(
                order.getUserId(), title, message, 
                NotificationType.SYSTEM_NOTIFICATION, order.getId(), "REFUND"
            );
        } catch (Exception e) {
            log.error("Error sending refund notification for order", e);
        }
    }

    /**
     * Envía una notificación al usuario informando de un cambio en el estado de su orden.
     *
     * @param order La orden cuyo estado ha cambiado.
     * @param oldStatus El estado anterior.
     * @param newStatus El nuevo estado.
     */
    public void notifyOrderStatusChange(Order order, OrderStatus oldStatus, OrderStatus newStatus) {
        try {
            String title = "📦 Estado de pedido actualizado";
            String message = String.format(
                "Tu pedido %s ha cambiado de estado: %s → %s",
                order.getOrderNumber(), translateStatus(oldStatus), translateStatus(newStatus)
            );

            // 1. Enviar externa
            notificationClient.sendNotification(order.getUserId(), title, message, "INFO");
            
            // 2. Guardar interna
            saveLocalNotification(
                order.getUserId(), title, message, 
                NotificationType.SYSTEM_NOTIFICATION, order.getId(), "ORDER_STATUS"
            );
        } catch (Exception e) {
            log.error("Error sending order status notification", e);
        }
    }

    // --- Métodos Auxiliares ---

    /**
     * Obtiene el nombre de un producto (canción o álbum) a partir de un {@link OrderItem} comunicándose con el microservicio de Catálogo.
     *
     * @param item El artículo de la orden.
     * @return El título del producto, o {@code null} si falla la consulta.
     */
    private String getProductName(OrderItem item) {
        try {
            if (item.getItemType() == ItemType.SONG) {
                Map<String, Object> song = musicCatalogClient.getSongById(item.getItemId());
                if (song != null && song.get("title") != null) {
                    return (String) song.get("title");
                }
            } else if (item.getItemType() == ItemType.ALBUM) {
                Map<String, Object> album = musicCatalogClient.getAlbumById(item.getItemId());
                if (album != null && album.get("title") != null) {
                    return (String) album.get("title");
                }
            }
        } catch (Exception e) {
            log.warn("Could not fetch product name for item {} (type: {})", item.getItemId(), item.getItemType());
        }
        return null;
    }

    /**
     * Persiste una notificación en la base de datos para el historial de bandeja de entrada del usuario.
     * <p>
     * Este método contiene la lógica de persistencia y manejo de errores para evitar que un fallo al guardar el historial
     * rompa el flujo principal de la aplicación.
     * </p>
     */
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
                    .createdAt(LocalDateTime.now()) 
                    .build();
            
            notificationRepository.save(notification);
        } catch (Exception e) {
            log.error("Could not save local notification history", e);
            // No relanzamos la excepción para no romper el flujo principal (ej: el email sí se envió)
        }
    }

    /**
     * Mapea una entidad {@link Notification} a su respectivo Data Transfer Object (DTO) {@link NotificationDTO}.
     */
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

    /**
     * Traduce los valores del enumerador {@link OrderStatus} a cadenas legibles en español.
     *
     * @param status El estado de la orden.
     * @return La traducción en español.
     */
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