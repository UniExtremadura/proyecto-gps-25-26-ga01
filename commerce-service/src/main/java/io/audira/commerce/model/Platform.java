package io.audira.commerce.model;

/**
 * Enumerador que define las plataformas o sistemas operativos de destino para el envío de notificaciones push (ej. Firebase Cloud Messaging).
 * <p>
 * Permite distinguir el tipo de dispositivo que ha registrado un token FCM para asegurar el formato de notificación correcto.
 * </p>
 *
 * @author Grupo GA01
 * 
 */
public enum Platform {
    /**
     * Dispositivo o aplicación móvil utilizando el sistema operativo Android.
     */
    ANDROID,
    
    /**
     * Dispositivo o aplicación móvil utilizando el sistema operativo iOS de Apple.
     */
    IOS,
    
    /**
     * Navegador web o aplicación web progresiva (PWA) utilizando el servicio de notificaciones web.
     */
    WEB
}