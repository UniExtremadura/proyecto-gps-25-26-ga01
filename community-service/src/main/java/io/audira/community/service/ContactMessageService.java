package io.audira.community.service;

import io.audira.community.model.ContactMessage;
import io.audira.community.model.ContactStatus;
import io.audira.community.repository.ContactMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Servicio de lógica de negocio responsable de gestionar los mensajes de contacto y tickets de soporte ({@link ContactMessage}).
 * <p>
 * Este servicio centraliza la creación, consulta, marcaje de lectura y actualización del estado de los mensajes.
 * Orquesta la notificación a los administradores al recibir un nuevo ticket y al usuario cuando un ticket es resuelto.
 * </p>
 *
 * @author Grupo GA01
 * @see ContactMessageRepository
 * @see io.audira.community.client.NotificationClient
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ContactMessageService {

    private final ContactMessageRepository contactMessageRepository;
    private final io.audira.community.client.NotificationClient notificationClient;

    /**
     * ID del usuario administrador principal que recibe notificaciones de nuevos tickets.
     * Configurable mediante la propiedad {@code admin.user.id}.
     * Valor por defecto: 1
     */
    @org.springframework.beans.factory.annotation.Value("${admin.user.id:1}")
    private Long adminUserId;

    // --- Métodos de Consulta ---

    /**
     * Obtiene una lista de todos los mensajes de contacto, ordenados por fecha de creación descendente.
     *
     * @return Una {@link List} de todos los objetos {@link ContactMessage}.
     */
    public List<ContactMessage> getAllMessages() {
        return contactMessageRepository.findAllByOrderByCreatedAtDesc();
    }

    /**
     * Obtiene una lista de todos los mensajes de contacto que aún no han sido marcados como leídos.
     *
     * @return Una {@link List} de mensajes no leídos.
     */
    public List<ContactMessage> getUnreadMessages() {
        return contactMessageRepository.findByIsReadFalseOrderByCreatedAtDesc();
    }

    /**
     * Obtiene todos los mensajes de contacto enviados por un usuario específico.
     *
     * @param userId ID del usuario remitente (tipo {@link Long}).
     * @return Una {@link List} de mensajes del usuario.
     */
    public List<ContactMessage> getMessagesByUserId(Long userId) {
        return contactMessageRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    /**
     * Obtiene todos los mensajes de contacto filtrados por un estado de ticket específico (ej. RESOLVED).
     *
     * @param status El estado del mensaje ({@link ContactStatus}) por el cual filtrar.
     * @return Una {@link List} de mensajes que coinciden con el estado.
     */
    public List<ContactMessage> getMessagesByStatus(ContactStatus status) {
        return contactMessageRepository.findByStatusOrderByCreatedAtDesc(status);
    }

    /**
     * Obtiene todos los mensajes que están en estado {@link ContactStatus#PENDING} o {@link ContactStatus#IN_PROGRESS}.
     * <p>
     * Se utiliza para ver los tickets activos o pendientes de revisión.
     * </p>
     *
     * @return Una {@link List} de mensajes activos.
     */
    public List<ContactMessage> getPendingAndInProgressMessages() {
        return contactMessageRepository.findByStatusInOrderByCreatedAtDesc(
                List.of(ContactStatus.PENDING, ContactStatus.IN_PROGRESS)
        );
    }

    /**
     * Obtiene un mensaje de contacto específico por su ID.
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @return El objeto {@link ContactMessage}.
     * @throws RuntimeException si el mensaje no se encuentra.
     */
    public ContactMessage getMessageById(Long id) {
        return contactMessageRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Mensaje de contacto no encontrado con id: " + id));
    }

    // --- Métodos Transaccionales (Creación y Modificación) ---

    /**
     * Crea y persiste un nuevo mensaje de contacto.
     * <p>
     * Realiza validaciones básicas de campos obligatorios y notifica al administrador sobre el nuevo ticket.
     * </p>
     *
     * @param message El objeto {@link ContactMessage} a crear.
     * @return El mensaje persistido.
     * @throws IllegalArgumentException si faltan campos obligatorios.
     */
    @Transactional
    public ContactMessage createMessage(ContactMessage message) {
        if (message.getName() == null || message.getName().trim().isEmpty()) {
            throw new IllegalArgumentException("El nombre es obligatorio");
        }
        if (message.getEmail() == null || message.getEmail().trim().isEmpty()) {
            throw new IllegalArgumentException("El email es obligatorio");
        }
        if (message.getSubject() == null || message.getSubject().trim().isEmpty()) {
            throw new IllegalArgumentException("El asunto es obligatorio");
        }
        if (message.getMessage() == null || message.getMessage().trim().isEmpty()) {
            throw new IllegalArgumentException("El mensaje es obligatorio");
        }

        // Set default status if not set
        if (message.getStatus() == null) {
            message.setStatus(ContactStatus.PENDING);
        }

        log.info("Creando mensaje de contacto de: {}", message.getEmail());
        ContactMessage savedMessage = contactMessageRepository.save(message);

        // Notificar a administradores
        try {
            log.info("Notificando nuevo ticket al admin con ID: {}", adminUserId);
            notificationClient.notifyAdminNewTicket(adminUserId, message.getName(), message.getSubject());
        } catch (Exception e) {
            log.error("Failed to send ticket notification to admin {}: {}", adminUserId, e.getMessage());
        }

        return savedMessage;
    }

    /**
     * Marca un mensaje de contacto como leído ({@code isRead = true}).
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @return El mensaje actualizado.
     */
    @Transactional
    public ContactMessage markAsRead(Long id) {
        ContactMessage message = getMessageById(id);
        message.setIsRead(true);
        log.info("Marcando mensaje {} como leído", id);
        return contactMessageRepository.save(message);
    }

    /**
     * Actualiza el estado de procesamiento de un mensaje de contacto (ej. a IN_PROGRESS o RESOLVED).
     * <p>
     * Si el nuevo estado es {@link ContactStatus#RESOLVED}, notifica al usuario original (si el {@code userId} no es nulo).
     * </p>
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @param status El nuevo estado ({@link ContactStatus}).
     * @return El mensaje actualizado.
     */
    @Transactional
    public ContactMessage updateStatus(Long id, ContactStatus status) {
        ContactMessage message = getMessageById(id);
        ContactStatus previousStatus = message.getStatus();
        message.setStatus(status);
        log.info("Actualizando estado del mensaje {} a {}", id, status);
        ContactMessage updatedMessage = contactMessageRepository.save(message);

        // Notificar al usuario si el ticket fue resuelto
        if (status == ContactStatus.RESOLVED && previousStatus != ContactStatus.RESOLVED) {
            try {
                if (message.getUserId() != null) {
                    notificationClient.notifyUserTicketResolved(message.getUserId(), message.getSubject());
                }
            } catch (Exception e) {
                log.error("Failed to send ticket resolved notification to user {}", message.getUserId(), e);
            }
        }

        return updatedMessage;
    }

    /**
     * Elimina un mensaje de contacto del sistema.
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @throws RuntimeException si el mensaje no se encuentra.
     */
    @Transactional
    public void deleteMessage(Long id) {
        ContactMessage message = getMessageById(id);
        log.info("Eliminando mensaje de contacto con id: {}", id);
        contactMessageRepository.delete(message);
    }
}