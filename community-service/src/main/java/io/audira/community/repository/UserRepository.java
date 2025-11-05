package io.audira.community.repository;

import io.audira.community.model.User;
import io.audira.community.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
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
}
