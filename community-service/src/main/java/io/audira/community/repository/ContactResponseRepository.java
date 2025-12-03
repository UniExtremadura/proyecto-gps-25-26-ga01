package io.audira.community.repository;

import io.audira.community.model.ContactResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * Interfaz de repositorio para la gestión y acceso a datos de la entidad {@link ContactResponse}.
 * <p>
 * Extiende {@link JpaRepository} para proporcionar las operaciones CRUD básicas y métodos
 * de consulta personalizados, utilizando la convención de nombres de métodos de Spring Data JPA
 * para interactuar con la base de datos.
 * </p>
 *
 * @author Grupo GA01
 * @see ContactResponse
 * @version 1.0
 */
@Repository
public interface ContactResponseRepository extends JpaRepository<ContactResponse, Long> {

    /**
     * Recupera una lista de todas las respuestas asociadas a un mensaje de contacto específico.
     *
     * @param contactMessageId El ID del mensaje de contacto original.
     * @return Una lista de objetos {@link ContactResponse}. Retorna una lista vacía si no se encuentra ninguna respuesta.
     */
    List<ContactResponse> findByContactMessageId(Long contactMessageId);

    /**
     * Recupera una lista de todas las respuestas asociadas a un mensaje de contacto específico,
     * ordenadas por la fecha de creación de forma descendente (las más recientes primero).
     *
     * @param contactMessageId El ID del mensaje de contacto original.
     * @return Una lista ordenada de objetos {@link ContactResponse}.
     */
    List<ContactResponse> findByContactMessageIdOrderByCreatedAtDesc(Long contactMessageId);

    /**
     * Recupera una lista de todas las respuestas que fueron creadas por un administrador específico.
     *
     * @param adminId El ID del administrador que creó las respuestas.
     * @return Una lista de objetos {@link ContactResponse}. Retorna una lista vacía si el administrador no tiene respuestas.
     */
    List<ContactResponse> findByAdminId(Long adminId);
}