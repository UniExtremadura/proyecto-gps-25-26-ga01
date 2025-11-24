package io.audira.catalog.repository;

import io.audira.catalog.model.Album;
import io.audira.catalog.model.ModerationStatus;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.query.Param;
import java.util.List;

@Repository
public interface AlbumRepository extends JpaRepository<Album, Long>{
    // Métodos sin filtro de publicación (para studio/admin)
    List<Album> findTop20ByOrderByCreatedAtDesc();

    List<Album> findByArtistId(Long artistId);

    @Query("SELECT a FROM Album a ORDER BY a.releaseDate DESC")
    List<Album> findRecentAlbums();

    @Query("SELECT a FROM Album a WHERE LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Album> searchByTitle(@Param("query") String query, Pageable pageable);

    @Query("SELECT a FROM Album a WHERE a.artistId IN :artistIds")
    Page<Album> searchByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);

    @Query("SELECT a FROM Album a WHERE LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%')) OR a.artistId IN :artistIds")
    Page<Album> searchByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);

    // Métodos con filtro de publicación (para vistas públicas)
    List<Album> findTop20ByPublishedTrueOrderByCreatedAtDesc();

    @Query("SELECT a FROM Album a WHERE a.published = true ORDER BY a.releaseDate DESC")
    List<Album> findRecentPublishedAlbums();

    @Query("SELECT a FROM Album a WHERE a.published = true AND LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Album> searchPublishedByTitle(@Param("query") String query, Pageable pageable);

    @Query("SELECT a FROM Album a WHERE a.published = true AND a.artistId IN :artistIds")
    Page<Album> searchPublishedByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);

    // Solo filtros (sin query de texto)
    @Query("SELECT DISTINCT a FROM Album a " +
           "LEFT JOIN a.genreIds g " + 
           "WHERE a.published = true " +
           "AND (:genreId IS NULL OR g = :genreId) " +
           "AND (:minPrice IS NULL OR a.price >= :minPrice) " +
           "AND (:maxPrice IS NULL OR a.price <= :maxPrice)")
    Page<Album> searchPublishedByFiltersOnly(
            @Param("genreId") Long genreId,
            @Param("minPrice") Double minPrice,
            @Param("maxPrice") Double maxPrice,
            Pageable pageable
    );

    // Búsqueda por título con filtros
    @Query("SELECT DISTINCT a FROM Album a " +
           "LEFT JOIN a.genreIds g " + 
           "WHERE a.published = true " +
           "AND (:genreId IS NULL OR g = :genreId) " +
           "AND (:minPrice IS NULL OR a.price >= :minPrice) " +
           "AND (:maxPrice IS NULL OR a.price <= :maxPrice) " +
           "AND LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Album> searchPublishedByTitleAndFilters(
            @Param("query") String query, 
            @Param("genreId") Long genreId,
            @Param("minPrice") Double minPrice,
            @Param("maxPrice") Double maxPrice,
            Pageable pageable
    );

    // Búsqueda por título O artistIds con filtros
    @Query("SELECT DISTINCT a FROM Album a " +
           "LEFT JOIN a.genreIds g " + 
           "WHERE a.published = true " +
           "AND (:genreId IS NULL OR g = :genreId) " +
           "AND (:minPrice IS NULL OR a.price >= :minPrice) " +
           "AND (:maxPrice IS NULL OR a.price <= :maxPrice) " +
           "AND (LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%')) OR a.artistId IN :artistIds)")
    Page<Album> searchPublishedByTitleOrArtistIdsAndFilters(
            @Param("query") String query, 
            @Param("artistIds") List<Long> artistIds,
            @Param("genreId") Long genreId,
            @Param("minPrice") Double minPrice,
            @Param("maxPrice") Double maxPrice,
            Pageable pageable
    );

    @Query("SELECT a FROM Album a WHERE a.published = true AND (LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%')) OR a.artistId IN :artistIds)")
    Page<Album> searchPublishedByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);

    List<Album> findByModerationStatus(ModerationStatus status);
    List<Album> findByModerationStatusOrderByCreatedAtDesc(ModerationStatus status);
    List<Album> findByArtistIdAndModerationStatus(Long artistId, ModerationStatus status);
    Long countByModerationStatus(ModerationStatus status);
    
    @Query("SELECT a FROM Album a WHERE a.moderationStatus = :status ORDER BY a.createdAt DESC")
    Page<Album> findByModerationStatusPaged(@Param("status") ModerationStatus status, Pageable pageable);
    
    @Query("SELECT a FROM Album a WHERE a.moderationStatus = 'PENDING' ORDER BY a.createdAt ASC")
    List<Album> findPendingModerationAlbums();
}
