package io.audira.community.repository;

import io.audira.community.model.FAQ;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Repositorio de Spring Data JPA para la entidad {@link FAQ}.
 * <p>
 * Proporciona métodos de consulta basados en nombres para gestionar las Preguntas Frecuentes,
 * incluyendo filtros por estado de actividad y categoría, y ordenamiento por orden de visualización
 * y fecha de creación.
 * </p>
 *
 * @author Grupo GA01
 * @see FAQ
 * @see JpaRepository
 * 
 */
@Repository
public interface FAQRepository extends JpaRepository<FAQ, Long> {

    /**
     * Busca y retorna todas las FAQ marcadas como activas ({@code isActive = true}),
     * ordenadas primero por el orden de visualización ascendente ({@code displayOrder}) y luego por fecha de creación descendente (más reciente).
     * <p>
     * Este método se utiliza para la vista pública de las preguntas frecuentes.
     * </p>
     *
     * @return Una {@link List} de {@link FAQ} activas.
     */
    List<FAQ> findByIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc();

    /**
     * Busca y retorna todas las FAQ de una categoría específica, incluyendo las inactivas (vista administrativa),
     * ordenadas por orden de visualización ascendente y luego por fecha de creación descendente.
     *
     * @param category La categoría (tipo {@link String}) por la cual filtrar.
     * @return Una {@link List} de {@link FAQ} de la categoría.
     */
    List<FAQ> findByCategoryOrderByDisplayOrderAscCreatedAtDesc(String category);

    /**
     * Busca y retorna las FAQ que son activas y pertenecen a una categoría específica (vista pública/filtrada),
     * ordenadas por orden de visualización ascendente y luego por fecha de creación descendente.
     *
     * @param category La categoría (tipo {@link String}) por la cual filtrar.
     * @return Una {@link List} de {@link FAQ} activas de la categoría.
     */
    List<FAQ> findByCategoryAndIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc(String category);

    /**
     * Busca y retorna todas las FAQ en el sistema (vista administrativa),
     * ordenadas por el orden de visualización ascendente y luego por fecha de creación descendente.
     *
     * @return Una {@link List} de todas las {@link FAQ} en la base de datos.
     */
    List<FAQ> findAllByOrderByDisplayOrderAscCreatedAtDesc();
}