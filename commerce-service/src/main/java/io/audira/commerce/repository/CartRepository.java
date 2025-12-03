package io.audira.commerce.repository;

import io.audira.commerce.model.Cart;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repositorio de Spring Data JPA para la entidad {@link Cart}.
 * <p>
 * Proporciona métodos CRUD y métodos de consulta específicos para gestionar
 * los carritos de compra, asegurando que los artículos asociados ({@code items})
 * se carguen eficientemente junto con el carrito.
 * </p>
 *
 * @author Grupo GA01
 * @see Cart
 * @see JpaRepository
 * 
 */
@Repository
public interface CartRepository extends JpaRepository<Cart, Long> {

    /**
     * Busca y recupera el carrito de compras asociado a un ID de usuario específico.
     * <p>
     * Utiliza una consulta JPQL con {@code LEFT JOIN FETCH} para cargar eager (ansiosamente)
     * la lista de {@code items} (artículos) dentro del mismo select, evitando así el problema N+1.
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) a buscar.
     * @return Un {@link Optional} que contiene el {@link Cart} completo si se encuentra.
     */
    @Query("SELECT DISTINCT c FROM Cart c LEFT JOIN FETCH c.items WHERE c.userId = :userId")
    Optional<Cart> findByUserId(@Param("userId") Long userId);

    /**
     * Busca y recupera un carrito de compras por su ID primario, cargando los artículos.
     * <p>
     * Sobrescribe el método {@code findById} estándar de JPA para incluir {@code LEFT JOIN FETCH}
     * y asegurar la carga eficiente de la lista de {@code items}.
     * </p>
     *
     * @param id El ID primario del carrito (tipo {@link Long}).
     * @return Un {@link Optional} que contiene el {@link Cart} completo si se encuentra.
     */
    @Query("SELECT DISTINCT c FROM Cart c LEFT JOIN FETCH c.items WHERE c.id = :id")
    Optional<Cart> findById(@Param("id") Long id);

    /**
     * Verifica si existe un carrito de compras asociado a un ID de usuario específico.
     *
     * @param userId El ID del usuario a verificar.
     * @return {@code true} si existe un carrito para el usuario, {@code false} en caso contrario.
     */
    boolean existsByUserId(Long userId);

    /**
     * Elimina el carrito de compras asociado a un ID de usuario específico.
     * <p>
     * Spring Data JPA infiere la consulta de eliminación basada en el nombre del método.
     * La operación debe ejecutarse dentro de una transacción (usando {@code @Transactional} en el servicio)
     * y es necesaria la anotación {@code @Modifying} si no se está utilizando el método {@code deleteBy...} de JPA
     * estándar o si la entidad {@link Cart} no maneja el {@code CascadeType.ALL} correctamente.
     * </p>
     *
     * @param userId El ID del usuario cuyo carrito será eliminado.
     */
    void deleteByUserId(Long userId);
}