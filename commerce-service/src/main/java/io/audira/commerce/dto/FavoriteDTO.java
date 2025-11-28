package io.audira.commerce.dto;

import io.audira.commerce.model.Favorite;
import io.audira.commerce.model.ItemType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Data Transfer Object (DTO) que representa un registro de artículo favorito de un usuario.
 * <p>
 * Este objeto se utiliza para exponer los datos de un favorito a través de la API,
 * facilitando la comunicación sin exponer directamente la entidad de base de datos ({@link Favorite}).
 * Incluye métodos de conversión bidireccional.
 * </p>
 *
 * @author Grupo GA01
 * @see Favorite
 * @see ItemType
 * 
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FavoriteDTO {

    /**
     * ID único del registro del favorito en la base de datos.
     */
    private Long id;

    /**
     * ID del usuario al que pertenece este favorito.
     */
    private Long userId;

    /**
     * Tipo de artículo favorito (ej. SONG, ALBUM, ARTIST) utilizando el enumerador {@link ItemType}.
     */
    private ItemType itemType;

    /**
     * ID único del artículo referenciado en el catálogo (ej. ID de la canción).
     */
    private Long itemId;

    /**
     * Marca de tiempo de la creación del registro del favorito.
     */
    private LocalDateTime createdAt;

    /**
     * Convierte una entidad {@link Favorite} de base de datos a un objeto {@link FavoriteDTO}.
     * <p>
     * Este método estático es útil en la capa de servicio para mapear resultados antes de retornarlos al controlador.
     * </p>
     *
     * @param favorite La entidad {@link Favorite} de origen.
     * @return Una nueva instancia de {@link FavoriteDTO}.
     */
    public static FavoriteDTO fromEntity(Favorite favorite) {
        return FavoriteDTO.builder()
            .id(favorite.getId())
            .userId(favorite.getUserId())
            .itemType(favorite.getItemType())
            .itemId(favorite.getItemId())
            .createdAt(favorite.getCreatedAt())
            .build();
    }

    /**
     * Convierte el objeto {@link FavoriteDTO} actual a su entidad de base de datos {@link Favorite}.
     * <p>
     * Este método es útil en la capa de servicio al recibir datos del controlador y prepararlos para ser guardados.
     * </p>
     *
     * @return Una nueva instancia de la entidad {@link Favorite}.
     */
    public Favorite toEntity() {
        return Favorite.builder()
            .id(this.id)
            .userId(this.userId)
            .itemType(this.itemType)
            .itemId(this.itemId)
            .createdAt(this.createdAt)
            .build();
    }
}