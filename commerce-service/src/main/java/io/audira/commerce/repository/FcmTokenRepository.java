package io.audira.commerce.repository;

import io.audira.commerce.model.FcmToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositorio de Spring Data JPA para la entidad {@link FcmToken}.
 * <p>
 * Proporciona métodos de consulta basados en nombres para gestionar los tokens de
 * Firebase Cloud Messaging (FCM) asociados a los usuarios, permitiendo la búsqueda,
 * el registro y la anulación del registro de dispositivos.
 * </p>
 *
 * @author Grupo GA01
 * @see FcmToken
 * @see JpaRepository
 * 
 */
@Repository
public interface FcmTokenRepository extends JpaRepository<FcmToken, Long> {

    /**
     * Busca y retorna todos los tokens FCM activos asociados a un usuario específico.
     * <p>
     * Un usuario puede tener múltiples tokens si utiliza varios dispositivos o navegadores.
     * </p>
     *
     * @param userId El ID del usuario (tipo {@link Long}) a buscar.
     * @return Una {@link List} de {@link FcmToken} para el usuario.
     */
    List<FcmToken> findByUserId(Long userId);

    /**
     * Busca un token FCM específico utilizando el valor del token (String).
     * <p>
     * Esta búsqueda es altamente eficiente ya que el campo {@code token} es único.
     * </p>
     *
     * @param token El valor del token (String) a buscar.
     * @return Un {@link Optional} que contiene el {@link FcmToken} si se encuentra.
     */
    Optional<FcmToken> findByToken(String token);

    /**
     * Busca un token FCM específico asociado a un usuario y valor de token determinados.
     *
     * @param userId El ID del usuario.
     * @param token El valor del token.
     * @return Un {@link Optional} que contiene el {@link FcmToken} si la combinación se encuentra.
     */
    Optional<FcmToken> findByUserIdAndToken(Long userId, String token);

    /**
     * Elimina todos los tokens FCM asociados a un usuario específico.
     * <p>
     * La operación se utiliza típicamente para limpiar la base de datos cuando la cuenta de un usuario es eliminada.
     * Debe ejecutarse dentro de una transacción.
     * </p>
     *
     * @param userId El ID del usuario cuyos tokens serán eliminados.
     */
    void deleteByUserId(Long userId);

    /**
     * Elimina un token FCM específico utilizando su valor (String).
     * <p>
     * Se utiliza para anular el registro de un solo dispositivo.
     * Debe ejecutarse dentro de una transacción.
     * </p>
     *
     * @param token El valor del token (String) a eliminar.
     */
    void deleteByToken(String token);
}