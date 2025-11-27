package io.audira.community.repository;

import io.audira.community.model.ContactResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ContactResponseRepository extends JpaRepository<ContactResponse, Long> {

    List<ContactResponse> findByContactMessageId(Long contactMessageId);

    List<ContactResponse> findByContactMessageIdOrderByCreatedAtDesc(Long contactMessageId);

    List<ContactResponse> findByAdminId(Long adminId);
}
