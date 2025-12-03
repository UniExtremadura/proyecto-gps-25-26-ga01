package io.audira.community.repository;

import io.audira.community.model.Rating;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

/**
 * Repositorio para la gestión y acceso a datos de la entidad **Rating** (Valoración).
 * <p>
 * Extiende {@link JpaRepository} para manejar las operaciones de persistencia,
 * y define métodos de consulta personalizados basados en la convención de nombres de métodos
 * de Spring Data JPA y consultas JPQL explícitas para cálculos.
 * </p>
 * Requisitos asociados: GA01-128, GA01-129, GA01-130
 *
 * @author Grupo GA01
 * @see Rating
 * 
 */
@Repository
public interface RatingRepository extends JpaRepository<Rating, Long> {

    /**
     * Busca la valoración específica y única realizada por un usuario para una entidad dada
     * (definida por su tipo y ID).
     *
     * @param userId El ID del usuario que realizó la valoración.
     * @param entityType El tipo de entidad (ej. 'SONG', 'ALBUM').
     * @param entityId El ID de la entidad valorada.
     * @return Un {@link Optional} que contiene la valoración si existe y es única.
     */
    Optional<Rating> findByUserIdAndEntityTypeAndEntityId(Long userId, String entityType, Long entityId);

    /**
     * Obtiene una lista de todas las valoraciones activas ({@code isActive = true}) realizadas por un usuario.
     *
     * @param userId El ID del usuario.
     * @return Una lista de objetos {@link Rating} activos.
     */
    List<Rating> findByUserIdAndIsActiveTrue(Long userId);

    /**
     * Obtiene una lista de todas las valoraciones activas ({@code isActive = true}) de una entidad específica.
     *
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return Una lista de objetos {@link Rating} activos para la entidad.
     */
    List<Rating> findByEntityTypeAndEntityIdAndIsActiveTrue(String entityType, Long entityId);

    /**
     * Obtiene una lista de todas las valoraciones activas realizadas por un usuario para un tipo de entidad específico.
     *
     * @param userId El ID del usuario.
     * @param entityType El tipo de entidad (ej. 'ARTIST').
     * @return Una lista de objetos {@link Rating} activos del usuario para ese tipo de entidad.
     */
    List<Rating> findByUserIdAndEntityTypeAndIsActiveTrue(Long userId, String entityType);

    /**
     * Calcula el promedio de las puntuaciones (rating) de todas las valoraciones activas
     * para una entidad específica.
     *
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return El promedio de las puntuaciones como {@link Double}, o {@code null} si no hay valoraciones.
     */
    @Query("SELECT AVG(r.rating) FROM Rating r WHERE r.entityType = :entityType AND r.entityId = :entityId AND r.isActive = true")
    Double calculateAverageRating(@Param("entityType") String entityType, @Param("entityId") Long entityId);

    /**
     * Cuenta el número total de valoraciones activas para una entidad específica.
     *
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return El número total de valoraciones activas como {@link Long}.
     */
    Long countByEntityTypeAndEntityIdAndIsActiveTrue(String entityType, Long entityId);

    /**
     * Cuenta el número de valoraciones activas que tienen un número de estrellas específico para una entidad.
     * <p>
     * Se utiliza para calcular la distribución de estrellas (ej. cuántas valoraciones de 5 estrellas).
     * </p>
     *
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @param stars El número de estrellas (ej. 1, 3, 5).
     * @return El número de valoraciones activas con ese número de estrellas como {@link Long}.
     */
    @Query("SELECT COUNT(r) FROM Rating r WHERE r.entityType = :entityType AND r.entityId = :entityId AND r.rating = :stars AND r.isActive = true")
    Long countByRatingStars(@Param("entityType") String entityType, @Param("entityId") Long entityId, @Param("stars") Integer stars);

    /**
     * Verifica si existe al menos una valoración activa realizada por un usuario específico para una entidad.
     * <p>
     * Se utiliza típicamente para prevenir valoraciones duplicadas.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return {@code true} si existe una valoración activa, {@code false} en caso contrario.
     */
    boolean existsByUserIdAndEntityTypeAndEntityIdAndIsActiveTrue(Long userId, String entityType, Long entityId);

    /**
     * Obtiene una lista de todas las valoraciones activas de una entidad, ordenadas por fecha de creación descendente
     * (las más recientes primero).
     *
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return Una lista ordenada de objetos {@link Rating} activos.
     */
    List<Rating> findByEntityTypeAndEntityIdAndIsActiveTrueOrderByCreatedAtDesc(String entityType, Long entityId);

    /**
     * Obtiene una lista de valoraciones activas para una entidad que incluyen un comentario no nulo y no vacío.
     * <p>
     * Las valoraciones se ordenan por fecha de creación descendente.
     * </p>
     *
     * @param entityType El tipo de entidad.
     * @param entityId El ID de la entidad.
     * @return Una lista de objetos {@link Rating} con comentarios para la entidad.
     */
    @Query("SELECT r FROM Rating r WHERE r.entityType = :entityType AND r.entityId = :entityId AND r.comment IS NOT NULL AND r.comment != '' AND r.isActive = true ORDER BY r.createdAt DESC")
    List<Rating> findRatingsWithComments(@Param("entityType") String entityType, @Param("entityId") Long entityId);

    /**
     * Busca una valoración específica por su ID y verifica que pertenezca al usuario con el ID proporcionado.
     * <p>
     * Esto es fundamental para implementar la lógica de seguridad y validar que un usuario solo pueda
     * editar o eliminar sus propias valoraciones.
     * </p>
     *
     * @param id El ID de la valoración.
     * @param userId El ID del usuario propietario.
     * @return Un {@link Optional} que contiene la valoración si se encuentra y el {@code userId} coincide.
     */
    Optional<Rating> findByIdAndUserId(Long id, Long userId);
}