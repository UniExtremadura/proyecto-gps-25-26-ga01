package io.audira.commerce.repository;

import io.audira.commerce.model.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositorio de Spring Data JPA para la entidad {@link OrderItem}.
 * <p>
 * Proporciona métodos CRUD y métodos de consulta basados en nombres para gestionar
 * los artículos individuales asociados a una orden de compra específica.
 * </p>
 *
 * @author Grupo GA01
 * @see OrderItem
 * @see JpaRepository
 * 
 */
@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {

    /**
     * Busca y retorna todos los artículos asociados a un ID de orden específico.
     * <p>
     * Se utiliza para obtener el desglose completo de productos de una orden.
     * </p>
     *
     * @param orderId El ID de la orden (tipo {@link Long}) a buscar.
     * @return Una {@link List} de {@link OrderItem} que pertenecen a esa orden.
     */
    List<OrderItem> findByOrderId(Long orderId);

    /**
     * Elimina todos los artículos de orden asociados a un ID de orden específico.
     * <p>
     * Esta operación se utiliza típicamente como parte del proceso de cancelación de una orden.
     * Debe ejecutarse dentro de una transacción (usando {@code @Transactional} en la capa de servicio).
     * </p>
     *
     * @param orderId El ID de la orden cuyos artículos serán eliminados.
     */
    void deleteByOrderId(Long orderId);
}