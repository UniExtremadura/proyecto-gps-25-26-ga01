package io.audira.catalog.repository;

import io.audira.catalog.model.FeaturedContent;
import io.audira.catalog.model.FeaturedContent.ContentType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * Repository for FeaturedContent entity
 * GA01-156: Seleccionar/ordenar contenido destacado
 * GA01-157: Programación de destacados
 */
@Repository
public interface FeaturedContentRepository extends JpaRepository<FeaturedContent, Long> {

    /**
     * Find all featured content ordered by display order
     * GA01-156
     */
    List<FeaturedContent> findAllByOrderByDisplayOrderAsc();

    /**
     * Find active featured content within the scheduled period
     * GA01-157: Programación de destacados
     */
    @Query("SELECT fc FROM FeaturedContent fc WHERE fc.isActive = true " +
           "AND (fc.startDate IS NULL OR fc.startDate <= :now) " +
           "AND (fc.endDate IS NULL OR fc.endDate >= :now) " +
           "ORDER BY fc.displayOrder ASC")
    List<FeaturedContent> findActiveScheduledContent(@Param("now") LocalDateTime now);

    /**
     * Find by content type and content id
     * GA01-156
     */
    Optional<FeaturedContent> findByContentTypeAndContentId(ContentType contentType, Long contentId);

    /**
     * Check if content already exists as featured
     * GA01-156
     */
    boolean existsByContentTypeAndContentId(ContentType contentType, Long contentId);

    /**
     * Find all active featured content (regardless of schedule)
     * GA01-156
     */
    List<FeaturedContent> findByIsActiveTrueOrderByDisplayOrderAsc();

    /**
     * Find featured content by type
     * GA01-156
     */
    List<FeaturedContent> findByContentTypeOrderByDisplayOrderAsc(ContentType contentType);

    /**
     * Get the maximum display order to add new items at the end
     * GA01-156
     */
    @Query("SELECT MAX(fc.displayOrder) FROM FeaturedContent fc")
    Integer findMaxDisplayOrder();
}
