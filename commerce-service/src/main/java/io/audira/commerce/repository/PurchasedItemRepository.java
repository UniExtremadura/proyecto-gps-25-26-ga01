package io.audira.commerce.repository;

import io.audira.commerce.model.ItemType;
import io.audira.commerce.model.PurchasedItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio de Spring Data JPA para la entidad {@link PurchasedItem}.
 * <p>
 * Proporciona métodos de consulta basados en nombres para gestionar los registros
 * de artículos adquiridos por los usuarios, que forman su biblioteca digital.
 * Esta entidad es la fuente de verdad sobre la propiedad de un producto.
 * </p>
 *
 * @author Grupo GA01
 * @see PurchasedItem
 * @see JpaRepository
 * 
 */
@Repository
public interface PurchasedItemRepository extends JpaRepository<PurchasedItem, Long> {

    /**
     * Busca y retorna todos los artículos comprados por un usuario específico.
     *
     * @param userId El ID del usuario (tipo {@link Long}) a buscar.
     * @return Una {@link List} de todos los objetos {@link PurchasedItem} del usuario.
     */
    List<PurchasedItem> findByUserId(Long userId);

    /**
     * Busca y retorna los artículos comprados de un usuario, filtrados por el tipo de artículo.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}) por el cual filtrar.
     * @return Una {@link List} de {@link PurchasedItem} que coinciden con el usuario y el tipo de artículo.
     */
    List<PurchasedItem> findByUserIdAndItemType(Long userId, ItemType itemType);

    /**
     * Verifica la existencia de un registro que indique si un usuario ha comprado un artículo específico.
     * <p>
     * Es una consulta optimizada basada en la restricción única compuesta de la entidad.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo en el catálogo.
     * @return {@code true} si el artículo ha sido comprado, {@code false} en caso contrario.
     */
    boolean existsByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Busca y retorna un artículo comprado específico utilizando la clave compuesta (userId, itemType, itemId).
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo en el catálogo.
     * @return Un {@link Optional} que contiene el {@link PurchasedItem} si se encuentra.
     */
    Optional<PurchasedItem> findByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Busca y retorna todos los artículos comprados que fueron parte de una orden específica.
     * <p>
     * Útil para la trazabilidad transaccional de una orden.
     * </p>
     *
     * @param orderId El ID de la orden (tipo {@link Long}).
     * @return Una {@link List} de {@link PurchasedItem} asociados a la orden.
     */
    List<PurchasedItem> findByOrderId(Long orderId);

    /**
     * Busca y retorna todos los artículos comprados que fueron registrados bajo un pago específico.
     * <p>
     * Útil para la trazabilidad transaccional de un pago.
     * </p>
     *
     * @param paymentId El ID del registro de pago (tipo {@link Long}).
     * @return Una {@link List} de {@link PurchasedItem} asociados al pago.
     */
    List<PurchasedItem> findByPaymentId(Long paymentId);

    /**
     * Elimina todos los registros de artículos comprados asociados a un usuario.
     * <p>
     * La operación se utiliza típicamente para fines de prueba o administrativos (ej. eliminación de cuenta).
     * Debe ejecutarse dentro de una transacción.
     * </p>
     *
     * @param userId El ID del usuario cuyos artículos serán eliminados.
     */
    void deleteByUserId(Long userId);
}