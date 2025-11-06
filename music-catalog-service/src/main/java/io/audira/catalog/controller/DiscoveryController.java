package io.audira.catalog.controller;

import io.audira.catalog.model.Song;
import io.audira.catalog.service.DiscoveryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/discovery")
@RequiredArgsConstructor
public class DiscoveryController {

    private final DiscoveryService discoveryService;

    @GetMapping("/trending/songs")
    public ResponseEntity<List<Song>> getTrendingSongs() {
        return ResponseEntity.ok(discoveryService.getTrendingSongs());
    }
}
