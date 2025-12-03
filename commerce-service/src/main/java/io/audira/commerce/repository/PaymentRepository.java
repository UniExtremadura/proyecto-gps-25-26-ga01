package io.audira.commerce.repository;

import io.audira.commerce.model.Payment;
import io.audira.commerce.model.PaymentStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio de Spring Data JPA para la entidad {@link Payment}.
 * <p>
 * Proporciona métodos CRUD y métodos de consulta basados en nombres para gestionar
 * los registros de pago, permitiendo la búsqueda por identificadores transaccionales
 * como ID de transacción, ID de orden y estado del pago.
 * </p>
 *
 * @author Grupo GA01
 * @see Payment
 * @see PaymentStatus
 * @see JpaRepository
 * 
 */
@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {

    /**
     * Busca y retorna un registro de pago utilizando el ID de transacción único de la pasarela.
     *
     * @param transactionId El ID de la transacción (tipo {@link String}) a buscar.
     * @return Un {@link Optional} que contiene el objeto {@link Payment} si se encuentra.
     */
    Optional<Payment> findByTransactionId(String transactionId);

    /**
     * Busca y retorna todos los registros de pago asociados a un ID de usuario específico.
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyas transacciones se desean obtener.
     * @return Una {@link List} de objetos {@link Payment} asociados a ese usuario.
     */
    List<Payment> findByUserId(Long userId);

    /**
     * Busca y retorna todos los registros de pago asociados a un ID de orden específico.
     * <p>
     * Nota: Una orden puede tener múltiples registros de pago debido a reintentos o reembolsos parciales.
     * </p>
     *
     * @param orderId El ID de la orden (tipo {@link Long}) cuyas transacciones se desean obtener.
     * @return Una {@link List} de objetos {@link Payment} asociados a esa orden.
     */
    List<Payment> findByOrderId(Long orderId);

    /**
     * Busca y retorna los registros de pago de un usuario filtrados por un estado transaccional específico.
     * <p>
     * Útil para encontrar pagos fallidos de un usuario para reintentos.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param status El estado del pago ({@link PaymentStatus}) por el cual filtrar.
     * @return Una {@link List} de objetos {@link Payment} que cumplen ambas condiciones.
     */
    List<Payment> findByUserIdAndStatus(Long userId, PaymentStatus status);

    /**
     * Busca y retorna todos los registros de pago que se encuentran en un estado transaccional específico.
     * <p>
     * Útil para tareas programadas que procesan pagos pendientes o fallidos.
     * </p>
     *
     * @param status El estado del pago ({@link PaymentStatus}) por el cual filtrar.
     * @return Una {@link List} de objetos {@link Payment} que coinciden con el estado.
     */
    List<Payment> findByStatus(PaymentStatus status);
}