package io.audira.catalog.dto;

import io.audira.catalog.model.Song;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Represents a recommended song with metadata about why it was recommended
 * GA01-117: Módulo básico de recomendaciones (placeholder)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecommendedSong {

    private Long id;
    private String title;
    private Long artistId;
    private String artistName;
    private String imageUrl;
    private Double price;
    private Long plays;
    private String reason; // Why this song was recommended (e.g., "Based on your listening history", "Trending now")
    private Double relevanceScore; // Score from 0.0 to 1.0 indicating how relevant this recommendation is

    /**
     * Create a RecommendedSong from a Song entity
     * @param song Song entity
     * @param artistName Artist name (real name from user service)
     * @param reason Reason for recommendation
     * @param relevanceScore Relevance score (0.0 to 1.0)
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
