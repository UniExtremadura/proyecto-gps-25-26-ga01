package io.audira.commerce.service;

import io.audira.commerce.dto.CartDTO;
import io.audira.commerce.dto.CartItemDTO;
import io.audira.commerce.model.Cart;
import io.audira.commerce.model.CartItem;
import io.audira.commerce.model.ItemType;
import io.audira.commerce.repository.CartRepository;
import io.audira.commerce.repository.CartItemRepository;
import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Servicio de lógica de negocio responsable de gestionar el ciclo de vida del carrito de compras ({@link Cart}).
 * <p>
 * Implementa las operaciones CRUD para el carrito y sus artículos ({@link CartItem}),
 * gestionando la lógica de duplicados para productos digitales y el recálculo del total.
 * </p>
 *
 * @author Grupo GA01
 * @see CartRepository
 * @see CartItemRepository
 * 
 */
@Service
@RequiredArgsConstructor
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final EntityManager entityManager;

    /**
     * Obtiene el carrito de compras de un usuario por su ID. Si no existe, crea un nuevo carrito.
     *
     * @param userId El ID del usuario (tipo {@link Long}).
     * @return El objeto {@link CartDTO} del usuario.
     */
    @Transactional
    public CartDTO getCartByUserId(Long userId) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseGet(() -> createNewCart(userId));
        return mapToDTO(cart);
    }

    /**
     * Añade un artículo al carrito de un usuario.
     * <p>
     * Lógica de manejo:
     * <ul>
     * <li>Si el carrito no existe, se crea.</li>
     * <li>Si el artículo ya existe:
     * <ul>
     * <li>Para productos digitales (SONG, ALBUM), lanza una {@link RuntimeException}.</li>
     * <li>Para otros productos (MERCHANDISE), incrementa la cantidad.</li>
     * </ul>
     * <li>Tras la adición/actualización, recarga el carrito y recalcula el monto total.</li>
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo en el catálogo.
     * @param price El precio unitario del artículo.
     * @param quantity La cantidad a añadir.
     * @return El {@link CartDTO} actualizado.
     * @throws RuntimeException Si se intenta añadir un producto digital que ya existe.
     */
    @Transactional
    public CartDTO addItemToCart(Long userId, ItemType itemType, Long itemId, BigDecimal price, Integer quantity) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseGet(() -> createNewCart(userId));

        // Check if item already exists in cart
        CartItem existingItem = cartItemRepository
                .findByCartIdAndItemTypeAndItemId(cart.getId(), itemType, itemId)
                .orElse(null);

        if (existingItem != null) {
            // For digital products (SONG, ALBUM), don't allow duplicates
            if (itemType == ItemType.SONG || itemType == ItemType.ALBUM) {
                throw new RuntimeException("Item already exists in cart. Digital products cannot be added more than once.");
            }
            // For physical products, update quantity
            existingItem.setQuantity(existingItem.getQuantity() + quantity);
            cartItemRepository.save(existingItem);
        } else {
            // Create new cart item
            CartItem newItem = CartItem.builder()
                    .cartId(cart.getId())
                    .itemType(itemType)
                    .itemId(itemId)
                    .quantity(quantity)
                    .price(price)
                    .build();
            cartItemRepository.save(newItem);
        }

        // Reload cart with updated items and recalculate total
        cart = cartRepository.findById(cart.getId())
                .orElseThrow(() -> new RuntimeException("Cart not found"));
        cart.calculateTotalAmount();
        cart = cartRepository.save(cart);

        return mapToDTO(cart);
    }

    /**
     * Actualiza la cantidad de un artículo existente en el carrito del usuario.
     * <p>
     * Si la cantidad es menor o igual a cero, el artículo es eliminado.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemId El ID del artículo del carrito ({@link CartItem}) a actualizar.
     * @param quantity La nueva cantidad deseada.
     * @return El {@link CartDTO} actualizado.
     * @throws RuntimeException Si no se encuentra el carrito o el artículo no pertenece al usuario.
     */
    @Transactional
    public CartDTO updateCartItemQuantity(Long userId, Long itemId, Integer quantity) {
        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Cart not found for user: " + userId));

        CartItem cartItem = cartItemRepository.findById(itemId)
                .orElseThrow(() -> new RuntimeException("Cart item not found: " + itemId));

        if (!cartItem.getCartId().equals(cart.getId())) {
            throw new RuntimeException("Cart item does not belong to user's cart");
        }

        if (quantity <= 0) {
            cartItemRepository.delete(cartItem);
        } else {
            cartItem.setQuantity(quantity);
            cartItemRepository.save(cartItem);
        }

        // Reload cart with updated items and recalculate total
        cart = cartRepository.findById(cart.getId())
                .orElseThrow(() -> new RuntimeException("Cart not found"));
        cart.calculateTotalAmount();
        cart = cartRepository.save(cart);

        return mapToDTO(cart);
    }

    /**
     * Elimina un artículo específico del carrito de un usuario.
     * <p>
     * Nota: Utiliza un método de eliminación directo del repositorio seguido de
     * {@code entityManager.clear()} y una recarga forzada para manejar posibles problemas de caché de JPA
     * cuando se usan operaciones {@code @Modifying} dentro de una transacción.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemId El ID del artículo del carrito ({@link CartItem}) a eliminar.
     * @return El {@link CartDTO} actualizado.
     * @throws RuntimeException Si no se encuentra el carrito o el artículo no pertenece al usuario.
     */
    @Transactional
    public CartDTO removeItemFromCart(Long userId, Long itemId) {
        System.out.println("=== removeItemFromCart called - userId: " + userId + ", itemId: " + itemId);

        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Cart not found for user: " + userId));

        System.out.println("Cart found - cartId: " + cart.getId() + ", current items count: " + cart.getItems().size());

        // Verify the item exists and belongs to this cart
        CartItem cartItem = cartItemRepository.findById(itemId)
                .orElseThrow(() -> new RuntimeException("Cart item not found: " + itemId));

        System.out.println("CartItem found - itemId: " + cartItem.getId() + ", cartId: " + cartItem.getCartId());

        if (!cartItem.getCartId().equals(cart.getId())) {
            throw new RuntimeException("Cart item does not belong to user's cart");
        }

        // Delete using custom query to force immediate execution
        System.out.println("Deleting cart item with custom query...");
        int deletedCount = cartItemRepository.deleteCartItemById(itemId);
        System.out.println("Cart item deleted - deleted count: " + deletedCount);

        // Clear the entity manager to remove all cached entities
        entityManager.clear();
        System.out.println("Entity manager cleared");

        // Reload cart with completely fresh data from database
        cart = cartRepository.findById(cart.getId())
                .orElseThrow(() -> new RuntimeException("Cart not found"));

        System.out.println("Cart reloaded - items count after deletion: " + cart.getItems().size());

        // Recalculate total amount
        cart.calculateTotalAmount();
        cart = cartRepository.save(cart);

        System.out.println("Cart saved - final items count: " + cart.getItems().size());

        CartDTO dto = mapToDTO(cart);
        System.out.println("DTO created - items count in DTO: " + dto.getItems().size());

        return dto;
    }

    /**
     * Vacía completamente el carrito de un usuario, eliminando todos los artículos.
     *
     * @param userId El ID del usuario cuyo carrito será limpiado.
     * @throws RuntimeException Si no se encuentra el carrito.
     */
    @Transactional
    public void clearCart(Long userId) {
        System.out.println("=== CartService.clearCart called - userId: " + userId);

        Cart cart = cartRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Cart not found for user: " + userId));

        System.out.println("Cart found - cartId: " + cart.getId() + ", items count: " + cart.getItems().size());

        int deletedCount = cartItemRepository.deleteByCartId(cart.getId());
        System.out.println("Cart items deleted - count: " + deletedCount);

        // Clear entity manager to ensure changes are reflected
        entityManager.clear();

        // Recalculate total amount
        cart = cartRepository.findById(cart.getId())
                .orElseThrow(() -> new RuntimeException("Cart not found"));
        cart.calculateTotalAmount();
        cartRepository.save(cart);

        System.out.println("=== Cart cleared successfully - userId: " + userId);
    }

    /**
     * Obtiene el número total de unidades de artículos en el carrito de un usuario.
     *
     * @param userId El ID del usuario.
     * @return El conteo total de unidades, o 0 si el carrito no existe.
     */
    public Integer getCartItemCount(Long userId) {
        Cart cart = cartRepository.findByUserId(userId).orElse(null);
        if (cart == null) {
            return 0;
        }
        return cart.getTotalItems();
    }

    /**
     * Crea y persiste una nueva entidad {@link Cart} para un usuario.
     * <p>
     * Método auxiliar privado.
     * </p>
     *
     * @param userId El ID del usuario.
     * @return El objeto {@link Cart} recién creado y persistido.
     */
    private Cart createNewCart(Long userId) {
        Cart cart = Cart.builder()
                .userId(userId)
                .totalAmount(BigDecimal.ZERO)
                .build();
        return cartRepository.save(cart);
    }

    /**
     * Mapea una entidad {@link Cart} a su respectivo Data Transfer Object (DTO) {@link CartDTO}.
     * <p>
     * Método auxiliar privado. Realiza la conversión de la lista de {@link CartItem} a {@link CartItemDTO}.
     * </p>
     *
     * @param cart La entidad {@link Cart} de origen.
     * @return El {@link CartDTO} resultante.
     */
    private CartDTO mapToDTO(Cart cart) {
        List<CartItemDTO> itemDTOs = cart.getItems().stream()
                .map(item -> CartItemDTO.builder()
                        .id(item.getId())
                        .cartId(item.getCartId())
                        .itemType(item.getItemType())
                        .itemId(item.getItemId())
                        .quantity(item.getQuantity())
                        .price(item.getPrice())
                        .build())
                .collect(Collectors.toList());

        return CartDTO.builder()
                .id(cart.getId())
                .userId(cart.getUserId())
                .items(itemDTOs)
                .totalAmount(cart.getTotalAmount())
                .createdAt(cart.getCreatedAt())
                .updatedAt(cart.getUpdatedAt())
                .build();
    }
}