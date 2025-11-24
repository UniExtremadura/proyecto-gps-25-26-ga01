package io.audira.catalog.repository;

import io.audira.catalog.model.ModerationHistory;
import io.audira.catalog.model.ModerationStatus;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * GA01-163: Repositorio para historial de moderaciones
 */
@Repository
public interface ModerationHistoryRepository extends JpaRepository<ModerationHistory, Long> {

    /**
     * Obtener historial de moderaciones ordenado por fecha (más reciente primero)
     */
    List<ModerationHistory> findAllByOrderByModeratedAtDesc();

    /**
     * Obtener historial de un producto específico
     */
    List<ModerationHistory> findByProductIdAndProductTypeOrderByModeratedAtDesc(
            Long productId, String productType);

    /**
     * Obtener historial de moderaciones de un artista
     */
    List<ModerationHistory> findByArtistIdOrderByModeratedAtDesc(Long artistId);

    /**
     * Obtener moderaciones realizadas por un admin específico
     */
    List<ModerationHistory> findByModeratedByOrderByModeratedAtDesc(Long moderatedBy);

    /**
     * Obtener moderaciones por estado
     */
    List<ModerationHistory> findByNewStatusOrderByModeratedAtDesc(ModerationStatus newStatus);

    /**
     * Obtener moderaciones en un rango de fechas
     */
    List<ModerationHistory> findByModeratedAtBetweenOrderByModeratedAtDesc(
            LocalDateTime startDate, LocalDateTime endDate);

    /**
     * Obtener estadísticas de moderaciones
     */
    @Query("SELECT m.newStatus, COUNT(m) FROM ModerationHistory m GROUP BY m.newStatus")
    List<Object[]> getModerationStatistics();

    /**
     * Contar moderaciones por admin
     */
    @Query("SELECT m.moderatedBy, m.moderatorName, COUNT(m) FROM ModerationHistory m " +
           "GROUP BY m.moderatedBy, m.moderatorName ORDER BY COUNT(m) DESC")
    List<Object[]> getModerationsByAdmin();

    /**
     * Obtener últimas N moderaciones
     * Usar Pageable.ofSize(n) para limitar resultados
     */
    List<ModerationHistory> findAllByOrderByModeratedAtDesc(Pageable pageable);
}
