package io.audira.catalog.service;

import io.audira.catalog.model.Genre;
import io.audira.catalog.repository.GenreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;

/**
 * Servicio encargado de la lógica de negocio para la gestión de géneros musicales (Taxonomía).
 * <p>
 * Proporciona operaciones CRUD completas y validaciones de unicidad para asegurar
 * la consistencia del catálogo de categorías musicales.
 * </p>
 */
@Service
@RequiredArgsConstructor
public class GenreService {

    private final GenreRepository genreRepository;

    /**
     * Crea un nuevo género musical en el sistema.
     * <p>
     * Valida que el nombre del género sea único antes de persistirlo para evitar duplicados.
     * </p>
     *
     * @param genre La entidad {@link Genre} con los datos a crear.
     * @return El género creado y persistido en la base de datos.
     * @throws IllegalArgumentException Si ya existe un género con el mismo nombre (insensible a mayúsculas/minúsculas según configuración de BD).
     */
    @Transactional
    public Genre createGenre(Genre genre) {
        if (genreRepository.existsByName(genre.getName())) {
            throw new IllegalArgumentException("Genre with name '" + genre.getName() + "' already exists");
        }
        return genreRepository.save(genre);
    }

    /**
     * Recupera la lista completa de géneros musicales disponibles.
     *
     * @return Una lista conteniendo todos los objetos {@link Genre} registrados.
     */
    public List<Genre> getAllGenres() {
        return genreRepository.findAll();
    }

    /**
     * Busca un género específico por su identificador único.
     *
     * @param id El ID del género a buscar.
     * @return La entidad {@link Genre} encontrada.
     * @throws IllegalArgumentException Si no se encuentra ningún género con el ID proporcionado.
     */
    public Genre getGenreById(Long id) {
        return genreRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Genre not found with id: " + id));
    }

    /**
     * Busca un género específico por su nombre exacto.
     * <p>
     * Útil para búsquedas o validaciones rápidas sin conocer el ID.
     * </p>
     *
     * @param name El nombre del género a buscar.
     * @return Un {@link Optional} que contiene el género si existe, o vacío si no.
     */
    public Optional<Genre> getGenreByName(String name) {
        return genreRepository.findByName(name);
    }

    /**
     * Actualiza la información de un género existente.
     * <p>
     * Permite modificar el nombre, descripción y URL de imagen.
     * Si se intenta cambiar el nombre, valida que el nuevo nombre no esté ocupado por otro género.
     * </p>
     *
     * @param id Identificador del género a modificar.
     * @param genreDetails Objeto {@link Genre} con los nuevos valores a aplicar.
     * @return La entidad {@link Genre} actualizada.
     * @throws IllegalArgumentException Si el género no existe o si el nuevo nombre ya está en uso.
     */
    @Transactional
    public Genre updateGenre(Long id, Genre genreDetails) {
        Genre genre = genreRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Genre not found with id: " + id));

        if (genreDetails.getName() != null && !genreDetails.getName().equals(genre.getName())) {
            if (genreRepository.existsByName(genreDetails.getName())) {
                throw new IllegalArgumentException("Genre with name '" + genreDetails.getName() + "' already exists");
            }
            genre.setName(genreDetails.getName());
        }

        if (genreDetails.getDescription() != null) {
            genre.setDescription(genreDetails.getDescription());
        }

        if (genreDetails.getImageUrl() != null) {
            genre.setImageUrl(genreDetails.getImageUrl());
        }

        return genreRepository.save(genre);
    }

    /**
     * Elimina un género musical del sistema.
     * <p>
     * Verifica la existencia del género antes de intentar el borrado físico.
     * </p>
     *
     * @param id El ID del género a eliminar.
     * @throws IllegalArgumentException Si el género no existe.
     */
    @Transactional
    public void deleteGenre(Long id) {
        if (!genreRepository.existsById(id)) {
            throw new IllegalArgumentException("Genre not found with id: " + id);
        }
        genreRepository.deleteById(id);
    }
}
