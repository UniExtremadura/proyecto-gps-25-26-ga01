package io.audira.commerce.service;

import io.audira.commerce.client.MusicCatalogClient;
import io.audira.commerce.dto.PurchasedItemDTO;
import io.audira.commerce.dto.UserLibraryDTO;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderItem;
import io.audira.commerce.model.PurchasedItem;
import io.audira.commerce.repository.PurchasedItemRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class LibraryService {

    private final PurchasedItemRepository purchasedItemRepository;
    private final MusicCatalogClient musicCatalogClient;

    /**
     * Get user's complete library organized by item type
     */
    @Transactional(readOnly = true)
    public UserLibraryDTO getUserLibrary(Long userId) {
        log.info("Getting library for user: {}", userId);

        List<PurchasedItem> allItems = purchasedItemRepository.findByUserId(userId);
        UserLibraryDTO library = new UserLibraryDTO(userId);

        for (PurchasedItem item : allItems) {
            PurchasedItemDTO dto = PurchasedItemDTO.fromEntity(item);

            switch (item.getItemType()) {
                case SONG:
                    library.addSong(dto);
                    break;
                case ALBUM:
                    library.addAlbum(dto);
                    break;
                case MERCHANDISE:
                    library.addMerchandise(dto);
                    break;
            }
        }

        log.info("Found {} items in library for user {}", library.getTotalItems(), userId);
        return library;
    }

    /**
     * Get all purchased items for a user
     */
    @Transactional(readOnly = true)
    public List<PurchasedItemDTO> getAllPurchasedItems(Long userId) {
        log.info("Getting all purchased items for user: {}", userId);

        return purchasedItemRepository.findByUserId(userId)
            .stream()
            .map(PurchasedItemDTO::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Get purchased items of a specific type
     */
    @Transactional(readOnly = true)
    public List<PurchasedItemDTO> getPurchasedItemsByType(Long userId, ItemType itemType) {
        log.info("Getting purchased {} for user: {}", itemType, userId);

        return purchasedItemRepository.findByUserIdAndItemType(userId, itemType)
            .stream()
            .map(PurchasedItemDTO::fromEntity)
            .collect(Collectors.toList());
    }

    /**
     * Check if user has purchased a specific item
     */
    @Transactional(readOnly = true)
    public boolean hasUserPurchasedItem(Long userId, ItemType itemType, Long itemId) {
        boolean purchased = purchasedItemRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId);
        log.debug("User {} {} purchased {}/{}", userId, purchased ? "has" : "has not", itemType, itemId);
        return purchased;
    }

    /**
     * Add items from a completed order to user's library
     * This should be called when a payment is completed successfully
     * When an album is purchased, all its songs are also added to the library
     */
    @Transactional
    public void addOrderToLibrary(Order order, Long paymentId) {
        log.info("Adding order {} items to library for user {}", order.getId(), order.getUserId());

        for (OrderItem orderItem : order.getItems()) {
            // Add the purchased item itself (album, song, or merchandise)
            addItemToLibrary(order.getUserId(), orderItem, order.getId(), paymentId);

            // If it's an album, also add all its songs to the library
            if (orderItem.getItemType() == ItemType.ALBUM) {
                addAlbumSongsToLibrary(order.getUserId(), orderItem.getItemId(), order.getId(), paymentId);
            }
        }

        log.info("Finished adding order {} to library", order.getId());
    }

    /**
     * Add a single item to the library
     */
    private void addItemToLibrary(Long userId, OrderItem orderItem, Long orderId, Long paymentId) {
        // Check if already exists (avoid duplicates)
        boolean exists = purchasedItemRepository.existsByUserIdAndItemTypeAndItemId(
            userId,
            orderItem.getItemType(),
            orderItem.getItemId()
        );

        if (!exists) {
            PurchasedItem purchasedItem = new PurchasedItem(
                userId,
                orderItem.getItemType(),
                orderItem.getItemId(),
                orderId,
                paymentId,
                orderItem.getPrice(),
                orderItem.getQuantity()
            );

            purchasedItemRepository.save(purchasedItem);
            log.info("Added {} {} to library for user {}",
                orderItem.getItemType(), orderItem.getItemId(), userId);
        } else {
            log.debug("Item {}/{} already in library for user {}",
                orderItem.getItemType(), orderItem.getItemId(), userId);
        }
    }

    /**
     * Add all songs from an album to the user's library
     */
    private void addAlbumSongsToLibrary(Long userId, Long albumId, Long orderId, Long paymentId) {
        try {
            log.info("Fetching songs for album {} to add to user {} library", albumId, userId);

            List<Long> songIds = musicCatalogClient.getSongIdsByAlbum(albumId);

            if (songIds.isEmpty()) {
                log.warn("No songs found for album {}. The album might be empty.", albumId);
                return;
            }

            log.info("Found {} songs in album {}. Adding them to user {} library",
                songIds.size(), albumId, userId);

            for (Long songId : songIds) {
                // Check if song is already in library
                boolean exists = purchasedItemRepository.existsByUserIdAndItemTypeAndItemId(
                    userId,
                    ItemType.SONG,
                    songId
                );

                if (!exists) {
                    PurchasedItem purchasedItem = new PurchasedItem(
                        userId,
                        ItemType.SONG,
                        songId,
                        orderId,
                        paymentId,
                        BigDecimal.ZERO,  // Individual songs from album purchase have no separate price
                        1
                    );

                    purchasedItemRepository.save(purchasedItem);
                    log.debug("Added song {} from album {} to library for user {}", songId, albumId, userId);
                } else {
                    log.debug("Song {} from album {} already in library for user {}", songId, albumId, userId);
                }
            }

            log.info("Successfully added {} songs from album {} to user {} library",
                songIds.size(), albumId, userId);

        } catch (Exception e) {
            log.error("Error adding songs from album {} to user {} library: {}",
                albumId, userId, e.getMessage(), e);
            // Don't throw exception - the album purchase itself was successful
            // User can still access the album even if individual songs weren't added
        }
    }

    /**
     * Delete all library items for a user (admin/testing purposes)
     */
    @Transactional
    public void clearUserLibrary(Long userId) {
        log.warn("Clearing all library items for user: {}", userId);
        purchasedItemRepository.deleteByUserId(userId);
    }
}
