package io.audira.catalog.client;

import io.audira.catalog.dto.UserDTO;
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

/**
 * Cliente REST para la comunicación con el Servicio de Usuarios (Community/User Service).
 * <p>
 * Permite hidratar los objetos del catálogo con información personal del usuario
 * (nombre, avatar) y gestionar relaciones sociales (seguidores).
 * </p>
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class UserServiceClient {

    private final RestTemplate restTemplate;

    @Value("${services.user.url:http://172.16.0.4:8080/api/users}")
    private String userServiceUrl;

    /**
     * Obtiene la información pública de un usuario o artista por su ID.
     *
     * @param userId ID del usuario.
     * @return DTO con la información del usuario, o un usuario "dummy" (Fallback) si falla la petición.
     */
    public UserDTO getUserById(Long userId) {
        String url = userServiceUrl + "/" + userId;

        try {
            log.debug("Fetching user information for userId: {} from URL: {}", userId, url);
            UserDTO user = restTemplate.getForObject(url, UserDTO.class);

            if (user == null) {
                log.warn("Received null response from user service for userId: {}", userId);
                return createFallbackUser(userId);
            }

            log.debug("User information retrieved successfully: id={}, username={}",
                    user.getId(), user.getUsername());
            return user;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching user for userId: {}. Status: {}",
                    userId, e.getStatusCode());
            return createFallbackUser(userId);

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing user service at {} for userId: {}",
                    url, userId);
            return createFallbackUser(userId);

        } catch (Exception e) {
            log.error("Unexpected error fetching user for userId: {}", userId, e);
            return createFallbackUser(userId);
        }
    }

    /**
     * Obtiene la lista de IDs de los usuarios que siguen a un artista.
     *
     * @param artistId ID del artista.
     * @return Lista de IDs de seguidores, o lista vacía si hay error.
     */
    public List<Long> getFollowedArtistIds(Long userId) {
        String url = userServiceUrl + "/" + userId + "/following/artists";

        try {
            log.debug("Fetching followed artists for userId: {} from URL: {}", userId, url);

            ResponseEntity<List<Long>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Long>>() {}
            );

            List<Long> artistIds = response.getBody();
            if (artistIds == null) {
                log.warn("Received null response for followed artists for userId: {}", userId);
                return new ArrayList<>();
            }

            log.debug("Followed artists retrieved successfully for userId: {}, count: {}",
                    userId, artistIds.size());
            return artistIds;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching followed artists for userId: {}. Status: {}",
                    userId, e.getStatusCode());
            return new ArrayList<>();

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing user service at {} for userId: {}",
                    url, userId);
            return new ArrayList<>();

        } catch (Exception e) {
            log.error("Unexpected error fetching followed artists for userId: {}", userId, e);
            return new ArrayList<>();
        }
    }

    /**
     * Obtiene la lista de identificadores (IDs) de los seguidores de un usuario.
     * <p>
     * Este método consulta al Servicio de Usuarios (Community Service) para recuperar
     * las relaciones sociales. Es fundamental para funcionalidades de difusión masiva,
     * como notificar nuevos lanzamientos a toda la base de fans.
     * </p>
     * <p>
     * Implementa tolerancia a fallos: si el servicio de usuarios no responde, retorna
     * una lista vacía para evitar que el proceso de notificación rompa el flujo principal.
     * </p>
     *
     * @param userId El ID del usuario (generalmente un artista) del cual se buscan los seguidores.
     * @return Una lista de {@link Long} conteniendo los IDs de los seguidores. Retorna lista vacía si hay error.
     */
    public List<Long> getFollowerIds(Long artistId) {
        String url = userServiceUrl + "/" + artistId + "/followers";

        try {
            log.debug("Fetching followers for artistId: {} from URL: {}", artistId, url);

            ResponseEntity<List<Long>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Long>>() {}
            );

            List<Long> followerIds = response.getBody();
            if (followerIds == null) {
                log.warn("Received null response for followers of artistId: {}", artistId);
                return new ArrayList<>();
            }

            log.debug("Followers retrieved successfully for artistId: {}, count: {}",
                    artistId, followerIds.size());
            return followerIds;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching followers for artistId: {}. Status: {}",
                    artistId, e.getStatusCode());
            return new ArrayList<>();

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing user service at {} for artistId: {}",
                    url, artistId);
            return new ArrayList<>();

        } catch (Exception e) {
            log.error("Unexpected error fetching followers for artistId: {}", artistId, e);
            return new ArrayList<>();
        }
    }

    /**
     * Crea un usuario temporal de respaldo (Fallback User).
     * <p>
     * Se utiliza cuando el servicio de usuarios no responde, permitiendo que la aplicación
     * muestre al menos el ID o un nombre genérico en lugar de fallar.
     * </p>
     *
     * @param userId ID del usuario solicitado.
     * @return UserDTO con datos genéricos ("User #123").
     */
    private UserDTO createFallbackUser(Long userId) {
        return UserDTO.builder()
                .id(userId)
                .username("User #" + userId)
                .artistName("Artist #" + userId)
                .build();
    }
}
