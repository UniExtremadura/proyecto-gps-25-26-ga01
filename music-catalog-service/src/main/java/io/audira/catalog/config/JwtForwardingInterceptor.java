package io.audira.catalog.config;

import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import java.io.IOException;

/**
 * Interceptor HTTP que propaga el token JWT (JSON Web Token) entre microservicios.
 * <p>
 * Implementa el patrón <b>Token Relay</b>. Cuando este servicio recibe una petición y necesita
 * llamar a otro microservicio (ej: Catálogo -> Inventario), este interceptor:
 * <ol>
 * <li>Captura el contexto de seguridad de la petición entrante original.</li>
 * <li>Extrae el token JWT del encabezado {@code Authorization}.</li>
 * <li>Inyecta dicho token en el encabezado de la nueva petición saliente.</li>
 * </ol>
 * Esto garantiza que el microservicio destino reciba la identidad del usuario que inició la acción.
 * </p>
 *
 * @see ClientHttpRequestInterceptor
 */
@Component
@Slf4j

public class JwtForwardingInterceptor implements ClientHttpRequestInterceptor {
    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

    /**
     * Intercepta cada petición HTTP saliente realizada por {@code RestTemplate}.
     *
     * @param request La petición HTTP que se va a enviar (contiene URL, método y headers actuales).
     * @param body El cuerpo (payload) de la petición.
     * @param execution La cadena de ejecución que permite continuar con el envío de la petición.
     * @return La respuesta HTTP recibida del servicio remoto.
     * @throws IOException Si ocurre un error de E/S durante la ejecución de la petición.
     */
    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body, ClientHttpRequestExecution execution) throws IOException {
        String token = extractJwtToken();

        if (token != null && !token.isEmpty()) {
            log.debug("Forwarding JWT token to: {}", request.getURI());
            request.getHeaders().add(AUTHORIZATION_HEADER, BEARER_PREFIX + token);
        } else {
            log.debug("No JWT token found in current request context for: {}", request.getURI());
        }

        return execution.execute(request, body);
    }

    /**
     * Extrae el token JWT crudo del contexto de la petición HTTP actual (Servlet Request).
     * <p>
     * Utiliza {@link RequestContextHolder} para acceder al hilo actual de la petición web,
     * lo que permite recuperar los headers originales aunque estemos en una capa de servicio.
     * </p>
     *
     * @return El token JWT como {@link String} (sin el prefijo "Bearer "), o {@code null} si no existe o hay error.
     */
    private String extractJwtToken() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();

            if (attributes == null) {
                log.trace("No request attributes found in context");
                return null;
            }

            HttpServletRequest request = attributes.getRequest();
            String authHeader = request.getHeader(AUTHORIZATION_HEADER);

            if (authHeader == null || authHeader.isEmpty()) {
                log.trace("No Authorization header found in request");
                return null;
            }

            if (authHeader.startsWith(BEARER_PREFIX)) {
                return authHeader.substring(BEARER_PREFIX.length());
            }
 
            return authHeader;

        } catch (Exception e) {
            log.warn("Error extracting JWT token from request context", e);
            return null;
        }
    }
}