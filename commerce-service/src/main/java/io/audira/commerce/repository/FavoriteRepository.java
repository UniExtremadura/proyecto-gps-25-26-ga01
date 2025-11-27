package io.audira.commerce.repository;

import io.audira.commerce.model.Favorite;
import io.audira.commerce.model.ItemType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    /**
     * Find all favorites for a user
     */
    List<Favorite> findByUserId(Long userId);

    /**
     * Find all favorites for a user by item type
     */
    List<Favorite> findByUserIdAndItemType(Long userId, ItemType itemType);

    /**
     * Find a specific favorite by user, item type and item id
     */
    Optional<Favorite> findByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Check if a favorite exists
     */
    boolean existsByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Delete a specific favorite
     */
    void deleteByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Delete all favorites for a user
     */
    void deleteByUserId(Long userId);

    /**
     * Count favorites for a user
     */
    long countByUserId(Long userId);

    /**
     * Count favorites for a user by item type
     */
    long countByUserIdAndItemType(Long userId, ItemType itemType);
}
