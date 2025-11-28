package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Set;

/**
 * DTO de entrada (Request Payload) para la actualización de un álbum existente.
 * <p>
 * Se utiliza en operaciones {@code PUT} o {@code PATCH}. Permite modificar
 * los metadatos descriptivos y comerciales, pero no la propiedad (autoría) ni la estructura de tracks.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlbumUpdateRequest {

    /**
     * Nuevo título del álbum.
     */
    private String title;

    /**
     * Nueva descripción o notas promocionales.
     */
    private String description;

    /**
     * Precio actualizado.
     */
    private BigDecimal price;

    /**
     * URL de la nueva imagen de portada.
     */
    private String coverImageUrl;

    /**
     * Conjunto actualizado de géneros musicales.
     * <p>Reemplaza la lista de géneros anterior.</p>
     */
    private Set<Long> genreIds;

    /**
     * Fecha de lanzamiento corregida o reprogramada.
     */
    private LocalDate releaseDate;

    /**
     * Nuevo porcentaje de descuento.
     */
    private Double discountPercentage;
}