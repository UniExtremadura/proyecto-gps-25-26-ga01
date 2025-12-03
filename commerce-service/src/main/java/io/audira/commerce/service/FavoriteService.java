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

/**
 * Servicio de lógica de negocio responsable de gestionar la lista de favoritos (wishlist) de los usuarios.
 * <p>
 * Implementa las operaciones CRUD, conteo y consulta para la entidad {@link Favorite},
 * asegurando la unicidad de los registros por usuario y artículo.
 * </p>
 *
 * @author Grupo GA01
 * @see FavoriteRepository
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;

    /**
     * Obtiene todos los favoritos de un usuario, organizados por tipo de artículo.
     * <p>
     * La consulta se realiza en la base de datos y los resultados se mapean y categorizan en un objeto {@link UserFavoritesDTO}.
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}).
     * @return El objeto {@link UserFavoritesDTO} con las listas de favoritos categorizadas.
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
     * Obtiene todos los favoritos de un usuario en una lista plana (sin categorizar).
     *
     * @param userId El ID del usuario.
     * @return Una {@link List} plana de objetos {@link FavoriteDTO}.
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
     * Obtiene los favoritos de un usuario filtrados por un tipo de artículo específico.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}) por el cual filtrar.
     * @return Una {@link List} de objetos {@link FavoriteDTO} que coinciden con el tipo.
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
     * Verifica si un artículo específico ya ha sido marcado como favorito por un usuario.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo.
     * @param itemId El ID del artículo.
     * @return {@code true} si el artículo es favorito, {@code false} en caso contrario.
     */
    @Transactional(readOnly = true)
    public boolean isFavorite(Long userId, ItemType itemType, Long itemId) {
        boolean favorite = favoriteRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId);
        log.debug("User {} {} favorited {}/{}", userId, favorite ? "has" : "has not", itemType, itemId);
        return favorite;
    }

    /**
     * Agrega un artículo a la lista de favoritos del usuario.
     * <p>
     * Si el artículo ya existe, simplemente retorna el registro existente.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo.
     * @param itemId El ID del artículo.
     * @return El objeto {@link FavoriteDTO} creado o existente.
     */
    @Transactional
    public FavoriteDTO addFavorite(Long userId, ItemType itemType, Long itemId) {
        log.info("Adding {}/{} to favorites for user {}", itemType, itemId, userId);

        // Check if already exists
        if (favoriteRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId)) {
            log.debug("Item {}/{} already in favorites for user {}", itemType, itemId, userId);
            // Si existe, lo recuperamos y lo devolvemos
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
     * Elimina un artículo de la lista de favoritos del usuario.
     * <p>
     * Utiliza el método de eliminación por clave compuesta del repositorio.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo.
     * @param itemId El ID del artículo.
     */
    @Transactional
    public void removeFavorite(Long userId, ItemType itemType, Long itemId) {
        log.info("Removing {}/{} from favorites for user {}", itemType, itemId, userId);

        favoriteRepository.deleteByUserIdAndItemTypeAndItemId(userId, itemType, itemId);

        log.info("Removed {}/{} from favorites for user {}", itemType, itemId, userId);
    }

    /**
     * Alterna el estado de favorito de un artículo: lo agrega si no existe, o lo elimina si ya es favorito.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo.
     * @param itemId El ID del artículo.
     * @return {@code true} si el artículo es ahora favorito (fue añadido), {@code false} si ya no lo es (fue eliminado).
     */
    @Transactional
    public boolean toggleFavorite(Long userId, ItemType itemType, Long itemId) {
        log.info("Toggling favorite {}/{} for user {}", itemType, itemId, userId);

        boolean exists = favoriteRepository.existsByUserIdAndItemTypeAndItemId(userId, itemType, itemId);

        if (exists) {
            favoriteRepository.deleteByUserIdAndItemTypeAndItemId(userId, itemType, itemId);
            log.info("Removed {}/{} from favorites for user {}", itemType, itemId, userId);
            return false; // Ahora no es un favorito
        } else {
            Favorite favorite = new Favorite(userId, itemType, itemId);
            favoriteRepository.save(favorite);
            log.info("Added {}/{} to favorites for user {}", itemType, itemId, userId);
            return true; // Ahora es un favorito
        }
    }

    /**
     * Obtiene el número total de artículos en la lista de favoritos de un usuario.
     *
     * @param userId El ID del usuario.
     * @return El conteo total (tipo {@code long}).
     */
    @Transactional(readOnly = true)
    public long getFavoriteCount(Long userId) {
        return favoriteRepository.countByUserId(userId);
    }

    /**
     * Obtiene el número de favoritos de un tipo específico para un usuario.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo a contar.
     * @return El conteo total por tipo (tipo {@code long}).
     */
    @Transactional(readOnly = true)
    public long getFavoriteCountByType(Long userId, ItemType itemType) {
        return favoriteRepository.countByUserIdAndItemType(userId, itemType);
    }

    /**
     * Elimina todos los registros de favoritos de un usuario.
     * <p>
     * Utilizado para propósitos administrativos o de prueba.
     * </p>
     *
     * @param userId El ID del usuario cuyos favoritos serán eliminados.
     */
    @Transactional
    public void clearUserFavorites(Long userId) {
        log.warn("Clearing all favorites for user: {}", userId);
        favoriteRepository.deleteByUserId(userId);
    }
}