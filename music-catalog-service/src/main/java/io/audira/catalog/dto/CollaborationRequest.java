package io.audira.catalog.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO de solicitud para crear invitaciones de colaboración.
 * <p>
 * Se utiliza para cumplir con el requisito <b>GA01-154: Añadir/aceptar colaboradores</b>.
 * Permite invitar a un artista a participar en una obra (Canción o Álbum) con un rol específico.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CollaborationRequest {

    /**
     * ID de la canción en la que se colabora.
     * <p>
     * <b>Regla de Negocio:</b> Se debe proporcionar {@code songId} O {@code albumId}, pero no ambos vacíos.
     * Si se proporciona, la colaboración se limita a este track.
     * </p>
     */
    private Long songId;

    /**
     * ID del álbum en el que se colabora.
     * <p>
     * Si se especifica, implica una colaboración a nivel de proyecto completo (aparece en todos los tracks
     * o como artista principal del álbum).
     * </p>
     */
    private Long albumId;

    /**
     * Identificador único del artista al que se está invitando.
     * <p>Este campo es obligatorio.</p>
     */
    @NotNull(message = "Artist ID is required")
    private Long artistId;

    /**
     * El rol que desempeñará el colaborador.
     * <p>
     * Ejemplos: "Featured Artist", "Producer", "Composer", "Songwriter".
     * Debe tener entre 1 y 100 caracteres.
     * </p>
     */
    @NotNull(message = "Role is required")
    @Size(min = 1, max = 100, message = "Role must be between 1 and 100 characters")
    private String role;
}