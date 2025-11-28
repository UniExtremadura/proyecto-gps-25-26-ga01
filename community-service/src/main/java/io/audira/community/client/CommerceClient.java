package io.audira.community.client;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.HttpClientErrorException;

/**
 * Cliente REST para la comunicación con el microservicio de Comercio (Commerce Service).
 * <p>
 * Este cliente se utiliza típicamente para consultar datos transaccionales, como verificar
 * si un usuario posee un producto, antes de permitir acciones relacionadas con la propiedad
 * (ej. dejar una valoración).
 * </p>
 *
 * @author Grupo GA01
 * @see RestTemplate
 * 
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CommerceClient {

    /**
     * Cliente de Spring utilizado para realizar las llamadas HTTP síncronas.
     */
    private final RestTemplate restTemplate;

    /**
     * URL base del microservicio de Comercio.
     * <p>
     * El valor por defecto es {@code http://172.16.0.4:8083} si la propiedad {@code services.commerce.url} no está definida.
     * </p>
     */
    @Value("${services.commerce.url:http://172.16.0.4:8083}")
    private String commerceServiceUrl;

    /**
     * Verifica si un usuario ha comprado un producto específico consultando el endpoint de la biblioteca del Commerce Service.
     * <p>
     * Llama a {@code GET /api/library/user/{userId}/check/{itemType}/{itemId}}.
     * En caso de fallo de comunicación (excepto 404), se aplica una política de **"fail-open"**
     * para no bloquear la funcionalidad si el servicio de Comercio no está disponible.
     * </p>
     *
     * @param userId ID del usuario (tipo {@link Long}).
     * @param itemType Tipo de producto (String, ej. "SONG", "ALBUM").
     * @param itemId ID del producto (tipo {@link Long}).
     * @return {@code true} si el usuario ha comprado el producto o si ocurre un error de comunicación no esperado; {@code false} si la respuesta es 404 o {@code false}.
     */
    public boolean hasPurchasedItem(Long userId, String itemType, Long itemId) {
        try {
            String url = String.format(
                "%s/api/library/user/%d/check/%s/%d",
                commerceServiceUrl,
                userId,
                itemType.toUpperCase(),
                itemId
            );

            log.debug("Checking if user {} has purchased {} {}", userId, itemType, itemId);

            // RestTemplate mapea directamente el booleano del cuerpo de la respuesta HTTP
            Boolean result = restTemplate.getForObject(url, Boolean.class);

            log.debug("Purchase check result for user {} on {} {}: {}",
                userId, itemType, itemId, result);

            return Boolean.TRUE.equals(result);

        } catch (HttpClientErrorException.NotFound e) {
            // El endpoint retorna 404 (NotFound) si el recurso o la compra no existe
            log.warn("Purchase not found (404) for user {} on {} {}", userId, itemType, itemId);
            return false;
        } catch (Exception e) {
            log.error("Error checking purchase for user {} on {} {}: {}",
                userId, itemType, itemId, e.getMessage());
            // En caso de error de conexión o excepción inesperada, se asume que el usuario *puede* valorar.
            // (Política "fail-open" para disponibilidad).
            return true;
        }
    }
}