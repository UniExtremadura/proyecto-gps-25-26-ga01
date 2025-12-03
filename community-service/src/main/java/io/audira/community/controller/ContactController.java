package io.audira.community.controller;

import io.audira.community.model.ContactMessage;
import io.audira.community.model.ContactStatus;
import io.audira.community.service.ContactMessageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Controlador REST que gestiona la creación, consulta y gestión de los mensajes de contacto (tickets de soporte o consultas generales).
 * <p>
 * Los endpoints se mapean a {@code /api/contact} y permiten la interacción con la entidad {@link ContactMessage},
 * incluyendo la actualización del estado del ticket (ej. {@code PENDING} a {@code RESOLVED}).
 * </p>
 *
 * @author Grupo GA01
 * @see ContactMessageService
 * 
 */
@RestController
@RequestMapping("/api/contact")
@RequiredArgsConstructor
public class ContactController {

    private final ContactMessageService contactMessageService;

    // --- Métodos de Consulta ---

    /**
     * Obtiene una lista de todos los mensajes de contacto registrados en el sistema.
     * <p>
     * Mapeo: {@code GET /api/contact}
     * Nota: Este endpoint está típicamente restringido a usuarios con rol ADMIN o SOPORTE.
     * </p>
     *
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link ContactMessage} con estado HTTP 200 (OK).
     */
    @GetMapping
    public ResponseEntity<List<ContactMessage>> getAllMessages() {
        return ResponseEntity.ok(contactMessageService.getAllMessages());
    }

    /**
     * Obtiene una lista de todos los mensajes de contacto que aún no han sido marcados como leídos.
     * <p>
     * Mapeo: {@code GET /api/contact/unread}
     * </p>
     *
     * @return {@link ResponseEntity} que contiene una {@link List} de mensajes no leídos.
     */
    @GetMapping("/unread")
    public ResponseEntity<List<ContactMessage>> getUnreadMessages() {
        return ResponseEntity.ok(contactMessageService.getUnreadMessages());
    }

