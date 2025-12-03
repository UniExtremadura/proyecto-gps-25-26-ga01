package io.audira.catalog.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

import java.util.HashSet;
import java.util.Set;

/**
 * Entidad que representa una Canción (Track musical).
 * <p>
 * Extiende de {@link Product} heredando propiedades como título y precio.
 * Se identifica con el discriminador {@code "SONG"} en la tabla padre.
 * </p>
 */
@Entity
@Table(name = "songs")
@DiscriminatorValue("SONG")
@Data
@EqualsAndHashCode(callSuper = true)
@SuperBuilder
@NoArgsConstructor
@AllArgsConstructor
public class Song extends Product {

    /**
     * ID del álbum al que pertenece la canción.
     * <p>Puede ser {@code null} si la canción es un "Single" sin álbum asociado.</p>
     */
    @Column(name = "album_id")
    private Long albumId;

    /**
     * Nombre del artista (Campo no persistente).
     * <p>
     * Marcado como {@code @Transient}. Este campo no se guarda en la base de datos de catálogo;
     * se rellena en tiempo de ejecución consultando el microservicio de Usuarios.
     * </p>
     */
    @Transient
    private String artistName;

    /**
     * Conjunto de géneros musicales asociados.
     * <p>Almacenado en la tabla secundaria {@code song_genres}.</p>
     */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "song_genres", joinColumns = @JoinColumn(name = "song_id"))
    @Column(name = "genre_id")
    @Builder.Default
    private Set<Long> genreIds = new HashSet<>();

    /** Duración exacta de la pista en segundos. */
    @Column(nullable = false)
    private Integer duration;

    /**
     * URL pública o firmada del archivo de audio.
     * <p>Apunta a la ubicación física gestionada por el {@code File Service}.</p>
     */
    @Column(name = "audio_url")
    private String audioUrl;

    /** Letra de la canción. */
    @Column(columnDefinition = "TEXT")
    private String lyrics;

    /**
     * Número de pista en el álbum.
     * <p>Solo relevante si {@code albumId} no es nulo.</p>
     */
    @Column(name = "track_number")
    private Integer trackNumber;

    /**
     * Contador de reproducciones acumuladas.
     * <p>Se inicializa en 0.</p>
     */
    @Column(nullable = false)
    @Builder.Default
    private Long plays = 0L;

    /** Categoría del contenido (ej: "MUSIC", "PODCAST"). */
    @Column(length = 50)
    @Builder.Default
    private String category = "MUSIC";

    /**
     * Indica si la canción está publicada.
     * <p>
     * Independiente del estado de moderación, el artista puede decidir ocultar una canción aprobada.
     * </p>
     */
    @Column(nullable = false)
    @Builder.Default
    private boolean published = false;

    /**
     * Implementación del método discriminador.
     * @return "SONG"
     */
    @Override
    public String getProductType() {
        return "SONG";
    }
}
