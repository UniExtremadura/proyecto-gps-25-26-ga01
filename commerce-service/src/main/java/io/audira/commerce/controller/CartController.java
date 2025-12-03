package io.audira.commerce.controller;

import io.audira.commerce.dto.CartDTO;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.service.CartService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

/**
 * Controlador REST para manejar todas las operaciones relacionadas con el carrito de compras (Cart).
 * <p>
 * Los endpoints base se mapean a {@code /api/cart}. Utiliza {@link CartService} para la lógica de negocio.
 * </p>
 *
 * @author Grupo GA01
 * @see CartService
 * 
 */
@RestController
@RequestMapping("/api/cart")
@RequiredArgsConstructor
public class CartController {

    /**
     * Servicio que contiene la lógica de negocio para la manipulación del carrito.
     * Se inyecta automáticamente gracias a {@link RequiredArgsConstructor} de Lombok.
     */
    private final CartService cartService;

    /**
     * Obtiene el carrito de compras actual para un usuario específico.
     * <p>
     * Mapeo: {@code GET /api/cart/{userId}}
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyo carrito se desea obtener.
     * @return {@link ResponseEntity} que contiene el objeto {@link CartDTO} del usuario con el estado HTTP 200 (OK).
     */
    @GetMapping("/{userId}")
    public ResponseEntity<CartDTO> getCart(@PathVariable Long userId) {
        CartDTO cart = cartService.getCartByUserId(userId);
        return ResponseEntity.ok(cart);
    }

    /**
     * Agrega un nuevo artículo al carrito de compras de un usuario.
     * <p>
     * Mapeo: {@code POST /api/cart/{userId}/items}
     * Si el artículo ya existe, generalmente se incrementa la cantidad (lógica definida en {@link CartService}).
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) al que se añadirá el artículo.
     * @param itemType Tipo de artículo (como String, ej. "ALBUM", "SONG"). Se mapea a {@link ItemType}.
     * @param itemId ID único del artículo (tipo {@link Long}) que se desea añadir.
     * @param price Precio del artículo (tipo {@link BigDecimal}).
     * @param quantity Cantidad de unidades a añadir (por defecto es 1).
     * @return {@link ResponseEntity} que contiene el carrito actualizado ({@link CartDTO}) con el estado HTTP 200 (OK).
     */
    @PostMapping("/{userId}/items")
    public ResponseEntity<CartDTO> addToCart(
            @PathVariable Long userId,
            @RequestParam String itemType,
            @RequestParam Long itemId,
            @RequestParam BigDecimal price,
            @RequestParam(defaultValue = "1") Integer quantity) {

        ItemType type = ItemType.valueOf(itemType);
        CartDTO cart = cartService.addItemToCart(userId, type, itemId, price, quantity);
        return ResponseEntity.ok(cart);
    }

    /**
     * Actualiza la cantidad de un artículo existente en el carrito.
     * <p>
     * Mapeo: {@code PUT /api/cart/{userId}/items/{itemId}}
     * Si {@code quantity} es cero o negativo, la lógica de negocio podría eliminar el artículo.
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) dueño del carrito.
     * @param itemId ID del artículo (tipo {@link Long}) cuya cantidad se va a modificar.
     * @param quantity Nueva cantidad total del artículo en el carrito.
     * @return {@link ResponseEntity} que contiene el carrito actualizado ({@link CartDTO}) con el estado HTTP 200 (OK).
     */
    @PutMapping("/{userId}/items/{itemId}")
    public ResponseEntity<CartDTO> updateCartItem(
            @PathVariable Long userId,
            @PathVariable Long itemId,
            @RequestParam Integer quantity) {

        CartDTO cart = cartService.updateCartItemQuantity(userId, itemId, quantity);
        return ResponseEntity.ok(cart);
    }

    /**
     * Elimina un artículo específico del carrito de compras.
     * <p>
     * Mapeo: {@code DELETE /api/cart/{userId}/items/{itemId}}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) dueño del carrito.
     * @param itemId ID del artículo (tipo {@link Long}) a eliminar.
     * @return {@link ResponseEntity} que contiene el carrito actualizado ({@link CartDTO}) con el estado HTTP 200 (OK).
     */
    @DeleteMapping("/{userId}/items/{itemId}")
    public ResponseEntity<CartDTO> removeFromCart(
            @PathVariable Long userId,
            @PathVariable Long itemId) {

        CartDTO cart = cartService.removeItemFromCart(userId, itemId);
        return ResponseEntity.ok(cart);
    }

    /**
     * Vacía completamente el carrito de compras de un usuario, eliminando todos los artículos.
     * <p>
     * Mapeo: {@code DELETE /api/cart/{userId}}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) cuyo carrito se vaciará.
     * @return {@link ResponseEntity} con estado HTTP 200 (OK) sin contenido ({@code Void}).
     */
    @DeleteMapping("/{userId}")
    public ResponseEntity<Void> clearCart(@PathVariable Long userId) {
        cartService.clearCart(userId);
        return ResponseEntity.ok().build();
    }

    /**
     * Obtiene el número total de artículos únicos o el total de la suma de cantidades en el carrito.
     * <p>
     * Mapeo: {@code GET /api/cart/{userId}/count}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) cuyo carrito se va a contar.
     * @return {@link ResponseEntity} que contiene el conteo de artículos ({@link Integer}) con el estado HTTP 200 (OK).
     */
    @GetMapping("/{userId}/count")
    public ResponseEntity<Integer> getCartCount(@PathVariable Long userId) {
        Integer count = cartService.getCartItemCount(userId);
        return ResponseEntity.ok(count);
    }
}