package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Entidad que representa una Lista de Reproducción creada por un usuario.
 * <p>
 * Soporta las funcionalidades de:
 * <ul>
 * <li><b>GA01-113:</b> Creación y visualización.</li>
 * <li><b>GA01-114:</b> Gestión de canciones (añadir/quitar).</li>
 * <li><b>GA01-115:</b> Edición y borrado.</li>
 * </ul>
 * </p>
 */
@Entity
@Table(name = "playlists")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Playlist {

    /** Identificador único de la playlist. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** ID del usuario creador/dueño de la lista. */
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /** Nombre de la lista. */
    @Column(nullable = false, length = 100)
    private String name;

    /** Descripción opcional. */
    @Column(columnDefinition = "TEXT")
    private String description;

    /**
     * Visibilidad de la lista.
     * <p>Si es {@code true}, aparece en búsquedas y perfiles públicos.</p>
     */
    @Column(name = "is_public", nullable = false)
    @Builder.Default
    private Boolean isPublic = false;

    /**
     * Lista ordenada de IDs de canciones.
     * <p>
     * Se utiliza {@code @OrderColumn} para mantener el orden de inserción/reordenamiento
     * persistido en la base de datos (columna {@code song_order}).
     * </p>
     */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "playlist_songs", joinColumns = @JoinColumn(name = "playlist_id"))
    @Column(name = "song_id")
    @OrderColumn(name = "song_order")
    @Builder.Default
    private List<Long> songIds = new ArrayList<>();

    /** Fecha de creación. */
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    /** Fecha de última modificación. */
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.isPublic == null) {
            this.isPublic = false;
        }
        if (this.songIds == null) {
            this.songIds = new ArrayList<>();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    /**
     * Obtiene la cantidad actual de canciones en la lista.
     * @return Número de canciones.
     */
    public int getSongCount() {
        return songIds != null ? songIds.size() : 0;
    }

    /**
     * Verifica si una canción específica ya está en la lista.
     * @param songId ID de la canción.
     * @return {@code true} si existe.
     */
    public boolean containsSong(Long songId) {
        return songIds != null && songIds.contains(songId);
    }

    /**
     * Añade una canción al final de la lista.
     * <p>Evita duplicados si la canción ya existe.</p>
     * @param songId ID de la canción a añadir.
     */
    public void addSong(Long songId) {
        if (songIds == null) {
            songIds = new ArrayList<>();
        }
        if (!songIds.contains(songId)) {
            songIds.add(songId);
        }
    }

    /**
     * Elimina una canción de la lista.
     * @param songId ID de la canción a remover.
     */
    public boolean removeSong(Long songId) {
        if (songIds != null) {
            return songIds.remove(songId);
        }
        return false;
    }
}
