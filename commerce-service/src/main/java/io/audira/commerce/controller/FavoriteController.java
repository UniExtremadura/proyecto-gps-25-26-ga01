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

/**
 * Controlador REST para manejar todas las operaciones relacionadas con la gestión de favoritos (wishlist).
 * <p>
 * Los endpoints base se mapean a {@code /api/favorites}. Utiliza {@link FavoriteService} para la lógica de negocio.
 * Esta clase también habilita CORS para todas las fuentes ({@code @CrossOrigin(origins = "*")}).
 * </p>
 *
 * @author Grupo GA01
 * @see FavoriteService
 * 
 */
@RestController
@RequestMapping("/api/favorites")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class FavoriteController {

    /**
     * Servicio que contiene la lógica de negocio para la gestión de favoritos.
     * Se inyecta automáticamente gracias a {@link RequiredArgsConstructor} de Lombok.
     */
    private final FavoriteService favoriteService;

    /**
     * Obtiene la lista completa de favoritos de un usuario, organizada por tipo de artículo.
     * <p>
     * Mapeo: {@code GET /api/favorites/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) del que se desean obtener los favoritos.
     * @return {@link ResponseEntity} que contiene el objeto {@link UserFavoritesDTO} (mapa de favoritos organizados) con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<UserFavoritesDTO> getUserFavorites(@PathVariable Long userId) {
        log.info("Request to get favorites for user: {}", userId);

        UserFavoritesDTO favorites = favoriteService.getUserFavorites(userId);
        return ResponseEntity.ok(favorites);
    }

    /**
     * Obtiene todos los favoritos de un usuario en una lista plana.
     * <p>
     * Mapeo: {@code GET /api/favorites/user/{userId}/items}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) del que se desean obtener los favoritos.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link FavoriteDTO} con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}/items")
    public ResponseEntity<List<FavoriteDTO>> getAllFavorites(@PathVariable Long userId) {
        log.info("Request to get all favorites for user: {}", userId);

        List<FavoriteDTO> favorites = favoriteService.getAllFavorites(userId);
        return ResponseEntity.ok(favorites);
    }

    /**
     * Obtiene los favoritos de un usuario filtrados por un tipo de artículo específico.
     * <p>
     * Mapeo: {@code GET /api/favorites/user/{userId}/items/{itemType}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) del que se desean obtener los favoritos.
     * @param itemType El tipo de artículo (ej. SONG, ALBUM, ARTIST) como {@link ItemType}.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link FavoriteDTO} filtrada con estado HTTP 200 (OK).
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
     * Verifica si un usuario ha marcado un artículo específico como favorito.
     * <p>
     * Mapeo: {@code GET /api/favorites/user/{userId}/check/{itemType}/{itemId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) a verificar.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo (tipo {@link Long}) a verificar.
     * @return {@link ResponseEntity} que contiene {@code true} si es favorito, {@code false} en caso contrario, con estado HTTP 200 (OK).
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
     * Agrega un artículo a la lista de favoritos del usuario.
     * <p>
     * Mapeo: {@code POST /api/favorites/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) al que se añadirá el favorito.
     * @param request Cuerpo de la solicitud que contiene {@code itemType} (String) y {@code itemId} (Long).
     * @return {@link ResponseEntity} que contiene el objeto {@link FavoriteDTO} recién creado, con estado HTTP 201 (CREATED).
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
     * Elimina un artículo de la lista de favoritos del usuario.
     * <p>
     * Mapeo: {@code DELETE /api/favorites/user/{userId}/{itemType}/{itemId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) del que se eliminará el favorito.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo (tipo {@link Long}) a eliminar.
     * @return {@link ResponseEntity} con estado HTTP 204 (NO CONTENT) si la eliminación es exitosa.
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
     * Alterna el estado de favorito de un artículo: lo agrega si no existe, o lo elimina si ya es favorito.
     * <p>
     * Mapeo: {@code POST /api/favorites/user/{userId}/toggle}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) para el que se alternará el estado.
     * @param request Cuerpo de la solicitud que contiene {@code itemType} (String) y {@code itemId} (Long).
     * @return {@link ResponseEntity} que contiene un mapa con la clave {@code isFavorite} y un valor booleano ({@code true} si ahora es favorito, {@code false} si fue eliminado), con estado HTTP 200 (OK).
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
     * Obtiene el número total de favoritos que tiene un usuario.
     * <p>
     * Mapeo: {@code GET /api/favorites/user/{userId}/count}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) para el que se contará.
     * @return {@link ResponseEntity} que contiene el conteo total (tipo {@link Long}) con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}/count")
    public ResponseEntity<Long> getFavoriteCount(@PathVariable Long userId) {
        log.info("Request to get favorite count for user: {}", userId);

        long count = favoriteService.getFavoriteCount(userId);
        return ResponseEntity.ok(count);
    }

    /**
     * Obtiene el número de favoritos que tiene un usuario para un tipo de artículo específico.
     * <p>
     * Mapeo: {@code GET /api/favorites/user/{userId}/count/{itemType}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) para el que se contará.
     * @param itemType El tipo de artículo ({@link ItemType}) a contar.
     * @return {@link ResponseEntity} que contiene el conteo (tipo {@link Long}) con estado HTTP 200 (OK).
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
     * Elimina todos los favoritos de un usuario. Usado típicamente para pruebas o administración.
     * <p>
     * Mapeo: {@code DELETE /api/favorites/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyos favoritos serán eliminados.
     * @return {@link ResponseEntity} con estado HTTP 204 (NO CONTENT) si la operación es exitosa.
     */
    @DeleteMapping("/user/{userId}")
    public ResponseEntity<Void> clearUserFavorites(@PathVariable Long userId) {
        log.warn("Request to clear all favorites for user: {}", userId);

        favoriteService.clearUserFavorites(userId);
        return ResponseEntity.noContent().build();
    }
}