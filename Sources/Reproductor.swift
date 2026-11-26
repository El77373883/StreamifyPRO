
import Foundation
import SwiftUI
import AVFoundation
import MediaPlayer
import Combine
import UIKit

class Reproductor: ObservableObject {

    @Published var cancionActual: Cancion? = nil
    @Published var reproduciendo = false
    @Published var progreso: Double = 0.0
    @Published var duracion: Double = 1.0

    @Published var favoritos: [Cancion] = []
    @Published var descargas: [Cancion] = []

    @Published var descargandoKeys: Set<String> = []
    @Published var mensajeDescarga = ""

    private var player: AVPlayer?
    private var timer: AnyCancellable?

    private let favoritosKey = "StreamifyFavoritos"
    private let descargasKey = "StreamifyDescargas"
    private let rutasKey = "StreamifyRutasDescarga"

    private var rutasDescarga: [String: String] = [:]

    init() {
        cargarDatos()
        configurarAudio()
        configurarControlesRemotos()
    }

    // MARK: - IDENTIFICADOR DE CANCIÓN

    private func clave(_ cancion: Cancion) -> String {
        return "\(cancion.titulo.lowercased())|\(cancion.artista.lowercased())"
    }

    // MARK: - FAVORITOS

    func esFavorita(_ cancion: Cancion) -> Bool {
        favoritos.contains {
            clave($0) == clave(cancion)
        }
    }

    func alternarFavorito(_ cancion: Cancion) {
        if esFavorita(cancion) {
            favoritos.removeAll {
                clave($0) == clave(cancion)
            }
        } else {
            favoritos.append(cancion)
        }

        guardarDatos()
    }

    // MARK: - DESCARGAS

    func estaDescargada(_ cancion: Cancion) -> Bool {
        let key = clave(cancion)

        guard let ruta = rutasDescarga[key] else {
            return false
        }

        return FileManager.default.fileExists(atPath: ruta)
    }

    func descargar(_ cancion: Cancion) {

        let key = clave(cancion)

        if estaDescargada(cancion) {
            mensajeDescarga = "Esta canción ya está descargada."
            return
        }

        if descargandoKeys.contains(key) {
            return
        }

        guard let url = URL(string: cancion.urlAudio),
              let esquema = url.scheme?.lowercased(),
              esquema == "https" || esquema == "http" else {
            mensajeDescarga = "No se pudo obtener el enlace de audio."
            return
        }

        descargandoKeys.insert(key)
        mensajeDescarga = "Descargando \(cancion.titulo)..."

        URLSession.shared.downloadTask(with: url) { [weak self] archivoTemporal, respuesta, error in

            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.descargandoKeys.remove(key)
                    self.mensajeDescarga = "Error al descargar: \(error.localizedDescription)"
                }
                return
            }

            guard let archivoTemporal = archivoTemporal else {
                DispatchQueue.main.async {
                    self.descargandoKeys.remove(key)
                    self.mensajeDescarga = "No se recibió el archivo."
                }
                return
            }

            if let respuesta = respuesta as? HTTPURLResponse,
               !(200...299).contains(respuesta.statusCode) {
                DispatchQueue.main.async {
                    self.descargandoKeys.remove(key)
                    self.mensajeDescarga = "El servidor rechazó la descarga."
                }
                return
            }

            do {
                let documentos = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                )[0]

                let carpeta = documentos.appendingPathComponent(
                    "StreamifyDownloads",
                    isDirectory: true
                )

                try FileManager.default.createDirectory(
                    at: carpeta,
                    withIntermediateDirectories: true
                )

                let extensionArchivo = URLSession.shared.configuration.httpAdditionalHeaders == nil
                    ? "mp3" : (url.pathExtension.isEmpty ? "mp3" : url.pathExtension)

                let destino = carpeta.appendingPathComponent(
                    UUID().uuidString + "." + extensionArchivo
                )

                try FileManager.default.moveItem(
                    at: archivoTemporal,
                    to: destino
                )

