package io.audira.catalog.config;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
/**
 * Configuration for REST clients
 */
@Configuration
@RequiredArgsConstructor

public class RestTemplateConfig {
    private final JwtForwardingInterceptor jwtForwardingInterceptor;

    @Bean
    public RestTemplate restTemplate() {
        RestTemplate restTemplate = new RestTemplate();

        // Add JWT forwarding interceptor to propagate authentication to other services
        List<ClientHttpRequestInterceptor> interceptors = new ArrayList<>();
        interceptors.add(jwtForwardingInterceptor);
        restTemplate.setInterceptors(interceptors);

        return restTemplate;
    }
}