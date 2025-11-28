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

/**
 * Clase de servicio que gestiona la lógica de negocio para la creación, consulta y gestión
 * de respuestas de mensajes de contacto ({@link ContactResponse}).
 * <p>
 * Coordina las operaciones entre los repositorios de respuestas y mensajes, e interactúa
 * con el servicio de notificaciones.
 * </p>
 *
 * @author Grupo GA01
 * @see ContactResponse
 * @see ContactResponseRepository
 * 
 */
@Service
@RequiredArgsConstructor
public class ContactResponseService {

    private final ContactResponseRepository contactResponseRepository;
    private final ContactMessageRepository contactMessageRepository;
    private final io.audira.community.client.NotificationClient notificationClient;

    /**
     * Crea una nueva respuesta para un mensaje de contacto existente y actualiza el estado del mensaje.
     * <p>
     * El proceso incluye:
     * <ul>
     * <li>Verificar la existencia del mensaje de contacto.</li>
     * <li>Guardar la nueva respuesta en el repositorio.</li>
     * <li>Actualizar el estado del mensaje a {@code IN_PROGRESS} si estaba {@code PENDING} y marcarlo como leído.</li>
     * <li>Intentar notificar al usuario original sobre la nueva respuesta (el fallo en la notificación no detiene la transacción).</li>
     * </ul>
     * </p>
     *
     * @param contactMessageId El ID del mensaje original que se está respondiendo.
     * @param adminId El ID del administrador que crea la respuesta.
     * @param adminName El nombre del administrador (para referencia).
     * @param responseText El contenido de la respuesta.
     * @return El objeto {@link ContactResponse} recién creado y persistido.
     * @throws RuntimeException Si el mensaje de contacto original no existe.
     */
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

    /**
     * Recupera todas las respuestas asociadas a un mensaje de contacto específico,
     * ordenadas por fecha de creación de forma descendente (más recientes primero).
     *
     * @param contactMessageId El ID del mensaje de contacto.
     * @return Una {@link List} de objetos {@link ContactResponse}.
     */
    public List<ContactResponse> getResponsesByMessageId(Long contactMessageId) {
        return contactResponseRepository.findByContactMessageIdOrderByCreatedAtDesc(contactMessageId);
    }

    /**
     * Recupera todas las respuestas creadas por un administrador específico.
     *
     * @param adminId El ID del administrador.
     * @return Una {@link List} de objetos {@link ContactResponse}.
     */
    public List<ContactResponse> getResponsesByAdminId(Long adminId) {
        return contactResponseRepository.findByAdminId(adminId);
    }

    /**
     * Recupera una respuesta de contacto por su identificador único.
     *
     * @param id El ID de la respuesta.
     * @return El objeto {@link ContactResponse} encontrado.
     * @throws RuntimeException Si la respuesta no se encuentra.
     */
    public ContactResponse getResponseById(Long id) {
        return contactResponseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Response not found with id: " + id));
    }

    /**
     * Actualiza el contenido del texto de una respuesta de contacto existente.
     *
     * @param id El ID de la respuesta a actualizar.
     * @param responseText El nuevo contenido de la respuesta.
     * @return El objeto {@link ContactResponse} actualizado y persistido.
     * @throws RuntimeException Si la respuesta no existe.
     */
    @Transactional
    public ContactResponse updateResponse(Long id, String responseText) {
        ContactResponse response = getResponseById(id);
        response.setResponse(responseText);
        return contactResponseRepository.save(response);
    }

    /**
     * Elimina una respuesta de contacto por su identificador único.
     *
     * @param id El ID de la respuesta a eliminar.
     * @throws RuntimeException Si la respuesta no se encuentra.
     */
    @Transactional
    public void deleteResponse(Long id) {
        if (!contactResponseRepository.existsById(id)) {
            throw new RuntimeException("Response not found with id: " + id);
        }
        contactResponseRepository.deleteById(id);
    }
}