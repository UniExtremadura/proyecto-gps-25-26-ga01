
package io.audira.catalog.client;

import io.audira.catalog.dto.RatingStatsDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

/**
 * Cliente REST para la comunicación con el Servicio de Comunidad (Community Service).
 * <p>
 * Gestiona la obtención de estadísticas de valoraciones (ratings/estrellas) para
 * canciones, álbumes y artistas.
 * </p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class RatingServiceClient {

    private final RestTemplate restTemplate;

    @Value("${services.community.url:http://172.16.0.4:9001}")
    private String communityServiceUrl;

    /**
     * Obtiene las estadísticas de valoración para una entidad cualquiera.
     * <p>
     * Implementa un <b>Circuit Breaker manual</b>: Si el servicio de ratings no responde o da error,
     * se retorna un objeto {@link RatingStatsDTO} "vacío" (con ceros) generado por {@link #createFallbackStats},
     * garantizando que la UI pueda renderizarse aunque no muestre estrellas.
     * </p>
     *
     * @param entityType Tipo de entidad ("SONG", "ALBUM", "ARTIST").
     * @param entityId ID de la entidad.
     * @return DTO con las estadísticas reales o un objeto fallback con valores en cero.
     */
    public RatingStatsDTO getEntityRatingStats(String entityType, Long entityId) {
        String url = String.format(
            "%s/api/ratings/entity/%s/%d/stats",
            communityServiceUrl,
            entityType.toUpperCase(),
            entityId
        );

        try {
            log.info("Fetching rating stats for {} {} from URL: {}", entityType, entityId, url);
            RatingStatsDTO stats = restTemplate.getForObject(url, RatingStatsDTO.class);

            if (stats == null) {
                log.warn("Received null response from rating service for {} {}", entityType, entityId);
                return createFallbackStats(entityType, entityId);
            }

            log.info("Rating stats retrieved successfully: {} {} - avg: {}, total: {}",
                    entityType, entityId, stats.getAverageRating(), stats.getTotalRatings());
            return stats;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching rating stats for {} {}. Status: {}",
                    entityType, entityId, e.getStatusCode());
            return createFallbackStats(entityType, entityId);

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing rating service at {} for {} {}",
                    url, entityType, entityId);
            return createFallbackStats(entityType, entityId);

        } catch (Exception e) {
            log.error("Unexpected error fetching rating stats for {} {}", entityType, entityId, e);
            return createFallbackStats(entityType, entityId);
        }
    }

    /**
     * Método de conveniencia para obtener estadísticas de un artista.
     *
     * @param artistId ID del artista.
     * @return Estadísticas combinadas de las canciones del artista.
     */
    public RatingStatsDTO getArtistRatingStats(Long artistId) {
        return getEntityRatingStats("ARTIST", artistId);
    }

    /**
     * Crea un objeto de estadísticas por defecto (Fallback) con todos los contadores a cero.
     * <p>
     * Se utiliza cuando el servicio de ratings no está disponible para evitar excepciones nulas en el frontend.
     * </p>
     *
     * @param entityType Tipo de entidad solicitada.
     * @param entityId ID de la entidad solicitada.
     * @return DTO inicializado en cero.
     */
    private RatingStatsDTO createFallbackStats(String entityType, Long entityId) {
        return RatingStatsDTO.builder()
                .entityType(entityType.toUpperCase())
                .entityId(entityId)
                .averageRating(0.0)
                .totalRatings(0L)
                .fiveStars(0L)
                .fourStars(0L)
                .threeStars(0L)
                .twoStars(0L)
                .oneStar(0L)
                .build();
    }
}
