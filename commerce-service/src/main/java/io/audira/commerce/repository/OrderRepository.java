package io.audira.commerce.repository;

import io.audira.commerce.model.Order;
import io.audira.commerce.model.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio de Spring Data JPA para la entidad {@link Order}.
 * <p>
 * Proporciona métodos CRUD y métodos de consulta basados en nombres para gestionar
 * las órdenes de compra, permitiendo la búsqueda eficiente por identificadores clave
 * como el número de orden, ID de usuario y estado de la orden.
 * </p>
 *
 * @author Grupo GA01
 * @see Order
 * @see OrderStatus
 * @see JpaRepository
 * 
 */
@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    /**
     * Busca y retorna una orden específica utilizando su número de orden único.
     *
     * @param orderNumber El número de orden (tipo {@link String}) a buscar.
     * @return Un {@link Optional} que contiene la {@link Order} si se encuentra.
     */
    Optional<Order> findByOrderNumber(String orderNumber);

    /**
     * Busca y retorna todas las órdenes realizadas por un usuario específico.
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyas órdenes se desean obtener.
     * @return Una {@link List} de {@link Order} asociadas a ese usuario.
     */
    List<Order> findByUserId(Long userId);

    /**
     * Busca y retorna todas las órdenes que se encuentran en un estado específico.
     * <p>
     * Útil para procesos de negocio que gestionan pedidos pendientes o completados.
     * </p>
     *
     * @param status El estado de la orden ({@link OrderStatus}) por el cual filtrar.
     * @return Una {@link List} de {@link Order} que coinciden con el estado.
     */
    List<Order> findByStatus(OrderStatus status);

    /**
     * Busca y retorna todas las órdenes realizadas por un usuario específico y que están en un estado particular.
     *
     * @param userId El ID del usuario.
     * @param status El estado de la orden ({@link OrderStatus}) por el cual filtrar.
     * @return Una {@link List} de {@link Order} que cumplen ambas condiciones.
     */
    List<Order> findByUserIdAndStatus(Long userId, OrderStatus status);

    /**
     * Verifica la existencia de una orden utilizando su número de orden único.
     *
     * @param orderNumber El número de orden (tipo {@link String}) a verificar.
     * @return {@code true} si la orden con ese número existe, {@code false} en caso contrario.
     */
    boolean existsByOrderNumber(String orderNumber);
}