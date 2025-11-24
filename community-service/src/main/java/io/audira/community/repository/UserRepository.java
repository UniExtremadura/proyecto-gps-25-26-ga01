package io.audira.community.repository;

import io.audira.community.model.User;
import io.audira.community.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    Optional<User> findByUsername(String username);
    Optional<User> findByEmailOrUsername(String email, String username);

    Boolean existsByEmail(String email);
    Boolean existsByUsername(String username);

    List<User> findByRole(UserRole role);
    List<User> findByIsActive(Boolean isActive);

    /**
     * Search artists by name (artistName, firstName, or lastName)
     * Works for both Artist entities and regular Users with ARTIST role
     * Searches by: artistName, firstName, lastName, or full name (firstName + lastName)
     * Case-insensitive and supports partial matches
     * 
     * @param query Search query (can be partial name)
     * @return List of User entities with ARTIST role matching the query
     */
    @Query("SELECT DISTINCT u FROM User u LEFT JOIN Artist a ON u.id = a.id " +
           "WHERE u.role = 'ARTIST' AND (" +
           "LOWER(u.firstName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(u.lastName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(CONCAT(u.firstName, ' ', u.lastName)) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(a.artistName) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<User> searchArtistsByName(@Param("query") String query);

    /**
     * Search artist IDs by name (artistName, firstName, or lastName)
     * Works for both Artist entities and regular Users with ARTIST role
     * Searches by: artistName, firstName, lastName, or full name (firstName + lastName)
     * Case-insensitive and supports partial matches
     * 
     * @param query Search query (can be partial name)
     * @return List of User IDs with ARTIST role matching the query
     */
    @Query("SELECT DISTINCT u.id FROM User u LEFT JOIN Artist a ON u.id = a.id " +
           "WHERE u.role = 'ARTIST' AND (" +
           "LOWER(u.firstName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(u.lastName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(CONCAT(u.firstName, ' ', u.lastName)) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(a.artistName) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<Long> searchArtistIdsByName(@Param("query") String query);
}