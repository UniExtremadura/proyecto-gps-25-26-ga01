package io.audira.catalog.service;

import io.audira.catalog.model.*;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * GA01-162 y GA01-163: Servicio de moderación de contenido
 * Gestiona aprobación/rechazo de canciones y álbumes, y mantiene historial
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ModerationService {

    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    //private final ModerationHistoryRepository moderationHistoryRepository;
    //private final UserServiceClient userServiceClient;

    /**
     * GA01-162: Aprobar una canción
     */
    @Transactional
    public Song approveSong(Long songId, Long adminId, String notes) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("Canción no encontrada: " + songId));

        //ModerationStatus previousStatus = song.getModerationStatus();

        // Actualizar estado de moderación
        song.setModerationStatus(ModerationStatus.APPROVED);
        song.setModeratedBy(adminId);
        song.setModeratedAt(LocalDateTime.now());
        song.setRejectionReason(null); // Limpiar razón de rechazo si existía

        Song savedSong = songRepository.save(song);

        // Registrar en historial
        //recordModerationHistory(savedSong, previousStatus, ModerationStatus.APPROVED, adminId, null, notes);

        log.info("Canción aprobada: {} por admin: {}", songId, adminId);
        return savedSong;
    }

    /**
     * GA01-162: Rechazar una canción
     */
    @Transactional
    public Song rejectSong(Long songId, Long adminId, String rejectionReason, String notes) {
        if (rejectionReason == null || rejectionReason.trim().isEmpty()) {
            throw new IllegalArgumentException("Debe proporcionar un motivo de rechazo");
        }

        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("Canción no encontrada: " + songId));

        //ModerationStatus previousStatus = song.getModerationStatus();

        // Actualizar estado de moderación
        song.setModerationStatus(ModerationStatus.REJECTED);
        song.setModeratedBy(adminId);
        song.setModeratedAt(LocalDateTime.now());
        song.setRejectionReason(rejectionReason);
        song.setPublished(false); // Asegurar que no esté publicada

        Song savedSong = songRepository.save(song);

        // Registrar en historial
        //recordModerationHistory(savedSong, previousStatus, ModerationStatus.REJECTED, adminId, rejectionReason, notes);

        log.info("Canción rechazada: {} por admin: {} - Motivo: {}", songId, adminId, rejectionReason);
        return savedSong;
    }

    /**
     * GA01-162: Aprobar un álbum
     */
    @Transactional
    public Album approveAlbum(Long albumId, Long adminId, String notes) {
        Album album = albumRepository.findById(albumId)
                .orElseThrow(() -> new IllegalArgumentException("Álbum no encontrado: " + albumId));

        //ModerationStatus previousStatus = album.getModerationStatus();

        // Actualizar estado de moderación
        album.setModerationStatus(ModerationStatus.APPROVED);
        album.setModeratedBy(adminId);
        album.setModeratedAt(LocalDateTime.now());
        album.setRejectionReason(null);

        Album savedAlbum = albumRepository.save(album);

        // Registrar en historial
        //recordModerationHistory(savedAlbum, previousStatus, ModerationStatus.APPROVED, adminId, null, notes);

        log.info("Álbum aprobado: {} por admin: {}", albumId, adminId);
        return savedAlbum;
    }

    /**
     * GA01-162: Rechazar un álbum
     */
    @Transactional
    public Album rejectAlbum(Long albumId, Long adminId, String rejectionReason, String notes) {
        if (rejectionReason == null || rejectionReason.trim().isEmpty()) {
            throw new IllegalArgumentException("Debe proporcionar un motivo de rechazo");
        }

        Album album = albumRepository.findById(albumId)
                .orElseThrow(() -> new IllegalArgumentException("Álbum no encontrado: " + albumId));

        //ModerationStatus previousStatus = album.getModerationStatus();

        // Actualizar estado de moderación
        album.setModerationStatus(ModerationStatus.REJECTED);
        album.setModeratedBy(adminId);
        album.setModeratedAt(LocalDateTime.now());
        album.setRejectionReason(rejectionReason);
        album.setPublished(false);

        Album savedAlbum = albumRepository.save(album);

        // Registrar en historial
        //recordModerationHistory(savedAlbum, previousStatus, ModerationStatus.REJECTED,adminId, rejectionReason, notes);

        log.info("Álbum rechazado: {} por admin: {} - Motivo: {}", albumId, adminId, rejectionReason);
        return savedAlbum;
    }

    /**
     * GA01-162: Obtener contenido pendiente de moderación
     */
    public List<Song> getPendingSongs() {
        return songRepository.findPendingModerationSongs();
    }

    public List<Album> getPendingAlbums() {
        return albumRepository.findPendingModerationAlbums();
    }

    /**
     * GA01-162: Obtener contenido por estado
     */
    public List<Song> getSongsByStatus(ModerationStatus status) {
        return songRepository.findByModerationStatusOrderByCreatedAtDesc(status);
    }

    public List<Album> getAlbumsByStatus(ModerationStatus status) {
        return albumRepository.findByModerationStatusOrderByCreatedAtDesc(status);
    }

    /**
     * Marcar contenido como pendiente de revisión (cuando se modifica)
     */
    @Transactional
    public void markSongAsPending(Long songId) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("Canción no encontrada: " + songId));

        ModerationStatus previousStatus = song.getModerationStatus();
        if (previousStatus != ModerationStatus.PENDING) {
            song.setModerationStatus(ModerationStatus.PENDING);
            song.setModeratedBy(null);
            song.setModeratedAt(null);
            song.setRejectionReason(null);
            song.setPublished(false);
            songRepository.save(song);

            log.info("Canción {} marcada como pendiente de revisión", songId);
        }
    }

    @Transactional
    public void markAlbumAsPending(Long albumId) {
        Album album = albumRepository.findById(albumId)
                .orElseThrow(() -> new IllegalArgumentException("Álbum no encontrado: " + albumId));

        ModerationStatus previousStatus = album.getModerationStatus();
        if (previousStatus != ModerationStatus.PENDING) {
            album.setModerationStatus(ModerationStatus.PENDING);
            album.setModeratedBy(null);
            album.setModeratedAt(null);
            album.setRejectionReason(null);
            album.setPublished(false);
            albumRepository.save(album);

            log.info("Álbum {} marcado como pendiente de revisión", albumId);
        }
    }
}
