package io.audira.commerce.service;

import io.audira.commerce.client.NotificationClient;
import io.audira.commerce.dto.PurchaseNotificationRequest;
import io.audira.commerce.model.*;
import io.audira.commerce.repository.OrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Servicio de lógica de negocio responsable del envío de notificaciones push
 * para eventos clave (compras, errores de pago, cambios de estado).
 *
 * @author Grupo GA01
 * @see NotificationClient
 *
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class NotificationService {

    private final NotificationClient notificationClient;
    private final OrderRepository orderRepository;
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

    // --- Métodos de Lógica de Notificación ---

    /**
     * Orquesta el envío de notificaciones push tras un pago exitoso.
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

            // Enviar notificación push (Firebase)
            notificationClient.sendNotification(order.getUserId(), title, message, "SUCCESS");
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

                // Enviar notificación push (Firebase)
                notificationClient.sendNotification(artistId, title, message, "INFO");
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

            // Enviar notificación push (Firebase)
            notificationClient.sendNotification(order.getUserId(), title, message, "ERROR");
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

            // Enviar notificación push (Firebase)
            notificationClient.sendNotification(payment.getUserId(), title, message, "INFO");
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

            // Enviar notificación push (Firebase)
            notificationClient.sendNotification(order.getUserId(), title, message, "INFO");
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

            // Enviar notificación push (Firebase)
            notificationClient.sendNotification(order.getUserId(), title, message, "INFO");
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