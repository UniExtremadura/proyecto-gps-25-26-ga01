package io.audira.community.service;

import io.audira.community.model.FAQ;
import io.audira.community.repository.FAQRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Servicio de lógica de negocio responsable de la gestión de las Preguntas Frecuentes (FAQ).
 * <p>
 * Implementa las operaciones CRUD para la entidad {@link FAQ}, así como métodos para
 * la consulta por estado (activo/inactivo), por categoría y el registro de estadísticas
 * de utilidad y visualización.
 * </p>
 *
 * @author Grupo GA01
 * @see FAQRepository
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FAQService {

    private final FAQRepository faqRepository;

    // --- Métodos de Consulta ---

    /**
     * Obtiene una lista de todas las FAQ en el sistema (vista administrativa), ordenadas por orden de visualización y fecha de creación.
     *
     * @return Una {@link List} de todas las {@link FAQ}.
     */
    public List<FAQ> getAllFaqs() {
        return faqRepository.findAllByOrderByDisplayOrderAscCreatedAtDesc();
    }

    /**
     * Obtiene una lista de las FAQ marcadas como activas (vista pública), ordenadas por orden de visualización y fecha de creación.
     *
     * @return Una {@link List} de {@link FAQ} activas.
     */
    public List<FAQ> getActiveFaqs() {
        return faqRepository.findByIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc();
    }

    /**
     * Obtiene una lista de todas las FAQ (activas e inactivas) de una categoría específica, ordenadas por orden de visualización y fecha de creación.
     *
     * @param category La categoría (tipo {@link String}) por la cual filtrar.
     * @return Una {@link List} de {@link FAQ} de la categoría.
     */
    public List<FAQ> getFaqsByCategory(String category) {
        return faqRepository.findByCategoryOrderByDisplayOrderAscCreatedAtDesc(category);
    }

    /**
     * Obtiene una lista de las FAQ activas de una categoría específica (vista pública/filtrada), ordenadas por orden de visualización y fecha de creación.
     *
     * @param category La categoría (tipo {@link String}) por la cual filtrar.
     * @return Una {@link List} de {@link FAQ} activas de la categoría.
     */
    public List<FAQ> getActiveFaqsByCategory(String category) {
        return faqRepository.findByCategoryAndIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc(category);
    }

    /**
     * Obtiene una FAQ específica por su ID.
     *
     * @param id ID de la FAQ (tipo {@link Long}).
     * @return El objeto {@link FAQ} encontrado.
     * @throws RuntimeException si la FAQ no se encuentra.
     */
    public FAQ getFaqById(Long id) {
        return faqRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("FAQ no encontrado con id: " + id));
    }

    // --- Métodos de Administración (CRUD y Modificación) ---

    /**
     * Crea y persiste una nueva FAQ.
     *
     * @param faq El objeto {@link FAQ} a crear.
     * @return La FAQ persistida.
     * @throws IllegalArgumentException si faltan la pregunta, la respuesta o la categoría.
     */
    @Transactional
    public FAQ createFaq(FAQ faq) {
        if (faq.getQuestion() == null || faq.getQuestion().trim().isEmpty()) {
            throw new IllegalArgumentException("La pregunta es obligatoria");
        }
        if (faq.getAnswer() == null || faq.getAnswer().trim().isEmpty()) {
            throw new IllegalArgumentException("La respuesta es obligatoria");
        }
        if (faq.getCategory() == null || faq.getCategory().trim().isEmpty()) {
            throw new IllegalArgumentException("La categoría es obligatoria");
        }

        log.info("Creando FAQ: {}", faq.getQuestion());
        return faqRepository.save(faq);
    }

    /**
     * Actualiza los detalles de una FAQ existente.
     * <p>
     * Solo actualiza los campos que se proporcionan en {@code faqDetails} (actualización parcial).
     * </p>
     *
     * @param id ID de la FAQ a actualizar.
     * @param faqDetails El objeto {@link FAQ} con los nuevos detalles.
     * @return La FAQ actualizada.
     * @throws RuntimeException si la FAQ no se encuentra.
     */
    @Transactional
    public FAQ updateFaq(Long id, FAQ faqDetails) {
        FAQ faq = getFaqById(id);

        if (faqDetails.getQuestion() != null && !faqDetails.getQuestion().trim().isEmpty()) {
            faq.setQuestion(faqDetails.getQuestion());
        }
        if (faqDetails.getAnswer() != null && !faqDetails.getAnswer().trim().isEmpty()) {
            faq.setAnswer(faqDetails.getAnswer());
        }
        if (faqDetails.getCategory() != null && !faqDetails.getCategory().trim().isEmpty()) {
            faq.setCategory(faqDetails.getCategory());
        }
        if (faqDetails.getDisplayOrder() != null) {
            faq.setDisplayOrder(faqDetails.getDisplayOrder());
        }
        if (faqDetails.getIsActive() != null) {
            faq.setIsActive(faqDetails.getIsActive());
        }

        log.info("Actualizando FAQ con id: {}", id);
        return faqRepository.save(faq);
    }

    /**
     * Alterna el estado de actividad ({@code isActive}) de una FAQ (de {@code true} a {@code false} y viceversa).
     *
     * @param id ID de la FAQ a modificar.
     * @return La FAQ actualizada.
     * @throws RuntimeException si la FAQ no se encuentra.
     */
    @Transactional
    public FAQ toggleActive(Long id) {
        FAQ faq = getFaqById(id);
        faq.setIsActive(!faq.getIsActive());
        log.info("Cambiando estado activo de FAQ {} a: {}", id, faq.getIsActive());
        return faqRepository.save(faq);
    }

    /**
     * Elimina una FAQ del sistema.
     *
     * @param id ID de la FAQ a eliminar.
     * @throws RuntimeException si la FAQ no se encuentra.
     */
    @Transactional
    public void deleteFaq(Long id) {
        FAQ faq = getFaqById(id);
        log.info("Eliminando FAQ con id: {}", id);
        faqRepository.delete(faq);
    }

    // --- Métodos de Estadísticas y Retroalimentación ---

    /**
     * Incrementa el contador de visualizaciones ({@code viewCount}) de una FAQ.
     *
     * @param id ID de la FAQ.
     * @throws RuntimeException si la FAQ no se encuentra.
     */
    @Transactional
    public void incrementViewCount(Long id) {
        FAQ faq = getFaqById(id);
        faq.setViewCount(faq.getViewCount() + 1);
        faqRepository.save(faq);
    }

    /**
     * Registra un voto positivo ("útil") para una FAQ, incrementando {@code helpfulCount}.
     *
     * @param id ID de la FAQ.
     * @throws RuntimeException si la FAQ no se encuentra.
     */
    @Transactional
    public void markAsHelpful(Long id) {
        FAQ faq = getFaqById(id);
        faq.setHelpfulCount(faq.getHelpfulCount() + 1);
        faqRepository.save(faq);
    }

    /**
     * Registra un voto negativo ("no útil") para una FAQ, incrementando {@code notHelpfulCount}.
     *
     * @param id ID de la FAQ.
     * @throws RuntimeException si la FAQ no se encuentra.
     */
    @Transactional
    public void markAsNotHelpful(Long id) {
        FAQ faq = getFaqById(id);
        faq.setNotHelpfulCount(faq.getNotHelpfulCount() + 1);
        faqRepository.save(faq);
    }
}