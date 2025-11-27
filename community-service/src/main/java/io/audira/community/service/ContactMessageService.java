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
        return contactMessageRepository.save(message);
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
        message.setStatus(status);
        log.info("Actualizando estado del mensaje {} a {}", id, status);
        return contactMessageRepository.save(message);
    }

    @Transactional
    public void deleteMessage(Long id) {
        ContactMessage message = getMessageById(id);
        log.info("Eliminando mensaje de contacto con id: {}", id);
        contactMessageRepository.delete(message);
    }
}
