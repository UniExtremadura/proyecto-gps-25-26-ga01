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
 * DTO de respuesta (Response) optimizado para clientes públicos.
 * <p>
 * Proporciona una vista simplificada de la entidad {@link Album}, ocultando campos administrativos
 * sensibles y agregando datos calculados útiles para la UI, como el conteo de canciones.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlbumResponse {

    /** Identificador único del álbum. */
    private Long id;

    /** Título del álbum. */
    private String title;

    /** ID del artista propietario. */
    private Long artistId;

    /** Descripción del álbum. */
    private String description;

    /** Precio de venta. */
    private BigDecimal price;

    /** URL de la carátula. */
    private String coverImageUrl;

    /** IDs de los géneros asociados. */
    private Set<Long> genreIds;

    /** Fecha de lanzamiento. */
    private LocalDate releaseDate;

    /** Descuento aplicado. */
    private Double discountPercentage;

    /** Fecha de creación del registro en base de datos. */
    private LocalDateTime createdAt;

    /** Fecha de la última modificación. */
    private LocalDateTime updatedAt;

    /** Indica si el álbum es visible públicamente. */
    private boolean published;

    /**
     * Número total de canciones contenidas en el álbum.
     * <p>Este es un campo calculado que evita enviar la lista completa de objetos canción cuando no es necesaria.</p>
     */
    private int songCount;

    /**
     * Método de fábrica (Factory Method) para convertir una entidad en una respuesta.
     * <p>
     * Facilita la transformación de datos dentro de la capa de servicio o controlador.
     * </p>
     *
     * @param album La entidad {@link Album} recuperada de la base de datos.
     * @param songCount El número de canciones asociadas (calculado externamente).
     * @return Una instancia de {@code AlbumResponse} lista para ser serializada a JSON.
     */
    public static AlbumResponse fromAlbum(Album album, int songCount) {
        return AlbumResponse.builder()
                .id(album.getId())
                .title(album.getTitle())
                .artistId(album.getArtistId())
                .description(album.getDescription())
                .price(album.getPrice())
                .coverImageUrl(album.getCoverImageUrl())
                .genreIds(album.getGenreIds())
                .releaseDate(album.getReleaseDate())
                .discountPercentage(album.getDiscountPercentage())
                .createdAt(album.getCreatedAt())
                .updatedAt(album.getUpdatedAt())
                .published(album.isPublished())
                .songCount(songCount)
                .build();
    }
}