    /**
     * Obtiene todos los mensajes de contacto enviados por un usuario específico.
     * <p>
     * Mapeo: {@code GET /api/contact/user/{userId}}
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}) remitente.
     * @return {@link ResponseEntity} que contiene una {@link List} de mensajes del usuario.
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<ContactMessage>> getMessagesByUserId(@PathVariable Long userId) {
        return ResponseEntity.ok(contactMessageService.getMessagesByUserId(userId));
    }

    /**
     * Obtiene todos los mensajes de contacto filtrados por un estado de ticket específico (ej. RESOLVED).
     * <p>
     * Mapeo: {@code GET /api/contact/status/{status}}
     * </p>
     *
     * @param status El estado del mensaje (String, ej. "PENDING", "IN_PROGRESS").
     * @return {@link ResponseEntity} con una {@link List} de mensajes filtrados o 400 BAD REQUEST si el estado es inválido.
     */
    @GetMapping("/status/{status}")
    public ResponseEntity<List<ContactMessage>> getMessagesByStatus(@PathVariable String status) {
        try {
            ContactStatus contactStatus = ContactStatus.valueOf(status.toUpperCase());
            return ResponseEntity.ok(contactMessageService.getMessagesByStatus(contactStatus));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    /**
     * Obtiene todos los mensajes que están en estado {@code PENDING} (Pendiente) o {@code IN_PROGRESS} (En Progreso).
     * <p>
     * Mapeo: {@code GET /api/contact/pending-inprogress}
     * </p>
     *
     * @return {@link ResponseEntity} que contiene una {@link List} de mensajes activos.
     */
    @GetMapping("/pending-inprogress")
    public ResponseEntity<List<ContactMessage>> getPendingAndInProgressMessages() {
        return ResponseEntity.ok(contactMessageService.getPendingAndInProgressMessages());
    }

    /**
     * Obtiene un mensaje de contacto específico por su ID.
     * <p>
     * Mapeo: {@code GET /api/contact/{id}}
     * </p>
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @return {@link ResponseEntity} que contiene el {@link ContactMessage} o un error 404 NOT FOUND.
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getMessageById(@PathVariable Long id) {
        try {
            ContactMessage message = contactMessageService.getMessageById(id);
            return ResponseEntity.ok(message);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    // --- Métodos de Creación y Modificación ---

    /**
     * Crea un nuevo mensaje de contacto o ticket de soporte.
     * <p>
     * Mapeo: {@code POST /api/contact}
     * Este endpoint no requiere autenticación, permitiendo a usuarios no registrados enviar mensajes.
     * </p>
     *
     * @param message El cuerpo de la solicitud ({@link ContactMessage}).
     * @return {@link ResponseEntity} con el mensaje creado (201 CREATED) o un 400 BAD REQUEST si falla la validación.
     */
    @PostMapping
    public ResponseEntity<?> createMessage(@RequestBody ContactMessage message) {
        try {
            ContactMessage createdMessage = contactMessageService.createMessage(message);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdMessage);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Marca un mensaje de contacto específico como leído.
     * <p>
     * Mapeo: {@code PATCH /api/contact/{id}/read}
     * </p>
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @return {@link ResponseEntity} con el mensaje actualizado o un error 404 NOT FOUND.
     */
    @PatchMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long id) {
        try {
            ContactMessage message = contactMessageService.markAsRead(id);
            return ResponseEntity.ok(message);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Actualiza el estado de procesamiento de un mensaje de contacto (ej. a IN_PROGRESS o RESOLVED).
     * <p>
     * Mapeo: {@code PATCH /api/contact/{id}/status}
     * </p>
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @param request Cuerpo de la solicitud que contiene la clave "status" (String).
     * @return {@link ResponseEntity} con el mensaje actualizado o un error si el ID o el estado son inválidos.
     */
    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> request) {
        try {
            String statusStr = request.get("status");
            if (statusStr == null || statusStr.trim().isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "El estado es obligatorio");
                return ResponseEntity.badRequest().body(error);
            }

            ContactStatus status = ContactStatus.valueOf(statusStr.toUpperCase());
            ContactMessage message = contactMessageService.updateStatus(id, status);
            return ResponseEntity.ok(message);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Estado inválido. Valores permitidos: PENDING, IN_PROGRESS, RESOLVED, CLOSED");
            return ResponseEntity.badRequest().body(error);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Endpoint PUT genérico para actualizar campos específicos del mensaje (actualmente solo soporta isRead y status).
     * <p>
     * Mapeo: {@code PUT /api/contact/{id}}
     * </p>
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @param updates Mapa de campos a actualizar.
     * @return {@link ResponseEntity} con el mensaje actualizado o un 400 BAD REQUEST si la solicitud es inválida.
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> updateMessage(@PathVariable Long id, @RequestBody Map<String, Object> updates) {
        try {
            // Maneja la actualización de isRead
            if (updates.containsKey("isRead") && (Boolean) updates.get("isRead")) {
                ContactMessage message = contactMessageService.markAsRead(id);
                return ResponseEntity.ok(message);
            }
            // Maneja la actualización de status
            if (updates.containsKey("status")) {
                String statusStr = (String) updates.get("status");
                ContactStatus status = ContactStatus.valueOf(statusStr.toUpperCase());
                ContactMessage message = contactMessageService.updateStatus(id, status);
                return ResponseEntity.ok(message);
            }
            Map<String, String> error = new HashMap<>();
            error.put("error", "Invalid update request");
            return ResponseEntity.badRequest().body(error);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Elimina un mensaje de contacto del sistema.
     * <p>
     * Mapeo: {@code DELETE /api/contact/{id}}
     * </p>
     *
     * @param id ID del mensaje (tipo {@link Long}).
     * @return {@link ResponseEntity} con estado HTTP 204 (NO CONTENT) si la eliminación fue exitosa, o 404 NOT FOUND.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteMessage(@PathVariable Long id) {
        try {
            contactMessageService.deleteMessage(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
}