package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO que representa la información de un usuario o artista externo.
 * <p>
 * Estos datos provienen del microservicio <b>Community Service</b> o <b>User Service</b>.
 * El catálogo utiliza este objeto para "hidratar" las respuestas, mostrando nombres reales
 * y avatares en lugar de solo IDs numéricos.
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {
    /** Identificador único del usuario en el sistema global. */
    private Long id;

    /** Correo electrónico de contacto. */
    private String email;

    /** Nombre de usuario único (handle, ej: @usuario). */
    private String username;

    /** Nombre real (Pila). */
    private String firstName;

    /** Apellidos. */
    private String lastName;

    /**
     * Nombre artístico público.
     * <p>Este es el campo principal que se debe mostrar en créditos de canciones y álbumes.</p>
     */
    private String artistName;

    /** Biografía o descripción del perfil del artista. */
    private String artistBio;

    /** Sello discográfico asociado (si aplica). */
    private String recordLabel;

    /**
     * Indica si el artista ha sido verificado por la plataforma (Blue check).
     */
    private Boolean verifiedArtist;

    /**
     * Rol principal del usuario en el sistema.
     * <p>Ej: {@code ARTIST}, {@code LISTENER}, {@code ADMIN}.</p>
     */
    private String role;
}
