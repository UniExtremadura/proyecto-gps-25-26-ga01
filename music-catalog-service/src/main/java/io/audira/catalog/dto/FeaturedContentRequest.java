package io.audira.catalog.dto;

import io.audira.catalog.model.FeaturedContent.ContentType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO de entrada (Request) para la gestión de contenido destacado.
 * <p>
 * Soporta los requisitos:
 * <ul>
 * <li><b>GA01-156:</b> Seleccionar y ordenar contenido.</li>
 * <li><b>GA01-157:</b> Programación temporal (fechas de inicio y fin).</li>
 * </ul>
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FeaturedContentRequest {

    /**
     * El tipo de entidad que se quiere destacar.
     * <p>Valores posibles: {@code SONG}, {@code ALBUM}, {@code PLAYLIST}, {@code ARTIST}.</p>
     */
    private ContentType contentType;

    /**
     * El ID numérico de la entidad referenciada.
     * <p>Ej: El ID del álbum o de la canción a promocionar.</p>
     */
    private Long contentId;

    /**
     * Prioridad de visualización.
     * <p>
     * Los números más bajos aparecen primero (izquierda o arriba) en el carrusel.
     * </p>
     */
    private Integer displayOrder;

    /**
     * Fecha y hora a partir de la cual el contenido será visible.
     * <p>Permite programar campañas de marketing con antelación.</p>
     */
    private LocalDateTime startDate;

    /**
     * Fecha y hora en la que el contenido dejará de ser destacado automáticamente.
     */
    private LocalDateTime endDate;

    /**
     * Interruptor manual de visibilidad.
     * <p>Si es {@code false}, el contenido no se muestra aunque esté dentro del rango de fechas válido.</p>
     */
    private Boolean isActive;
}