                DispatchQueue.main.async {
                    self.rutasDescarga[key] = destino.path

                    if !self.descargas.contains(where: {
                        self.clave($0) == key
                    }) {
                        self.descargas.append(cancion)
                    }

                    self.descargandoKeys.remove(key)
                    self.mensajeDescarga = "¡Canción descargada correctamente!"

                    self.guardarDatos()
                }

            } catch {
                DispatchQueue.main.async {
                    self.descargandoKeys.remove(key)
                    self.mensajeDescarga = "No se pudo guardar el archivo."
                }
            }
        }.resume()
    }

    // MARK: - GUARDAR DATOS

    private func cargarDatos() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: favoritosKey),
           let canciones = try? JSONDecoder().decode([Cancion].self, from: data) {
            favoritos = canciones
        }

        if let data = defaults.data(forKey: descargasKey),
           let canciones = try? JSONDecoder().decode([Cancion].self, from: data) {
            descargas = canciones
        }

        if let rutas = defaults.dictionary(forKey: rutasKey) as? [String: String] {
            rutasDescarga = rutas
        }

        // Eliminar registros de descargas cuyos archivos ya no existen.
        descargas.removeAll {
            !estaDescargada($0)
        }

        guardarDatos()
    }

    private func guardarDatos() {
        let defaults = UserDefaults.standard

        if let data = try? JSONEncoder().encode(favoritos) {
            defaults.set(data, forKey: favoritosKey)
        }

        if let data = try? JSONEncoder().encode(descargas) {
            defaults.set(data, forKey: descargasKey)
        }

        defaults.set(rutasDescarga, forKey: rutasKey)
    }

    // MARK: - CONFIGURAR AUDIO

    private func configurarAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )

            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configurando audio: \(error)")
        }
    }

    // MARK: - REPRODUCIR

    func reproducir(_ cancion: Cancion) {
        cancionActual = cancion
        progreso = 0
        duracion = 1

        let key = clave(cancion)

        let url: URL

        if let ruta = rutasDescarga[key],
           FileManager.default.fileExists(atPath: ruta) {
            url = URL(fileURLWithPath: ruta)
        } else {
            guard let onlineURL = URL(string: cancion.urlAudio) else {
                mensajeDescarga = "Enlace de audio no válido."
                return
            }

            url = onlineURL
        }

        player = AVPlayer(url: url)
        player?.play()

        reproduciendo = true

        actualizarInfoPantallaBloqueo(cancion)
        iniciarTimer()
    }

    func pausar() {
        player?.pause()
        reproduciendo = false
        actualizarEstadoBloqueo()
    }

    func reanudar() {
        guard player != nil else { return }

        player?.play()
        reproduciendo = true
        actualizarEstadoBloqueo()
    }

    func alternarPlayPausa() {
        if reproduciendo {
            pausar()
        } else {
            reanudar()
        }
    }

    func cambiarProgreso(a valor: Double) {
        guard let player = player,
              duracion.isFinite,
              duracion > 0 else {
            return
        }

        let valorSeguro = min(max(valor, 0), 1)
        let nuevoTiempo = CMTime(
            seconds: duracion * valorSeguro,
            preferredTimescale: 600
        )

        player.seek(to: nuevoTiempo)
        progreso = valorSeguro
    }

    // MARK: - TEMPORIZADOR

    private func iniciarTimer() {
        timer?.cancel()

        timer = Timer.publish(
            every: 0.5,
            on: .main,
            in: .common
        )
        .autoconnect()
        .sink { [weak self] _ in

            guard let self = self,
                  let player = self.player else {
                return
            }

            let actual = CMTimeGetSeconds(player.currentTime())

            if let dur = player.currentItem?.duration.seconds,
               dur.isFinite,
               dur > 0 {

                self.duracion = dur
                self.progreso = min(max(actual / dur, 0), 1)
            }
        }
    }

    // MARK: - PANTALLA BLOQUEADA

    private func actualizarInfoPantallaBloqueo(_ cancion: Cancion) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: cancion.titulo,
            MPMediaItemPropertyArtist: cancion.artista,
            MPMediaItemPropertyAlbumTitle: cancion.album,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        guard let url = URL(string: cancion.urlPortada) else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let imagen = UIImage(data: data) else {
                return
            }

            let artwork = MPMediaItemArtwork(boundsSize: imagen.size) { _ in
                imagen
            }

            info[MPMediaItemPropertyArtwork] = artwork

            DispatchQueue.main.async {
                MPNowPlayingInfoCenter.default().nowPlayingInfo = info
            }
        }.resume()
    }

    private func actualizarEstadoBloqueo() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

        info[MPNowPlayingInfoPropertyPlaybackRate] =
            reproduciendo ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - CONTROLES REMOTOS

    private func configurarControlesRemotos() {
        let centro = MPRemoteCommandCenter.shared()

        centro.playCommand.addTarget { [weak self] _ in
            self?.reanudar()
            return .success
        }

        centro.pauseCommand.addTarget { [weak self] _ in
            self?.pausar()
            return .success
        }

        centro.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.alternarPlayPausa()
            return .success
        }
    }
}
