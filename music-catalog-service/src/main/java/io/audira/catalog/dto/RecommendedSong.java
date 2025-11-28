package io.audira.catalog.dto;

import io.audira.catalog.model.Song;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Representa una canción recomendada con metadatos explicativos.
 * <p>
 * Extiende la información básica de una canción añadiendo el <b>porqué</b> se recomienda
 * y un puntaje de relevancia. Fundamental para la transparencia del sistema de recomendaciones
 * (Explainable AI).
 * </p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecommendedSong {

    /** ID de la canción. */
    private Long id;

    /** Título de la canción. */
    private String title;

    /** ID del artista. */
    private Long artistId;

    /** Nombre del artista (resolved). */
    private String artistName;

    /** URL de la carátula. */
    private String imageUrl;

    /** Precio de venta unitario. */
    private Double price;

    /** Número de reproducciones (contexto de popularidad). */
    private Long plays;

    /**
     * Texto explicativo de la recomendación.
     * <p>Ej: "Porque escuchaste 'Bohemian Rhapsody'" o "Tendencia en tu región".</p>
     */
    private String reason;

    /**
     * Puntuación de relevancia o confianza (Score).
     * <p>Valor decimal de 0.0 a 1.0 que indica qué tan segura está la IA de que esta canción gustará.</p>
     */
    private Double relevanceScore;

    /**
     * Método de fábrica para convertir una entidad {@link Song} en una recomendación.
     *
     * @param song La entidad de canción original.
     * @param artistName Nombre del artista resuelto.
     * @param reason La razón generada por el algoritmo.
     * @param relevanceScore El puntaje calculado por el algoritmo.
     * @return Instancia de {@code RecommendedSong}.
     */
    public static RecommendedSong fromSong(Song song, String artistName, String reason, Double relevanceScore) {
        return RecommendedSong.builder()
                .id(song.getId())
                .title(song.getTitle())
                .artistId(song.getArtistId())
                .artistName(artistName)
                .imageUrl(song.getCoverImageUrl())
                .price(song.getPrice() != null ? song.getPrice().doubleValue() : null)
                .plays(song.getPlays())
                .reason(reason)
                .relevanceScore(relevanceScore)
                .build();
    }
}
