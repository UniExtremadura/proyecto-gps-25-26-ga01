package io.audira.catalog.client;

import io.audira.catalog.dto.UserDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;

/**
 * REST client for communication with Community Service (User management)
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class UserServiceClient {

    private final RestTemplate restTemplate;

    @Value("${services.user.url:http://172.16.0.4:8080/api/users}")
    private String userServiceUrl;

    /**
     * Get user/artist information by ID
     *
     * @param userId User ID
     * @return UserDTO with user information
     */
    public UserDTO getUserById(Long userId) {
        String url = userServiceUrl + "/" + userId;

        try {
            log.debug("Fetching user information for userId: {} from URL: {}", userId, url);
            UserDTO user = restTemplate.getForObject(url, UserDTO.class);

            if (user == null) {
                log.warn("Received null response from user service for userId: {}", userId);
                return createFallbackUser(userId);
            }

            log.debug("User information retrieved successfully: id={}, username={}",
                    user.getId(), user.getUsername());
            return user;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching user for userId: {}. Status: {}",
                    userId, e.getStatusCode());
            return createFallbackUser(userId);

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing user service at {} for userId: {}",
                    url, userId);
            return createFallbackUser(userId);

        } catch (Exception e) {
            log.error("Unexpected error fetching user for userId: {}", userId, e);
            return createFallbackUser(userId);
        }
    }

    /**
     * Get list of artist IDs that a user follows
     * GA01-117: For recommendations based on followed artists
     *
     * @param userId User ID
     * @return List of artist IDs
     */
    public List<Long> getFollowedArtistIds(Long userId) {
        String url = userServiceUrl + "/" + userId + "/following/artists";

        try {
            log.debug("Fetching followed artists for userId: {} from URL: {}", userId, url);

            ResponseEntity<List<UserDTO>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<UserDTO>>() {}
            );

            List<UserDTO> artists = response.getBody();
            if (artists == null) {
                log.warn("Received null response for followed artists for userId: {}", userId);
                return new ArrayList<>();
            }

            // Extract IDs from UserDTO objects
            List<Long> artistIds = artists.stream()
                    .map(UserDTO::getId)
                    .toList();

            log.debug("Followed artists retrieved successfully for userId: {}, count: {}",
                    userId, artistIds.size());
            return artistIds;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching followed artists for userId: {}. Status: {}",
                    userId, e.getStatusCode());
            return new ArrayList<>();

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing user service at {} for userId: {}",
                    url, userId);
            return new ArrayList<>();

        } catch (Exception e) {
            log.error("Unexpected error fetching followed artists for userId: {}", userId, e);
            return new ArrayList<>();
        }
    }

    /**
     * Get list of user IDs that follow a specific artist
     * Used for notifying followers about new content
     *
     * @param artistId Artist ID
     * @return List of follower user IDs
     */
    public List<Long> getFollowerIds(Long artistId) {
        String url = userServiceUrl + "/" + artistId + "/followers";

        try {
            log.debug("Fetching followers for artistId: {} from URL: {}", artistId, url);

            ResponseEntity<List<UserDTO>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<UserDTO>>() {}
            );

            List<UserDTO> followers = response.getBody();
            if (followers == null) {
                log.warn("Received null response for followers of artistId: {}", artistId);
                return new ArrayList<>();
            }

            // Ahora se extraen los IDs de los objetos UserDTO
            List<Long> followerIds = followers.stream()
                    .map(UserDTO::getId)
                    .toList();

            log.debug("Followers retrieved successfully for artistId: {}, count: {}",
                    artistId, followerIds.size());
            return followerIds;

        } catch (HttpClientErrorException e) {
            log.warn("HTTP error fetching followers for artistId: {}. Status: {}",
                    artistId, e.getStatusCode());
            return new ArrayList<>();

        } catch (ResourceAccessException e) {
            log.warn("Connection error accessing user service at {} for artistId: {}",
                    url, artistId);
            return new ArrayList<>();

        } catch (Exception e) {
            log.error("Unexpected error fetching followers for artistId: {}", artistId, e);
            return new ArrayList<>();
        }
    }

    /**
     * Create a fallback user when the service is unavailable
     */
    private UserDTO createFallbackUser(Long userId) {
        return UserDTO.builder()
                .id(userId)
                .username("User #" + userId)
                .artistName("Artist #" + userId)
                .build();
    }
}
