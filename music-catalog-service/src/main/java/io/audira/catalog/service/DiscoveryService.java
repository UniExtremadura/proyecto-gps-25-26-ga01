package io.audira.catalog.service;

import io.audira.catalog.client.CommerceServiceClient;
import io.audira.catalog.client.UserServiceClient;
import io.audira.catalog.dto.OrderDTO;
import io.audira.catalog.dto.OrderItemDTO;
import io.audira.catalog.dto.RecommendationsResponse;
import io.audira.catalog.dto.RecommendedSong;
import io.audira.catalog.model.Album;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class DiscoveryService {
    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    private final CommerceServiceClient commerceServiceClient;
    private final UserServiceClient userServiceClient;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${community.service.url:http://172.16.0.4:8081}")
    private String communityServiceUrl;

    private static final int RECOMMENDATIONS_PER_CATEGORY = 10;

    public List<Song> getTrendingSongs() {
        return songRepository.findTopByPlays();
    }

    public List<Album> getTrendingAlbums() {
        // Por ahora devuelve los álbumes más recientes
        return albumRepository.findTop20ByOrderByCreatedAtDesc();
    }

    // Search methods for GA01-96 and GA01-98
    public Page<Song> searchSongs(String query, Pageable pageable) {
        if (query == null || query.trim().isEmpty()) {
            return Page.empty(pageable);
        }

        // Get artist IDs matching the query from community-service
        List<Long> artistIds = getArtistIdsByName(query);

        // Search by title and/or artist IDs
        if (artistIds.isEmpty()) {
            // Only search by title
            return songRepository.searchByTitle(query, pageable);
        } else {
            // Search by both title and artist IDs
            return songRepository.searchByTitleOrArtistIds(query, artistIds, pageable);
        }
    }

    public Page<Album> searchAlbums(String query, Pageable pageable) {
        if (query == null || query.trim().isEmpty()) {
            return Page.empty(pageable);
        }

        // Get artist IDs matching the query from community-service
        List<Long> artistIds = getArtistIdsByName(query);

        // Search by title and/or artist IDs
        if (artistIds.isEmpty()) {
            // Only search by title
            return albumRepository.searchByTitle(query, pageable);
        } else {
            // Search by both title and artist IDs
            return albumRepository.searchByTitleOrArtistIds(query, artistIds, pageable);
        }
    }

    private List<Long> getArtistIdsByName(String query) {
        try {
            String url = UriComponentsBuilder.fromHttpUrl(communityServiceUrl + "/api/users/search/artist-ids")
                    .queryParam("query", query)
                    .toUriString();

            ResponseEntity<List<Long>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Long>>() {}
            );

            return response.getBody() != null ? response.getBody() : new ArrayList<>();
        } catch (Exception e) {
            // If community-service is unavailable, just return empty list
            // This allows searching by title only
            return new ArrayList<>();
        }
    }

    /**
     * Generate personalized recommendations for a user
     * GA01-117: Módulo básico de recomendaciones (placeholder)
     *
     * This is a basic placeholder implementation. Future improvements could include:
     * - Machine learning algorithms
     * - Collaborative filtering
     * - Content-based filtering
     * - Real-time listening history tracking
     * - User behavior analysis
     *
     * @param userId User ID
     * @return Recommendations response with categorized song lists
     */
    public RecommendationsResponse getRecommendationsForUser(Long userId) {
        log.info("Generating recommendations for user {}", userId);

        RecommendationsResponse response = RecommendationsResponse.builder()
                .userId(userId)
                .generatedAt(LocalDateTime.now())
                .algorithm("basic_placeholder_v1")
                .build();

        try {
            // 1. Based on purchase history (genres from purchased songs)
            response.setBasedOnPurchases(getRecommendationsFromPurchaseHistory(userId));

            // 2. From followed artists
            response.setFromFollowedArtists(getRecommendationsFromFollowedArtists(userId));

            // 3. Trending songs
            response.setTrending(getTrendingRecommendations());

            // 4. New releases
            response.setNewReleases(getNewReleasesRecommendations());

            // 5. Similar to favorites (for now, same as purchase-based)
            response.setSimilarToFavorites(getRecommendationsFromPurchaseHistory(userId));

            // Note: basedOnListeningHistory would require a listening history tracking system
            // For now, we'll leave it empty as a placeholder
            response.setBasedOnListeningHistory(new ArrayList<>());

            // Calculate total recommendations
            int total = safeListSize(response.getBasedOnPurchases())
                    + safeListSize(response.getFromFollowedArtists())
                    + safeListSize(response.getTrending())
                    + safeListSize(response.getNewReleases())
                    + safeListSize(response.getSimilarToFavorites())
                    + safeListSize(response.getBasedOnListeningHistory());

            response.setTotalRecommendations(total);

            log.info("Generated {} total recommendations for user {}", total, userId);

        } catch (Exception e) {
            log.error("Error generating recommendations for user {}", userId, e);
            // Return empty recommendations in case of error
            response.setBasedOnPurchases(new ArrayList<>());
            response.setFromFollowedArtists(new ArrayList<>());
            response.setTrending(new ArrayList<>());
            response.setNewReleases(new ArrayList<>());
            response.setSimilarToFavorites(new ArrayList<>());
            response.setBasedOnListeningHistory(new ArrayList<>());
            response.setTotalRecommendations(0);
        }

        return response;
    }

    /**
     * Get recommendations based on user's purchase history
     * Analyzes genres from purchased songs and recommends similar songs
     */
    private List<RecommendedSong> getRecommendationsFromPurchaseHistory(Long userId) {
        try {
            // Get user's orders
            List<OrderDTO> orders = commerceServiceClient.getUserOrders(userId);

            // Extract song IDs from orders
            Set<Long> purchasedSongIds = orders.stream()
                    .flatMap(order -> order.getItems().stream())
                    .filter(item -> "SONG".equals(item.getItemType()))
                    .map(OrderItemDTO::getItemId)
                    .collect(Collectors.toSet());

            if (purchasedSongIds.isEmpty()) {
                log.debug("User {} has no purchase history", userId);
                return new ArrayList<>();
            }

            // Get purchased songs to analyze their genres
            List<Song> purchasedSongs = songRepository.findAllById(purchasedSongIds);

            // Collect all genres from purchased songs
            Set<Long> favoriteGenres = purchasedSongs.stream()
                    .flatMap(song -> song.getGenreIds().stream())
                    .collect(Collectors.toSet());

            if (favoriteGenres.isEmpty()) {
                return new ArrayList<>();
            }

            // Find songs with similar genres that user hasn't purchased
            List<Song> recommendations = new ArrayList<>();
            for (Long genreId : favoriteGenres) {
                List<Song> genreSongs = songRepository.findPublishedByGenreId(genreId);
                recommendations.addAll(genreSongs.stream()
                        .filter(song -> !purchasedSongIds.contains(song.getId()))
                        .limit(5)
                        .collect(Collectors.toList()));
            }

            // Remove duplicates and limit
            List<Song> limitedRecommendations = recommendations.stream()
                    .distinct()
                    .limit(RECOMMENDATIONS_PER_CATEGORY)
                    .collect(Collectors.toList());

            // Convert to RecommendedSong with real artist names
            return enrichWithArtistNames(limitedRecommendations, "Based on your purchase history", 0.85);

        } catch (Exception e) {
            log.warn("Error getting recommendations from purchase history for user {}", userId, e);
            return new ArrayList<>();
        }
    }

    /**
     * Get recommendations from artists the user follows
     */
    private List<RecommendedSong> getRecommendationsFromFollowedArtists(Long userId) {
        try {
            // Get artists that user follows
            List<Long> followedArtistIds = userServiceClient.getFollowedArtistIds(userId);

            if (followedArtistIds.isEmpty()) {
                log.debug("User {} doesn't follow any artists", userId);
                return new ArrayList<>();
            }

            // Get songs from followed artists
            List<Song> artistSongs = new ArrayList<>();
            for (Long artistId : followedArtistIds) {
                List<Song> songs = songRepository.findByArtistId(artistId).stream()
                        .filter(Song::isPublished)
                        .limit(3) // Limit per artist to ensure variety
                        .collect(Collectors.toList());
                artistSongs.addAll(songs);
            }

            List<Song> limitedSongs = artistSongs.stream()
                    .limit(RECOMMENDATIONS_PER_CATEGORY)
                    .collect(Collectors.toList());

            // Convert to RecommendedSong with real artist names
            return enrichWithArtistNames(limitedSongs, "From artists you follow", 0.9);

        } catch (Exception e) {
            log.warn("Error getting recommendations from followed artists for user {}", userId, e);
            return new ArrayList<>();
        }
    }

    /**
     * Get trending song recommendations
     */
    private List<RecommendedSong> getTrendingRecommendations() {
        try {
            List<Song> trendingSongs = songRepository.findTopPublishedByPlays().stream()
                    .limit(RECOMMENDATIONS_PER_CATEGORY)
                    .collect(Collectors.toList());

            // Convert to RecommendedSong with real artist names
            return enrichWithArtistNames(trendingSongs, "Trending now", 0.7);

        } catch (Exception e) {
            log.warn("Error getting trending recommendations", e);
            return new ArrayList<>();
        }
    }

    /**
     * Get new releases recommendations
     */
    private List<RecommendedSong> getNewReleasesRecommendations() {
        try {
            List<Song> newSongs = songRepository.findTop20ByPublishedTrueOrderByCreatedAtDesc().stream()
                    .limit(RECOMMENDATIONS_PER_CATEGORY)
                    .collect(Collectors.toList());

            // Convert to RecommendedSong with real artist names
            return enrichWithArtistNames(newSongs, "New release", 0.75);

        } catch (Exception e) {
            log.warn("Error getting new releases recommendations", e);
            return new ArrayList<>();
        }
    }

    /**
     * Enrich songs with real artist names from UserServiceClient
     * GA01-117: Obtains real artist names instead of placeholders
     *
     * @param songs List of songs to enrich
     * @param reason Recommendation reason
     * @param relevanceScore Relevance score
     * @return List of RecommendedSong with real artist names
     */
    private List<RecommendedSong> enrichWithArtistNames(List<Song> songs, String reason, Double relevanceScore) {
        // Build a map of artist IDs to artist names
        Map<Long, String> artistNamesCache = new HashMap<>();

        return songs.stream()
                .map(song -> {
                    // Get or fetch artist name
                    String artistName = artistNamesCache.computeIfAbsent(
                            song.getArtistId(),
                            artistId -> {
                                try {
                                    return userServiceClient.getUserById(artistId).getArtistName();
                                } catch (Exception e) {
                                    log.debug("Failed to fetch artist name for artistId: {}, using fallback", artistId);
                                    return "Artist #" + artistId;
                                }
                            }
                    );

                    return RecommendedSong.fromSong(song, artistName, reason, relevanceScore);
                })
                .collect(Collectors.toList());
    }

    /**
     * Helper method to safely get list size
     */
    private int safeListSize(List<?> list) {
        return list != null ? list.size() : 0;
    }
}