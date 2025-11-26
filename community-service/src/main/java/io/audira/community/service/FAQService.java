package io.audira.community.service;

import io.audira.community.model.FAQ;
import io.audira.community.repository.FAQRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class FAQService {

    private final FAQRepository faqRepository;

    public List<FAQ> getAllFaqs() {
        return faqRepository.findAllByOrderByDisplayOrderAscCreatedAtDesc();
    }

    public List<FAQ> getActiveFaqs() {
        return faqRepository.findByIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc();
    }

    public List<FAQ> getFaqsByCategory(String category) {
        return faqRepository.findByCategoryOrderByDisplayOrderAscCreatedAtDesc(category);
    }

    public List<FAQ> getActiveFaqsByCategory(String category) {
        return faqRepository.findByCategoryAndIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc(category);
    }

    public FAQ getFaqById(Long id) {
        return faqRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("FAQ no encontrado con id: " + id));
    }

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

    @Transactional
    public FAQ toggleActive(Long id) {
        FAQ faq = getFaqById(id);
        faq.setIsActive(!faq.getIsActive());
        log.info("Cambiando estado activo de FAQ {} a: {}", id, faq.getIsActive());
        return faqRepository.save(faq);
    }

    @Transactional
    public void deleteFaq(Long id) {
        FAQ faq = getFaqById(id);
        log.info("Eliminando FAQ con id: {}", id);
        faqRepository.delete(faq);
    }

    @Transactional
    public void incrementViewCount(Long id) {
        FAQ faq = getFaqById(id);
        faq.setViewCount(faq.getViewCount() + 1);
        faqRepository.save(faq);
    }

    @Transactional
    public void markAsHelpful(Long id) {
        FAQ faq = getFaqById(id);
        faq.setHelpfulCount(faq.getHelpfulCount() + 1);
        faqRepository.save(faq);
    }

    @Transactional
    public void markAsNotHelpful(Long id) {
        FAQ faq = getFaqById(id);
        faq.setNotHelpfulCount(faq.getNotHelpfulCount() + 1);
        faqRepository.save(faq);
    }
}
