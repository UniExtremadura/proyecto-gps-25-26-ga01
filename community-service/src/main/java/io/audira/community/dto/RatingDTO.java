package io.audira.community.dto;

import io.audira.community.model.Rating;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.ZonedDateTime;

/**
 * Data Transfer Object (DTO) que representa una valoración (rating) o reseña en la respuesta de la API.
 * <p>
 * Este objeto se utiliza para transferir la información de una valoración, incluyendo la puntuación,
 * el comentario y los metadatos de usuario (nombre y foto de perfil) para visualización.
 * </p>
 *
 * @author Grupo GA01
 * @see Rating
 * 
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RatingDTO {

    /**
     * ID único de la valoración.
     */
    private Long id;

    /**
     * ID del usuario que creó la valoración.
     */
    private Long userId;

    /**
     * Tipo de la entidad valorada (ej. "ALBUM", "SONG").
     */
    private String entityType;

    /**
     * ID único de la entidad valorada en el catálogo.
     */
    private Long entityId;

    /**
     * Puntuación otorgada (generalmente de 1 a 5).
     */
    private Integer rating;

    /**
     * Comentario o reseña opcional del usuario.
     */
    private String comment;

    /**
     * Marca de tiempo de la fecha y hora de creación de la valoración. Se utiliza {@link ZonedDateTime} para incluir la zona horaria.
     */
    private ZonedDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización de la valoración.
     */
    private ZonedDateTime updatedAt;

    /**
     * Indica si la valoración está activa o visible ({@code true}) o si ha sido eliminada lógicamente ({@code false}).
     */
    private Boolean isActive;

    /**
     * Nombre de usuario o alias del creador de la valoración (información obtenida de otro servicio, opcional).
     */
    private String userName;

    /**
     * URL de la imagen de perfil del creador de la valoración (opcional).
     */
    private String userProfileImageUrl;

    /**
     * Constructor que inicializa el DTO a partir de una entidad {@link Rating} de base de datos.
     * <p>
     * Este constructor copia todos los campos base de la entidad.
     * </p>
     *
     * @param rating La entidad {@link Rating} de origen.
     */
    public RatingDTO(Rating rating) {
        this.id = rating.getId();
        this.userId = rating.getUserId();
        this.entityType = rating.getEntityType();
        this.entityId = rating.getEntityId();
        this.rating = rating.getRating();
        this.comment = rating.getComment();
        this.createdAt = rating.getCreatedAt();
        this.updatedAt = rating.getUpdatedAt();
        this.isActive = rating.getIsActive();
    }

    /**
     * Constructor completo que inicializa el DTO desde la entidad {@link Rating} y añade información auxiliar del usuario.
     *
     * @param rating La entidad {@link Rating} de origen.
     * @param userName Nombre de usuario a incluir en la respuesta.
     * @param userProfileImageUrl URL de la imagen de perfil del usuario a incluir.
     */
    public RatingDTO(Rating rating, String userName, String userProfileImageUrl) {
        this(rating);
        this.userName = userName;
        this.userProfileImageUrl = userProfileImageUrl;
    }
}