package io.audira.community.dto;

import lombok.Data;

/**
 * Data Transfer Object (DTO) que representa la solicitud de un usuario para actualizar su información de perfil.
 * <p>
 * Este objeto permite la modificación de campos generales (nombre, biografía, imágenes) y campos
 * específicos para el rol de artista, así como enlaces a redes sociales.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Data
public class UpdateProfileRequest {

    /**
     * Nuevo nombre de pila del usuario.
     */
    private String firstName;

    /**
     * Nuevo apellido del usuario.
     */
    private String lastName;

    /**
     * Nueva biografía general o descripción del usuario.
     */
    private String bio;

    /**
     * URL de la nueva imagen de perfil del usuario.
     */
    private String profileImageUrl;

    /**
     * URL de la nueva imagen de banner del perfil.
     */
    private String bannerImageUrl;

    /**
     * Ubicación geográfica del usuario.
     */
    private String location;

    /**
     * Enlace a un sitio web personal.
     */
    private String website;

    // --- Campos Específicos del Artista ---

    /**
     * Nombre artístico o alias del artista (si aplica).
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

    // --- Enlaces a Redes Sociales ---

    /**
     * URL del perfil de Twitter/X del artista/usuario.
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