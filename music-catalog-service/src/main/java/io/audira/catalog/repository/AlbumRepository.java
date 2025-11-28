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

/**
 * Repositorio JPA para la gestión de la entidad {@link Album}.
 * <p>
 * Contiene lógica crítica de descubrimiento, incluyendo búsquedas de texto completo (título/artista),
 * filtrado por rangos de precio, filtrado por género y gestión de colas de moderación.
 * </p>
 */
@Repository
public interface AlbumRepository extends JpaRepository<Album, Long>{
    /**
     * Recupera los 20 álbumes más recientes por fecha de creación.
     * <p>Utilizado en el dashboard del estudio o panel de administración.</p>
     * @return Lista de álbumes recientes.
     */
    List<Album> findTop20ByOrderByCreatedAtDesc();

    /**
     * Encuentra todos los álbumes de un artista específico.
     * @param artistId ID del artista.
     * @return Lista completa de álbumes (publicados y borradores).
     */
    List<Album> findByArtistId(Long artistId);

    /**
     * Recupera álbumes ordenados por fecha de lanzamiento oficial.
     * @return Lista ordenada cronológicamente descendente.
     */
    @Query("SELECT a FROM Album a ORDER BY a.releaseDate DESC")
    List<Album> findRecentAlbums();

    /**
     * Busca álbumes que contengan el texto en el título.
     * @param query Texto a buscar.
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT a FROM Album a WHERE LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Album> searchByTitle(@Param("query") String query, Pageable pageable);

    /**
     * Busca álbumes pertenecientes a una lista de artistas.
     * @param artistIds Lista de IDs de artistas.
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT a FROM Album a WHERE a.artistId IN :artistIds")
    Page<Album> searchByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);

    /**
     * Búsqueda híbrida por título O por lista de artistas.
     * @param query Texto del título.
     * @param artistIds Lista de IDs de artistas (posibles coincidencias de nombre).
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT a FROM Album a WHERE LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%')) OR a.artistId IN :artistIds")
    Page<Album> searchByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);
        
    /** 
     * Recupera los 20 álbumes publicados más recientes.
     * <p>Filtra explícitamente por {@code published = true}.</p>
     * @return Lista de álbumes publicados recientes.
     */
    List<Album> findTop20ByPublishedTrueOrderByCreatedAtDesc();

    /**
     * Recupera los álbumes publicados más recientes.
     * <p>Filtra explícitamente por {@code published = true}.</p>
     * @return Lista de lanzamientos públicos recientes.
     */
    @Query("SELECT a FROM Album a WHERE a.published = true ORDER BY a.releaseDate DESC")
    List<Album> findRecentPublishedAlbums();

    /**
     * Busca álbumes publicados que contengan el texto en el título.
     * @param query Texto a buscar.
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT a FROM Album a WHERE a.published = true AND LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Album> searchPublishedByTitle(@Param("query") String query, Pageable pageable);

    /**
     * Busca álbumes publicados pertenecientes a una lista de artistas.
     * @param artistIds Lista de IDs de artistas.
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT a FROM Album a WHERE a.published = true AND a.artistId IN :artistIds")
    Page<Album> searchPublishedByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);

    /**
     * Búsqueda pública híbrida por título O por lista de artistas, con filtros opcionales de precio y género.
     * @param query Texto del título.
     * @param artistIds Lista de IDs de artistas (posibles coincidencias de nombre).
     * @param genreId Filtro opcional de género (puede ser null).
     * @param minPrice Filtro opcional de precio mínimo (puede ser null).
     * @param maxPrice Filtro opcional de precio máximo (puede ser null).
     * @param pageable Paginación.
     * @return Página de resultados.
     */
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

    /**
     * Motor de búsqueda avanzado para el catálogo público.
     * <p>
     * Aplica múltiples filtros opcionales:
     * <ul>
     * <li>Solo álbumes publicados ({@code published = true}).</li>
     * <li>Coincidencia por Género (si {@code genreId} no es nulo).</li>
     * <li>Rango de precios ({@code minPrice}, {@code maxPrice}).</li>
     * <li>Coincidencia por texto en título O autoría.</li>
     * </ul>
     * </p>
     *
     * @param query Texto de búsqueda.
     * @param artistIds IDs de artistas coincidentes con el texto.
     * @param genreId Filtro opcional por género.
     * @param minPrice Precio mínimo.
     * @param maxPrice Precio máximo.
     * @param pageable Configuración de paginación y ordenamiento.
     * @return Página de álbumes que cumplen todos los criterios.
     */
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

    /**
     * Motor de búsqueda avanzado para el catálogo público.
     * <p>
     * Aplica múltiples filtros opcionales:
     * <ul>
     * <li>Solo álbumes publicados ({@code published = true}).</li>
     * <li>Coincidencia por Género (si {@code genreId} no es nulo).</li>
     * <li>Rango de precios ({@code minPrice}, {@code maxPrice}).</li>
     * <li>Coincidencia por autoría.</li>
     * </ul>
     * </p>
     *
     * @param artistIds IDs de artistas coincidentes con el texto.
     * @param genreId Filtro opcional por género.
     * @param minPrice Precio mínimo.
     * @param maxPrice Precio máximo.
     * @param pageable Configuración de paginación y ordenamiento.
     * @return Página de álbumes que cumplen todos los criterios.
     */
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

    /**
     * Búsqueda híbrida pública por título O por lista de artistas.
     * @param query Texto del título.
     * @param artistIds Lista de IDs de artistas (posibles coincidencias de nombre).
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT a FROM Album a WHERE a.published = true AND (LOWER(a.title) LIKE LOWER(CONCAT('%', :query, '%')) OR a.artistId IN :artistIds)")
    Page<Album> searchPublishedByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);

    /**
     * Busca álbumes por su estado de moderación exacto.
     * @param status Estado deseado (ej: PENDING).
     * @return Lista de álbumes.
     */
    List<Album> findByModerationStatus(ModerationStatus status);
    
    /**
     * Busca álbumes por su estado de moderación, ordenados por fecha de creación descendente.
     * @param status Estado deseado (ej: APPROVED).
     * @return Lista de álbumes.
     */
    List<Album> findByModerationStatusOrderByCreatedAtDesc(ModerationStatus status);
    
    /**
     * Busca álbumes de un artista específico filtrados por estado de moderación.
     * @param artistId ID del artista.
     * @param status Estado deseado.
     * @return Lista de álbumes.
     */
    List<Album> findByArtistIdAndModerationStatus(Long artistId, ModerationStatus status);
    
    /**
     * Cuenta el número de álbumes por estado de moderación.
     * @param status Estado a contar.
     * @return Número de álbumes.
     */
    Long countByModerationStatus(ModerationStatus status);
    
   /**
     * Recupera una página de álbumes filtrada por estado de moderación.
     * @param status Estado a filtrar.
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT a FROM Album a WHERE a.moderationStatus = :status ORDER BY a.createdAt DESC")
    Page<Album> findByModerationStatusPaged(@Param("status") ModerationStatus status, Pageable pageable);
    
    /**
     * Recupera todos los álbumes que están pendientes de moderación, ordenados por fecha de creación ascendente.
     * <p>Útil para procesar la cola de moderación en orden FIFO.</p>
     * @return Lista de álbumes pendientes de moderación.
     */
    @Query("SELECT a FROM Album a WHERE a.moderationStatus = 'PENDING' ORDER BY a.createdAt ASC")
    List<Album> findPendingModerationAlbums();
}
