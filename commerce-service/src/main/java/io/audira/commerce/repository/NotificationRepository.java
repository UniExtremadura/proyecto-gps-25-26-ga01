package io.audira.commerce.repository;

import io.audira.commerce.model.Notification;
import io.audira.commerce.model.NotificationType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositorio de Spring Data JPA para la entidad {@link Notification}.
 * <p>
 * Proporciona métodos para consultar, contar y gestionar notificaciones de usuarios,
 * incluyendo soporte para paginación y ordenamiento por fecha de creación.
 * </p>
 *
 * @author Grupo GA01
 * @see Notification
 * @see JpaRepository
 * 
 */
@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    /**
     * Busca y retorna notificaciones para un usuario específico, con paginación y ordenadas por fecha de creación descendente.
     * <p>
     * Este es el método **optimizado** para la interfaz de bandeja de entrada del usuario.
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) cuyas notificaciones se desean obtener.
     * @param pageable El objeto {@link Pageable} que contiene la información de paginación (número de página, tamaño, ordenamiento).
     * @return Un objeto {@link Page} de {@link Notification} para la página solicitada.
     */
    Page<Notification> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    /**
     * Busca y retorna todas las notificaciones de un usuario, ordenadas por fecha de creación descendente.
     * <p>
     * Utilizado para obtener la lista completa sin paginación, si fuera necesario.
     * </p>
     *
     * @param userId El ID del usuario.
     * @return Una {@link List} completa de {@link Notification} del usuario.
     */
    List<Notification> findByUserIdOrderByCreatedAtDesc(Long userId);

    /**
     * Busca y retorna notificaciones de un usuario filtradas por el estado de lectura (leído o no leído), ordenadas por fecha descendente.
     *
     * @param userId El ID del usuario.
     * @param isRead Estado de lectura ({@code true} para leídas, {@code false} para no leídas).
     * @return Una {@link List} de {@link Notification} que coinciden con el estado de lectura.
     */
    List<Notification> findByUserIdAndIsReadOrderByCreatedAtDesc(Long userId, Boolean isRead);

    /**
     * Busca y retorna notificaciones de un usuario filtradas por un tipo específico, ordenadas por fecha descendente.
     *
     * @param userId El ID del usuario.
     * @param type El tipo de notificación ({@link NotificationType}) por el cual filtrar.
     * @return Una {@link List} de {@link Notification} que coinciden con el tipo.
     */
    List<Notification> findByUserIdAndTypeOrderByCreatedAtDesc(Long userId, NotificationType type);

    /**
     * Cuenta el número de notificaciones de un usuario, filtradas por el estado de lectura (leído o no leído).
     * <p>
     * Este método se utiliza típicamente para obtener el conteo de notificaciones no leídas.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param isRead Estado de lectura ({@code true} para leídas, {@code false} para no leídas).
     * @return El número de notificaciones que cumplen con la condición (tipo {@code Long}).
     */
    Long countByUserIdAndIsRead(Long userId, Boolean isRead);

    /**
     * Cuenta el número total de notificaciones filtradas por el estado de lectura.
     * <p>
     * Útil para obtener métricas generales del sistema de notificaciones.
     * </p>
     *
     * @param isRead Estado de lectura ({@code true} para leídas, {@code false} para no leídas).
     * @return El número total de notificaciones que cumplen con la condición (tipo {@code Long}).
     */
    Long countByIsRead(Boolean isRead);

    /**
     * Busca y retorna todas las notificaciones que aún no han sido marcadas como enviadas (isSent = false).
     * <p>
     * Este método es utilizado por un proceso o tarea programada para reintentar o gestionar los envíos push pendientes.
     * </p>
     *
     * @return Una {@link List} de {@link Notification} pendientes de envío.
     */
    List<Notification> findByIsSentFalse();
}