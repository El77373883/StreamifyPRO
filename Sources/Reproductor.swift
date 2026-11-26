
import Foundation
import SwiftUI
import AVFoundation
import MediaPlayer
import Combine
import UIKit

class Reproductor: ObservableObject {

    @Published var cancionActual: Cancion?
    @Published var reproduciendo = false
    @Published var progreso: Double = 0
    @Published var duracion: Double = 1

    @Published var favoritos: [Cancion] = []
    @Published var descargas: [Cancion] = []

    @Published var descargandoKeys: Set<String> = []
    @Published var mensajeDescarga = ""

    private var player: AVPlayer?
    private var timer: AnyCancellable?

    private let favoritosKey = "StreamifyFavoritos"
    private let descargasKey = "StreamifyDescargas"

    init() {
        cargarDatos()
        configurarControlesRemotos()
    }

    // MARK: - GUARDAR DATOS

    private func cargarDatos() {

        if let data = UserDefaults.standard.data(
            forKey: favoritosKey
        ) {
            favoritos = (try? JSONDecoder().decode(
                [Cancion].self,
                from: data
            )) ?? []
        }

        if let data = UserDefaults.standard.data(
            forKey: descargasKey
        ) {
            let guardadas = (try? JSONDecoder().decode(
                [Cancion].self,
                from: data
            )) ?? []

            descargas = guardadas.filter {
                guard let url = URL(string: $0.urlAudio) else {
                    return false
                }
                return FileManager.default.fileExists(
                    atPath: url.path
                )
            }

            guardarDescargas()
        }
    }

    private func guardarFavoritos() {
        if let data = try? JSONEncoder().encode(favoritos) {
            UserDefaults.standard.set(data, forKey: favoritosKey)
        }
    }

    private func guardarDescargas() {
        if let data = try? JSONEncoder().encode(descargas) {
            UserDefaults.standard.set(data, forKey: descargasKey)
        }
    }

    // MARK: - FAVORITOS

    func esFavorita(_ cancion: Cancion) -> Bool {
        favoritos.contains {
            $0.clave == cancion.clave
        }
    }

    func alternarFavorito(_ cancion: Cancion) {

        if esFavorita(cancion) {
            favoritos.removeAll {
                $0.clave == cancion.clave
            }
        } else {
            favoritos.append(cancion)
        }

        guardarFavoritos()
    }

    // MARK: - DESCARGAS

    func estaDescargada(_ cancion: Cancion) -> Bool {
        descargas.contains {
            $0.clave == cancion.clave
        }
    }

    func descargar(_ cancion: Cancion) {

        if estaDescargada(cancion) {
            mensajeDescarga = "Esta canción ya está descargada."
            return
        }

        guard let url = URL(string: cancion.urlAudio),
              let esquema = url.scheme,
              esquema == "https" || esquema == "http" else {

            mensajeDescarga = "URL de audio no válida."
            return
        }

        guard !descargandoKeys.contains(cancion.clave) else {
            return
        }

        descargandoKeys.insert(cancion.clave)
        mensajeDescarga = "Descargando canción..."

        URLSession.shared.downloadTask(with: url) {
            [weak self] archivoTemporal, response, error in

            guard let self = self else { return }

            defer {
                DispatchQueue.main.async {
                    self.descargandoKeys.remove(cancion.clave)
                }
            }

            guard error == nil,
                  let archivoTemporal = archivoTemporal,
                  let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {

                DispatchQueue.main.async {
                    self.mensajeDescarga = "No se pudo descargar."
                }
                return
            }

            do {
                let carpeta = FileManager.default.urls(
                    for: .documentDirectory,
                    in: .userDomainMask
                )[0].appendingPathComponent("StreamifyMusic")

                try FileManager.default.createDirectory(
                    at: carpeta,
                    withIntermediateDirectories: true
                )

                let nombre = UUID().uuidString + ".mp3"
                let destino = carpeta.appendingPathComponent(nombre)

                try FileManager.default.moveItem(
                    at: archivoTemporal,
                    to: destino
                )

                var cancionLocal = cancion
                cancionLocal.urlAudio = destino.absoluteString

                DispatchQueue.main.async {

                    self.descargas.removeAll {
                        $0.clave == cancion.clave
                    }

                    self.descargas.append(cancionLocal)
                    self.guardarDescargas()

                    self.mensajeDescarga = "¡Canción descargada!"
                }

            } catch {

                DispatchQueue.main.async {
                    self.mensajeDescarga = "Error guardando la canción."
                }
            }

        }.resume()
    }

    // MARK: - REPRODUCCIÓN

    func reproducir(_ cancion: Cancion) {

        cancionActual = cancion

        let cancionLocal = descargas.first {
            $0.clave == cancion.clave
        }

        let cancionParaReproducir = cancionLocal ?? cancion

        guard let url = URL(
            string: cancionParaReproducir.urlAudio
        ) else {
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default
            )

            try AVAudioSession.sharedInstance().setActive(true)

        } catch {
            print("Error de audio: \(error)")
        }

        player?.pause()

        player = AVPlayer(url: url)
        progreso = 0
        duracion = 1

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

        guard let player = player else { return }

        let seguro = min(max(valor, 0), 1)
        let segundos = duracion * seguro

        let tiempo = CMTime(
            seconds: segundos,
            preferredTimescale: 600
        )

        player.seek(to: tiempo)

        progreso = seguro
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

            let actual = CMTimeGetSeconds(
                player.currentTime()
            )

            if let dur = player.currentItem?.duration.seconds,
               dur.isFinite,
               dur > 0 {

                self.duracion = dur
                self.progreso = min(max(actual / dur, 0), 1)
            }

            if player.timeControlStatus == .paused {
                self.reproduciendo = false
            }
        }
    }

    // MARK: - PANTALLA BLOQUEADA

    private func actualizarInfoPantallaBloqueo(
        _ cancion: Cancion
    ) {

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: cancion.titulo,
            MPMediaItemPropertyArtist: cancion.artista,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        guard let url = URL(string: cancion.urlPortada) else {
            return
        }

        URLSession.shared.dataTask(with: url) {
            data, _, _ in

            guard let data = data,
                  let imagen = UIImage(data: data) else {
                return
            }

            info[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: imagen.size) {
                    _ in imagen
                }

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
