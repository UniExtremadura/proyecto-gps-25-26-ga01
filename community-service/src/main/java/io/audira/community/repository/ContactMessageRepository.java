package io.audira.community.repository;

import io.audira.community.model.ContactMessage;
import io.audira.community.model.ContactStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositorio de Spring Data JPA para la entidad {@link ContactMessage}.
 * <p>
 * Proporciona métodos de consulta basados en nombres para gestionar los mensajes de contacto
 * y tickets de soporte, incluyendo filtros por estado, usuario y estado de lectura,
 * ordenando siempre los resultados por la fecha de creación de forma descendente (más recientes primero).
 * </p>
 *
 * @author Grupo GA01
 * @see ContactMessage
 * @see JpaRepository
 * 
 */
@Repository
public interface ContactMessageRepository extends JpaRepository<ContactMessage, Long> {

    /**
     * Busca y retorna todos los mensajes de contacto, ordenados por la fecha de creación descendente.
     * <p>
     * Utilizado típicamente por el panel de administración/soporte para ver el historial completo.
     * </p>
     *
     * @return Una {@link List} de {@link ContactMessage} ordenada por fecha de creación (más reciente).
     */
    List<ContactMessage> findAllByOrderByCreatedAtDesc();

    /**
     * Busca y retorna todos los mensajes que aún no han sido leídos ({@code isRead = false}), ordenados por fecha de creación descendente.
     *
     * @return Una {@link List} de mensajes no leídos.
     */
    List<ContactMessage> findByIsReadFalseOrderByCreatedAtDesc();

    /**
     * Busca y retorna todos los mensajes de contacto enviados por un usuario específico, ordenados por fecha de creación descendente.
     *
     * @param userId El ID del usuario (tipo {@link Long}) remitente.
     * @return Una {@link List} de {@link ContactMessage} del usuario.
     */
    List<ContactMessage> findByUserIdOrderByCreatedAtDesc(Long userId);

    /**
     * Busca y retorna los mensajes filtrados por un estado de ticket específico (ej. PENDING, RESOLVED), ordenados por fecha de creación descendente.
     *
     * @param status El estado del mensaje ({@link ContactStatus}) por el cual filtrar.
     * @return Una {@link List} de {@link ContactMessage} que coinciden con el estado.
     */
    List<ContactMessage> findByStatusOrderByCreatedAtDesc(ContactStatus status);

    /**
     * Busca y retorna los mensajes cuyo estado se encuentra en una lista de estados proporcionada (ej. PENDING e IN_PROGRESS), ordenados por fecha de creación descendente.
     *
     * @param statuses Una {@link List} de estados ({@link ContactStatus}) por los cuales filtrar.
     * @return Una {@link List} de {@link ContactMessage} que coinciden con alguno de los estados.
     */
    List<ContactMessage> findByStatusInOrderByCreatedAtDesc(List<ContactStatus> statuses);
}