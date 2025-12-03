package io.audira.catalog.repository;

import io.audira.catalog.model.Playlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositorio JPA para la entidad {@link Playlist}.
 * <p>
 * Soporta los requisitos de gestión de listas:
 * <ul>
 * <li><b>GA01-113:</b> Visualización de listas propias.</li>
 * <li><b>GA01-115:</b> Eliminación y búsqueda de listas públicas.</li>
 * </ul>
 * </p>
 */
@Repository
public interface PlaylistRepository extends JpaRepository<Playlist, Long> {

    /**
     * Encuentra todas las listas de reproducción creadas por un usuario específico.
     *
     * @param userId ID del usuario creador.
     * @return Lista de playlists del usuario.
     */
    List<Playlist> findByUserId(Long userId);

    /**
     * Encuentra todas las listas de reproducción marcadas como públicas.
     * <p>Utilizado en la sección de descubrimiento o comunidad.</p>
     *
     * @return Lista de todas las playlists públicas del sistema.
     */
    List<Playlist> findByIsPublicTrue();

    /**
     * Encuentra playlists de un usuario filtrando por visibilidad.
     * <p>Ej: Ver solo las listas públicas de otro usuario en su perfil.</p>
     *
     * @param userId ID del usuario.
     * @param isPublic Estado de visibilidad (true/false).
     * @return Lista filtrada.
     */
    List<Playlist> findByUserIdAndIsPublic(Long userId, Boolean isPublic);

    /**
     * Elimina todas las listas de reproducción de un usuario.
     * <p>
     * Se ejecuta típicamente cuando un usuario elimina su cuenta (Derecho al olvido/GDPR).
     * </p>
     *
     * @param userId ID del usuario.
     */
    void deleteByUserId(Long userId);
}
