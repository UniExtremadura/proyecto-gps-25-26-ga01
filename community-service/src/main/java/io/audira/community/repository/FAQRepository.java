package io.audira.community.repository;

import io.audira.community.model.FAQ;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FAQRepository extends JpaRepository<FAQ, Long> {

    List<FAQ> findByIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc();

    List<FAQ> findByCategoryOrderByDisplayOrderAscCreatedAtDesc(String category);

    List<FAQ> findByCategoryAndIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc(String category);

    List<FAQ> findAllByOrderByDisplayOrderAscCreatedAtDesc();
}
