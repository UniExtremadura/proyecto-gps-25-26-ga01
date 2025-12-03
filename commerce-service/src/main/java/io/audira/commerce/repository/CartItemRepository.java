package io.audira.commerce.repository;

import io.audira.commerce.model.CartItem;
import io.audira.commerce.model.ItemType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio de Spring Data JPA para la entidad {@link CartItem}.
 * <p>
 * Proporciona métodos CRUD y métodos de consulta específicos para gestionar
 * los artículos individuales dentro de los carritos de compra.
 * </p>
 *
 * @author Grupo GA01
 * @see CartItem
 * @see JpaRepository
 * 
 */
@Repository
public interface CartItemRepository extends JpaRepository<CartItem, Long> {

    /**
     * Busca y retorna todos los artículos asociados a un ID de carrito específico.
     *
     * @param cartId El ID del carrito (tipo {@link Long}) a buscar.
     * @return Una {@link List} de {@link CartItem} que pertenecen a ese carrito.
     */
    List<CartItem> findByCartId(Long cartId);

    /**
     * Busca un artículo específico en el carrito utilizando el ID del carrito, el tipo de artículo y el ID del artículo.
     * <p>
     * Esta consulta es clave debido a la restricción única compuesta definida en la entidad {@link CartItem}.
     * </p>
     *
     * @param cartId El ID del carrito.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo en el catálogo.
     * @return Un {@link Optional} que contiene el {@link CartItem} si se encuentra.
     */
    Optional<CartItem> findByCartIdAndItemTypeAndItemId(Long cartId, ItemType itemType, Long itemId);

    /**
     * Elimina todos los artículos asociados a un carrito específico.
     * <p>
     * Utiliza una consulta JPQL personalizada con la anotación {@code @Modifying} para ejecutar la operación de eliminación.
     * </p>
     *
     * @param cartId El ID del carrito cuyos artículos serán eliminados.
     * @return El número de filas eliminadas.
     */
    @Modifying
    @Query("DELETE FROM CartItem ci WHERE ci.cartId = :cartId")
    int deleteByCartId(@Param("cartId") Long cartId);

    /**
     * Elimina un artículo específico del carrito utilizando su ID primario.
     * <p>
     * Utiliza una consulta JPQL personalizada con la anotación {@code @Modifying}.
     * Aunque {@code deleteById} podría usarse, este método proporciona una clara semántica basada en la columna {@code id}.
     * </p>
     *
     * @param itemId El ID primario del {@link CartItem} a eliminar.
     * @return El número de filas eliminadas.
     */
    @Modifying
    @Query("DELETE FROM CartItem ci WHERE ci.id = :itemId")
    int deleteCartItemById(@Param("itemId") Long itemId);
}