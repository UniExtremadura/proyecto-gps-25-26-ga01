package io.audira.catalog.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

/**
 * Cliente REST para el envío de notificaciones a usuarios.
 * <p>
 * Centraliza la lógica de comunicación con el endpoint de notificaciones (alojado en el servicio de Comercio).
 * Facilita métodos de alto nivel para casos de uso comunes como aprobaciones o rechazos de contenido.
 * </p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationClient {

    private final RestTemplate restTemplate;

    @Value("${services.commerce.url:http://172.16.0.4:8080/api/notifications}")
    private String notificationServiceUrl;

    /**
     * Método genérico para enviar una notificación personalizada.
     *
     * @param userId ID del usuario destinatario.
     * @param title Título de la notificación.
     * @param message Cuerpo del mensaje.
     * @param type Tipo de notificación (ej: NEW_PRODUCT, PRODUCT_APPROVED).
     * @return {@code true} si el envío fue exitoso, {@code false} si hubo error.
     */
    public boolean sendNotification(Long userId, String title, String message, String type) {
        try {
            log.info("Sending notification to user {}: {}", userId, title);

            Map<String, Object> notificationRequest = new HashMap<>();
            notificationRequest.put("userId", userId);
            notificationRequest.put("title", title);
            notificationRequest.put("message", message);
            notificationRequest.put("type", type);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(notificationRequest, headers);

            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                notificationServiceUrl,
                HttpMethod.POST,
                request,
                new ParameterizedTypeReference<Map<String, Object>>() {}
            );

            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Notification sent successfully to user {}", userId);
                return true;
            } else {
                log.warn("Failed to send notification to user {}. Status: {}",
                    userId, response.getStatusCode());
                return false;
            }

        } catch (Exception e) {
            log.error("Error sending notification to user {}: {}", userId, e.getMessage());
            return false;
        }
    }

    /**
     * Notifica a un usuario (seguidor) sobre un nuevo lanzamiento de un artista.
     * <p>
     * Se utiliza para fidelizar a la audiencia, enviando una alerta de tipo {@code NEW_PRODUCT}
     * cada vez que un artista al que siguen publica nuevo material.
     * </p>
     *
     * @param followerId ID del usuario seguidor.
     * @param artistName Nombre del artista que lanza el producto.
     * @param productTitle Título del nuevo lanzamiento.
     * @param productType Tipo de lanzamiento ("SONG" o "ALBUM").
     * @return {@code true} si el envío fue exitoso, {@code false} en caso de error.
     */
    public boolean notifyNewProduct(Long userId, String productType, String productTitle, String artistName) {
        String title = "Nuevo contenido disponible";
        String message = String.format(
            "%s ha publicado: %s \"%s\"",
            artistName,
            productType.equalsIgnoreCase("SONG") ? "la canción" : "el álbum",
            productTitle
        );

        return sendNotification(userId, title, message, "NEW_PRODUCT");
    }

    /**
     * Notifica a un administrador específico sobre contenido pendiente de revisión.
     * <p>
     * Este método se utiliza en el flujo de aprobación de contenido. Genera una alerta
     * de tipo {@code PRODUCT_PENDING_REVIEW} para que el administrador sepa que debe actuar.
     * </p>
     *
     * @param adminId ID del usuario administrador que recibirá la alerta.
     * @param productTitle Título de la obra (canción o álbum).
     * @param productType Tipo de producto ("SONG" o "ALBUM").
     * @param artistName Nombre del artista que subió el contenido.
     * @return {@code true} si la notificación se encoló correctamente en el servicio de comercio.
     */
    public boolean notifyAdminPendingReview(Long adminId, String productType, String productTitle, String artistName) {
        String title = "Nuevo contenido pendiente de revisión";
        String message = String.format(
            "%s ha subido %s \"%s\" que requiere revisión",
            artistName,
            productType.equalsIgnoreCase("SONG") ? "la canción" : "el álbum",
            productTitle
        );

        return sendNotification(adminId, title, message, "PRODUCT_PENDING_REVIEW");
    }

    /**
     * Notifica al artista que su contenido ha sido aprobado y publicado.
     *
     * @param artistId ID del artista.
     * @param productType Tipo de producto.
     * @param productTitle Título del producto.
     * @return {@code true} si la notificación se envió correctamente.
     */
    public boolean notifyArtistApproved(Long artistId, String productType, String productTitle) {
        String title = "Contenido aprobado";
        String message = String.format(
            "Tu %s \"%s\" ha sido aprobado",
            productType.equalsIgnoreCase("SONG") ? "canción" : "álbum",
            productTitle
        );

        return sendNotification(artistId, title, message, "PRODUCT_APPROVED");
    }

    /**
     * Notifica al artista que su contenido ha sido rechazado.
     *
     * @param artistId ID del artista.
     * @param productType Tipo de producto.
     * @param productTitle Título del producto.
     * @param reason Razón del rechazo proporcionada por el administrador.
     * @return {@code true} si la notificación se envió correctamente.
     */
    public boolean notifyArtistRejected(Long artistId, String productType, String productTitle, String reason) {
        String title = "Contenido rechazado";
        String message = String.format(
            "Tu %s \"%s\" ha sido rechazado. Motivo: %s",
            productType.equalsIgnoreCase("SONG") ? "canción" : "álbum",
            productTitle,
            reason
        );

        return sendNotification(artistId, title, message, "PRODUCT_REJECTED");
    }
}
