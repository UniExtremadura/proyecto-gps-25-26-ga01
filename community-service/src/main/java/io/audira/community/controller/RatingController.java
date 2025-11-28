package io.audira.community.controller;

import io.audira.community.dto.*;
import io.audira.community.exception.RatingException;
import io.audira.community.security.UserPrincipal;
import io.audira.community.service.RatingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.List;
import java.util.Map;

/**
 * Controlador REST que gestiona la creación, consulta, modificación y eliminación de valoraciones (ratings) de productos o entidades.
 * <p>
 * Los endpoints base se mapean a {@code /api/ratings}. Implementa los requisitos funcionales de puntuación (1-5 estrellas),
 * comentario opcional, y gestión por parte del usuario creador.
 * </p>
 * Requisitos asociados: GA01-128 (Puntuación), GA01-129 (Comentario), GA01-130 (Editar/Eliminar).
 *
 * @author Grupo GA01
 * @see RatingService
 * 
 */
@RestController
@RequestMapping("/api/ratings")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class RatingController {

    private final RatingService ratingService;

    // --- Métodos Transaccionales (Requieren Autenticación) ---

    /**
     * Crea una nueva valoración o actualiza una existente (si ya existe una valoración para el usuario/entidad).
     * <p>
     * Mapeo: {@code POST /api/ratings}
     * Requiere que el usuario esté autenticado.
     * </p>
     *
     * @param currentUser El principio de usuario autenticado (inyectado por Spring Security).
     * @param request La solicitud {@link CreateRatingRequest} validada, que contiene la puntuación y el comentario.
     * @return {@link ResponseEntity} con el {@link RatingDTO} creado/actualizado (201 CREATED) o un error 400 BAD REQUEST si falla la validación o reglas de negocio.
     */
    @PostMapping
    public ResponseEntity<?> createRating(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @Valid @RequestBody CreateRatingRequest request) {
        try {
            RatingDTO rating = ratingService.createOrUpdateRating(currentUser.getId(), request);
            // Establecer timestamps después de la creación para reflejar el momento de la API
            rating.setCreatedAt(ZonedDateTime.now(ZoneId.of("Europe/Madrid")));
            rating.setUpdatedAt(ZonedDateTime.now(ZoneId.of("Europe/Madrid")));
            return ResponseEntity.status(HttpStatus.CREATED).body(rating);
        } catch (RatingException e) {
            log.error("Error creating rating: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error creating rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Internal server error"));
        }
    }

    /**
     * Actualiza completamente los datos de una valoración existente, verificando que pertenezca al usuario autenticado.
     * <p>
     * Mapeo: {@code PUT /api/ratings/{ratingId}}
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @param ratingId ID de la valoración (tipo {@link Long}) a actualizar.
     * @param request La solicitud {@link UpdateRatingRequest} validada con los nuevos detalles.
     * @return {@link ResponseEntity} con el {@link RatingDTO} actualizado (200 OK) o 403 FORBIDDEN si el usuario no es el dueño.
     */
    @PutMapping("/{ratingId}")
    public ResponseEntity<?> updateRating(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable Long ratingId,
            @Valid @RequestBody UpdateRatingRequest request) {
        try {
            RatingDTO rating = ratingService.updateRating(ratingId, currentUser.getId(), request);
            rating.setUpdatedAt(ZonedDateTime.now(ZoneId.of("Europe/Madrid")));
            return ResponseEntity.ok(rating);
        } catch (RatingException.RatingNotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (RatingException.UnauthorizedRatingAccessException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", e.getMessage()));
        } catch (RatingException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error updating rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Internal server error"));
        }
    }

    /**
     * Elimina una valoración existente, verificando que pertenezca al usuario autenticado.
     * <p>
     * Mapeo: {@code DELETE /api/ratings/{ratingId}}
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @param ratingId ID de la valoración (tipo {@link Long}) a eliminar.
     * @return {@link ResponseEntity} con estado 204 (NO CONTENT) si la eliminación es exitosa, 404 NOT FOUND o 403 FORBIDDEN.
     */
    @DeleteMapping("/{ratingId}")
    public ResponseEntity<?> deleteRating(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable Long ratingId) {
        try {
            ratingService.deleteRating(ratingId, currentUser.getId());
            return ResponseEntity.noContent().build();
        } catch (RatingException.RatingNotFoundException e) {
            return ResponseEntity.notFound().build();
        } catch (RatingException.UnauthorizedRatingAccessException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Unexpected error deleting rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Internal server error"));
        }
    }

    // --- Métodos de Consulta Pública y de Usuario ---

    /**
     * Obtiene todas las valoraciones hechas por un usuario específico (público).
     * <p>
     * Mapeo: {@code GET /api/ratings/user/{userId}}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) cuyas valoraciones se desean obtener.
     * @return {@link ResponseEntity} con una {@link List} de {@link RatingDTO}.
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<RatingDTO>> getUserRatings(@PathVariable Long userId) {
        try {
            List<RatingDTO> ratings = ratingService.getUserRatings(userId);
            return ResponseEntity.ok(ratings);
        } catch (Exception e) {
            log.error("Error getting user ratings", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtiene todas las valoraciones hechas por el usuario actualmente autenticado.
     * <p>
     * Mapeo: {@code GET /api/ratings/my-ratings}
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @return {@link ResponseEntity} con una {@link List} de {@link RatingDTO} del usuario actual.
     */
    @GetMapping("/my-ratings")
    public ResponseEntity<List<RatingDTO>> getMyRatings(
            @AuthenticationPrincipal UserPrincipal currentUser) {
        try {
            List<RatingDTO> ratings = ratingService.getUserRatings(currentUser.getId());
            return ResponseEntity.ok(ratings);
        } catch (Exception e) {
            log.error("Error getting my ratings", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtiene todas las valoraciones asociadas a una entidad específica (ej. un álbum, una canción).
     * <p>
     * Mapeo: {@code GET /api/ratings/entity/{entityType}/{entityId}}
     * </p>
     *
     * @param entityType Tipo de la entidad (String).
     * @param entityId ID de la entidad (tipo {@link Long}).
     * @return {@link ResponseEntity} con una {@link List} de {@link RatingDTO}.
     */
    @GetMapping("/entity/{entityType}/{entityId}")
    public ResponseEntity<List<RatingDTO>> getEntityRatings(
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            List<RatingDTO> ratings = ratingService.getEntityRatings(entityType, entityId);
            return ResponseEntity.ok(ratings);
        } catch (Exception e) {
            log.error("Error getting entity ratings", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtiene todas las valoraciones de una entidad específica que incluyen un comentario (filtrado de reseñas).
     * <p>
     * Mapeo: {@code GET /api/ratings/entity/{entityType}/{entityId}/with-comments}
     * </p>
     *
     * @param entityType Tipo de la entidad.
     * @param entityId ID de la entidad.
     * @return {@link ResponseEntity} con una {@link List} de {@link RatingDTO} que tienen comentarios.
     */
    @GetMapping("/entity/{entityType}/{entityId}/with-comments")
    public ResponseEntity<List<RatingDTO>> getEntityRatingsWithComments(
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            List<RatingDTO> ratings = ratingService.getEntityRatingsWithComments(entityType, entityId);
            return ResponseEntity.ok(ratings);
        } catch (Exception e) {
            log.error("Error getting entity ratings with comments", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtiene las estadísticas resumidas de las valoraciones para una entidad (puntuación media, conteo por estrella).
     * <p>
     * Mapeo: {@code GET /api/ratings/entity/{entityType}/{entityId}/stats}
     * </p>
     *
     * @param entityType Tipo de la entidad.
     * @param entityId ID de la entidad.
     * @return {@link ResponseEntity} con el objeto {@link RatingStatsDTO}.
     */
    @GetMapping("/entity/{entityType}/{entityId}/stats")
    public ResponseEntity<RatingStatsDTO> getEntityRatingStats(
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            RatingStatsDTO stats = ratingService.getEntityRatingStats(entityType, entityId);
            return ResponseEntity.ok(stats);
        } catch (Exception e) {
            log.error("Error getting rating stats", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtiene la valoración específica de un usuario para una entidad determinada.
     * <p>
     * Mapeo: {@code GET /api/ratings/user/{userId}/entity/{entityType}/{entityId}}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) que hizo la valoración.
     * @param entityType Tipo de la entidad.
     * @param entityId ID de la entidad.
     * @return {@link ResponseEntity} con el {@link RatingDTO} o 404 NOT FOUND si el usuario no ha valorado la entidad.
     */
    @GetMapping("/user/{userId}/entity/{entityType}/{entityId}")
    public ResponseEntity<RatingDTO> getUserEntityRating(
            @PathVariable Long userId,
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            RatingDTO rating = ratingService.getUserEntityRating(userId, entityType, entityId);
            if (rating == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(rating);
        } catch (Exception e) {
            log.error("Error getting user entity rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Obtiene la valoración específica del usuario actualmente autenticado para una entidad determinada.
     * <p>
     * Mapeo: {@code GET /api/ratings/my-rating/entity/{entityType}/{entityId}}
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @param entityType Tipo de la entidad.
     * @param entityId ID de la entidad.
     * @return {@link ResponseEntity} con el {@link RatingDTO} o 404 NOT FOUND si el usuario actual no ha valorado la entidad.
     */
    @GetMapping("/my-rating/entity/{entityType}/{entityId}")
    public ResponseEntity<RatingDTO> getMyEntityRating(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            RatingDTO rating = ratingService.getUserEntityRating(currentUser.getId(), entityType, entityId);
            if (rating == null) {
                return ResponseEntity.notFound().build();
            }
            return ResponseEntity.ok(rating);
        } catch (Exception e) {
            log.error("Error getting my entity rating", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Verifica si el usuario autenticado ha proporcionado una valoración para una entidad específica.
     * <p>
     * Mapeo: {@code GET /api/ratings/has-rated/entity/{entityType}/{entityId}}
     * </p>
     *
     * @param currentUser El principio de usuario autenticado.
     * @param entityType Tipo de la entidad.
     * @param entityId ID de la entidad.
     * @return {@link ResponseEntity} con un mapa que contiene {@code "hasRated": true|false}.
     */
    @GetMapping("/has-rated/entity/{entityType}/{entityId}")
    public ResponseEntity<Map<String, Boolean>> hasRatedEntity(
            @AuthenticationPrincipal UserPrincipal currentUser,
            @PathVariable String entityType,
            @PathVariable Long entityId) {
        try {
            boolean hasRated = ratingService.hasUserRatedEntity(currentUser.getId(), entityType, entityId);
            return ResponseEntity.ok(Map.of("hasRated", hasRated));
        } catch (Exception e) {
            log.error("Error checking if user has rated entity", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}