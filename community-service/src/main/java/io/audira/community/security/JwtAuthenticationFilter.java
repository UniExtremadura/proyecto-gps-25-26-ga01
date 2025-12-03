package io.audira.community.security;

import jakarta.annotation.Nonnull;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

/**
 * Filtro de autenticación JWT personalizado.
 * <p>
 * Este filtro se ejecuta una sola vez por cada solicitud HTTP para extraer el token JWT
 * de la cabecera {@code Authorization}, validarlo y, si es válido, establecer la
 * autenticación del usuario en el contexto de seguridad de Spring Security ({@link SecurityContextHolder}).
 * </p>
 *
 * @author Grupo GA01
 * @see OncePerRequestFilter
 * @see JwtTokenProvider
 * 
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider tokenProvider;
    private final CustomUserDetailsService customUserDetailsService;
    private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

    /**
     * Procesa la solicitud HTTP para verificar la presencia y validez de un token JWT.
     * <p>
     * 1. Ignora el proceso para los endpoints de autenticación ({@code /api/auth}).
     * 2. Extrae el token JWT del encabezado "Authorization".
     * 3. Si el token es válido, carga los detalles del usuario por ID.
     * 4. Crea un objeto {@link UsernamePasswordAuthenticationToken} y lo establece en el
     * {@link SecurityContextHolder}.
     * </p>
     *
     * @param request La solicitud HTTP.
     * @param response La respuesta HTTP.
     * @param filterChain La cadena de filtros para continuar el procesamiento.
     * @throws ServletException Si ocurre un error de servlet.
     * @throws IOException Si ocurre un error de I/O.
     */
    @Override
    protected void doFilterInternal(
            @Nonnull HttpServletRequest request,
            @Nonnull HttpServletResponse response,
            @Nonnull FilterChain filterChain
    ) throws ServletException, IOException {

        String path = request.getServletPath();
        logger.debug("Processing request for path: {}", path);

        // Bypass JWT authentication for auth endpoints
        if (path.contains("/api/auth")) {
            logger.debug("Bypassing JWT filter for auth endpoint: {}", path);
            filterChain.doFilter(request, response);
            return;
        }

        try {
            String jwt = getJwtFromRequest(request);
            if (StringUtils.hasText(jwt) && tokenProvider.validateToken(jwt)) {
                // Obtener ID del token y cargar usuario
                Long userId = tokenProvider.getUserIdFromToken(jwt);
                UserDetails userDetails = customUserDetailsService.loadUserById(userId);

                // Crear y establecer la autenticación en el contexto de seguridad
                UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                        userDetails, null, userDetails.getAuthorities());
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                SecurityContextHolder.getContext().setAuthentication(authentication);
                logger.debug("User authenticated successfully: {}", userId);
            }
        } catch (Exception ex) {
            logger.error("Could not set user authentication in security context", ex);
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Extrae el token JWT de la cabecera 'Authorization' de la solicitud.
     * <p>
     * Espera el formato: {@code Bearer <token>}.
     * </p>
     *
     * @param request La solicitud HTTP.
     * @return El token JWT como {@link String}, o {@code null} si no se encuentra o tiene un formato incorrecto.
     */
    private String getJwtFromRequest(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }
}