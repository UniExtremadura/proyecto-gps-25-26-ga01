package io.audira.community.util;

import java.util.regex.Pattern;

/**
 * Clase de utilidad estática que proporciona métodos para validar y extraer información
 * de URLs de diversas plataformas de redes sociales y servicios de música.
 * <p>
 * Utiliza expresiones regulares (Regex) para asegurar que los formatos de URL
 * proporcionados son correctos y compatibles con los perfiles de usuario o artista.
 * Se asume que los campos vacíos/nulos son válidos, ya que típicamente estos enlaces
 * son opcionales en los formularios.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
public class SocialMediaValidator {

    // --- Patrones Regex para la validación de URLs ---

    /**
     * Patrón Regex para URLs de Twitter/X.
     * Soporta dominios {@code twitter.com} y {@code x.com}, y permite opcionalmente parámetros de consulta.
     * Ejemplo válido: {@code https://twitter.com/nombre_usuario?s=12}
     */
    private static final Pattern TWITTER_PATTERN = Pattern.compile(
        "^https?://(www\\.)?(twitter\\.com|x\\.com)/[a-zA-Z0-9_]{1,15}(/?(\\?[^\\s]*)?)?$"
    );

    /**
     * Patrón Regex para URLs de Instagram.
     * Ejemplo válido: {@code https://www.instagram.com/nombre_usuario/}
     */
    private static final Pattern INSTAGRAM_PATTERN = Pattern.compile(
        "^https?://(www\\.)?instagram\\.com/[a-zA-Z0-9_.]+(/?(\\?[^\\s]*)?)?$"
    );

    /**
     * Patrón Regex para URLs de Facebook (perfiles públicos).
     * Ejemplo válido: {@code https://facebook.com/pagina.nombre}
     */
    private static final Pattern FACEBOOK_PATTERN = Pattern.compile(
        "^https?://(www\\.)?facebook\\.com/[a-zA-Z0-9.]+(/?(\\?[^\\s]*)?)?$"
    );

    /**
     * Patrón Regex para URLs de YouTube (canales).
     * Soporta los formatos de canal {@code /c/}, {@code /channel/} y {@code /@}.
     * Ejemplo válido: {@code https://youtube.com/@nombre_canal}
     */
    private static final Pattern YOUTUBE_PATTERN = Pattern.compile(
        "^https?://(www\\.)?youtube\\.com/(c/|channel/|@)[a-zA-Z0-9_-]+(/?(\\?[^\\s]*)?)?$"
    );

    /**
     * Patrón Regex para URLs de artistas de Spotify.
     * Ejemplo válido: {@code https://open.spotify.com/artist/XXXXXXXXXXX}
     */
    private static final Pattern SPOTIFY_PATTERN = Pattern.compile(
        "^https?://open\\.spotify\\.com/artist/[a-zA-Z0-9]+(/?(\\?[^\\s]*)?)?$"
    );

    /**
     * Patrón Regex para URLs de TikTok (perfiles).
     * Ejemplo válido: {@code https://tiktok.com/@nombre_usuario}
     */
    private static final Pattern TIKTOK_PATTERN = Pattern.compile(
        "^https?://(www\\.)?tiktok\\.com/@[a-zA-Z0-9_.]+(/?(\\?[^\\s]*)?)?$"
    );

    // --- Métodos de Validación ---

    /**
     * Valida si la cadena proporcionada es una URL válida de Twitter o X.
     * <p>
     * Se considera válido si la URL es {@code null} o vacía (asumiendo que es un campo opcional).
     * </p>
     *
     * @param url La URL a validar.
     * @return {@code true} si la URL es válida o vacía, {@code false} en caso contrario.
     */
    public static boolean isValidTwitterUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true; // Empty is valid (optional field)
        }
        return TWITTER_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Valida si la cadena proporcionada es una URL válida de Instagram.
     *
     * @param url La URL a validar.
     * @return {@code true} si la URL es válida o vacía, {@code false} en caso contrario.
     */
    public static boolean isValidInstagramUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return INSTAGRAM_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Valida si la cadena proporcionada es una URL válida de Facebook (perfil/página).
     *
     * @param url La URL a validar.
     * @return {@code true} si la URL es válida o vacía, {@code false} en caso contrario.
     */
    public static boolean isValidFacebookUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return FACEBOOK_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Valida si la cadena proporcionada es una URL válida de YouTube (canal).
     *
     * @param url La URL a validar.
     * @return {@code true} si la URL es válida o vacía, {@code false} en caso contrario.
     */
    public static boolean isValidYoutubeUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return YOUTUBE_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Valida si la cadena proporcionada es una URL válida de artista de Spotify.
     *
     * @param url La URL a validar.
     * @return {@code true} si la URL es válida o vacía, {@code false} en caso contrario.
     */
    public static boolean isValidSpotifyUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return SPOTIFY_PATTERN.matcher(url.trim()).matches();
    }

    /**
     * Valida si la cadena proporcionada es una URL válida de TikTok.
     *
     * @param url La URL a validar.
     * @return {@code true} si la URL es válida o vacía, {@code false} en caso contrario.
     */
    public static boolean isValidTiktokUrl(String url) {
        if (url == null || url.trim().isEmpty()) {
            return true;
        }
        return TIKTOK_PATTERN.matcher(url.trim()).matches();
    }

    // --- Métodos de Extracción ---

    /**
     * Extrae el nombre de usuario de una URL válida de Twitter/X.
     *
     * @param url URL de Twitter/X.
     * @return El nombre de usuario sin el símbolo '@', o una cadena vacía si la URL es nula, vacía o no se puede analizar.
     */
    public static String extractTwitterUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remover parámetros de consulta
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        // La URL debe ser del tipo: https://(www.)?dominio.com/username
        String[] parts = cleanUrl.split("/");
        // El nombre de usuario está en la posición [3]
        if (parts.length > 3) {
            // Asegura que no haya una barra final (el regex permite opcionalmente una barra)
            String username = parts[3].replace("@", "");
            return username;
        }
        return "";
    }

    /**
     * Extrae el nombre de usuario de una URL válida de Instagram.
     *
     * @param url URL de Instagram.
     * @return El nombre de usuario sin el símbolo '@', o una cadena vacía si la URL es nula, vacía o no se puede analizar.
     */
    public static String extractInstagramUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remover parámetros de consulta
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        if (parts.length > 3) {
            // El nombre de usuario está en parts[3]
            return parts[3].replace("@", "");
        }
        return "";
    }

    /**
     * Extrae el nombre de usuario de una URL válida de Facebook (página/perfil).
     *
     * @param url URL de Facebook.
     * @return El nombre de usuario (segmento final), o una cadena vacía si la URL es nula, vacía o no se puede analizar.
     */
    public static String extractFacebookUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remover parámetros de consulta
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        // El nombre de usuario está en parts[3]
        if (parts.length > 3) {
            return parts[3].replace("@", "");
        }
        return "";
    }

    /**
     * Extrae el nombre del canal o alias de una URL válida de YouTube.
     * <p>
     * Se asume que el formato es {@code youtube.com/c/nombre}, {@code youtube.com/channel/ID} o {@code youtube.com/@alias}.
     * El nombre o ID a extraer está en la posición [4] de los segmentos.
     * </p>
     *
     * @param url URL de YouTube.
     * @return El nombre/ID del canal, o una cadena vacía si la URL es nula, vacía o no se puede analizar.
     */
    public static String extractYoutubeUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remover parámetros de consulta
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        // El nombre del canal (o alias) está en parts[4] después de /c/ o /@ o /channel/
        if (parts.length > 4) {
            return parts[4].replace("@", "");
        }
        return "";
    }

    /**
     * Extrae el ID de artista de una URL válida de Spotify ({@code open.spotify.com/artist/ID}).
     *
     * @param url URL de Spotify Artist.
     * @return El ID único del artista, o una cadena vacía si la URL es nula, vacía o no se puede analizar.
     */
    public static String extractSpotifyUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remover parámetros de consulta
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        // El ID del artista está en parts[4]
        if (parts.length > 4) {
            return parts[4];
        }
        return "";
    }

    /**
     * Extrae el nombre de usuario de una URL válida de TikTok ({@code tiktok.com/@username}).
     *
     * @param url URL de TikTok.
     * @return El nombre de usuario sin el símbolo '@', o una cadena vacía si la URL es nula, vacía o no se puede analizar.
     */
    public static String extractTiktokUsername(String url) {
        if (url == null || url.trim().isEmpty()) {
            return "";
        }
        String cleanUrl = url.trim();
        // Remover parámetros de consulta
        if (cleanUrl.contains("?")) {
            cleanUrl = cleanUrl.substring(0, cleanUrl.indexOf("?"));
        }
        String[] parts = cleanUrl.split("/");
        // El nombre de usuario está en parts[3]
        if (parts.length > 3) {
            return parts[3].replace("@", "");
        }
        return "";
    }
}