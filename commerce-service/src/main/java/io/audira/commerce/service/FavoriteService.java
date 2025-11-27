package io.audira.commerce.service;

import io.audira.commerce.dto.FavoriteDTO;
import io.audira.commerce.dto.UserFavoritesDTO;
import io.audira.commerce.model.Favorite;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.repository.FavoriteRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;

    /**
     * Get all favorites for a user organized by type
     */
    @Transactional(readOnly = true)
    public UserFavoritesDTO getUserFavorites(Long userId) {
        log.info("Getting favorites for user: {}", userId);

        List<Favorite> allFavorites = favoriteRepository.findByUserId(userId);
        UserFavoritesDTO favorites = new UserFavoritesDTO(userId);

        for (Favorite favorite : allFavorites) {
            FavoriteDTO dto = FavoriteDTO.fromEntity(favorite);

            switch (favorite.getItemType()) {
                case SONG:
                    favorites.addSong(dto);
                    break;
                case ALBUM:
                    favorites.addAlbum(dto);
                    break;
                case MERCHANDISE:
                    favorites.addMerchandise(dto);
                    break;
            }
        }

        log.info("Found {} favorites for user {}", favorites.getTotalFavorites(), userId);
        return favorites;
    }

    /**
     * Get all favorites for a user (flat list)
     */
    @Transactional(readOnly = true)
    public List<FavoriteDTO> getAllFavorites(Long userId) {
        log.info("Getting all favorites for user: {}", userId);

        return favoriteRepository.findByUserId(userId)
            .stream()
            .map(FavoriteDTO::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Get favorites of a specific type
     */
    @Transactional(readOnly = true)
    public List<FavoriteDTO> getFavoritesByType(Long userId, ItemType itemType) {
        log.info("Getting favorite {} for user: {}", itemType, userId);

        return favoriteRepository.findByUserIdAndItemType(userId, itemType)
            .stream()
            .map(FavoriteDTO::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Check if an item is favorited
     */
    @Transactional(readOnly = true)
    public boolean isFavorite(Long userId, ItemType itemType, Long itemId) {
        boolean favorite = favoriteRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId);
        log.debug("User {} {} favorited {}/{}", userId, favorite ? "has" : "has not", itemType, itemId);
        return favorite;
    }

    /**
     * Add an item to favorites
     */
    @Transactional
    public FavoriteDTO addFavorite(Long userId, ItemType itemType, Long itemId) {
        log.info("Adding {}/{} to favorites for user {}", itemType, itemId, userId);

        // Check if already exists
        if (favoriteRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId)) {
            log.debug("Item {}/{} already in favorites for user {}", itemType, itemId, userId);
            return favoriteRepository.findByUserIdAndItemTypeAndItemId(userId, itemType, itemId)
                .map(FavoriteDTO::fromEntity)
                .orElseThrow();
        }

        Favorite favorite = new Favorite(userId, itemType, itemId);
        Favorite saved = favoriteRepository.save(favorite);

        log.info("Added {}/{} to favorites for user {}", itemType, itemId, userId);
        return FavoriteDTO.fromEntity(saved);
    }

    /**
     * Remove an item from favorites
     */
    @Transactional
    public void removeFavorite(Long userId, ItemType itemType, Long itemId) {
        log.info("Removing {}/{} from favorites for user {}", itemType, itemId, userId);

        favoriteRepository.deleteByUserIdAndItemTypeAndItemId(userId, itemType, itemId);

        log.info("Removed {}/{} from favorites for user {}", itemType, itemId, userId);
    }

    /**
     * Toggle favorite status (add if not exists, remove if exists)
     */
    @Transactional
    public boolean toggleFavorite(Long userId, ItemType itemType, Long itemId) {
        log.info("Toggling favorite {}/{} for user {}", itemType, itemId, userId);

        boolean exists = favoriteRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId);

        if (exists) {
            favoriteRepository.deleteByUserIdAndItemTypeAndItemId(userId, itemType, itemId);
            log.info("Removed {}/{} from favorites for user {}", itemType, itemId, userId);
            return false; // Now not a favorite
        } else {
            Favorite favorite = new Favorite(userId, itemType, itemId);
            favoriteRepository.save(favorite);
            log.info("Added {}/{} to favorites for user {}", itemType, itemId, userId);
            return true; // Now is a favorite
        }
    }

    /**
     * Get favorite count for a user
     */
    @Transactional(readOnly = true)
    public long getFavoriteCount(Long userId) {
        return favoriteRepository.countByUserId(userId);
    }

    /**
     * Get favorite count by type
     */
    @Transactional(readOnly = true)
    public long getFavoriteCountByType(Long userId, ItemType itemType) {
        return favoriteRepository.countByUserIdAndItemType(userId, itemType);
    }

    /**
     * Clear all favorites for a user (admin/testing purposes)
     */
    @Transactional
    public void clearUserFavorites(Long userId) {
        log.warn("Clearing all favorites for user: {}", userId);
        favoriteRepository.deleteByUserId(userId);
    }
}
