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
 * Interceptor that forwards JWT token from incoming requests to outgoing REST calls
 * This ensures that authentication context is propagated between microservices
 */
@Component
@Slf4j

public class JwtForwardingInterceptor implements ClientHttpRequestInterceptor {
    private static final String AUTHORIZATION_HEADER = "Authorization";
    private static final String BEARER_PREFIX = "Bearer ";

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
     * Extract JWT token from current HTTP request context
     *
     * @return JWT token without "Bearer " prefix, or null if not found
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
 
            // If header doesn't start with "Bearer ", return it as is
            return authHeader;

        } catch (Exception e) {
            log.warn("Error extracting JWT token from request context", e);
            return null;
        }
    }
}