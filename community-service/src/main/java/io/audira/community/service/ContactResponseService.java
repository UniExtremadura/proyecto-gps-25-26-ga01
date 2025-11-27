package io.audira.community.service;

import io.audira.community.model.ContactMessage;
import io.audira.community.model.ContactResponse;
import io.audira.community.model.ContactStatus;
import io.audira.community.repository.ContactMessageRepository;
import io.audira.community.repository.ContactResponseRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ContactResponseService {

    private final ContactResponseRepository contactResponseRepository;
    private final ContactMessageRepository contactMessageRepository;
    private final io.audira.community.client.NotificationClient notificationClient;

    @Transactional
    public ContactResponse createResponse(Long contactMessageId, Long adminId, String adminName, String responseText) {
        // Verificar que el mensaje existe
        ContactMessage message = contactMessageRepository.findById(contactMessageId)
                .orElseThrow(() -> new RuntimeException("Contact message not found with id: " + contactMessageId));

        // Crear la respuesta
        ContactResponse response = ContactResponse.builder()
                .contactMessageId(contactMessageId)
                .adminId(adminId)
                .adminName(adminName)
                .response(responseText)
                .build();

        ContactResponse savedResponse = contactResponseRepository.save(response);

        // Actualizar el estado del mensaje a IN_PROGRESS o RESOLVED
        if (message.getStatus() == ContactStatus.PENDING) {
            message.setStatus(ContactStatus.IN_PROGRESS);
        }
        message.setIsRead(true);
        contactMessageRepository.save(message);

        // Notificar al usuario que recibió una respuesta
        try {
            if (message.getUserId() != null) {
                notificationClient.notifyUserTicketResponse(message.getUserId(), message.getSubject());
            }
        } catch (Exception e) {
            // Log error but don't fail the response creation
        }

        return savedResponse;
    }

    public List<ContactResponse> getResponsesByMessageId(Long contactMessageId) {
        return contactResponseRepository.findByContactMessageIdOrderByCreatedAtDesc(contactMessageId);
    }

    public List<ContactResponse> getResponsesByAdminId(Long adminId) {
        return contactResponseRepository.findByAdminId(adminId);
    }

    public ContactResponse getResponseById(Long id) {
        return contactResponseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Response not found with id: " + id));
    }

    @Transactional
    public ContactResponse updateResponse(Long id, String responseText) {
        ContactResponse response = getResponseById(id);
        response.setResponse(responseText);
        return contactResponseRepository.save(response);
    }

    @Transactional
    public void deleteResponse(Long id) {
        if (!contactResponseRepository.existsById(id)) {
            throw new RuntimeException("Response not found with id: " + id);
        }
        contactResponseRepository.deleteById(id);
    }
}
