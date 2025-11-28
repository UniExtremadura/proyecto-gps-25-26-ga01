package io.audira.community.security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;
import java.security.Key;
import java.util.Date;

/**
 * Componente proveedor de tokens JWT (JSON Web Token).
 * <p>
 * Se encarga de la creación (firma), la extracción de información y la validación de los tokens
 * utilizados para la autenticación sin estado (stateless) en el microservicio.
 * Utiliza la librería {@code io.jsonwebtoken} (jjwt).
 * </p>
 *
 * @author Grupo GA01
 * 
 */
@Component
public class JwtTokenProvider {

    /**
     * Clave secreta (secreto) utilizada para firmar y verificar los tokens JWT.
     * Inyectada desde la configuración de la aplicación (ej. application.properties).
     */
    @Value("${jwt.secret}")
    private String jwtSecret;

    /**
     * Tiempo de validez del token en milisegundos (expiración).
     * Inyectado desde la configuración de la aplicación.
     */
    @Value("${jwt.expiration}")
    private long jwtExpiration;

    /**
     * Genera la clave de firma HMAC-SHA para la firma y verificación del token.
     * <p>
     * Utiliza la clave secreta inyectada ({@code jwtSecret}) y la codifica en bytes.
     * </p>
     *
     * @return La {@link Key} de firma.
     */
    private Key getSigningKey() {
        return Keys.hmacShaKeyFor(jwtSecret.getBytes());
    }

    /**
     * Genera un token JWT para un usuario autenticado.
     * <p>
     * El token incluye la ID del usuario como el "Subject" y establece las fechas de emisión y expiración.
     * </p>
     *
     * @param authentication El objeto {@link Authentication} que contiene al usuario autenticado ({@link UserPrincipal}).
     * @return El token JWT como cadena (String).
     */
    public String generateToken(Authentication authentication) {
        UserPrincipal userPrincipal = (UserPrincipal) authentication.getPrincipal();
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpiration);

        return Jwts.builder()
                .setSubject(Long.toString(userPrincipal.getId()))
                .setIssuedAt(now)
                .setExpiration(expiryDate)
                .signWith(getSigningKey(), SignatureAlgorithm.HS512)
                .compact();
    }

    /**
     * Obtiene el ID de usuario almacenado en el cuerpo (claims) de un token JWT.
     * <p>
     * El parser valida la firma del token antes de extraer el Subject (que es el ID del usuario).
     * </p>
     *
     * @param token El token JWT a parsear.
     * @return El ID del usuario (tipo {@link Long}).
     */
    public Long getUserIdFromToken(String token) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();

        return Long.parseLong(claims.getSubject());
    }

    /**
     * Valida la integridad y validez (firma y expiración) de un token JWT.
     * <p>
     * Si la firma es inválida, el token ha expirado, o está mal formado, se retorna {@code false}.
     * </p>
     *
     * @param token El token JWT a validar.
     * @return {@code true} si el token es válido, {@code false} en caso contrario.
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(getSigningKey())
                    .build()
                    .parseClaimsJws(token);
            return true;
        } catch (JwtException | IllegalArgumentException ex) {
            // Captura errores como SignatureException, MalformedJwtException, ExpiredJwtException, etc.
            return false;
        }
    }
}