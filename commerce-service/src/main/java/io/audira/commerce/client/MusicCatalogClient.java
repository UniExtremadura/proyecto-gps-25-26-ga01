package io.audira.commerce.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * Cliente para comunicarse con el servicio de catálogo de música
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class MusicCatalogClient {

    private final RestTemplate restTemplate;

    @Value("${services.catalog.url:http://172.16.0.4:9002/api}")
    private String catalogServiceUrl;

    /**
     * Obtiene los IDs de todas las canciones de un álbum
     * @param albumId ID del álbum
     * @return Lista de IDs de canciones
     */
    public List<Long> getSongIdsByAlbum(Long albumId) {
        String url = catalogServiceUrl + "/songs/album/" + albumId;

        try {
            log.debug("Fetching songs for album {} from URL: {}", albumId, url);

            ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Map<String, Object>>>() {}
            );

            List<Map<String, Object>> songs = response.getBody();
            if (songs == null) {
                log.warn("Received null response for songs of album: {}", albumId);
                return new ArrayList<>();
            }

            List<Long> songIds = new ArrayList<>();
            for (Map<String, Object> song : songs) {
                Object idObj = song.get("id");
                if (idObj != null) {
                    songIds.add(((Number) idObj).longValue());
                }
            }

            log.debug("Retrieved {} songs for album {}", songIds.size(), albumId);
            return songIds;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching songs for album: {}. Status: {}", albumId, e.getStatusCode());
            return new ArrayList<>();

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing catalog service at {} for album: {}", url, albumId);
            return new ArrayList<>();

        } catch (Exception e) {
            log.error("Unexpected error fetching songs for album: {} from URL: {}", albumId, url, e);
            return new ArrayList<>();
        }
    }
}
