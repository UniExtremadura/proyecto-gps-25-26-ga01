package io.audira.community.controller;

import io.audira.community.model.FAQ;
import io.audira.community.service.FAQService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Controlador REST que gestiona las operaciones CRUD y de consulta para las Preguntas Frecuentes (FAQ).
 * <p>
 * Los endpoints base se mapean a {@code /api/faqs}. Permite la visualización pública de las FAQ activas
 * y la administración de las preguntas.
 * </p>
 *
 * @author Grupo GA01
 * @see FAQService
 * 
 */
@RestController
@RequestMapping("/api/faqs")
@RequiredArgsConstructor
public class FAQController {

    private final FAQService faqService;

    // --- Métodos de Consulta ---

    /**
     * Obtiene una lista de todas las FAQ, incluyendo las inactivas (vista administrativa).
     * <p>
     * Mapeo: {@code GET /api/faqs}
     * </p>
     *
     * @return {@link ResponseEntity} que contiene una {@link List} de todas las {@link FAQ} con estado HTTP 200 (OK).
     */
    @GetMapping
    public ResponseEntity<List<FAQ>> getAllFaqs() {
        return ResponseEntity.ok(faqService.getAllFaqs());
    }

    /**
     * Obtiene una lista de solo las FAQ marcadas como activas (vista pública).
     * <p>
     * Mapeo: {@code GET /api/faqs/active}
     * </p>
     *
     * @return {@link ResponseEntity} que contiene una {@link List} de las {@link FAQ} activas.
     */
    @GetMapping("/active")
    public ResponseEntity<List<FAQ>> getActiveFaqs() {
        return ResponseEntity.ok(faqService.getActiveFaqs());
    }

    /**
     * Obtiene una lista de FAQ filtradas por una categoría específica.
     * <p>
     * Mapeo: {@code GET /api/faqs/category/{category}}
     * </p>
     *
     * @param category La categoría (tipo {@link String}) por la cual filtrar.
     * @return {@link ResponseEntity} que contiene una {@link List} de {@link FAQ} de la categoría.
     */
    @GetMapping("/category/{category}")
    public ResponseEntity<List<FAQ>> getFaqsByCategory(@PathVariable String category) {
        return ResponseEntity.ok(faqService.getFaqsByCategory(category));
    }

    /**
     * Obtiene una FAQ específica por su ID.
     * <p>
     * Mapeo: {@code GET /api/faqs/{id}}
     * </p>
     *
     * @param id ID de la FAQ (tipo {@link Long}).
     * @return {@link ResponseEntity} con la {@link FAQ} encontrada o un error 404 NOT FOUND si no existe.
     */
    @GetMapping("/{id}")
    public ResponseEntity<?> getFaqById(@PathVariable Long id) {
        try {
            FAQ faq = faqService.getFaqById(id);
            return ResponseEntity.ok(faq);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    // --- Métodos de Administración (CRUD) ---

    /**
     * Crea una nueva FAQ en el sistema.
     * <p>
     * Mapeo: {@code POST /api/faqs}
     * Nota: Este endpoint está típicamente restringido por seguridad a usuarios ADMIN.
     * </p>
     *
     * @param faq El cuerpo de la solicitud ({@link FAQ}) con la pregunta, respuesta y categoría.
     * @return {@link ResponseEntity} con la FAQ creada (201 CREATED) o un 400 BAD REQUEST si falla la validación.
     */
    @PostMapping
    public ResponseEntity<?> createFaq(@RequestBody FAQ faq) {
        try {
            FAQ createdFaq = faqService.createFaq(faq);
            return ResponseEntity.status(HttpStatus.CREATED).body(createdFaq);
        } catch (IllegalArgumentException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        }
    }

    /**
     * Actualiza completamente una FAQ existente.
     * <p>
     * Mapeo: {@code PUT /api/faqs/{id}}
     * </p>
     *
     * @param id ID de la FAQ (tipo {@link Long}) a actualizar.
     * @param faqDetails El cuerpo de la solicitud ({@link FAQ}) con los nuevos detalles.
     * @return {@link ResponseEntity} con la {@link FAQ} actualizada o un error 404 NOT FOUND si no existe.
     */
    @PutMapping("/{id}")
    public ResponseEntity<?> updateFaq(@PathVariable Long id, @RequestBody FAQ faqDetails) {
        try {
            FAQ updatedFaq = faqService.updateFaq(id, faqDetails);
            return ResponseEntity.ok(updatedFaq);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Alterna el estado de actividad (activo/inactivo) de una FAQ.
     * <p>
     * Mapeo: {@code PUT /api/faqs/{id}/toggle-active}
     * </p>
     *
     * @param id ID de la FAQ (tipo {@link Long}).
     * @return {@link ResponseEntity} con la {@link FAQ} actualizada o un error 404 NOT FOUND.
     */
    @PutMapping("/{id}/toggle-active")
    public ResponseEntity<?> toggleActive(@PathVariable Long id) {
        try {
            FAQ faq = faqService.toggleActive(id);
            return ResponseEntity.ok(faq);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Elimina una FAQ del sistema.
     * <p>
     * Mapeo: {@code DELETE /api/faqs/{id}}
     * </p>
     *
     * @param id ID de la FAQ (tipo {@link Long}) a eliminar.
     * @return {@link ResponseEntity} con estado HTTP 204 (NO CONTENT) si la eliminación fue exitosa, o 404 NOT FOUND.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteFaq(@PathVariable Long id) {
        try {
            faqService.deleteFaq(id);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    // --- Métodos de Estadísticas y Retroalimentación (Feedback) ---

    /**
     * Incrementa el contador de visualizaciones de una FAQ específica.
     * <p>
     * Mapeo: {@code POST /api/faqs/{id}/view}
     * </p>
     *
     * @param id ID de la FAQ (tipo {@link Long}).
     * @return {@link ResponseEntity} con estado HTTP 200 (OK) o 404 NOT FOUND.
     */
    @PostMapping("/{id}/view")
    public ResponseEntity<?> incrementViewCount(@PathVariable Long id) {
        try {
            faqService.incrementViewCount(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Registra un voto positivo ("útil") para una FAQ.
     * <p>
     * Mapeo: {@code POST /api/faqs/{id}/helpful}
     * </p>
     *
     * @param id ID de la FAQ (tipo {@link Long}).
     * @return {@link ResponseEntity} con estado HTTP 200 (OK) o 404 NOT FOUND.
     */
    @PostMapping("/{id}/helpful")
    public ResponseEntity<?> markAsHelpful(@PathVariable Long id) {
        try {
            faqService.markAsHelpful(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }

    /**
     * Registra un voto negativo ("no útil") para una FAQ.
     * <p>
     * Mapeo: {@code POST /api/faqs/{id}/not-helpful}
     * </p>
     *
     * @param id ID de la FAQ (tipo {@link Long}).
     * @return {@link ResponseEntity} con estado HTTP 200 (OK) o 404 NOT FOUND.
     */
    @PostMapping("/{id}/not-helpful")
    public ResponseEntity<?> markAsNotHelpful(@PathVariable Long id) {
        try {
            faqService.markAsNotHelpful(id);
            return ResponseEntity.ok().build();
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
        }
    }
}