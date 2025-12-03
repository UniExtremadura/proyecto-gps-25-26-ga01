package io.audira.community.repository;

import io.audira.community.model.Artist;
import io.audira.community.model.User;
import io.audira.community.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

/**
 * Repositorio de Spring Data JPA para la entidad base {@link User}.
 * <p>
 * Proporciona métodos de consulta para la autenticación, verificación de existencia
 * y la búsqueda avanzada de usuarios, incluyendo consultas específicas dirigidas a la subclase {@link Artist}.
 * </p>
 *
 * @author Grupo GA01
 * @see User
 * @see JpaRepository
 * 
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * Busca y retorna un usuario por su dirección de correo electrónico.
     *
     * @param email La dirección de correo electrónico.
     * @return Un {@link Optional} que contiene el {@link User} si se encuentra.
     */
    Optional<User> findByEmail(String email);

    /**
     * Busca y retorna un usuario por su nombre de usuario (alias).
     *
     * @param username El nombre de usuario.
     * @return Un {@link Optional} que contiene el {@link User} si se encuentra.
     */
    Optional<User> findByUsername(String username);

    /**
     * Busca y retorna un usuario por su correo electrónico O su nombre de usuario.
     * <p>
     * Se utiliza típicamente en el proceso de inicio de sesión (login) para aceptar ambas credenciales como identificador.
     * </p>
     *
     * @param email El correo electrónico.
     * @param username El nombre de usuario.
     * @return Un {@link Optional} que contiene el {@link User} si se encuentra.
     */
    Optional<User> findByEmailOrUsername(String email, String username);

    /**
     * Verifica la existencia de un usuario por su correo electrónico.
     *
     * @param email La dirección de correo electrónico a verificar.
     * @return {@code true} si existe un usuario con ese email.
     */
    Boolean existsByEmail(String email);

    /**
     * Verifica la existencia de un usuario por su nombre de usuario.
     *
     * @param username El nombre de usuario a verificar.
     * @return {@code true} si existe un usuario con ese nombre de usuario.
     */
    Boolean existsByUsername(String username);

    /**
     * Busca y retorna una lista de usuarios que tienen un rol específico.
     *
     * @param role El rol de usuario ({@link UserRole}) por el cual filtrar.
     * @return Una {@link List} de {@link User} que coinciden con el rol.
     */
    List<User> findByRole(UserRole role);

    /**
     * Busca y retorna una lista de usuarios filtrados por su estado de actividad.
     *
     * @param isActive Estado de actividad ({@code true} para activos, {@code false} para suspendidos).
     * @return Una {@link List} de {@link User} que coinciden con el estado.
     */
    List<User> findByIsActive(Boolean isActive);

    /**
     * Consulta personalizada para buscar artistas (subclase {@link Artist}) activos por una cadena de texto
     * que coincida con el nombre artístico, nombre de pila o apellido.
     * <p>
     * La consulta utiliza {@code LEFT JOIN FETCH} implícito debido a que {@link Artist} es una subclase de {@link User}.
     * {@code COALESCE} maneja los campos nulos en la concatenación de nombres.
     * </p>
     *
     * @param query La cadena de texto de búsqueda.
     * @return Una {@link List} de entidades {@link Artist} que coinciden con la consulta.
     */
    @Query("SELECT a FROM Artist a WHERE a.isActive = true AND (" +
            "LOWER(COALESCE(a.artistName, '')) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(COALESCE(a.firstName, '')) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(COALESCE(a.lastName, '')) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(CONCAT(COALESCE(a.firstName, ''), ' ', COALESCE(a.lastName, ''))) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<Artist> searchArtistsByName(@Param("query") String query);

    /**
     * Consulta personalizada para buscar los IDs de artistas (subclase {@link Artist}) activos por una cadena de texto.
     * <p>
     * Es idéntica a {@link #searchArtistsByName(String)} pero proyecta solo el ID ({@code a.id}),
     * optimizada para consultas internas de microservicios que solo necesitan el identificador.
     * </p>
     *
     * @param query La cadena de texto de búsqueda.
     * @return Una {@link List} de IDs (tipo {@link Long}) de artistas que coinciden con la consulta.
     */
    @Query("SELECT a.id FROM Artist a WHERE a.isActive = true AND (" +
            "LOWER(COALESCE(a.artistName, '')) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(COALESCE(a.firstName, '')) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(COALESCE(a.lastName, '')) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(CONCAT(COALESCE(a.firstName, ''), ' ', COALESCE(a.lastName, ''))) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<Long> searchArtistIdsByName(@Param("query") String query);
}