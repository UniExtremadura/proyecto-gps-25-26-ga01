package io.audira.catalog.dto;

import io.audira.catalog.model.FeaturedContent;
import io.audira.catalog.model.FeaturedContent.ContentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO de respuesta (Response) que representa un elemento destacado en la UI.
 * <p>
 * Incluye información desnormalizada de la entidad referenciada (título, imagen, artista)
 * para que el cliente (Web/Móvil) pueda renderizar la tarjeta o banner sin necesidad
 * de realizar peticiones adicionales a los endpoints de detalles.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeaturedContentResponse {

    /** ID único del registro de destacado. */
    private Long id;

    /** Tipo de contenido (SONG, ALBUM, etc.). */
    private ContentType contentType;

    /** ID de la entidad original. */
    private Long contentId;

    /** Orden de visualización en la lista. */
    private Integer displayOrder;

    /** Fecha de inicio de la promoción. */
    private LocalDateTime startDate;

    /** Fecha de fin de la promoción. */
    private LocalDateTime endDate;

    /** Indica si el destacado está activo manualmente. */
    private Boolean isActive;

    /**
     * Título del contenido (Copia del título de la Canción/Álbum).
     * <p>Campo de solo lectura para la vista.</p>
     */
    private String contentTitle;

    /**
     * URL de la imagen de portada o avatar.
     * <p>Campo de solo lectura para la vista.</p>
     */
    private String contentImageUrl;

    /**
     * Nombre del artista principal (si aplica).
     * <p>Campo de solo lectura para la vista.</p>
     */
    private String contentArtist;

    /** Fecha de creación del registro. */
    private LocalDateTime createdAt;

    /** Fecha de última modificación. */
    private LocalDateTime updatedAt;

    /**
     * Método de fábrica (Factory Method) para convertir la entidad de base de datos en este DTO.
     * <p>
     * Mapea los campos directos de la entidad {@link FeaturedContent} a la respuesta.
     * </p>
     *
     * @param entity La entidad persistida en base de datos.
     * @return Una nueva instancia de {@code FeaturedContentResponse}.
     */
    public static FeaturedContentResponse fromEntity(FeaturedContent entity) {
        return FeaturedContentResponse.builder()
                .id(entity.getId())
                .contentType(entity.getContentType())
                .contentId(entity.getContentId())
                .displayOrder(entity.getDisplayOrder())
                .startDate(entity.getStartDate())
                .endDate(entity.getEndDate())
                .isActive(entity.getIsActive())
                .contentTitle(entity.getContentTitle())
                .contentImageUrl(entity.getContentImageUrl())
                .contentArtist(entity.getContentArtist())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }
}
