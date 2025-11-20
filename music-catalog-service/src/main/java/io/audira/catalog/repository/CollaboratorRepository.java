package io.audira.catalog.repository;

import io.audira.catalog.model.Collaborator;
import io.audira.catalog.model.CollaborationStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repository for Collaborator entity
 * GA01-154: Añadir/aceptar colaboradores - status queries
 */
@Repository
public interface CollaboratorRepository extends JpaRepository<Collaborator, Long> {

    // Existing queries
    List<Collaborator> findBySongId(Long songId);

    List<Collaborator> findByArtistId(Long artistId);

    void deleteBySongId(Long songId);

    // GA01-154: New queries for collaboration invitations
    List<Collaborator> findByAlbumId(Long albumId);

    List<Collaborator> findByArtistIdAndStatus(Long artistId, CollaborationStatus status);

    List<Collaborator> findBySongIdAndStatus(Long songId, CollaborationStatus status);

    List<Collaborator> findByAlbumIdAndStatus(Long albumId, CollaborationStatus status);

    List<Collaborator> findByInvitedBy(Long invitedBy);

    void deleteByAlbumId(Long albumId);
}