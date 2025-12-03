package io.audira.catalog.repository;

import io.audira.catalog.model.Collaborator;
import io.audira.catalog.model.CollaborationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositorio JPA para la entidad {@link Collaborator}.
 * <p>
 * Implementa las consultas necesarias para <b>GA01-154 (Gestión de Colaboradores)</b>.
 * Permite distinguir entre colaboradores activos (ACCEPTED) e invitaciones pendientes (PENDING).
 * </p>
 */
@Repository
public interface CollaboratorRepository extends JpaRepository<Collaborator, Long> {

    // --- Consultas Generales (Sin filtro de estado) ---
    /** Encuentra todos los colaboradores de una canción. */
    List<Collaborator> findBySongId(Long songId);

    /** Encuentra todas las colaboraciones de un artista. */
    List<Collaborator> findByArtistId(Long artistId);

    /** Elimina todos los colaboradores de una canción. */
    void deleteBySongId(Long songId);

    /** Encuentra todos los colaboradores de un álbum. */
    List<Collaborator> findByAlbumId(Long albumId);

    // --- Consultas por Estado (Invitaciones) ---
    /**
     * Encuentra las colaboraciones de un artista filtradas por estado.
     * <p>Ej: Ver todas las invitaciones PENDING de un usuario.</p>
     */
    List<Collaborator> findByArtistIdAndStatus(Long artistId, CollaborationStatus status);

    /**
     * Encuentra los colaboradores de una canción con un estado específico.
     * <p>Ej: Obtener solo los colaboradores ACCEPTED para mostrar en los créditos.</p>
     */
    List<Collaborator> findBySongIdAndStatus(Long songId, CollaborationStatus status);

    /**
     * Encuentra los colaboradores de un álbum con un estado específico.
     */
    List<Collaborator> findByAlbumIdAndStatus(Long albumId, CollaborationStatus status);

    /**
     * Encuentra las invitaciones enviadas por un usuario específico (dueño del contenido).
     * @param invitedBy ID del usuario que envió la invitación.
     * @return Lista de colaboraciones iniciadas por este usuario.
     */
    List<Collaborator> findByInvitedBy(Long invitedBy);

    /** Elimina todos los colaboradores de un álbum. */
    void deleteByAlbumId(Long albumId);
}