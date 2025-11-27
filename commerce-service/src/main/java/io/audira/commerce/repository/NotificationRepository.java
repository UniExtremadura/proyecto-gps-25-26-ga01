package io.audira.commerce.repository;

import io.audira.commerce.model.Notification;
import io.audira.commerce.model.NotificationType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    // ✅ NUEVO: Método optimizado para paginación real en base de datos
    Page<Notification> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    // Métodos auxiliares para otras operaciones (listas completas)
    List<Notification> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Notification> findByUserIdAndIsReadOrderByCreatedAtDesc(Long userId, Boolean isRead);

    List<Notification> findByUserIdAndTypeOrderByCreatedAtDesc(Long userId, NotificationType type);

    Long countByUserIdAndIsRead(Long userId, Boolean isRead);

    List<Notification> findByIsSentFalse();
}