package io.audira.catalog.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Response containing personalized recommendations for a user
 * GA01-117: Módulo básico de recomendaciones (placeholder)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecommendationsResponse {

    private Long userId;
    private LocalDateTime generatedAt;

    // Different categories of recommendations
    private List<RecommendedSong> basedOnListeningHistory; // Based on user's listening patterns
    private List<RecommendedSong> basedOnPurchases; // Based on user's purchase history
    private List<RecommendedSong> fromFollowedArtists; // From artists the user follows
    private List<RecommendedSong> trending; // Currently trending songs
    private List<RecommendedSong> newReleases; // Recent releases
    private List<RecommendedSong> similarToFavorites; // Similar to user's favorite songs

    // NEW: More specific recommendation categories
    private List<RecommendedSong> byPurchasedGenres; // Songs from genres user has purchased
    private List<RecommendedSong> byPurchasedArtists; // Songs from artists user has purchased from
    private List<RecommendedSong> byLikedSongs; // Based on songs rated 4-5 stars

    // Metadata
    private String algorithm; // Which algorithm was used (e.g., "basic_placeholder_v1")
    private Integer totalRecommendations; // Total number of recommendations across all categories

    /**
     * Get all recommendations combined from all categories
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
