package io.audira.catalog.repository;

import io.audira.catalog.model.ModerationStatus;
import io.audira.catalog.model.Song;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.repository.query.Param;
import java.util.List;

/**
 * Repositorio JPA para la gestión de la entidad {@link Song}.
 * <p>
 * Proporciona métodos para:
 * <ul>
 * <li>Búsqueda y filtrado de canciones en el catálogo público.</li>
 * <li>Consultas administrativas (moderación y gestión de artistas).</li>
 * <li>Listados por género y popularidad.</li>
 * </ul>
 * </p>
 */
@Repository
public interface SongRepository extends JpaRepository<Song, Long> {
    /**
     * Encuentra todas las canciones de un artista específico.
     * @param artistId ID del artista.
     * @return Lista completa de canciones (incluyendo borradores y rechazadas).
     */
    List<Song> findByArtistId(Long artistId);

    /**
     * Encuentra todas las canciones pertenecientes a un álbum.
     * @param albumId ID del álbum.
     * @return Lista de canciones del álbum.
     */
    List<Song> findByAlbumId(Long albumId);

    /**
     * Busca canciones cuyo título contenga la cadena proporcionada (insensible a mayúsculas).
     * @param title Fragmento del título.
     * @return Lista de coincidencias.
     */
    List<Song> findByTitleContainingIgnoreCase(String title);

    /**
     * Recupera las 20 canciones más recientemente creadas en el sistema.
     * @return Lista de las últimas canciones subidas.
     */
    List<Song> findTop20ByOrderByCreatedAtDesc();

    /**
     * Recupera las canciones de un álbum ordenadas secuencialmente por su número de pista.
     * @param albumId ID del álbum.
     * @return Lista ordenada de tracks.
     */
    List<Song> findByAlbumIdOrderByTrackNumberAsc(Long albumId);

    /**
     * Búsqueda general por título (alias para búsqueda interna).
     * @param query Texto a buscar.
     * @return Lista de resultados.
     */
    @Query("SELECT s FROM Song s WHERE LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Song> searchByTitleOrArtist(String query);

    /**
     * Recupera todas las canciones ordenadas por fecha de creación descendente.
     * @return Lista completa cronológica inversa.
     */
    @Query("SELECT s FROM Song s ORDER BY s.createdAt DESC")
    List<Song> findRecentSongs();

    /**
     * Encuentra canciones asociadas a un género específico.
     * <p>Utiliza un JOIN implícito con la colección de IDs de géneros.</p>
     * @param genreId ID del género.
     * @return Lista de canciones.
     */
    @Query("SELECT s FROM Song s JOIN s.genreIds g WHERE g = :genreId")
    List<Song> findByGenreId(Long genreId);

    /**
     * Obtiene las canciones más populares basadas en el número de reproducciones.
     * @return Lista ordenada por número de reproducciones (descendente).
     */
    @Query("SELECT s FROM Song s ORDER BY s.plays DESC")
    List<Song> findTopByPlays();

    /**
     * Búsqueda paginada por título.
     * @param query Texto a buscar.
     * @return Página de resultados.
     */
    @Query("SELECT s FROM Song s WHERE LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Song> searchByTitle(@Param("query") String query, Pageable pageable);

    /**
     * Búsqueda paginada por IDs de artista.
     * @param artistIds Lista de IDs de artistas.
     * @return Página de resultados.
     */
    @Query("SELECT s FROM Song s WHERE s.artistId IN :artistIds")
    Page<Song> searchByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);

    /**
     * Búsqueda paginada por título O IDs de artista.
     * @param query Texto a buscar.
     * @param artistIds Lista de IDs de artistas.
     * @return Página de resultados.
     */
    @Query("SELECT s FROM Song s WHERE LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%')) OR s.artistId IN :artistIds")
    Page<Song> searchByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);

    /**
     * Recupera las 20 canciones publicadas más recientes.
     * @return Lista de las últimas canciones publicadas.
     */
    List<Song> findTop20ByPublishedTrueOrderByCreatedAtDesc();

    /**
     * Recupera las canciones publicadas más recientes.
     * @return Lista de lanzamientos recientes visibles.
     */
    @Query("SELECT s FROM Song s WHERE s.published = true ORDER BY s.createdAt DESC")
    List<Song> findRecentPublishedSongs();

