package io.audira.catalog.service;

import io.audira.catalog.client.UserServiceClient;
import io.audira.catalog.dto.UserDTO;
import io.audira.catalog.model.*;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.ModerationHistoryRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * Servicio encargado de la lógica de moderación de contenido.
 * <p>
 * Implementa los requisitos <b>GA01-162 (Moderación)</b> y <b>GA01-163 (Historial)</b>.
 * Coordina el flujo de aprobación y rechazo de obras musicales (Canciones y Álbumes),
 * gestionando el cambio de estados, la auditoría de acciones y las notificaciones automáticas
 * tanto al artista (feedback) como a los seguidores (nuevo lanzamiento).
 * </p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ModerationService {

    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    private final ModerationHistoryRepository moderationHistoryRepository;
    private final UserServiceClient userServiceClient;
    private final io.audira.catalog.client.NotificationClient notificationClient;

    /**
     * Aprueba una canción pendiente de revisión.
     * <p>
     * Realiza las siguientes acciones atómicas:
     * <ol>
     * <li>Cambia el estado de moderación a {@code APPROVED}.</li>
     * <li><b>Auto-publicación:</b> Establece {@code published = true} para que sea visible inmediatamente.</li>
     * <li>Registra la acción en el historial de auditoría.</li>
     * <li>Notifica al artista sobre la aprobación.</li>
     * <li>Dispara notificaciones a los seguidores del artista sobre el nuevo lanzamiento.</li>
     * </ol>
     * </p>
     *
     * @param songId  ID de la canción a aprobar.
     * @param adminId ID del administrador que realiza la acción.
     * @param notes   Notas internas opcionales sobre la aprobación.
     * @return La entidad {@link Song} actualizada.
     * @throws RuntimeException Si la canción no existe.
     */
    @Transactional
    public Song approveSong(Long songId, Long adminId, String notes) {
        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("Canción no encontrada: " + songId));

        ModerationStatus previousStatus = song.getModerationStatus();

        // Actualizar estado de moderación
        song.setModerationStatus(ModerationStatus.APPROVED);
        song.setModeratedBy(adminId);
        song.setModeratedAt(LocalDateTime.now());
        song.setRejectionReason(null); // Limpiar razón de rechazo si existía
        song.setPublished(true); // Publicar automáticamente al aprobar

        Song savedSong = songRepository.save(song);

        // Registrar en historial
        recordModerationHistory(savedSong, previousStatus, ModerationStatus.APPROVED,
                adminId, null, notes);

        // Notificar al artista que su canción fue aprobada
        try {
            notificationClient.notifyArtistApproved(savedSong.getArtistId(), "SONG", savedSong.getTitle());
        } catch (Exception e) {
            log.error("Failed to send approval notification to artist {}", savedSong.getArtistId(), e);
        }

        // Notificar a los seguidores sobre el nuevo contenido publicado
        try {
            notifyFollowersNewProduct(savedSong);
        } catch (Exception e) {
            log.error("Failed to notify followers about new song {}", songId, e);
        }

        log.info("Canción aprobada y publicada: {} por admin: {}", songId, adminId);
        return savedSong;
    }

    /**
     * Rechaza una canción indicando el motivo.
     * <p>
     * Acciones realizadas:
     * <ol>
     * <li>Cambia el estado a {@code REJECTED}.</li>
     * <li>Oculta la canción ({@code published = false}).</li>
     * <li>Registra la auditoría incluyendo la razón del rechazo.</li>
     * <li>Envía una notificación al artista con el motivo para que realice correcciones.</li>
     * </ol>
     * </p>
     *
     * @param songId          ID de la canción a rechazar.
     * @param adminId         ID del administrador.
     * @param rejectionReason Motivo obligatorio del rechazo.
     * @param notes           Notas internas adicionales.
     * @return La entidad {@link Song} actualizada.
     * @throws RuntimeException Si la canción no existe.
     */
    @Transactional
    public Song rejectSong(Long songId, Long adminId, String rejectionReason, String notes) {
        if (rejectionReason == null || rejectionReason.trim().isEmpty()) {
            throw new IllegalArgumentException("Debe proporcionar un motivo de rechazo");
        }

        Song song = songRepository.findById(songId)
                .orElseThrow(() -> new IllegalArgumentException("Canción no encontrada: " + songId));

        ModerationStatus previousStatus = song.getModerationStatus();

        // Actualizar estado de moderación
        song.setModerationStatus(ModerationStatus.REJECTED);
        song.setModeratedBy(adminId);
        song.setModeratedAt(LocalDateTime.now());
        song.setRejectionReason(rejectionReason);
        song.setPublished(false); // Asegurar que no esté publicada

        Song savedSong = songRepository.save(song);

        // Registrar en historial
        recordModerationHistory(savedSong, previousStatus, ModerationStatus.REJECTED,
                adminId, rejectionReason, notes);

        // Notificar al artista que su canción fue rechazada
        try {
            notificationClient.notifyArtistRejected(savedSong.getArtistId(), "SONG", savedSong.getTitle(), rejectionReason);
        } catch (Exception e) {
            log.error("Failed to send rejection notification to artist {}", savedSong.getArtistId(), e);
        }

        log.info("Canción rechazada: {} por admin: {} - Motivo: {}", songId, adminId, rejectionReason);
        return savedSong;
    }

    /**
     * Aprueba un álbum completo.
     * <p>
     * Similar a {@link #approveSong}, cambia el estado a {@code APPROVED}, publica el álbum automáticamente
     * y notifica tanto al artista como a su base de seguidores.
     * </p>
     *
     * @param albumId ID del álbum a aprobar.
     * @param adminId ID del administrador.
     * @param notes   Notas internas opcionales.
     * @return La entidad {@link Album} actualizada.
     * @throws RuntimeException Si el álbum no existe.
     */
    @Transactional
    public Album approveAlbum(Long albumId, Long adminId, String notes) {
        Album album = albumRepository.findById(albumId)
                .orElseThrow(() -> new IllegalArgumentException("Álbum no encontrado: " + albumId));

        ModerationStatus previousStatus = album.getModerationStatus();

        // Actualizar estado de moderación
        album.setModerationStatus(ModerationStatus.APPROVED);
        album.setModeratedBy(adminId);
        album.setModeratedAt(LocalDateTime.now());
        album.setRejectionReason(null);
        album.setPublished(true); // Publicar automáticamente al aprobar

        Album savedAlbum = albumRepository.save(album);

        // Registrar en historial
        recordModerationHistory(savedAlbum, previousStatus, ModerationStatus.APPROVED,
                adminId, null, notes);

        // Notificar al artista que su álbum fue aprobado
        try {
            notificationClient.notifyArtistApproved(savedAlbum.getArtistId(), "ALBUM", savedAlbum.getTitle());
        } catch (Exception e) {
            log.error("Failed to send approval notification to artist {}", savedAlbum.getArtistId(), e);
        }

        // Notificar a los seguidores sobre el nuevo contenido publicado
        try {
            notifyFollowersNewProduct(savedAlbum);
        } catch (Exception e) {
            log.error("Failed to notify followers about new album {}", albumId, e);
        }

        log.info("Álbum aprobado y publicado: {} por admin: {}", albumId, adminId);
        return savedAlbum;
    }

    /**
     * Rechaza un álbum completo.
     * <p>
     * Marca el álbum como {@code REJECTED}, lo despublica y notifica al artista con la razón proporcionada.
     * </p>
     *
     * @param albumId         ID del álbum.
     * @param adminId         ID del administrador.
     * @param rejectionReason Motivo obligatorio del rechazo.
     * @param notes           Notas internas.
     * @return La entidad {@link Album} actualizada.
     * @throws RuntimeException Si el álbum no existe.
     */
    @Transactional
    public Album rejectAlbum(Long albumId, Long adminId, String rejectionReason, String notes) {
        if (rejectionReason == null || rejectionReason.trim().isEmpty()) {
            throw new IllegalArgumentException("Debe proporcionar un motivo de rechazo");
        }

        Album album = albumRepository.findById(albumId)
                .orElseThrow(() -> new IllegalArgumentException("Álbum no encontrado: " + albumId));

        ModerationStatus previousStatus = album.getModerationStatus();

        // Actualizar estado de moderación
        album.setModerationStatus(ModerationStatus.REJECTED);
        album.setModeratedBy(adminId);
        album.setModeratedAt(LocalDateTime.now());
        album.setRejectionReason(rejectionReason);
        album.setPublished(false);

        Album savedAlbum = albumRepository.save(album);

        // Registrar en historial
        recordModerationHistory(savedAlbum, previousStatus, ModerationStatus.REJECTED,
                adminId, rejectionReason, notes);

        // Notificar al artista que su álbum fue rechazado
        try {
            notificationClient.notifyArtistRejected(savedAlbum.getArtistId(), "ALBUM", savedAlbum.getTitle(), rejectionReason);
        } catch (Exception e) {
            log.error("Failed to send rejection notification to artist {}", savedAlbum.getArtistId(), e);
        }

        log.info("Álbum rechazado: {} por admin: {} - Motivo: {}", albumId, adminId, rejectionReason);
        return savedAlbum;
    }

    /**
     * Obtiene la cola de canciones pendientes de moderación.
     * <p>
     * Recupera todas las canciones cuyo estado actual es {@code PENDING}.
     * </p>
     *
     * @return Lista de canciones esperando revisión.
     */
    public List<Song> getPendingSongs() {
        return songRepository.findPendingModerationSongs();
    }

    /**
     * Obtiene la cola de álbumes pendientes de moderación.
     * <p>
     * Recupera todos los álbumes cuyo estado actual es {@code PENDING}.
     * </p>
     *
     * @return Lista de álbumes esperando revisión.
     */
    public List<Album> getPendingAlbums() {
        return albumRepository.findPendingModerationAlbums();
    }

    /**
     * Recupera una lista de canciones filtrada por su estado de moderación.
     * <p>
     * Permite obtener no solo las pendientes, sino también consultar el histórico de
     * canciones aprobadas o rechazadas para auditoría.
     * </p>
     *
     * @param status El estado de moderación deseado ({@code PENDING}, {@code APPROVED}, {@code REJECTED}).
     * @return Lista de canciones que coinciden con el estado.
     */
    public List<Song> getSongsByStatus(ModerationStatus status) {
        return songRepository.findByModerationStatusOrderByCreatedAtDesc(status);
    }

    /**
     * Recupera una lista de álbumes filtrada por su estado de moderación.
     *
     * @param status El estado de moderación deseado.
     * @return Lista de álbumes que coinciden con el estado.
     */
    public List<Album> getAlbumsByStatus(ModerationStatus status) {
        return albumRepository.findByModerationStatusOrderByCreatedAtDesc(status);
    }

    /**
     * Recupera el historial completo de moderación asociado a un artista.
     * <p>
     * Permite visualizar todas las acciones (aprobaciones/rechazos) realizadas sobre
     * el catálogo de un artista específico, ordenadas cronológicamente.
     * </p>
     *
     * @param artistId ID del artista.
     * @return Lista de registros de historial.
     */
    public List<ModerationHistory> getModerationHistory() {
        return moderationHistoryRepository.findAllByOrderByModeratedAtDesc();
    }

    /**
     * Obtiene el historial de moderación específico de un producto (Canción o Álbum).
     * <p>
     * Proporciona la trazabilidad completa del ciclo de vida de una obra: cuándo se subió,
     * cuándo se rechazó (y por qué), y cuándo se aprobó finalmente.
     * </p>
     *
     * @param productId   ID único del producto.
     * @param productType Tipo de producto ("SONG" o "ALBUM").
     * @return Lista cronológica de eventos de moderación para ese ítem.
     */
    public List<ModerationHistory> getProductModerationHistory(Long productId, String productType) {
        return moderationHistoryRepository.findByProductIdAndProductTypeOrderByModeratedAtDesc(
                productId, productType);
    }

    /**
     * Recupera todo el historial de moderación relacionado con un artista.
     * <p>
     * Útil para detectar patrones de comportamiento (ej: un artista que sistemáticamente
     * sube contenido que infringe copyright).
     * </p>
     *
     * @param artistId ID del artista.
     * @return Lista de eventos de moderación de todo su catálogo.
     */
    public List<ModerationHistory> getArtistModerationHistory(Long artistId) {
        return moderationHistoryRepository.findByArtistIdOrderByModeratedAtDesc(artistId);
    }

    /**
     * Registra manualmente un evento en el historial de moderación.
     * <p>
     * Aunque el historial suele ser automático, este método permite a los administradores
     * añadir notas o registros de auditoría sin necesariamente cambiar el estado del producto
     * (ej: "Revisión parcial realizada, pendiente de segunda opinión").
     * </p>
     *
     * @param product   La entidad producto (Canción o Álbum) sobre la que se anota.
     * @param newStatus El estado reportado en este registro.
     * @param adminId   ID del administrador que crea el registro.
     * @param notes     Notas o comentarios de auditoría.
     */
    private void recordModerationHistory(Product product, ModerationStatus previousStatus,
                                        ModerationStatus newStatus, Long moderatedBy,
                                        String rejectionReason, String notes) {
        // Obtener información del moderador
        UserDTO moderator = userServiceClient.getUserById(moderatedBy);

        // Obtener información del artista
        UserDTO artist = userServiceClient.getUserById(product.getArtistId());

        // GA01-163: Determinar el nombre del artista con fallbacks apropiados
        String artistName = "Desconocido";
        if (artist != null) {
            // Prioridad: artistName > username > firstName + lastName
            if (artist.getArtistName() != null && !artist.getArtistName().trim().isEmpty()) {
                artistName = artist.getArtistName();
            } else if (artist.getUsername() != null) {
                artistName = artist.getUsername();
            } else if (artist.getFirstName() != null && artist.getLastName() != null) {
                artistName = artist.getFirstName() + " " + artist.getLastName();
            }
        }

        ModerationHistory history = ModerationHistory.builder()
                .productId(product.getId())
                .productType(product.getProductType())
                .productTitle(product.getTitle())
                .artistId(product.getArtistId())
                .artistName(artistName)
                .previousStatus(previousStatus)
                .newStatus(newStatus)
                .moderatedBy(moderatedBy)
                .moderatorName(moderator != null ? moderator.getUsername() : "Admin #" + moderatedBy)
                .rejectionReason(rejectionReason)
                .notes(notes)
                .moderatedAt(LocalDateTime.now())
                .build();

        moderationHistoryRepository.save(history);
        log.debug("Historial de moderación registrado para producto {} ({})", product.getId(), product.getProductType());
    }

    /**
     * Revierte el estado de una canción a "Pendiente de Revisión".
     * <p>
     * Útil si una canción fue aprobada o rechazada por error y necesita volver a la cola
     * de trabajo de los moderadores. Al hacerlo, la canción se oculta del público ({@code published = false}).
     * </p>
     *
     * @param songId ID de la canción a resetear.
     * @return La canción actualizada en estado {@code PENDING}.
     * @throws RuntimeException Si la canción no existe.
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

    /**
     * Revierte el estado de un álbum a "Pendiente de Revisión".
     * <p>
     * Devuelve el álbum a la cola de moderación y lo retira de la visibilidad pública.
     * </p>
     *
     * @param albumId ID del álbum a resetear.
     * @return El álbum actualizada en estado {@code PENDING}.
     * @throws RuntimeException Si el álbum no existe.
     */
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

    /**
     * Método auxiliar privado para notificar a los seguidores sobre un nuevo lanzamiento.
     * <p>
     * Se ejecuta tras la aprobación exitosa de un contenido. Obtiene la lista de seguidores
     * del artista y envía una notificación individual a cada uno.
     * </p>
     *
     * @param product El producto (Canción o Álbum) que acaba de ser publicado.
     */
    private void notifyFollowersNewProduct(Product product) {
        try {
            // Obtener seguidores del artista
            List<Long> followerIds = userServiceClient.getFollowerIds(product.getArtistId());

            if (followerIds.isEmpty()) {
                log.debug("Artista {} no tiene seguidores para notificar", product.getArtistId());
                return;
            }

            // Obtener información del artista
            UserDTO artist = userServiceClient.getUserById(product.getArtistId());
            String artistName = artist != null && artist.getArtistName() != null
                ? artist.getArtistName()
                : (artist != null ? artist.getUsername() : "Artista");

            // Enviar notificación a cada seguidor
            for (Long followerId : followerIds) {
                try {
                    notificationClient.notifyNewProduct(
                        followerId,
                        product.getProductType(),
                        product.getTitle(),
                        artistName
                    );
                } catch (Exception e) {
                    log.warn("Failed to notify follower {} about new product {}", followerId, product.getId(), e);
                }
            }

            log.info("Notificados {} seguidores sobre nuevo producto: {} ({})",
                followerIds.size(), product.getTitle(), product.getProductType());

        } catch (Exception e) {
            log.error("Error notifying followers about new product {}", product.getId(), e);
        }
    }
}
