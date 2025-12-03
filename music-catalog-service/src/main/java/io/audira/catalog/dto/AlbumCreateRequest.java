package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;

/**
 * DTO de entrada (Request Payload) para la creación de un nuevo álbum.
 * <p>
 * Encapsula todos los datos necesarios que el cliente debe enviar al endpoint {@code POST /api/albums}.
 * Incluye metadatos descriptivos y la asociación inicial con canciones existentes.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlbumCreateRequest {

    /**
     * Título oficial del álbum.
     * <p>Este campo es obligatorio.</p>
     */
    private String title;

    /**
     * Identificador único del artista o banda propietario del álbum.
     * <p>Debe corresponder a un usuario con rol de ARTIST existente en el sistema.</p>
     */
    private Long artistId;

    /**
     * Descripción promocional o notas del álbum.
     * <p>Puede contener detalles sobre la producción, inspiración, etc.</p>
     */
    private String description;

    /**
     * Precio base del álbum completo.
     * <p>Si es 0, el álbum se considera gratuito.</p>
     */
    private BigDecimal price;

    /**
     * URL pública de la imagen de portada (Carátula).
     * <p>Generalmente apunta a un recurso alojado en el <b>File Service</b> o un bucket S3.</p>
     */
    private String coverImageUrl;

    /**
     * Conjunto de IDs de los géneros musicales asociados.
     * <p>Permite categorizar el álbum en múltiples géneros (ej: Pop, Rock).</p>
     */
    private Set<Long> genreIds;

    /**
     * Fecha oficial de lanzamiento.
     * <p>Puede ser una fecha futura para lanzamientos programados (Pre-save).</p>
     */
    private LocalDate releaseDate;

    /**
     * Porcentaje de descuento aplicable (0.0 a 100.0).
     * <p>Utilizado para ofertas promocionales.</p>
     */
    private Double discountPercentage;

    // Lista de IDs de canciones a incluir en el álbum
    private List<Long> songIds;
}