package io.audira.community.repository;

import io.audira.community.model.ContactMessage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContactMessageRepository extends JpaRepository<ContactMessage, Long> {

    List<ContactMessage> findAllByOrderByCreatedAtDesc();

    List<ContactMessage> findByIsReadFalseOrderByCreatedAtDesc();

    List<ContactMessage> findByUserIdOrderByCreatedAtDesc(Long userId);
}
