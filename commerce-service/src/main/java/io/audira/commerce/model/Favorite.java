package io.audira.commerce.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * Entidad de base de datos que representa un registro de un artículo favorito (wishlist) para un usuario.
 * <p>
 * Mapeada a la tabla {@code favorites}. Esta entidad asegura que la combinación de
 * {@code userId}, {@code itemType} e {@code itemId} sea única, previniendo duplicados.
 * </p>
 *
 * @author Grupo GA01
 * @see ItemType
 * @see Entity
 */
@Entity
@Table(name = "favorites",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "item_type", "item_id"})
    },
    indexes = {
        @Index(name = "idx_favorites_user", columnList = "user_id"),
        @Index(name = "idx_favorites_item", columnList = "item_type, item_id")
    }
)
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Favorite {

    /**
     * ID primario y clave única de la entidad Favorite. Generado automáticamente.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /**
     * ID del usuario al que pertenece este registro de favorito.
     * <p>
     * Se crea un índice ({@code idx_favorites_user}) sobre esta columna para mejorar el rendimiento de la consulta por usuario.
     * </p>
     */
    @Column(name = "user_id", nullable = false)
    private Long userId;

    /**
     * Tipo de artículo favorito (ej. SONG, ALBUM).
     * <p>
     * Mapeado como String en la base de datos ({@code @Enumerated(EnumType.STRING)}) y la longitud se limita a 20.
     * </p>
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "item_type", nullable = false, length = 20)
    private ItemType itemType;

    /**
     * ID del artículo referenciado en el catálogo (ej. ID de la canción o ID del álbum).
     */
    @Column(name = "item_id", nullable = false)
    private Long itemId;

    /**
     * Marca de tiempo de la creación inicial del registro.
     * <p>
     * La anotación {@code @CreationTimestamp} de Hibernate asegura que el valor se
     * establezca automáticamente al momento de la inserción y que no pueda ser modificado posteriormente ({@code updatable = false}).
     * </p>
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    /**
     * Constructor utilizado para crear una nueva instancia de Favorite antes de ser guardada,
     * cuando el ID primario y la marca de tiempo aún no están definidos.
     *
     * @param userId ID del usuario.
     * @param itemType Tipo de artículo.
     * @param itemId ID del artículo en el catálogo.
     */
    public Favorite(Long userId, ItemType itemType, Long itemId) {
        this.userId = userId;
        this.itemType = itemType;
        this.itemId = itemId;
    }
}