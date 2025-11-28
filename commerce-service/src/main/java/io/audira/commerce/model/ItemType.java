package io.audira.commerce.model;

/**
 * Enumerador que define los tipos de artículos o productos que pueden ser comercializados
 * y gestionados dentro del sistema de comercio (carrito, órdenes, favoritos, biblioteca).
 *
 * @author Grupo GA01
 * 
 */
public enum ItemType {
    /**
     * Representa un producto de tipo Canción o Pista musical individual.
     */
    SONG,
    
    /**
     * Representa un producto de tipo Álbum musical completo.
     */
    ALBUM,
    
    /**
     * Representa un producto físico o digital de tipo Mercancía (Merchandise).
     */
    MERCHANDISE
}