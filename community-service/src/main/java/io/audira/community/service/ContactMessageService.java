package io.audira.community.service;

import io.audira.community.model.ContactMessage;
import io.audira.community.model.ContactStatus;
import io.audira.community.repository.ContactMessageRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ContactMessageService {

    private final ContactMessageRepository contactMessageRepository;
    private final io.audira.community.client.NotificationClient notificationClient;

    public List<ContactMessage> getAllMessages() {
        return contactMessageRepository.findAllByOrderByCreatedAtDesc();
    }

    public List<ContactMessage> getUnreadMessages() {
        return contactMessageRepository.findByIsReadFalseOrderByCreatedAtDesc();
    }

    public List<ContactMessage> getMessagesByUserId(Long userId) {
        return contactMessageRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<ContactMessage> getMessagesByStatus(ContactStatus status) {
        return contactMessageRepository.findByStatusOrderByCreatedAtDesc(status);
    }

    public List<ContactMessage> getPendingAndInProgressMessages() {
        return contactMessageRepository.findByStatusInOrderByCreatedAtDesc(
                List.of(ContactStatus.PENDING, ContactStatus.IN_PROGRESS)
        );
    }

    public ContactMessage getMessageById(Long id) {
        return contactMessageRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Mensaje de contacto no encontrado con id: " + id));
    }

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

        // Notificar a administradores (usando un ID genérico o lista de admins)
        // Por ahora notificamos a admin con ID 1
        try {
            notificationClient.notifyAdminNewTicket(1L, message.getName(), message.getSubject());
        } catch (Exception e) {
            log.error("Failed to send ticket notification to admin", e);
        }

        return savedMessage;
    }

    @Transactional
    public ContactMessage markAsRead(Long id) {
        ContactMessage message = getMessageById(id);
        message.setIsRead(true);
        log.info("Marcando mensaje {} como leído", id);
        return contactMessageRepository.save(message);
    }

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

    @Transactional
    public void deleteMessage(Long id) {
        ContactMessage message = getMessageById(id);
        log.info("Eliminando mensaje de contacto con id: {}", id);
        contactMessageRepository.delete(message);
    }
}
