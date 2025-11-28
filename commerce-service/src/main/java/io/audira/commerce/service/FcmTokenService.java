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

@Service
@RequiredArgsConstructor
@Slf4j
public class FcmTokenService {

    private final FcmTokenRepository fcmTokenRepository;

    /**
     * Register or update an FCM token for a user
     */
    @Transactional
    public FcmToken registerToken(Long userId, String token, Platform platform) {
        // Check if token already exists
        Optional<FcmToken> existing = fcmTokenRepository.findByToken(token);

        if (existing.isPresent()) {
            // Update existing token
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
     * Delete a specific token for a user
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
     * Delete all tokens for a user
     */
    @Transactional
    public void deleteAllUserTokens(Long userId) {
        fcmTokenRepository.deleteByUserId(userId);
        log.info("Deleted all FCM tokens for user {}", userId);
    }

    /**
     * Get all tokens for a user
     */
    public List<FcmToken> getUserTokens(Long userId) {
        return fcmTokenRepository.findByUserId(userId);
    }

    /**
     * Get a specific token
     */
    public Optional<FcmToken> getToken(String token) {
        return fcmTokenRepository.findByToken(token);
    }
}
