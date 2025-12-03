package io.audira.community.dto;

import io.audira.community.model.UserRole;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.Set;

/**
 * Data Transfer Object (DTO) que representa la información completa del perfil de un usuario en el sistema.
 * <p>
 * Este objeto se utiliza para transferir datos de perfil a la capa de presentación (API) y entre microservicios.
 * Incluye campos básicos de autenticación, detalles de perfil social y campos específicos para el rol de artista.
 * </p>
 *
 * @author Grupo GA01
 * @see UserRole
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserDTO {

    /**
     * ID único del usuario en el sistema.
     */
    private Long id;

    /**
     * Dirección de correo electrónico del usuario.
     */
    private String email;

    /**
     * Nombre de usuario o alias.
     */
    private String username;

    /**
     * Nombre de pila o primer nombre del usuario.
     */
    private String firstName;

    /**
     * Apellido del usuario.
     */
    private String lastName;

    /**
     * Biografía general del usuario.
     */
    private String bio;

    /**
     * URL de la imagen de perfil (avatar).
     */
    private String profileImageUrl;

    /**
     * URL de la imagen de banner del perfil.
     */
    private String bannerImageUrl;

    /**
     * Ubicación geográfica del usuario.
     */
    private String location;

    /**
     * Enlace a un sitio web personal o promocional.
     */
    private String website;

    /**
     * Rol de seguridad del usuario (ej. USER, ARTIST, ADMIN) utilizando el enumerador {@link UserRole}.
     */
    private UserRole role;

    /**
     * Indica si la cuenta del usuario está activa ({@code true}) o suspendida ({@code false}).
     */
    private Boolean isActive;

    /**
     * Indica si el correo electrónico del usuario ha sido verificado ({@code true}).
     */
    private Boolean isVerified;

    /**
     * Conjunto de IDs de los usuarios que siguen a este perfil (seguidores).
     */
    private Set<Long> followerIds;

    /**
     * Conjunto de IDs de los usuarios que este perfil está siguiendo.
     */
    private Set<Long> followingIds;

    /**
     * Marca de tiempo de la creación de la cuenta.
     */
    private LocalDateTime createdAt;

    /**
     * Marca de tiempo de la última actualización del perfil.
     */
    private LocalDateTime updatedAt;

    // --- Campos Específicos del Artista ---

    /**
     * Nombre artístico o alias principal (si el rol es ARTIST).
     */
    private String artistName;

    /**
     * Biografía específica del artista.
     */
    private String artistBio;

    /**
     * Sello discográfico o discográfica asociada al artista.
     */
    private String recordLabel;

    /**
     * Indica si el perfil del artista ha sido verificado por la administración del sistema.
     */
    private Boolean verifiedArtist;

    // --- Enlaces a Redes Sociales ---

    /**
     * URL del perfil de Twitter/X.
     */
    private String twitterUrl;

    /**
     * URL del perfil de Instagram.
     */
    private String instagramUrl;

    /**
     * URL del perfil de Facebook.
     */
    private String facebookUrl;

    /**
     * URL del canal de YouTube.
     */
    private String youtubeUrl;

    /**
     * URL del perfil de Spotify.
     */
    private String spotifyUrl;

    /**
     * URL del perfil de TikTok.
     */
    private String tiktokUrl;
}