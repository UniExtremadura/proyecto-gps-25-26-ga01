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
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
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

    // ============= ADVANCED SEARCH METHODS (User's Implementation) =============

    /**
     * Simple search - searches by query only
     */
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

    /**
     * Advanced search for songs with filters
     * Full implementation with genreId, price range, and sorting
     */
    public Page<Song> searchSongs(String query, Long genreId, Double minPrice, Double maxPrice, String sortBy, Pageable pageable) {
        log.debug("Advanced search - query: {}, genreId: {}, minPrice: {}, maxPrice: {}, sortBy: {}",
                query, genreId, minPrice, maxPrice, sortBy);

        boolean hasQuery = query != null && !query.trim().isEmpty();
        boolean hasFilters = genreId != null || minPrice != null || maxPrice != null;

        // Determine sort order
        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt"); // Default: newest first
        if ("price_asc".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.ASC, "price");
        } else if ("price_desc".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.DESC, "price");
        } else if ("oldest".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.ASC, "createdAt");
        } else if ("recent".equals(sortBy) || "newest".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.DESC, "createdAt");
        }

        // Create new pageable with sort
        Pageable sortedPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);

        // Case 1: Only filters, no search query
        if (!hasQuery && hasFilters) {
            log.debug("Searching with filters only");
            return songRepository.searchPublishedByFiltersOnly(genreId, minPrice, maxPrice, sortedPageable);
        }

        // Case 2: Search query with optional filters
        if (hasQuery) {
            String searchQuery = query.trim();
            List<Long> artistIds = getArtistIdsByName(searchQuery);

            // Case 2a: Search by title only (no artist matches) with filters
            if (artistIds.isEmpty()) {
                log.debug("Searching by title with filters: {}", searchQuery);
                return songRepository.searchPublishedByTitleAndFilters(searchQuery, genreId, minPrice, maxPrice, sortedPageable);
            }

            // Case 2b: Search by title AND artist with filters
            log.debug("Searching by title or artist IDs with filters: {}, artistIds: {}", searchQuery, artistIds);
            return songRepository.searchPublishedByTitleOrArtistIdsAndFilters(searchQuery, artistIds, genreId, minPrice, maxPrice, sortedPageable);
        }

        // Case 3: No query and no filters - return empty
        log.debug("No query and no filters provided, returning empty page");
        return Page.empty(sortedPageable);
    }

    /**
     * Simple album search
     */
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

    /**
     * Advanced search for albums with filters
     */
    public Page<Album> searchAlbums(String query, Long genreId, Double minPrice, Double maxPrice, String sortBy, Pageable pageable) {
        // Permitir búsqueda si hay query, genreId o rango de precio
        boolean hasQuery = query != null && !query.trim().isEmpty();
        boolean hasFilters = genreId != null || minPrice != null || maxPrice != null;
        
        if (!hasQuery && !hasFilters) {
            return Page.empty(pageable);
        }
        
        String searchQuery = hasQuery ? query : "";

        Sort sort = Sort.by(Sort.Direction.DESC, "releaseDate");
        if ("price_asc".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.ASC, "price");
        } else if ("price_desc".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.DESC, "price");
        } else if ("oldest".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.ASC, "createdAt");
        }

        Pageable sortedPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);
        log.info("DEBUG SEARCH ALBUMS -> Query: {}, GenreID: {}, MinPrice: {}, MaxPrice: {}, SortBy: {}", 
                 searchQuery, genreId, minPrice, maxPrice, sortBy);
        
        // Si no hay query de texto, solo filtrar por género y/o precio
        if (searchQuery.isEmpty()) {
            return albumRepository.searchPublishedByFiltersOnly(genreId, minPrice, maxPrice, sortedPageable);
        }
        
        List<Long> artistIds = getArtistIdsByName(searchQuery);
        log.info("DEBUG SEARCH ALBUMS -> ArtistIds encontrados: {}", artistIds);

        if (artistIds.isEmpty()) {
            return albumRepository.searchPublishedByTitleAndFilters(searchQuery, genreId, minPrice, maxPrice, sortedPageable);
        } else {
            return albumRepository.searchPublishedByTitleOrArtistIdsAndFilters(searchQuery, artistIds, genreId, minPrice, maxPrice, sortedPageable);
        }
    }

    /**
     * Get artist IDs by name from community-service
     */
    private List<Long> getArtistIdsByName(String query) {
        if (query == null || query.trim().isEmpty()) {
            return new ArrayList<>();
        }
        
        try {
            String url = UriComponentsBuilder.fromHttpUrl(communityServiceUrl + "/api/users/search/artist-ids")
                    .queryParam("query", query.trim())
                    .toUriString();

            log.debug("Searching artists with query: '{}' at URL: {}", query, url);

            ResponseEntity<List<Long>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Long>>() {}
            );

            List<Long> artistIds = response.getBody() != null ? response.getBody() : new ArrayList<>();
            log.info("Found {} artist(s) matching query: '{}'", artistIds.size(), query);
            
            return artistIds;
            
        } catch (Exception e) {
            log.warn("Error searching artists by name '{}': {}", query, e.getMessage());
            return new ArrayList<>();
        }
    }

    // ============= RECOMMENDATIONS METHODS =============

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
            // 1. NEW: By purchased genres - Most specific genre-based recommendations
            response.setByPurchasedGenres(getRecommendationsByPurchasedGenres(userId));

            // 2. NEW: By purchased artists - Songs from artists you bought from
            response.setByPurchasedArtists(getRecommendationsByPurchasedArtists(userId));

            // 3. NEW: By liked songs - Based on 4-5 star ratings
            response.setByLikedSongs(getRecommendationsByLikedSongs(userId));

            // 4. From followed artists
            response.setFromFollowedArtists(getRecommendationsFromFollowedArtists(userId));

            // 5. Based on purchase history (general - kept for backward compatibility)
            response.setBasedOnPurchases(getRecommendationsFromPurchaseHistory(userId));

            // 6. Trending songs
            response.setTrending(getTrendingRecommendations());

            // 7. New releases
            response.setNewReleases(getNewReleasesRecommendations());

            // 8. Similar to favorites (same as purchase-based for now)
            response.setSimilarToFavorites(getRecommendationsFromPurchaseHistory(userId));

            // Note: basedOnListeningHistory would require a listening history tracking system
            // For now, we'll leave it empty as a placeholder
            response.setBasedOnListeningHistory(new ArrayList<>());

            // Calculate total recommendations
            int total = safeListSize(response.getByPurchasedGenres())
                    + safeListSize(response.getByPurchasedArtists())
                    + safeListSize(response.getByLikedSongs())
                    + safeListSize(response.getBasedOnPurchases())
                    + safeListSize(response.getFromFollowedArtists())
                    + safeListSize(response.getTrending())
                    + safeListSize(response.getNewReleases())
                    + safeListSize(response.getSimilarToFavorites())
                    + safeListSize(response.getBasedOnListeningHistory());

            response.setTotalRecommendations(total);

            log.info("Generated {} total recommendations for user {} - By genres: {}, By artists: {}, By likes: {}, From followed: {}, Trending: {}, New: {}",
                    total, userId,
                    safeListSize(response.getByPurchasedGenres()),
                    safeListSize(response.getByPurchasedArtists()),
                    safeListSize(response.getByLikedSongs()),
                    safeListSize(response.getFromFollowedArtists()),
                    safeListSize(response.getTrending()),
                    safeListSize(response.getNewReleases()));

        } catch (Exception e) {
            log.error("Error generating recommendations for user {}", userId, e);
            // Return empty recommendations in case of error
            response.setByPurchasedGenres(new ArrayList<>());
            response.setByPurchasedArtists(new ArrayList<>());
            response.setByLikedSongs(new ArrayList<>());
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
     * CRITICAL FIX: Get recommendations based on user's purchase history
     * Analyzes genres from purchased songs and recommends similar songs
     * NOW ONLY counts DELIVERED orders (successfully paid)
     */
    private List<RecommendedSong> getRecommendationsFromPurchaseHistory(Long userId) {
        try {
            // Get user's orders
            List<OrderDTO> orders = commerceServiceClient.getUserOrders(userId);

            // CRITICAL FIX: Only count DELIVERED orders (successfully paid)
            Set<Long> purchasedSongIds = orders.stream()
                    .filter(order -> order.getStatus() != null && "DELIVERED".equals(order.getStatus()))
                    .flatMap(order -> order.getItems().stream())
                    .filter(item -> "SONG".equals(item.getItemType()))
                    .map(OrderItemDTO::getItemId)
                    .collect(Collectors.toSet());

            if (purchasedSongIds.isEmpty()) {
                log.debug("User {} has no delivered purchase history", userId);
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
     * NEW: Get recommendations by genres from purchased songs
     * More specific than purchase history - focuses only on genre matching
     */
    private List<RecommendedSong> getRecommendationsByPurchasedGenres(Long userId) {
        try {
            List<OrderDTO> orders = commerceServiceClient.getUserOrders(userId);

            // Only DELIVERED orders
            Set<Long> purchasedSongIds = orders.stream()
                    .filter(order -> order.getStatus() != null && "DELIVERED".equals(order.getStatus()))
                    .flatMap(order -> order.getItems().stream())
                    .filter(item -> "SONG".equals(item.getItemType()))
                    .map(OrderItemDTO::getItemId)
                    .collect(Collectors.toSet());

            if (purchasedSongIds.isEmpty()) {
                return new ArrayList<>();
            }

            List<Song> purchasedSongs = songRepository.findAllById(purchasedSongIds);
            Set<Long> favoriteGenres = purchasedSongs.stream()
                    .flatMap(song -> song.getGenreIds().stream())
                    .collect(Collectors.toSet());

            if (favoriteGenres.isEmpty()) {
                return new ArrayList<>();
            }

            // Get songs from favorite genres
            List<Song> recommendations = new ArrayList<>();
            for (Long genreId : favoriteGenres) {
                List<Song> genreSongs = songRepository.findPublishedByGenreId(genreId);
                recommendations.addAll(genreSongs.stream()
                        .filter(song -> !purchasedSongIds.contains(song.getId()))
                        .limit(4)
                        .collect(Collectors.toList()));
            }

            List<Song> limited = recommendations.stream()
                    .distinct()
                    .limit(RECOMMENDATIONS_PER_CATEGORY)
                    .collect(Collectors.toList());

            return enrichWithArtistNames(limited, "Songs from genres you love", 0.88);

        } catch (Exception e) {
            log.warn("Error getting recommendations by purchased genres for user {}", userId, e);
            return new ArrayList<>();
        }
    }

    /**
     * NEW: Get recommendations from artists whose songs the user purchased
     */
    private List<RecommendedSong> getRecommendationsByPurchasedArtists(Long userId) {
        try {
            List<OrderDTO> orders = commerceServiceClient.getUserOrders(userId);

            // Only DELIVERED orders
            Set<Long> purchasedSongIds = orders.stream()
                    .filter(order -> order.getStatus() != null && "DELIVERED".equals(order.getStatus()))
                    .flatMap(order -> order.getItems().stream())
                    .filter(item -> "SONG".equals(item.getItemType()))
                    .map(OrderItemDTO::getItemId)
                    .collect(Collectors.toSet());

            if (purchasedSongIds.isEmpty()) {
                return new ArrayList<>();
            }

            // Get artists from purchased songs
            List<Song> purchasedSongs = songRepository.findAllById(purchasedSongIds);
            Set<Long> purchasedArtistIds = purchasedSongs.stream()
                    .map(Song::getArtistId)
                    .collect(Collectors.toSet());

            // Get other songs from these artists
            List<Song> recommendations = new ArrayList<>();
            for (Long artistId : purchasedArtistIds) {
                List<Song> artistSongs = songRepository.findByArtistId(artistId).stream()
                        .filter(Song::isPublished)
                        .filter(song -> !purchasedSongIds.contains(song.getId()))
                        .limit(3)
                        .collect(Collectors.toList());
                recommendations.addAll(artistSongs);
            }

            List<Song> limited = recommendations.stream()
                    .distinct()
                    .limit(RECOMMENDATIONS_PER_CATEGORY)
                    .collect(Collectors.toList());

            return enrichWithArtistNames(limited, "More from artists you bought", 0.92);

        } catch (Exception e) {
            log.warn("Error getting recommendations by purchased artists for user {}", userId, e);
            return new ArrayList<>();
        }
    }

    /**
     * NEW: Get recommendations based on songs the user liked (4-5 stars ratings)
     */
    private List<RecommendedSong> getRecommendationsByLikedSongs(Long userId) {
        try {
            // Get user's ratings from community-service via REST call
            String url = communityServiceUrl + "/api/ratings/user/" + userId;
            ResponseEntity<List<Map<String, Object>>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Map<String, Object>>>() {}
            );

            if (response.getBody() == null) {
                return new ArrayList<>();
            }

            // Extract song IDs from high ratings (4-5 stars)
            Set<Long> likedSongIds = response.getBody().stream()
                    .filter(rating -> {
                        String entityType = (String) rating.get("entityType");
                        Number ratingValue = (Number) rating.get("rating");
                        return "SONG".equals(entityType) && ratingValue != null && ratingValue.doubleValue() >= 4.0;
                    })
                    .map(rating -> {
                        Number entityId = (Number) rating.get("entityId");
                        return entityId != null ? entityId.longValue() : null;
                    })
                    .filter(Objects::nonNull)
                    .collect(Collectors.toSet());

            if (likedSongIds.isEmpty()) {
                return new ArrayList<>();
            }

            // Get liked songs
            List<Song> likedSongs = songRepository.findAllById(likedSongIds);

            // Get genres from liked songs
            Set<Long> likedGenres = likedSongs.stream()
                    .flatMap(song -> song.getGenreIds().stream())
                    .collect(Collectors.toSet());

            // Recommend songs from same genres
            List<Song> recommendations = new ArrayList<>();
            for (Long genreId : likedGenres) {
                List<Song> genreSongs = songRepository.findPublishedByGenreId(genreId);
                recommendations.addAll(genreSongs.stream()
                        .filter(song -> !likedSongIds.contains(song.getId()))
                        .limit(4)
                        .collect(Collectors.toList()));
            }

            List<Song> limited = recommendations.stream()
                    .distinct()
                    .limit(RECOMMENDATIONS_PER_CATEGORY)
                    .collect(Collectors.toList());

            return enrichWithArtistNames(limited, "Based on songs you liked", 0.90);

        } catch (Exception e) {
            log.warn("Error getting recommendations by liked songs for user {}", userId, e);
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
