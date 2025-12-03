package io.audira.catalog.repository;

import io.audira.catalog.model.Genre;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

/**
 * Repositorio JPA para la gestión de la entidad {@link Genre}.
 * <p>
 * Proporciona operaciones CRUD estándar y métodos de búsqueda optimizados por nombre
 * para validar la unicidad de los géneros musicales.
 * </p>
 */
@Repository
public interface GenreRepository extends JpaRepository<Genre, Long> {
    /**
     * Busca un género musical por su nombre exacto.
     *
     * @param name Nombre del género (ej: "Rock").
     * @return Un {@link Optional} que contiene el género si existe.
     */
    Optional<Genre> findByName(String name);

    /**
     * Verifica eficientemente si ya existe un género con el nombre dado.
     * <p>
     * Utilizado en la validación antes de crear o actualizar para evitar duplicados.
     * </p>
     *
     * @param name Nombre a verificar.
     * @return {@code true} si el nombre ya está registrado, {@code false} en caso contrario.
     */
    boolean existsByName(String name);
}
