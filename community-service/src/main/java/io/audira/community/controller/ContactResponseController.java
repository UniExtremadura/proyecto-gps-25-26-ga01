package io.audira.community.controller;

import io.audira.community.model.ContactResponse;
import io.audira.community.service.ContactResponseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Controlador REST que gestiona la creación, consulta y modificación de las respuestas a los mensajes de contacto (tickets).
 * <p>
 * Los endpoints se mapean a {@code /api/contact/responses} y son utilizados por los administradores o
 * personal de soporte para registrar sus contestaciones a un mensaje de contacto original.
 * </p>
 *
 * @author Grupo GA01
 * @see ContactResponseService
 * 
 */
@RestController
@RequestMapping("/api/contact/responses")
@RequiredArgsConstructor
public class ContactResponseController {

    private final ContactResponseService contactResponseService;

    // --- Métodos de Consulta ---

    /**
     * Obtiene una lista de todas las respuestas asociadas a un mensaje de contacto (ticket) específico.
     * <p>
     * Mapeo: {@code GET /api/contact/responses/message/{messageId}}
     * </p>
     *
     * @param messageId ID del mensaje de contacto (ticket) padre (tipo {@link Long}).
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link ContactResponse} con estado HTTP 200 (OK).
     */
    @GetMapping("/message/{messageId}")
    public ResponseEntity<List<ContactResponse>> getResponsesByMessageId(@PathVariable Long messageId) {
        return ResponseEntity.ok(contactResponseService.getResponsesByMessageId(messageId));
    }

    /**
     * Obtiene una lista de todas las respuestas enviadas por un administrador específico.
     * <p>
     * Mapeo: {@code GET /api/contact/responses/admin/{adminId}}
     * </p>
     *
     * @param adminId ID del administrador (tipo {@link Long}) que envió las respuestas.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link ContactResponse} con estado HTTP 200 (OK).
     */
    @GetMapping("/admin/{adminId}")
    public ResponseEntity<List<ContactResponse>> getResponsesByAdminId(@PathVariable Long adminId) {
        return ResponseEntity.ok(contactResponseService.getResponsesByAdminId(adminId));
    }

    /**
     * Obtiene una respuesta de contacto específica por su ID primario.
     * <p>
     * Mapeo: {@code GET /api/contact/responses/{id}}
     * </p>
     *
     * @param id ID de la respuesta (tipo {@link Long}).
     * @return {@link ResponseEntity} con la {@link ContactResponse} o un error 404 NOT FOUND.
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getResponseById(@PathVariable Long id) {
        try {
            ContactResponse response = contactResponseService.getResponseById(id);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    // --- Métodos de Creación, Modificación y Eliminación ---

    /**
     * Crea una nueva respuesta para un mensaje de contacto existente.
     * <p>
     * Mapeo: {@code POST /api/contact/responses}
     * Esta acción también debería notificar al usuario original del mensaje (lógica en el servicio).
     * </p>
     *
     * @param request Cuerpo de la solicitud {@link RequestBody} que debe contener: {@code contactMessageId}, {@code adminId}, {@code adminName}, y {@code response}.
     * @return {@link ResponseEntity} con la respuesta creada (201 CREATED) o un 400 BAD REQUEST si faltan datos obligatorios.
     */
    @PostMapping
    public ResponseEntity<?> createResponse(@RequestBody Map<String, Object> request) {
        try {
            // Extracción y validación básica de tipos
            Long contactMessageId = ((Number) request.get("contactMessageId")).longValue();
            Long adminId = ((Number) request.get("adminId")).longValue();
            String adminName = (String) request.get("adminName");
            String responseText = (String) request.get("response");

            if (responseText == null || responseText.trim().isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "La respuesta es obligatoria");
                return ResponseEntity.badRequest().body(error);
            }

            ContactResponse response = contactResponseService.createResponse(
                    contactMessageId, adminId, adminName, responseText
            );
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            // 400 BAD REQUEST si el messageId no existe
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Actualiza el texto de una respuesta de contacto existente.
     * <p>
     * Mapeo: {@code PUT /api/contact/responses/{id}}
     * </p>
     *
     * @param id ID de la respuesta (tipo {@link Long}) a actualizar.
     * @param request Cuerpo de la solicitud {@link RequestBody} que contiene el nuevo texto en la clave "response".
     * @return {@link ResponseEntity} con la respuesta actualizada o un error 404 NOT FOUND.
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> updateResponse(@PathVariable Long id, @RequestBody Map<String, String> request) {
        try {
            String responseText = request.get("response");
            if (responseText == null || responseText.trim().isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "La respuesta es obligatoria");
                return ResponseEntity.badRequest().body(error);
            }

            ContactResponse response = contactResponseService.updateResponse(id, responseText);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Elimina una respuesta de contacto del sistema.
     * <p>
     * Mapeo: {@code DELETE /api/contact/responses/{id}}
     * </p>
     *
     * @param id ID de la respuesta (tipo {@link Long}) a eliminar.
     * @return {@link ResponseEntity} con estado HTTP 204 (NO CONTENT) si la eliminación fue exitosa, o 404 NOT FOUND.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteResponse(@PathVariable Long id) {
        try {
            contactResponseService.deleteResponse(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
}