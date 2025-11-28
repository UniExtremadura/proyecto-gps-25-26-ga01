package io.audira.community.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * Componente que maneja los errores de autenticación en Spring Security cuando se utiliza JWT.
 * <p>
 * Implementa la interfaz {@link AuthenticationEntryPoint}. Este componente se activa
 * cuando un usuario no autenticado (sin credenciales válidas, con un token ausente o inválido)
 * intenta acceder a un recurso protegido.
 * </p>
 * Su función principal es devolver una respuesta HTTP 401 (Unauthorized) al cliente.
 *
 * @author Grupo GA01
 * @see AuthenticationEntryPoint
 * 
 */
@Component
public class JwtAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationEntryPoint.class);

    /**
     * Se invoca cuando una excepción de autenticación ({@link AuthenticationException}) ocurre,
     * indicando que un usuario no autenticado intentó acceder a un recurso protegido.
     *
     * @param request La solicitud HTTP que causó el fallo.
     * @param response La respuesta HTTP a la que se debe escribir el error.
     * @param authException La excepción de autenticación que fue lanzada (ej. token expirado, token mal formado).
     * @throws IOException Si ocurre un error de E/S al escribir la respuesta.
     */
    @Override
    public void commence(HttpServletRequest request,
                         HttpServletResponse response,
                         AuthenticationException authException) throws IOException {

        logger.error("Responding with unauthorized error. Message - {}", authException.getMessage());
        logger.error("Request URI: {}", request.getRequestURI());
        logger.error("Request Method: {}", request.getMethod());

        // Retorna una respuesta HTTP 401 (UNAUTHORIZED) al cliente con el mensaje de la excepción.
        response.sendError(HttpServletResponse.SC_UNAUTHORIZED, authException.getMessage());
    }
}