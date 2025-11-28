package io.audira.commerce.service;

import io.audira.commerce.model.FcmToken;
import io.audira.commerce.model.Platform;
import io.audira.commerce.repository.FcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * Servicio de lógica de negocio responsable de la gestión de tokens de Firebase Cloud Messaging (FCM).
 * <p>
 * Implementa las operaciones para registrar (añadir/actualizar), consultar y eliminar los tokens
 * de dispositivos asociados a los usuarios, manteniendo la unicidad del token.
 * </p>
 *
 * @author Grupo GA01
 * @see FcmTokenRepository
 * @see FcmToken
 * 
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FcmTokenService {

    private final FcmTokenRepository fcmTokenRepository;

    /**
     * Registra o actualiza un token FCM para un usuario.
     * <p>
     * Si el token ya existe en la base de datos (incluso si estaba asociado a otro usuario),
     * se actualiza para asociarlo al nuevo {@code userId} y la nueva {@code platform} (re-asociación).
     * Si no existe, se crea un nuevo registro.
     * </p>
     *
     * @param userId El ID del usuario al que se debe asociar el token.
     * @param token El valor del token FCM único del dispositivo.
     * @param platform La plataforma del dispositivo ({@link Platform}).
     * @return La entidad {@link FcmToken} registrada o actualizada.
     */
    @Transactional
    public FcmToken registerToken(Long userId, String token, Platform platform) {
        // Check if token already exists
        Optional<FcmToken> existing = fcmTokenRepository.findByToken(token);

        if (existing.isPresent()) {
            // Update existing token (re-associate it if necessary)
            FcmToken existingToken = existing.get();
            existingToken.setUserId(userId);
            existingToken.setPlatform(platform);
            log.info("Updated existing FCM token for user {}", userId);
            return fcmTokenRepository.save(existingToken);
        } else {
            // Create new token
            FcmToken newToken = FcmToken.builder()
                    .userId(userId)
                    .token(token)
                    .platform(platform)
                    .build();

            log.info("Registered new FCM token for user {}", userId);
            return fcmTokenRepository.save(newToken);
        }
    }

    /**
     * Elimina un token específico asociado a un usuario.
     * <p>
     * La eliminación solo procede si el token existe y está asociado a la combinación de usuario y token proporcionada.
     * </p>
     *
     * @param userId El ID del usuario.
     * @param token El valor del token a eliminar.
     */
    @Transactional
    public void deleteToken(Long userId, String token) {
        Optional<FcmToken> existing = fcmTokenRepository.findByUserIdAndToken(userId, token);

        if (existing.isPresent()) {
            fcmTokenRepository.delete(existing.get());
            log.info("Deleted FCM token for user {}", userId);
        } else {
            log.warn("FCM token not found for user {}", userId);
        }
    }

    /**
     * Elimina todos los tokens FCM asociados a un usuario.
     * <p>
     * Utilizado, por ejemplo, cuando la cuenta de un usuario es desactivada o eliminada.
     * </p>
     *
     * @param userId El ID del usuario cuyos tokens serán eliminados.
     */
    @Transactional
    public void deleteAllUserTokens(Long userId) {
        fcmTokenRepository.deleteByUserId(userId);
        log.info("Deleted all FCM tokens for user {}", userId);
    }

    /**
     * Obtiene todos los tokens FCM registrados para un usuario específico.
     *
     * @param userId El ID del usuario.
     * @return Una lista de entidades {@link FcmToken} del usuario.
     */
    public List<FcmToken> getUserTokens(Long userId) {
        return fcmTokenRepository.findByUserId(userId);
    }

    /**
     * Obtiene un token FCM específico utilizando su valor (String).
     *
     * @param token El valor del token a buscar.
     * @return Un {@link Optional} que contiene la entidad {@link FcmToken} si se encuentra.
     */
    public Optional<FcmToken> getToken(String token) {
        return fcmTokenRepository.findByToken(token);
    }
}