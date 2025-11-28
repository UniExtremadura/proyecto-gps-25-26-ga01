package io.audira.catalog.dto;

import io.audira.catalog.model.Song;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Set;

/**
 * DTO completo que representa el estado detallado de una canción (Track).
 * <p>
 * Incluye metadatos técnicos, información comercial, estado de moderación y
 * datos enriquecidos externamente (como el nombre del artista).
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SongDTO {
    // --- Identificación ---
    /** ID único de la canción. */
    private Long id;

    /** Título de la obra. */
    private String title;

    /** ID del artista principal (Propietario). */
    private Long artistId;

    /**
     * Nombre del artista principal.
     * <p>Dato inyectado desde el {@code User Service}, no almacenado en la tabla de canciones.</p>
     */
    private String artistName;

    // --- Metadatos Comerciales y Visuales ---
    /** Precio de venta individual. */
    private BigDecimal price;

    /** URL de la imagen de portada (Cover Art). */
    private String coverImageUrl;

    /** Descripción o notas de producción. */
    private String description;

    // --- Auditoría ---
    /** Fecha de subida. */
    private LocalDateTime createdAt;

    /** Fecha de última modificación. */
    private LocalDateTime updatedAt;

    // --- Relaciones y Clasificación ---
    /** ID del álbum al que pertenece (puede ser nulo si es un Single). */
    private Long albumId;

    /** Conjunto de géneros musicales asociados. */
    private Set<Long> genreIds;

    /** Categoría del contenido (ej: MUSIC, PODCAST). */
    private String category;

    // --- Metadatos Técnicos (File Service) ---
    /** Duración en segundos. */
    private Integer duration;

    /** URL pública para el streaming del archivo de audio. */
    private String audioUrl;

    /** Letra de la canción. */
    private String lyrics;

    /** Número de pista dentro del álbum. */
    private Integer trackNumber;

    // --- Estadísticas y Estado ---
    /** Contador histórico de reproducciones. */
    private Long plays;

    /** Indica si la canción es visible para el público. */
    private boolean published;

    // --- Moderación (Admin) ---
    /** Estado actual de revisión (PENDING, APPROVED, REJECTED). */
    private String moderationStatus;

    /** Motivo del rechazo (si aplica). */
    private String rejectionReason;

    /** ID del administrador que moderó la canción. */
    private Long moderatedBy;

    /** Fecha de la moderación. */
    private LocalDateTime moderatedAt;

    /**
     * Método de fábrica para convertir una entidad {@link Song} en un DTO enriquecido.
     * <p>
     * Permite desacoplar el modelo de persistencia de la vista API, inyectando
     * dependencias externas como el {@code artistName}.
     * </p>
     *
     * @param song La entidad persistida.
     * @param artistName El nombre del artista resuelto.
     * @return DTO listo para ser enviado al cliente.
     */
    public static SongDTO fromSong(Song song, String artistName) {
        return SongDTO.builder()
                .id(song.getId())
                .title(song.getTitle())
                .artistId(song.getArtistId())
                .artistName(artistName)
                .price(song.getPrice())
                .coverImageUrl(song.getCoverImageUrl())
                .description(song.getDescription())
                .createdAt(song.getCreatedAt())
                .updatedAt(song.getUpdatedAt())
                .albumId(song.getAlbumId())
                .genreIds(song.getGenreIds())
                .duration(song.getDuration())
                .audioUrl(song.getAudioUrl())
                .lyrics(song.getLyrics())
                .trackNumber(song.getTrackNumber())
                .plays(song.getPlays())
                .category(song.getCategory())
                .published(song.isPublished())
                .moderationStatus(song.getModerationStatus() != null ? song.getModerationStatus().name() : null)
                .rejectionReason(song.getRejectionReason())
                .moderatedBy(song.getModeratedBy())
                .moderatedAt(song.getModeratedAt())
                .build();
    }
}
