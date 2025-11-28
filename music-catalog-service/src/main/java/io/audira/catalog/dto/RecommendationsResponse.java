package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * DTO de respuesta que agrupa todas las recomendaciones personalizadas para un usuario.
 * <p>
 * Implementa la salida del <b>GA01-117: Módulo básico de recomendaciones</b>.
 * En lugar de una lista plana, categoriza las canciones según la heurística utilizada
 * (historial, compras, social, etc.) para que el frontend pueda mostrarlas en secciones diferenciadas
 * (ej: "Porque escuchaste X", "Tendencias", "Novedades").
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecommendationsResponse {

    /** ID del usuario para el cual se generaron estas recomendaciones. */
    private Long userId;

    /** Marca de tiempo de la generación (útil para caché). */
    private LocalDateTime generatedAt;

    // --- Categorías Generales ---

    /** Recomendaciones basadas en el historial de reproducción reciente (Listening History). */
    private List<RecommendedSong> basedOnListeningHistory;

    /** Recomendaciones basadas en el historial de compras previas. */
    private List<RecommendedSong> basedOnPurchases;

    /** Novedades de los artistas que el usuario sigue (Followed Artists). */
    private List<RecommendedSong> fromFollowedArtists;

    /** Canciones en tendencia global (Popularidad general). */
    private List<RecommendedSong> trending;

    /** Nuevos lanzamientos generales (New Releases). */
    private List<RecommendedSong> newReleases;

    /** Recomendaciones por similitud de audio/género con las canciones favoritas del usuario. */
    private List<RecommendedSong> similarToFavorites;

    // --- Nuevas Categorías Específicas ---

    /** Canciones pertenecientes a los géneros más comprados por el usuario. */
    private List<RecommendedSong> byPurchasedGenres;

    /** Otras canciones de artistas a los que el usuario ya ha comprado contenido. */
    private List<RecommendedSong> byPurchasedArtists;

    /** Recomendaciones basadas en canciones marcadas con 4 o 5 estrellas (Liked Songs). */
    private List<RecommendedSong> byLikedSongs;

    // --- Metadatos del Motor ---

    /** Nombre o versión del algoritmo utilizado (ej: "collaborative_filtering_v2"). */
    private String algorithm;

    /** Conteo total de recomendaciones únicas incluidas en este objeto. */
    private Integer totalRecommendations;

    /**
     * Método de utilidad para obtener una lista unificada de todas las recomendaciones.
     * <p>
     * Combina todas las categorías en una sola lista plana, útil para funcionalidades
     * como "Reproducir todas las recomendaciones" o "Radio personalizada".
     * </p>
     *
     * @return Lista combinada de {@link RecommendedSong}.
     */
    public List<RecommendedSong> getAllRecommendations() {
        java.util.List<RecommendedSong> all = new java.util.ArrayList<>();
        if (basedOnListeningHistory != null) all.addAll(basedOnListeningHistory);
        if (basedOnPurchases != null) all.addAll(basedOnPurchases);
        if (fromFollowedArtists != null) all.addAll(fromFollowedArtists);
        if (trending != null) all.addAll(trending);
        if (newReleases != null) all.addAll(newReleases);
        if (similarToFavorites != null) all.addAll(similarToFavorites);
        if (byPurchasedGenres != null) all.addAll(byPurchasedGenres);
        if (byPurchasedArtists != null) all.addAll(byPurchasedArtists);
        if (byLikedSongs != null) all.addAll(byLikedSongs);
        return all;
    }
}
