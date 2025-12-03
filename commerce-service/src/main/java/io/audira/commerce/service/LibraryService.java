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

/**
 * Servicio de lógica de negocio responsable de gestionar la Biblioteca Digital de Artículos Comprados (Library) de los usuarios.
 * <p>
 * Este servicio controla qué artículos (canciones, álbumes, mercancía) posee un usuario y gestiona
 * el proceso de adición de ítems tras una compra exitosa, incluyendo la lógica de desagregación de álbumes.
 * </p>
 *
 * @author Grupo GA01
 * @see PurchasedItemRepository
 * @see MusicCatalogClient
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LibraryService {

    private final PurchasedItemRepository purchasedItemRepository;
    private final MusicCatalogClient musicCatalogClient;

    /**
     * Obtiene la biblioteca completa de un usuario, organizada por tipo de artículo.
     * <p>
     * Se consulta la base de datos por todos los artículos comprados y se mapean a la estructura categorizada {@link UserLibraryDTO}.
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}).
     * @return El objeto {@link UserLibraryDTO} con los artículos clasificados.
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
     * Obtiene todos los artículos comprados por un usuario en una lista plana.
     *
     * @param userId El ID del usuario.
     * @return Una {@link List} plana de objetos {@link PurchasedItemDTO}.
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
     * Obtiene los artículos comprados de un usuario, filtrados por un tipo de artículo específico.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}) por el cual filtrar.
     * @return Una {@link List} de objetos {@link PurchasedItemDTO} filtrada.
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
     * Verifica si un usuario ya ha adquirido un artículo específico.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo.
     * @param itemId El ID del artículo.
     * @return {@code true} si el artículo ha sido comprado, {@code false} en caso contrario.
     */
    @Transactional(readOnly = true)
    public boolean hasUserPurchasedItem(Long userId, ItemType itemType, Long itemId) {
        boolean purchased = purchasedItemRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId);
        log.debug("User {} {} purchased {}/{}", userId, purchased ? "has" : "has not", itemType, itemId);
        return purchased;
    }

    /**
     * Procesa una orden completada y añade todos los artículos de dicha orden a la biblioteca del usuario.
     * <p>
     * Este método debe ser llamado solo después de que el pago asociado ha sido confirmado como exitoso.
     * Lógica clave: Si se compra un {@code ItemType.ALBUM}, también se añaden todas las canciones individuales del álbum a la biblioteca.
     * </p>
     *
     * @param order La entidad {@link Order} completada.
     * @param paymentId El ID del registro de pago asociado a la transacción.
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
     * Añade un único artículo de orden a la biblioteca, siempre y cuando no exista ya.
     *
     * @param userId El ID del usuario.
     * @param orderItem El artículo de orden ({@link OrderItem}) a registrar.
     * @param orderId ID de la orden.
     * @param paymentId ID del pago.
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
     * Obtiene la lista de canciones de un álbum (a través del {@link MusicCatalogClient}) y las añade individualmente a la biblioteca del usuario.
     * <p>
     * Las canciones individuales añadidas de un álbum tienen un precio de {@code BigDecimal.ZERO} para reflejar que el costo ya fue cubierto por el álbum.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param albumId El ID del álbum en el catálogo.
     * @param orderId ID de la orden.
     * @param paymentId ID del pago.
     */
    private void addAlbumSongsToLibrary(Long userId, Long albumId, Long orderId, Long paymentId) {
        try {
            log.info("Fetching songs for album {} to add to user {} library", albumId, userId);

            // Comunicación con el microservicio de Catálogo
            List<Long> songIds = musicCatalogClient.getSongIdsByAlbum(albumId);

            if (songIds.isEmpty()) {
                log.warn("No songs found for album {}. The album might be empty.", albumId);
                return;
            }

            log.info("Found {} songs in album {}. Adding them to user {} library",
                songIds.size(), albumId, userId);

            for (Long songId : songIds) {
                // Check if song is already in library (ej. si fue comprada individualmente antes)
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
            // El fallo de un proceso auxiliar (como esta desagregación) no debe revertir la transacción principal de la compra.
        }
    }

    /**
     * Elimina todos los registros de artículos comprados de un usuario.
     * <p>
     * Utilizado para propósitos administrativos o de prueba.
     * </p>
     *
     * @param userId El ID del usuario cuya biblioteca será eliminada.
     */
    @Transactional
    public void clearUserLibrary(Long userId) {
        log.warn("Clearing all library items for user: {}", userId);
        purchasedItemRepository.deleteByUserId(userId);
    }
}