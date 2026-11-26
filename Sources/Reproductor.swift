
import Foundation
import SwiftUI
import AVFoundation
import MediaPlayer
import Combine
import UIKit

// MARK: - DESCARGADOR CON PROGRESO REAL

private final class DescargaAudio: NSObject, URLSessionDownloadDelegate {

    private let url: URL
    private let progresoHandler: (Double) -> Void
    private let completion: (Result<URL, Error>) -> Void
    private var session: URLSession?

    init(
        url: URL,
        progreso: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        self.url = url
        self.progresoHandler = progreso
        self.completion = completion
        super.init()
    }

    func iniciar() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 180

        let nuevaSesion = URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: OperationQueue.main
        )

        session = nuevaSesion
        nuevaSesion.downloadTask(with: url).resume()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }

        let porcentaje =
            Double(totalBytesWritten) /
            Double(totalBytesExpectedToWrite)

        progresoHandler(min(max(porcentaje, 0), 1))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        do {
            if let respuesta = downloadTask.response as? HTTPURLResponse,
               !(200...299).contains(respuesta.statusCode) {
                throw URLError(.badServerResponse)
            }

            let documentos = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )[0]

            let carpeta = documentos.appendingPathComponent(
                "StreamifyMusic",
                isDirectory: true
            )

            try FileManager.default.createDirectory(
                at: carpeta,
                withIntermediateDirectories: true
            )

            let extensionArchivo =
                downloadTask.response?.suggestedFilename?
                    .split(separator: ".").last
                    .map(String.init) ?? "mp3"

            let destino = carpeta.appendingPathComponent(
                UUID().uuidString + "." + extensionArchivo
            )

            try FileManager.default.moveItem(
                at: location,
                to: destino
            )

            progresoHandler(1)
            completion(.success(destino))

        } catch {
            completion(.failure(error))
        }

        session.finishTasksAndInvalidate()
        self.session = nil
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            completion(.failure(error))
            session.invalidateAndCancel()
            self.session = nil
        }
    }
}

// MARK: - REPRODUCTOR

class Reproductor: ObservableObject {

    @Published var cancionActual: Cancion?
    @Published var reproduciendo = false
    @Published var progreso: Double = 0
    @Published var duracion: Double = 1

    @Published var favoritos: [Cancion] = []
    @Published var descargas: [Cancion] = []

    @Published var descargandoKeys: Set<String> = []
    @Published var progresoDescarga: [String: Double] = [:]
    @Published var mensajeDescarga = ""

    private var descargasActivas: [String: DescargaAudio] = [:]

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
                guard let url = URL(string: $0.urlAudio),
                      url.isFileURL else {
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

        let clave = cancion.clave

        guard !descargandoKeys.contains(clave) else {
            return
        }

        descargandoKeys.insert(clave)
        progresoDescarga[clave] = 0
        mensajeDescarga = "Preparando descarga..."

        let descarga = DescargaAudio(
            url: url,
            progreso: { [weak self] valor in
                guard let self = self else { return }

                self.progresoDescarga[clave] = valor
                self.mensajeDescarga = "Descargando música..."
            },
            completion: { [weak self] resultado in
                guard let self = self else { return }

                self.descargandoKeys.remove(clave)
                self.descargasActivas.removeValue(forKey: clave)

                switch resultado {

                case .success(let archivo):

                    var local = cancion
                    local.urlAudio = archivo.absoluteString

                    self.descargas.removeAll {
                        $0.clave == clave
                    }

                    self.descargas.append(local)
                    self.guardarDescargas()

                    self.progresoDescarga[clave] = 1
                    self.mensajeDescarga = "¡Descarga completada!"

                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 2
                    ) {
                        self.progresoDescarga.removeValue(
                            forKey: clave
                        )
                    }

                case .failure:

                    self.progresoDescarga.removeValue(
                        forKey: clave
                    )

                    self.mensajeDescarga =
                        "No se pudo descargar. Inténtalo otra vez."
                }
            }
        )

        descargasActivas[clave] = descarga
        descarga.iniciar()
    }

    // MARK: - REPRODUCCIÓN

    func reproducir(_ cancion: Cancion) {

        cancionActual = cancion

        let local = descargas.first {
            $0.clave == cancion.clave
        }

        let cancionParaReproducir = local ?? cancion

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

            self.reproduciendo =
                player.timeControlStatus == .playing
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

        var info =
            MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

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
