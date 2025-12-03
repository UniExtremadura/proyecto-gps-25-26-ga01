package io.audira.community.service;

import io.audira.community.client.CommerceClient;
import io.audira.community.dto.*;
import io.audira.community.exception.RatingException;
import io.audira.community.model.Rating;
import io.audira.community.repository.RatingRepository;
import io.audira.community.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.ZonedDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Servicio principal para la gestión completa de **Valoraciones (Ratings)**.
 * <p>
 * Este servicio implementa la lógica de negocio, incluyendo validaciones (ej. rango de estrellas,
 * longitud del comentario, requisitos de compra), la creación, actualización y eliminación
 * (soft delete) de valoraciones, así como la recuperación de estadísticas y listas.
 * </p>
 * Requisitos asociados:
 * <ul>
 * <li>GA01-128: Puntuación de 1-5 estrellas</li>
 * <li>GA01-129: Comentario opcional (máx. 500 caracteres)</li>
 * <li>GA01-130: Edición/eliminación de valoración (Soft Delete)</li>
 * </ul>
 *
 * @author Grupo GA01
 * @see Rating
 * @see RatingRepository
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class RatingService {

    private final RatingRepository ratingRepository;
    private final UserRepository userRepository;
    private final CommerceClient commerceClient;

    // --- Métodos de CRUD y Lógica de Negocio ---

    /**
     * Crea una nueva valoración o actualiza una existente si el usuario ya ha valorado la entidad.
     * <p>
     * Aplica las siguientes reglas de negocio:
     * <ul>
     * <li>Valida que la puntuación esté entre 1 y 5 estrellas (GA01-128).</li>
     * <li>Valida que el comentario no exceda los 500 caracteres (GA01-129).</li>
     * <li>Para entidades de tipo {@code SONG} o {@code ALBUM}, verifica que el usuario haya comprado
     * el artículo a través del {@link CommerceClient}.</li>
     * </ul>
     * </p>
     *
     * @param userId El ID del usuario que realiza la valoración.
     * @param request El DTO que contiene los datos de la valoración.
     * @return El objeto {@link RatingDTO} de la valoración creada o actualizada.
     * @throws RatingException.InvalidRatingValueException Si la puntuación no está entre 1 y 5.
     * @throws RatingException.InvalidCommentLengthException Si el comentario excede los 500 caracteres.
     * @throws RatingException.ProductNotPurchasedException Si el usuario intenta valorar un producto no comprado (solo para SONG/ALBUM).
     */
    @Transactional
    public RatingDTO createOrUpdateRating(Long userId, CreateRatingRequest request) {
        log.info("Creating/updating rating for user {} on {} {}", userId, request.getEntityType(), request.getEntityId());

        // Validaciones
        validateRatingValue(request.getRating());
        validateComment(request.getComment());

        // Buscar si ya existe una valoración
        Rating rating = ratingRepository
                .findByUserIdAndEntityTypeAndEntityId(userId, request.getEntityType(), request.getEntityId())
                .orElse(null);

        // Si es una nueva valoración (no actualización), verificar que haya comprado el producto
        if (rating == null) {
            String entityType = request.getEntityType().toUpperCase();

            // Solo verificar compra para SONG y ALBUM
            if ("SONG".equals(entityType) || "ALBUM".equals(entityType)) {
                boolean hasPurchased = commerceClient.hasPurchasedItem(
                    userId,
                    entityType,
                    request.getEntityId()
                );

                if (!hasPurchased) {
                    log.warn("User {} attempted to rate {} {} without purchasing it",
                        userId, entityType, request.getEntityId());
                    throw new RatingException.ProductNotPurchasedException(entityType, request.getEntityId());
                }

                log.info("User {} has purchased {} {} - allowing rating",
                    userId, entityType, request.getEntityId());
            }
        }

        ZonedDateTime now = ZonedDateTime.now().truncatedTo(ChronoUnit.SECONDS);

        if (rating != null) {
            // Actualizar valoración existente
            log.info("Updating existing rating {} for user {}", rating.getId(), userId);

            // Si la valoración estaba inactiva (eliminada previamente con soft delete), restablecer la fecha de creación
            if (Boolean.FALSE.equals(rating.getIsActive())) {
                rating.setCreatedAt(now);
            }

            rating.setRating(request.getRating());
            rating.setComment(request.getComment());
            rating.setIsActive(true);
            rating.setUpdatedAt(now);

        } else {
            // Crear nueva valoración
            rating = new Rating();
            rating.setUserId(userId);
            rating.setEntityType(request.getEntityType().toUpperCase());
            rating.setEntityId(request.getEntityId());
            rating.setRating(request.getRating());
            rating.setComment(request.getComment());
            rating.setIsActive(true);
            rating.setCreatedAt(now);
            rating.setUpdatedAt(null); // Se establece a null o la misma fecha en la entidad, dependiendo de la configuración
        }

        Rating savedRating = ratingRepository.save(rating);
        log.info("Rating saved successfully: {}", savedRating.getId());

        return convertToDTO(savedRating);
    }

    /**
     * Actualiza la puntuación y/o el comentario de una valoración existente (GA01-130).
     * <p>
     * Requiere que el ID de usuario proporcionado sea el propietario de la valoración.
     * </p>
     *
     * @param ratingId El ID de la valoración a modificar.
     * @param userId El ID del usuario que intenta modificar la valoración (para validación de propiedad).
     * @param request El DTO con los campos a actualizar.
     * @return El objeto {@link RatingDTO} de la valoración actualizada.
     * @throws RatingException.RatingNotFoundException Si la valoración no existe o no pertenece al usuario.
     * @throws RatingException.UnauthorizedRatingAccessException Si el {@code userId} no es el propietario.
     */
    @Transactional
    public RatingDTO updateRating(Long ratingId, Long userId, UpdateRatingRequest request) {
        log.info("Updating rating {} by user {}", ratingId, userId);

        Rating rating = ratingRepository.findByIdAndUserId(ratingId, userId)
                .orElseThrow(() -> new RatingException.RatingNotFoundException(ratingId));

        // Validar ownership (aunque findByIdAndUserId ya lo hace, se mantiene por seguridad explícita)
        if (!rating.getUserId().equals(userId)) {
            throw new RatingException.UnauthorizedRatingAccessException();
        }

        // Actualizar campos si están presentes
        if (request.getRating() != null) {
            validateRatingValue(request.getRating());
            rating.setRating(request.getRating());
        }

        if (request.getComment() != null) {
            validateComment(request.getComment());
            rating.setComment(request.getComment());
        }

        // Actualizar la marca de tiempo de modificación si se cambió algún campo
        if (request.getRating() != null || request.getComment() != null) {
            ZonedDateTime now = ZonedDateTime.now().truncatedTo(ChronoUnit.SECONDS);
            rating.setUpdatedAt(now);
        }

        Rating updatedRating = ratingRepository.save(rating);
        log.info("Rating {} updated successfully", ratingId);

        return convertToDTO(updatedRating);
    }

    /**
     * Marca una valoración como inactiva (soft delete) (GA01-130).
     * <p>
     * Requiere que el ID de usuario proporcionado sea el propietario de la valoración.
     * </p>
     *
     * @param ratingId El ID de la valoración a eliminar.
     * @param userId El ID del usuario que intenta eliminar la valoración (para validación de propiedad).
     * @throws RatingException.RatingNotFoundException Si la valoración no existe o no pertenece al usuario.
     * @throws RatingException.UnauthorizedRatingAccessException Si el {@code userId} no es el propietario.
     */
    @Transactional
    public void deleteRating(Long ratingId, Long userId) {
        log.info("Deleting rating {} by user {}", ratingId, userId);

        Rating rating = ratingRepository.findByIdAndUserId(ratingId, userId)
                .orElseThrow(() -> new RatingException.RatingNotFoundException(ratingId));

        // Validar ownership
        if (!rating.getUserId().equals(userId)) {
            throw new RatingException.UnauthorizedRatingAccessException();
        }

        // Soft delete: marcar como inactiva
        rating.setIsActive(false);
        ratingRepository.save(rating);

        log.info("Rating {} deleted successfully", ratingId);
    }

    // --- Métodos de Consulta y Estadísticas ---

    /**
     * Obtiene todas las valoraciones activas de un usuario.
     *
     * @param userId El ID del usuario.
     * @return Una lista de objetos {@link RatingDTO}.
     */
    @Transactional(readOnly = true)
    public List<RatingDTO> getUserRatings(Long userId) {
        log.info("Getting ratings for user {}", userId);
        List<Rating> ratings = ratingRepository.findByUserIdAndIsActiveTrue(userId);
        return ratings.stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene todas las valoraciones activas de una entidad específica, ordenadas por fecha de creación descendente.
     *
     * @param entityType El tipo de entidad (ej. "SONG", "ALBUM").
     * @param entityId El ID de la entidad.
     * @return Una lista de objetos {@link RatingDTO} que incluyen información básica del usuario que valoró.
     */
    @Transactional(readOnly = true)
    public List<RatingDTO> getEntityRatings(String entityType, Long entityId) {
        log.info("Getting ratings for {} {}", entityType, entityId);
        List<Rating> ratings = ratingRepository
                .findByEntityTypeAndEntityIdAndIsActiveTrueOrderByCreatedAtDesc(
                        entityType.toUpperCase(), entityId);

        return ratings.stream()
                .map(this::convertToDTOWithUserInfo)
                .collect(Collectors.toList());
    }

    /**
     * Obtiene solo las valoraciones activas de una entidad que contienen un comentario, ordenadas por fecha descendente.
     *
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return Una lista de objetos {@link RatingDTO} que incluyen información básica del usuario que valoró.
     */
    @Transactional(readOnly = true)
    public List<RatingDTO> getEntityRatingsWithComments(String entityType, Long entityId) {
        log.info("Getting ratings with comments for {} {}", entityType, entityId);
        List<Rating> ratings = ratingRepository.findRatingsWithComments(
                entityType.toUpperCase(), entityId);

        return ratings.stream()
                .map(this::convertToDTOWithUserInfo)
                .collect(Collectors.toList());
    }

    /**
     * Calcula y retorna las estadísticas resumidas de valoración para una entidad.
     * <p>
     * Esto incluye el promedio de la puntuación total, el número total de valoraciones
     * y la distribución de estrellas (1 a 5).
     * </p>
     *
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return El objeto {@link RatingStatsDTO} con las estadísticas calculadas.
     */
    @Transactional(readOnly = true)
    public RatingStatsDTO getEntityRatingStats(String entityType, Long entityId) {
        log.info("Getting rating stats for {} {}", entityType, entityId);

        String entityTypeUpper = entityType.toUpperCase();
        Double average = ratingRepository.calculateAverageRating(entityTypeUpper, entityId);
        Long total = ratingRepository.countByEntityTypeAndEntityIdAndIsActiveTrue(entityTypeUpper, entityId);

        RatingStatsDTO stats = new RatingStatsDTO(entityTypeUpper, entityId, average, total);

        // Obtener distribución de estrellas
        stats.setFiveStars(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 5));
        stats.setFourStars(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 4));
        stats.setThreeStars(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 3));
        stats.setTwoStars(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 2));
        stats.setOneStar(ratingRepository.countByRatingStars(entityTypeUpper, entityId, 1));

        return stats;
    }

    /**
     * Obtiene la valoración activa de un usuario para una entidad específica, si existe.
     *
     * @param userId El ID del usuario.
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return El objeto {@link RatingDTO} de la valoración activa, o {@code null} si no existe o está inactiva.
     */
    @Transactional(readOnly = true)
    public RatingDTO getUserEntityRating(Long userId, String entityType, Long entityId) {
        log.info("Getting rating for user {} on {} {}", userId, entityType, entityId);

        return ratingRepository
                .findByUserIdAndEntityTypeAndEntityId(userId, entityType.toUpperCase(), entityId)
                .filter(Rating::getIsActive)
                .map(this::convertToDTO)
                .orElse(null);
    }

    /**
     * Verifica si un usuario ya ha realizado una valoración activa para una entidad específica.
     *
     * @param userId El ID del usuario.
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return {@code true} si existe una valoración activa, {@code false} en caso contrario.
     */
    @Transactional(readOnly = true)
    public boolean hasUserRatedEntity(Long userId, String entityType, Long entityId) {
        return ratingRepository.existsByUserIdAndEntityTypeAndEntityIdAndIsActiveTrue(
                userId, entityType.toUpperCase(), entityId);
    }

    // --- Métodos privados de validación y conversión ---

    /**
     * Valida que la puntuación de la valoración esté en el rango permitido (1 a 5).
     *
     * @param rating La puntuación.
     * @throws RatingException.InvalidRatingValueException Si la puntuación no es válida.
     */
    private void validateRatingValue(Integer rating) {
        if (rating == null || rating < 1 || rating > 5) {
            throw new RatingException.InvalidRatingValueException();
        }
    }

    /**
     * Valida que el comentario de la valoración no exceda la longitud máxima (500 caracteres).
     *
     * @param comment El comentario.
     * @throws RatingException.InvalidCommentLengthException Si la longitud es excesiva.
     */
    private void validateComment(String comment) {
        if (comment != null && comment.length() > 500) {
            throw new RatingException.InvalidCommentLengthException();
        }
    }

    /**
     * Convierte la entidad {@link Rating} a su DTO correspondiente.
     *
     * @param rating La entidad de valoración.
     * @return El {@link RatingDTO} simple.
     */
    private RatingDTO convertToDTO(Rating rating) {
        return new RatingDTO(rating);
    }

    /**
     * Convierte la entidad {@link Rating} a su DTO e inyecta la información básica del usuario.
     * <p>
     * Esto se utiliza para mostrar valoraciones en listas públicas.
     * </p>
     *
     * @param rating La entidad de valoración.
     * @return El {@link RatingDTO} con información del usuario (nombre de usuario e imagen de perfil).
     */
    private RatingDTO convertToDTOWithUserInfo(Rating rating) {
        RatingDTO dto = new RatingDTO(rating);

        // Obtener información del usuario
        userRepository.findById(rating.getUserId()).ifPresent(user -> {
            dto.setUserName(user.getUsername());
            dto.setUserProfileImageUrl(user.getProfileImageUrl());
        });

        return dto;
    }
}