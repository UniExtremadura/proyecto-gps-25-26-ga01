package io.audira.catalog.dto;

import io.audira.catalog.model.Album;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Set;

/**
 * DTO completo que representa el estado detallado de un álbum.
 * <p>
 * A diferencia de {@link AlbumResponse}, este objeto incluye información enriquecida (como el nombre del artista)
 * y datos sensibles de administración (estado de moderación, razones de rechazo, auditoría).
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlbumDTO {

    /** ID único del álbum. */
    private Long id;

    /** Título del álbum. */
    private String title;

    /** ID del artista. */
    private Long artistId;

    /**
     * Nombre legible del artista.
     * <p>Este campo se hidrata consultando el <b>User Service</b>, ya que el modelo {@code Album} solo guarda el ID.</p>
     */
    private String artistName;

    /** Precio. */
    private BigDecimal price;

    /** URL de la imagen de portada. */
    private String coverImageUrl;

    /** Descripción. */
    private String description;

    /** Fecha de creación. */
    private LocalDateTime createdAt;

    /** Fecha de actualización. */
    private LocalDateTime updatedAt;

    /** Géneros asociados. */
    private Set<Long> genreIds;

    /** Fecha de lanzamiento. */
    private LocalDate releaseDate;

    /** Descuento. */
    private Double discountPercentage;

    /** Estado de publicación. */
    private boolean published;

    /**
     * Estado actual en el flujo de aprobación (ej: PENDING_REVIEW, APPROVED, REJECTED).
     */
    private String moderationStatus;

    /**
     * Motivo del rechazo, si aplica.
     * <p>Visible para el artista y los administradores.</p>
     */
    private String rejectionReason;

    /** ID del administrador que realizó la moderación. */
    private Long moderatedBy;

    /** Fecha y hora en la que se realizó la moderación. */
    private LocalDateTime moderatedAt;

    /**
     * Método estático para construir un DTO completo a partir de la entidad.
     * <p>
     * Mapea todos los campos de la base de datos y permite inyectar el nombre del artista
     * resuelto externamente.
     * </p>
     *
     * @param album La entidad {@link Album} persistida.
     * @param artistName El nombre del artista obtenido del servicio de usuarios.
     * @return Un objeto {@code AlbumDTO} enriquecido.
     */
    public static AlbumDTO fromAlbum(Album album, String artistName) {
        return AlbumDTO.builder()
                .id(album.getId())
                .title(album.getTitle())
                .artistId(album.getArtistId())
                .artistName(artistName)
                .price(album.getPrice())
                .coverImageUrl(album.getCoverImageUrl())
                .description(album.getDescription())
                .createdAt(album.getCreatedAt())
                .updatedAt(album.getUpdatedAt())
                .genreIds(album.getGenreIds())
                .releaseDate(album.getReleaseDate())
                .discountPercentage(album.getDiscountPercentage())
                .published(album.isPublished())
                .moderationStatus(album.getModerationStatus() != null ? album.getModerationStatus().name() : null)
                .rejectionReason(album.getRejectionReason())
                .moderatedBy(album.getModeratedBy())
                .moderatedAt(album.getModeratedAt())
                .build();
    }
}
