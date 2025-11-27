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
 * REST client for sending notifications to users
 * Communicates with Commerce Service notification endpoints
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class NotificationClient {

    private final RestTemplate restTemplate;

    @Value("${services.commerce.url:http://172.16.0.4:9003/api/notifications}")
    private String notificationServiceUrl;

    /**
     * Send a notification to a user
     *
     * @param userId User ID to receive notification
     * @param title Notification title
     * @param message Notification message
     * @param type Notification type (NEW_PRODUCT, PRODUCT_APPROVED, PRODUCT_REJECTED, etc.)
     * @return true if notification was sent successfully
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
     * Notify followers that an artist has published new content
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
     * Notify admin that there is new content pending review
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
     * Notify artist that their content was approved
     */
    public boolean notifyArtistApproved(Long artistId, String productType, String productTitle) {
        String title = "Contenido aprobado";
        String message = String.format(
            "Tu %s \"%s\" ha sido aprobado y publicado",
            productType.equalsIgnoreCase("SONG") ? "canción" : "álbum",
            productTitle
        );

        return sendNotification(artistId, title, message, "PRODUCT_APPROVED");
    }

    /**
     * Notify artist that their content was rejected
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