    /**
     * Búsqueda pública por título.
     * @param query Texto a buscar.
     * @return Lista de resultados.
     */
    @Query("SELECT s FROM Song s WHERE s.published = true AND LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    List<Song> searchPublishedByTitleOrArtist(String query);

    /**
     * Encuentra canciones publicadas asociadas a un género específico.
     * @param genreId ID del género.
     * @return Lista de canciones.
     */
    @Query("SELECT s FROM Song s JOIN s.genreIds g WHERE s.published = true AND g = :genreId")
    List<Song> findPublishedByGenreId(Long genreId);

    /**
     * Obtiene las canciones publicadas más populares basadas en el número de reproducciones.
     * @return Lista ordenada por número de reproducciones (descendente).
     */
    @Query("SELECT s FROM Song s WHERE s.published = true ORDER BY s.plays DESC")
    List<Song> findTopPublishedByPlays();

    /**
     * Búsqueda pública paginada por título.
     * @param query Texto a buscar.
     * @return Página de resultados.
     */
    @Query("SELECT s FROM Song s WHERE s.published = true AND LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Song> searchPublishedByTitle(@Param("query") String query, Pageable pageable);

    /**
     * Búsqueda pública paginada por IDs de artista.
     * @param artistIds Lista de IDs de artistas.
     * @return Página de resultados.
     */
    @Query("SELECT s FROM Song s WHERE s.published = true AND s.artistId IN :artistIds")
    Page<Song> searchPublishedByArtistIds(@Param("artistIds") List<Long> artistIds, Pageable pageable);
    
    /**
     * Búsqueda pública con filtros avanzados (precio/género).
     * @param genreId Filtro de género (opcional).
     * @param minPrice Precio mínimo (opcional).
     * @param maxPrice Precio máximo (opcional).
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT DISTINCT s FROM Song s " +
           "LEFT JOIN s.genreIds g " + 
           "WHERE s.published = true " +
           "AND (:genreId IS NULL OR g = :genreId) " +
           "AND (:minPrice IS NULL OR s.price >= :minPrice) " +
           "AND (:maxPrice IS NULL OR s.price <= :maxPrice)")
    Page<Song> searchPublishedByFiltersOnly(
            @Param("genreId") Long genreId,
            @Param("minPrice") Double minPrice,
            @Param("maxPrice") Double maxPrice,
            Pageable pageable
    );

    /**
     * Búsqueda pública con filtros avanzados (título/IDs de artista + precio/género).
     * @param query Texto del título.
     * @param artistIds IDs de artistas coincidentes.
     * @param genreId Filtro de género (opcional).
     * @param minPrice Precio mínimo (opcional).
     * @param maxPrice Precio máximo (opcional).
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT DISTINCT s FROM Song s " +
           "LEFT JOIN s.genreIds g " + 
           "WHERE s.published = true " +
           "AND (:genreId IS NULL OR g = :genreId) " +
           "AND (:minPrice IS NULL OR s.price >= :minPrice) " +
           "AND (:maxPrice IS NULL OR s.price <= :maxPrice) " +
           "AND LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%'))")
    Page<Song> searchPublishedByTitleAndFilters(
            @Param("query") String query, 
            @Param("genreId") Long genreId,
            @Param("minPrice") Double minPrice,
            @Param("maxPrice") Double maxPrice,
            Pageable pageable
    );

    /**
     * Motor de búsqueda avanzado y facetado para el catálogo público.
     * <p>
     * Aplica lógica de filtrado dinámico: si un parámetro es {@code NULL}, se ignora ese filtro.
     * </p>
     *
     * @param query Texto a buscar en el título.
     * @param artistIds Lista de IDs de artistas que coinciden con la búsqueda de nombre.
     * @param genreId (Opcional) Filtro por género.
     * @param minPrice (Opcional) Precio mínimo.
     * @param maxPrice (Opcional) Precio máximo.
     * @param pageable Configuración de paginación y ordenamiento.
     * @return Página de canciones que cumplen todos los criterios.
     */
    @Query("SELECT DISTINCT s FROM Song s " +
           "LEFT JOIN s.genreIds g " + 
           "WHERE s.published = true " +
           "AND (:genreId IS NULL OR g = :genreId) " +
           "AND (:minPrice IS NULL OR s.price >= :minPrice) " +
           "AND (:maxPrice IS NULL OR s.price <= :maxPrice) " +
           "AND (LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%')) OR s.artistId IN :artistIds)")
    Page<Song> searchPublishedByTitleOrArtistIdsAndFilters(
            @Param("query") String query, 
            @Param("artistIds") List<Long> artistIds,
            @Param("genreId") Long genreId,
            @Param("minPrice") Double minPrice,
            @Param("maxPrice") Double maxPrice,
            Pageable pageable
    );

    /**
     * Versión simplificada de búsqueda pública (sin filtros de precio/género).
     * @param query Texto del título.
     * @param artistIds IDs de artistas coincidentes.
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT s FROM Song s WHERE s.published = true AND (LOWER(s.title) LIKE LOWER(CONCAT('%', :query, '%')) OR s.artistId IN :artistIds)")
    Page<Song> searchPublishedByTitleOrArtistIds(@Param("query") String query, @Param("artistIds") List<Long> artistIds, Pageable pageable);
    
    /**
     * Encuentra canciones por su estado de moderación.
     * @param status Estado deseado (ej: PENDING).
     * @return Lista de canciones.
     */
    List<Song> findByModerationStatus(ModerationStatus status);
    
    /**
     * Encuentra canciones por estado, ordenadas por novedad.
     * <p>Útil para colas de revisión LIFO.</p>
     * @param status Estado de moderación.
     * @return Lista ordenada por fecha de creación descendente.
     */
    List<Song> findByModerationStatusOrderByCreatedAtDesc(ModerationStatus status);

    /**
     * Consulta el estado de las canciones de un artista específico.
     * @param artistId ID del artista.
     * @param status Estado a filtrar.
     * @return Lista de canciones del artista en ese estado.
     */
    List<Song> findByArtistIdAndModerationStatus(Long artistId, ModerationStatus status);

    /**
     * Recupera una página de canciones filtrada por estado de moderación.
     * <p>Utilizado en el dashboard de administradores para paginar listas largas de tareas pendientes.</p>
     *
     * @param status Estado a filtrar.
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT s FROM Song s WHERE s.moderationStatus = :status ORDER BY s.createdAt DESC")
    Page<Song> findByModerationStatusPaged(@Param("status") ModerationStatus status, Pageable pageable);

    /**
     * Recupera una página de canciones filtrada por estado de moderación.
     * <p>Utilizado en el dashboard de administradores para paginar listas largas de tareas pendientes.</p>
     *
     * @param status Estado a filtrar.
     * @param pageable Paginación.
     * @return Página de resultados.
     */
    @Query("SELECT s FROM Song s WHERE s.moderationStatus = 'PENDING' ORDER BY s.createdAt ASC")
    List<Song> findPendingModerationSongs();

    // Contadores
    Long countByModerationStatus(ModerationStatus status);
}
