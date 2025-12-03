package io.audira.commerce.controller;

import io.audira.commerce.dto.PurchasedItemDTO;
import io.audira.commerce.dto.UserLibraryDTO;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.service.LibraryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Controlador REST para manejar todas las operaciones relacionadas con la Biblioteca de Compras del Usuario.
 * <p>
 * Los endpoints base se mapean a {@code /api/library}. Esta clase permite a los usuarios
 * consultar los artículos que han adquirido. Utiliza {@link LibraryService} para la lógica de negocio.
 * </p>
 *
 * @author Grupo GA01
 * @see LibraryService
 * 
 */
@RestController
@RequestMapping("/api/library")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class LibraryController {

    /**
     * Servicio que contiene la lógica de negocio para la gestión de la biblioteca del usuario.
     * Se inyecta automáticamente gracias a {@link RequiredArgsConstructor} de Lombok.
     */
    private final LibraryService libraryService;

    /**
     * Obtiene la biblioteca completa de un usuario, organizada por tipo de artículo.
     * <p>
     * Mapeo: {@code GET /api/library/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuya biblioteca se desea obtener.
     * @return {@link ResponseEntity} que contiene el objeto {@link UserLibraryDTO} (biblioteca organizada) con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<UserLibraryDTO> getUserLibrary(@PathVariable Long userId) {
        log.info("Request to get library for user: {}", userId);

        UserLibraryDTO library = libraryService.getUserLibrary(userId);
        return ResponseEntity.ok(library);
    }

    /**
     * Obtiene todos los artículos comprados por un usuario en una lista plana.
     * <p>
     * Mapeo: {@code GET /api/library/user/{userId}/items}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) del que se desean obtener los artículos.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link PurchasedItemDTO} con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}/items")
    public ResponseEntity<List<PurchasedItemDTO>> getAllPurchasedItems(@PathVariable Long userId) {
        log.info("Request to get all purchased items for user: {}", userId);

        List<PurchasedItemDTO> items = libraryService.getAllPurchasedItems(userId);
        return ResponseEntity.ok(items);
    }

    /**
     * Obtiene los artículos comprados de un usuario filtrados por un tipo específico.
     * <p>
     * Mapeo: {@code GET /api/library/user/{userId}/items/{itemType}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) del que se desean obtener los artículos.
     * @param itemType El tipo de artículo (ej. SONG, ALBUM) como {@link ItemType}.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link PurchasedItemDTO} filtrada con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}/items/{itemType}")
    public ResponseEntity<List<PurchasedItemDTO>> getPurchasedItemsByType(
            @PathVariable Long userId,
            @PathVariable ItemType itemType) {
        log.info("Request to get purchased {} for user: {}", itemType, userId);

        List<PurchasedItemDTO> items = libraryService.getPurchasedItemsByType(userId, itemType);
        return ResponseEntity.ok(items);
    }

    /**
     * Verifica si un usuario ha comprado un artículo específico.
     * <p>
     * Mapeo: {@code GET /api/library/user/{userId}/check/{itemType}/{itemId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) a verificar.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo (tipo {@link Long}) a verificar.
     * @return {@link ResponseEntity} que contiene {@code true} si el artículo ha sido comprado, {@code false} en caso contrario, con estado HTTP 200 (OK).
     */
    @GetMapping("/user/{userId}/check/{itemType}/{itemId}")
    public ResponseEntity<Boolean> checkIfPurchased(
            @PathVariable Long userId,
            @PathVariable ItemType itemType,
            @PathVariable Long itemId) {
        log.info("Checking if user {} has purchased {}/{}", userId, itemType, itemId);

        boolean purchased = libraryService.hasUserPurchasedItem(userId, itemType, itemId);
        return ResponseEntity.ok(purchased);
    }

    /**
     * Elimina todos los artículos de la biblioteca de un usuario. Usado típicamente para pruebas o administración.
     * <p>
     * Mapeo: {@code DELETE /api/library/user/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuya biblioteca será limpiada.
     * @return {@link ResponseEntity} con estado HTTP 204 (NO CONTENT) si la operación es exitosa.
     */
    @DeleteMapping("/user/{userId}")
    public ResponseEntity<Void> clearUserLibrary(@PathVariable Long userId) {
        log.warn("Request to clear library for user: {}", userId);

        libraryService.clearUserLibrary(userId);
        return ResponseEntity.noContent().build();
    }
}