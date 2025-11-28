package io.audira.commerce.repository;

import io.audira.commerce.model.FcmToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FcmTokenRepository extends JpaRepository<FcmToken, Long> {

    /**
     * Find all tokens for a specific user
     */
    List<FcmToken> findByUserId(Long userId);

    /**
     * Find a specific token
     */
    Optional<FcmToken> findByToken(String token);

    /**
     * Find a token for a specific user
     */
    Optional<FcmToken> findByUserIdAndToken(Long userId, String token);

    /**
     * Delete all tokens for a specific user
     */
    void deleteByUserId(Long userId);

    /**
     * Delete a specific token
     */
    void deleteByToken(String token);
}
