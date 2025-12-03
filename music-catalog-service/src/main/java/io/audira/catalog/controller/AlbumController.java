package io.audira.catalog.controller;

import io.audira.catalog.dto.AlbumCreateRequest;
import io.audira.catalog.dto.AlbumDTO;
import io.audira.catalog.dto.AlbumResponse;
import io.audira.catalog.dto.AlbumUpdateRequest;
import io.audira.catalog.model.Album;
import io.audira.catalog.service.AlbumService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

/**
 * Controlador REST para la gestión de álbumes musicales.
 * <p>
 * Proporciona endpoints para el ciclo de vida completo de un álbum: creación, edición,
 * publicación, consulta y eliminación. Distingue entre endpoints administrativos y públicos.
 * </p>
 */
@RestController
@RequestMapping("/api/albums")
@RequiredArgsConstructor
public class AlbumController {

    private final AlbumService albumService;

    /**
     * Recupera los lanzamientos más recientes, independientemente de su estado.
     * <p>
     * Utilizado principalmente en paneles de administración o dashboards internos.
     * </p>
     *
     * @param limit Número máximo de álbumes a retornar (por defecto 20).
     * @return Lista de álbumes recientes.
     */
    @GetMapping("/latest-releases")
    public ResponseEntity<List<Album>> getLatestReleases(@RequestParam(defaultValue = "20") int limit) {
        List<Album> albums = albumService.getRecentAlbums();
        return ResponseEntity.ok(albums.stream().limit(limit).toList());
    }

    /**
     * Obtiene el listado completo de álbumes registrados en el sistema.
     *
     * @return Lista de todos los álbumes.
     */
    @GetMapping
    public ResponseEntity<List<Album>> getAllAlbums() {
        List<Album> albums = albumService.getAllAlbums();
        return ResponseEntity.ok(albums);
    }

    /**
     * Busca un álbum específico por su identificador único.
     *
     * @param id ID del álbum.
     * @return Objeto {@link AlbumResponse} con los detalles si existe, o 404 Not Found.
     */
    @GetMapping("/{id}")
    public ResponseEntity<AlbumResponse> getAlbumById(@PathVariable Long id) {
        AlbumResponse response = albumService.getAlbumResponseById(id);
        if (response == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(response);
    }

    /**
     * Obtiene todos los álbumes asociados a un artista específico.
     *
     * @param artistId ID del artista.
     * @return Lista de álbumes del artista con sus nombres.
     */
    @GetMapping("/artist/{artistId}")
    public ResponseEntity<List<AlbumDTO>> getAlbumsByArtist(@PathVariable Long artistId) {
        List<AlbumDTO> albums = albumService.getAlbumsByArtistWithArtistName(artistId);
        return ResponseEntity.ok(albums);
    }

    /**
     * Crea un nuevo álbum en el catálogo.
     *
     * @param request DTO con la información necesaria para crear el álbum (título, artista, etc.).
     * @return El álbum creado con estado HTTP 201 (Created).
     */
    @PostMapping
    public ResponseEntity<AlbumResponse> createAlbum(@RequestBody AlbumCreateRequest request) {
        try {
            AlbumResponse response = albumService.createAlbum(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * Actualiza la información de un álbum existente.
     *
     * @param id ID del álbum a modificar.
     * @param request DTO con los campos actualizables.
     * @return El álbum actualizado o 404 si no se encuentra.
     */
    @PutMapping("/{id}")
    public ResponseEntity<AlbumResponse> updateAlbum(
            @PathVariable Long id,
            @RequestBody AlbumUpdateRequest request) {
        Optional<AlbumResponse> response = albumService.updateAlbum(id, request);
        return response.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Modifica el estado de publicación de un álbum.
     * <p>
     * Permite publicar (hacer visible) o despublicar (ocultar) un álbum.
     * </p>
     *
     * @param id ID del álbum.
     * @param published {@code true} para publicar, {@code false} para ocultar.
     * @return El álbum con el nuevo estado actualizado.
     */
    @PatchMapping("/{id}/publish")
    public ResponseEntity<AlbumResponse> publishAlbum(
            @PathVariable Long id,
            @RequestParam boolean published) {
        Optional<AlbumResponse> response = albumService.publishAlbum(id, published);
        return response.map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * Elimina un álbum del sistema permanentemente.
     *
     * @param id ID del álbum a eliminar.
     * @return 204 No Content si se eliminó con éxito, 404 si no existía.
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAlbum(@PathVariable Long id) {
        boolean deleted = albumService.deleteAlbum(id);
        if (deleted) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }

    /**
     * Endpoint público para obtener los últimos lanzamientos oficiales.
     * <p>
     * A diferencia de {@link #getLatestReleases}, este método filtra solo aquellos
     * álbumes que tienen el estado "publicado".
     * </p>
     *
     * @param limit Límite de resultados.
     * @return Lista de álbumes publicados recientemente.
     */
    @GetMapping("/public/latest-releases")
    public ResponseEntity<List<Album>> getLatestPublishedReleases(@RequestParam(defaultValue = "20") int limit) {
        List<Album> albums = albumService.getRecentPublishedAlbums();
        return ResponseEntity.ok(albums.stream().limit(limit).toList());
    }
}
