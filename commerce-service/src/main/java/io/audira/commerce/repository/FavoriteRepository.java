package io.audira.commerce.repository;

import io.audira.commerce.model.Favorite;
import io.audira.commerce.model.ItemType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio de Spring Data JPA para la entidad {@link Favorite}.
 * <p>
 * Proporciona métodos CRUD y métodos de consulta basados en nombres para gestionar
 * la lista de favoritos de los usuarios, incluyendo búsquedas, conteos y eliminaciones
 * basadas en el ID del usuario y el tipo de artículo.
 * </p>
 *
 * @author Grupo GA01
 * @see Favorite
 * @see JpaRepository
 * 
 */
@Repository
public interface FavoriteRepository extends JpaRepository<Favorite, Long> {

    /**
     * Busca y retorna todos los registros de favoritos para un usuario específico.
     *
     * @param userId El ID del usuario (tipo {@link Long}) a buscar.
     * @return Una {@link List} de todos los objetos {@link Favorite} del usuario.
     */
    List<Favorite> findByUserId(Long userId);

    /**
     * Busca y retorna los registros de favoritos de un usuario, filtrados por el tipo de artículo.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}) por el cual filtrar.
     * @return Una {@link List} de {@link Favorite} que coinciden con el usuario y el tipo de artículo.
     */
    List<Favorite> findByUserIdAndItemType(Long userId, ItemType itemType);

    /**
     * Busca un registro de favorito específico utilizando el ID del usuario, el tipo de artículo y el ID del artículo.
     * <p>
     * Esta consulta es esencial para verificar si un elemento ha sido marcado previamente como favorito.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo en el catálogo.
     * @return Un {@link Optional} que contiene el {@link Favorite} si se encuentra.
     */
    Optional<Favorite> findByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Verifica si existe un registro de favorito específico utilizando la clave compuesta (userId, itemType, itemId).
     * <p>
     * Es una versión optimizada para comprobar la existencia sin recuperar el objeto completo.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo en el catálogo.
     * @return {@code true} si el favorito existe, {@code false} en caso contrario.
     */
    boolean existsByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Elimina un registro de favorito específico utilizando la clave compuesta (userId, itemType, itemId).
     * <p>
     * La operación debe ejecutarse dentro de una transacción (usando {@code @Transactional} en la capa de servicio).
     * </p>
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}).
     * @param itemId El ID del artículo en el catálogo.
     */
    void deleteByUserIdAndItemTypeAndItemId(Long userId, ItemType itemType, Long itemId);

    /**
     * Elimina todos los registros de favoritos asociados a un usuario.
     * <p>
     * La operación debe ejecutarse dentro de una transacción.
     * </p>
     *
     * @param userId El ID del usuario cuyos favoritos serán eliminados.
     */
    void deleteByUserId(Long userId);

    /**
     * Cuenta el número total de registros de favoritos para un usuario específico.
     *
     * @param userId El ID del usuario para el que se realizará el conteo.
     * @return El número total de favoritos (tipo {@code long}).
     */
    long countByUserId(Long userId);

    /**
     * Cuenta el número de registros de favoritos para un usuario, filtrado por el tipo de artículo.
     *
     * @param userId El ID del usuario.
     * @param itemType El tipo de artículo ({@link ItemType}) a contar.
     * @return El número de favoritos del tipo especificado (tipo {@code long}).
     */
    long countByUserIdAndItemType(Long userId, ItemType itemType);
}