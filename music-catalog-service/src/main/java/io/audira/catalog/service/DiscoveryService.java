package io.audira.catalog.service;

import io.audira.catalog.model.Album;
import io.audira.catalog.model.Song;
import io.audira.catalog.repository.AlbumRepository;
import io.audira.catalog.repository.SongRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.data.domain.Sort;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class DiscoveryService {
    private final SongRepository songRepository;
    private final AlbumRepository albumRepository;
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${community.service.url:http://172.16.0.4:8081}")
    private String communityServiceUrl;

    public List<Song> getTrendingSongs() {
        return songRepository.findTopByPlays();
    }

    public List<Album> getTrendingAlbums() {
        return albumRepository.findTop20ByOrderByCreatedAtDesc();
    }

    public Page<Song> searchSongs(String query, Long genreId, Double minPrice, Double maxPrice, String sortBy, Pageable pageable) {
        // Permitir búsqueda si hay query, genreId o rango de precio
        boolean hasQuery = query != null && !query.trim().isEmpty();
        boolean hasFilters = genreId != null || minPrice != null || maxPrice != null;
        
        if (!hasQuery && !hasFilters) {
            return Page.empty(pageable);
        }
        
        String searchQuery = hasQuery ? query : "";

        Sort sort = Sort.by(Sort.Direction.DESC, "createdAt");
        if ("price_asc".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.ASC, "price");
        } else if ("price_desc".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.DESC, "price");
        } else if ("oldest".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.ASC, "createdAt");
        }

        Pageable sortedPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);
        log.info("DEBUG SEARCH SONGS -> Query: {}, GenreID: {}, MinPrice: {}, MaxPrice: {}, SortBy: {}", 
                 searchQuery, genreId, minPrice, maxPrice, sortBy);
        
        // Si no hay query de texto, solo filtrar por género y/o precio
        if (searchQuery.isEmpty()) {
            return songRepository.searchPublishedByFiltersOnly(genreId, minPrice, maxPrice, sortedPageable);
        }
        
        List<Long> artistIds = getArtistIdsByName(searchQuery);
        log.info("DEBUG SEARCH SONGS -> ArtistIds encontrados: {}", artistIds);

        if (artistIds.isEmpty()) {
            return songRepository.searchPublishedByTitleAndFilters(searchQuery, genreId, minPrice, maxPrice, sortedPageable);
        } else {
            return songRepository.searchPublishedByTitleOrArtistIdsAndFilters(searchQuery, artistIds, genreId, minPrice, maxPrice, sortedPageable);
        }
    }

    public Page<Album> searchAlbums(String query, Long genreId, Double minPrice, Double maxPrice, String sortBy, Pageable pageable) {
        // Permitir búsqueda si hay query, genreId o rango de precio
        boolean hasQuery = query != null && !query.trim().isEmpty();
        boolean hasFilters = genreId != null || minPrice != null || maxPrice != null;
        
        if (!hasQuery && !hasFilters) {
            return Page.empty(pageable);
        }
        
        String searchQuery = hasQuery ? query : "";

        Sort sort = Sort.by(Sort.Direction.DESC, "releaseDate");
        if ("price_asc".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.ASC, "price");
        } else if ("price_desc".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.DESC, "price");
        } else if ("oldest".equals(sortBy)) {
            sort = Sort.by(Sort.Direction.ASC, "createdAt");
        }

        Pageable sortedPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), sort);
        log.info("DEBUG SEARCH ALBUMS -> Query: {}, GenreID: {}, MinPrice: {}, MaxPrice: {}, SortBy: {}", 
                 searchQuery, genreId, minPrice, maxPrice, sortBy);
        
        // Si no hay query de texto, solo filtrar por género y/o precio
        if (searchQuery.isEmpty()) {
            return albumRepository.searchPublishedByFiltersOnly(genreId, minPrice, maxPrice, sortedPageable);
        }
        
        List<Long> artistIds = getArtistIdsByName(searchQuery);
        log.info("DEBUG SEARCH ALBUMS -> ArtistIds encontrados: {}", artistIds);

        if (artistIds.isEmpty()) {
            return albumRepository.searchPublishedByTitleAndFilters(searchQuery, genreId, minPrice, maxPrice, sortedPageable);
        } else {
            return albumRepository.searchPublishedByTitleOrArtistIdsAndFilters(searchQuery, artistIds, genreId, minPrice, maxPrice, sortedPageable);
        }
    }

    private List<Long> getArtistIdsByName(String query) {
        try {
            String url = UriComponentsBuilder.fromHttpUrl(communityServiceUrl + "/api/users/search/artist-ids")
                    .queryParam("query", query)
                    .toUriString();

            ResponseEntity<List<Long>> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    null,
                    new ParameterizedTypeReference<List<Long>>() {}
            );

            return response.getBody() != null ? response.getBody() : new ArrayList<>();
        } catch (Exception e) {
            log.warn("Error al obtener artistIds del community-service: {}", e.getMessage());
            return new ArrayList<>();
        }
    }
}