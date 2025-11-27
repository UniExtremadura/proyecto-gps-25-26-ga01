package io.audira.commerce.controller;

import io.audira.commerce.dto.FavoriteDTO;
import io.audira.commerce.dto.UserFavoritesDTO;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/favorites")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class FavoriteController {

    private final FavoriteService favoriteService;

    /**
     * Get user's complete favorites organized by type
     * GET /api/favorites/user/{userId}
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<UserFavoritesDTO> getUserFavorites(@PathVariable Long userId) {
        log.info("Request to get favorites for user: {}", userId);

        UserFavoritesDTO favorites = favoriteService.getUserFavorites(userId);
        return ResponseEntity.ok(favorites);
    }

    /**
     * Get all favorites for a user (flat list)
     * GET /api/favorites/user/{userId}/items
     */
    @GetMapping("/user/{userId}/items")
    public ResponseEntity<List<FavoriteDTO>> getAllFavorites(@PathVariable Long userId) {
        log.info("Request to get all favorites for user: {}", userId);

        List<FavoriteDTO> favorites = favoriteService.getAllFavorites(userId);
        return ResponseEntity.ok(favorites);
    }

    /**
     * Get favorites of a specific type
     * GET /api/favorites/user/{userId}/items/{itemType}
     */
    @GetMapping("/user/{userId}/items/{itemType}")
    public ResponseEntity<List<FavoriteDTO>> getFavoritesByType(
            @PathVariable Long userId,
            @PathVariable ItemType itemType) {
        log.info("Request to get favorite {} for user: {}", itemType, userId);

        List<FavoriteDTO> favorites = favoriteService.getFavoritesByType(userId, itemType);
        return ResponseEntity.ok(favorites);
    }

    /**
     * Check if user has favorited a specific item
     * GET /api/favorites/user/{userId}/check/{itemType}/{itemId}
     */
    @GetMapping("/user/{userId}/check/{itemType}/{itemId}")
    public ResponseEntity<Boolean> checkIfFavorite(
            @PathVariable Long userId,
            @PathVariable ItemType itemType,
            @PathVariable Long itemId) {
        log.info("Checking if user {} has favorited {}/{}", userId, itemType, itemId);

        boolean favorite = favoriteService.isFavorite(userId, itemType, itemId);
        return ResponseEntity.ok(favorite);
    }

    /**
     * Add an item to favorites
     * POST /api/favorites/user/{userId}
     * Body: { "itemType": "SONG", "itemId": 123 }
     */
    @PostMapping("/user/{userId}")
    public ResponseEntity<FavoriteDTO> addFavorite(
            @PathVariable Long userId,
            @RequestBody Map<String, Object> request) {
        ItemType itemType = ItemType.valueOf((String) request.get("itemType"));
        Long itemId = Long.valueOf(request.get("itemId").toString());

        log.info("Request to add {}/{} to favorites for user: {}", itemType, itemId, userId);

        FavoriteDTO favorite = favoriteService.addFavorite(userId, itemType, itemId);
        return ResponseEntity.status(HttpStatus.CREATED).body(favorite);
    }

    /**
     * Remove an item from favorites
     * DELETE /api/favorites/user/{userId}/{itemType}/{itemId}
     */
    @DeleteMapping("/user/{userId}/{itemType}/{itemId}")
    public ResponseEntity<Void> removeFavorite(
            @PathVariable Long userId,
            @PathVariable ItemType itemType,
            @PathVariable Long itemId) {
        log.info("Request to remove {}/{} from favorites for user: {}", itemType, itemId, userId);

        favoriteService.removeFavorite(userId, itemType, itemId);
        return ResponseEntity.noContent().build();
    }

    /**
     * Toggle favorite status (add if not exists, remove if exists)
     * POST /api/favorites/user/{userId}/toggle
     * Body: { "itemType": "SONG", "itemId": 123 }
     */
    @PostMapping("/user/{userId}/toggle")
    public ResponseEntity<Map<String, Boolean>> toggleFavorite(
            @PathVariable Long userId,
            @RequestBody Map<String, Object> request) {
        ItemType itemType = ItemType.valueOf((String) request.get("itemType"));
        Long itemId = Long.valueOf(request.get("itemId").toString());

        log.info("Request to toggle favorite {}/{} for user: {}", itemType, itemId, userId);

        boolean isFavorite = favoriteService.toggleFavorite(userId, itemType, itemId);
        return ResponseEntity.ok(Map.of("isFavorite", isFavorite));
    }

    /**
     * Get favorite count for a user
     * GET /api/favorites/user/{userId}/count
     */
    @GetMapping("/user/{userId}/count")
    public ResponseEntity<Long> getFavoriteCount(@PathVariable Long userId) {
        log.info("Request to get favorite count for user: {}", userId);

        long count = favoriteService.getFavoriteCount(userId);
        return ResponseEntity.ok(count);
    }

    /**
     * Get favorite count by type
     * GET /api/favorites/user/{userId}/count/{itemType}
     */
    @GetMapping("/user/{userId}/count/{itemType}")
    public ResponseEntity<Long> getFavoriteCountByType(
            @PathVariable Long userId,
            @PathVariable ItemType itemType) {
        log.info("Request to get favorite {} count for user: {}", itemType, userId);

        long count = favoriteService.getFavoriteCountByType(userId, itemType);
        return ResponseEntity.ok(count);
    }

    /**
     * Clear all favorites for a user (for testing/admin purposes)
     * DELETE /api/favorites/user/{userId}
     */
    @DeleteMapping("/user/{userId}")
    public ResponseEntity<Void> clearUserFavorites(@PathVariable Long userId) {
        log.warn("Request to clear all favorites for user: {}", userId);

        favoriteService.clearUserFavorites(userId);
        return ResponseEntity.noContent().build();
    }
}
