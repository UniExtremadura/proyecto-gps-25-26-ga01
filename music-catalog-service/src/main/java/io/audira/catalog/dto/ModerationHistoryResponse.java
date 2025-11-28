package io.audira.catalog.dto;

import io.audira.catalog.model.ModerationStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * DTO de respuesta que representa un registro histórico de moderación.
 * <p>
 * Se utiliza para cumplir con el requisito <b>GA01-163: Historial de moderación</b>.
 * Permite a los administradores visualizar la trazabilidad de los cambios de estado
 * de una obra (Canción o Álbum), incluyendo quién realizó la acción, cuándo y por qué.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ModerationHistoryResponse {
    /** Identificador único del registro de historial (Log ID). */
    private Long id;

    /** ID de la entidad moderada (Canción o Álbum). */
    private Long productId;

    /** Tipo de producto ("SONG" o "ALBUM"). */
    private String productType;

    /** Título de la obra en el momento de la moderación. */
    private String productTitle;

    /** ID del artista propietario. */
    private Long artistId;

    /** Nombre del artista (desnormalizado para visualización rápida). */
    private String artistName;

    /** Estado en el que se encontraba la obra antes de esta acción. */
    private ModerationStatus previousStatus;

    /** Nuevo estado asignado tras la acción (ej: de PENDING_REVIEW a REJECTED). */
    private ModerationStatus newStatus;

    /** ID del administrador o moderador que ejecutó la acción. */
    private Long moderatedBy;

    /** Nombre del moderador (para mostrar en la tabla de historial). */
    private String moderatorName;

    /**
     * Razón del rechazo proporcionada al artista.
     * <p>Solo tendrá valor si {@code newStatus} es {@code REJECTED}.</p>
     */
    private String rejectionReason;

    /** Fecha y hora exacta en la que se realizó la moderación. */
    private LocalDateTime moderatedAt;

    /**
     * Notas internas del moderador.
     * <p>Comentarios visibles solo para otros administradores, no para el artista.</p>
     */
    private String notes;
}
