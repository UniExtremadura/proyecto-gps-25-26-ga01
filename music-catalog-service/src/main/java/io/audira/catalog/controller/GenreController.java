package io.audira.catalog.controller;

import io.audira.catalog.model.Genre;
import io.audira.catalog.service.GenreService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

/**
 * Controlador para la gestión de géneros musicales (Taxonomía).
 * <p>
 * Permite administrar las categorías utilizadas para clasificar música.
 * </p>
 */
@RestController
@RequestMapping("/api/genres")
@RequiredArgsConstructor
public class GenreController {

    private final GenreService genreService;

    /**
     * Crea un nuevo género musical.
     * @param genre Objeto género.
     * @return Género creado.
     */
    @PostMapping
    public ResponseEntity<Genre> createGenre(@RequestBody Genre genre) {
        return ResponseEntity.ok(genreService.createGenre(genre));
    }

    /**
     * Obtiene un género por ID.
     * @param id ID del género.
     * @return Detalle del género.
     */
    @GetMapping("/{id}")
    public ResponseEntity<Genre> getGenreById(@PathVariable Long id) {
        return ResponseEntity.ok(genreService.getGenreById(id));
    }

    /**
     * Lista todos los géneros disponibles.
     * @return Lista de géneros.
     */
    @GetMapping
    public ResponseEntity<List<Genre>> getAllGenres() {
        return ResponseEntity.ok(genreService.getAllGenres());
    }

    /**
     * Actualiza el nombre o descripción de un género.
     * @param id ID del género.
     * @param genre Nuevos datos.
     * @return Género actualizado.
     */
    @PutMapping("/{id}")
    public ResponseEntity<Genre> updateGenre(@PathVariable Long id, @RequestBody Genre genre) {
        return ResponseEntity.ok(genreService.updateGenre(id, genre));
    }

    /**
     * Elimina un género del sistema.
     * @param id ID del género.
     * @return 204 No Content.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteGenre(@PathVariable Long id) {
        genreService.deleteGenre(id);
        return ResponseEntity.noContent().build();
    }
}
