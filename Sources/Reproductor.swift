
import Foundation
import SwiftUI
import AVFoundation
import MediaPlayer
import Combine
import UIKit

// MARK: - DESCARGADOR

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

        let porcentaje = Double(totalBytesWritten) /
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

            let ext = downloadTask.response?.suggestedFilename?
                .split(separator: ".").last
                .map(String.init) ?? "mp3"

            let destino = carpeta.appendingPathComponent(
                UUID().uuidString + "." + ext
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

// MARK: - LETRAS

private struct RespuestaLetra: Decodable {
    let plainLyrics: String?
    let syncedLyrics: String?
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

    // Cola y controles
    @Published var cola: [Cancion] = []
    @Published var aleatorio = false

    // 0 = apagado, 1 = repetir todo, 2 = repetir canción
    @Published var repetirModo = 0

    // Letras
    @Published var letra = ""
    @Published var cargandoLetra = false
    @Published var letraNoEncontrada = false

    private var indiceActual = 0
    private var descargasActivas: [String: DescargaAudio] = [:]

    private var player: AVPlayer?
    private var timer: AnyCancellable?
    private var observadorFinal: NSObjectProtocol?

    private let favoritosKey = "StreamifyFavoritos"
    private let descargasKey = "StreamifyDescargas"

    init() {
        cargarDatos()
        configurarControlesRemotos()
    }

    deinit {
        timer?.cancel()

        if let observadorFinal {
            NotificationCenter.default.removeObserver(observadorFinal)
        }
    }

    // MARK: - DATOS

    private func cargarDatos() {
        if let data = UserDefaults.standard.data(forKey: favoritosKey) {
            favoritos = (try? JSONDecoder().decode(
                [Cancion].self,
                from: data
            )) ?? []
        }

        if let data = UserDefaults.standard.data(forKey: descargasKey) {
            let guardadas = (try? JSONDecoder().decode(
                [Cancion].self,
                from: data
            )) ?? []

            descargas = guardadas.filter {
                guard let url = URL(string: $0.urlAudio),
                      url.isFileURL else { return false }

                return FileManager.default.fileExists(atPath: url.path)
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
        favoritos.contains { $0.clave == cancion.clave }
    }

    func alternarFavorito(_ cancion: Cancion) {
        if esFavorita(cancion) {
            favoritos.removeAll { $0.clave == cancion.clave }
        } else {
            favoritos.append(cancion)
        }

        guardarFavoritos()
    }

    // MARK: - DESCARGAS

    func estaDescargada(_ cancion: Cancion) -> Bool {
        descargas.contains { $0.clave == cancion.clave }
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

        guard !descargandoKeys.contains(clave) else { return }

        descargandoKeys.insert(clave)
        progresoDescarga[clave] = 0
        mensajeDescarga = "Preparando descarga..."

        let descarga = DescargaAudio(
            url: url,
            progreso: { [weak self] valor in
                guard let self else { return }
                self.progresoDescarga[clave] = valor
                self.mensajeDescarga = "Descargando música..."
            },
            completion: { [weak self] resultado in
                guard let self else { return }

                self.descargandoKeys.remove(clave)
                self.descargasActivas.removeValue(forKey: clave)

                switch resultado {
                case .success(let archivo):
                    var local = cancion
                    local.urlAudio = archivo.absoluteString

                    self.descargas.removeAll { $0.clave == clave }
                    self.descargas.append(local)
                    self.guardarDescargas()

                    self.progresoDescarga[clave] = 1
                    self.mensajeDescarga = "¡Descarga completada!"

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.progresoDescarga.removeValue(forKey: clave)
                    }

                case .failure:
                    self.progresoDescarga.removeValue(forKey: clave)
                    self.mensajeDescarga =
                        "No se pudo descargar. Inténtalo otra vez."
                }
            }
        )

        descargasActivas[clave] = descarga
        descarga.iniciar()
    }

    // MARK: - COLA DE REPRODUCCIÓN

    func establecerCola(_ canciones: [Cancion]) {
        cola = canciones
    }

    // Usa esta función cuando quieras que siguiente y aleatorio
    // recorran la lista completa de canciones.
    func reproducir(_ cancion: Cancion, de canciones: [Cancion]) {
        cola = canciones

        if let indice = canciones.firstIndex(where: {
            $0.clave == cancion.clave
        }) {
            indiceActual = indice
        }

        reproducir(cancion)
    }

    // MARK: - REPRODUCIR

    func reproducir(_ cancion: Cancion) {
        if cola.isEmpty {
            cola = [cancion]
            indiceActual = 0
        } else if let indice = cola.firstIndex(where: {
            $0.clave == cancion.clave
        }) {
            indiceActual = indice
        }

        cancionActual = cancion
        cargarLetra(cancion)

        let local = descargas.first {
            $0.clave == cancion.clave
        }

        let cancionParaReproducir = local ?? cancion

        guard let url = URL(string: cancionParaReproducir.urlAudio) else {
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

        configurarFinDeCancion()
        player?.play()

        reproduciendo = true
        actualizarInfoPantallaBloqueo(cancion)
        iniciarTimer()
    }

    // MARK: - SIGUIENTE Y ANTERIOR

    func siguiente() {
        guard !cola.isEmpty else { return }

        if aleatorio && cola.count > 1 {
            var nuevoIndice = indiceActual

            while nuevoIndice == indiceActual {
                nuevoIndice = Int.random(in: 0..<cola.count)
            }

            indiceActual = nuevoIndice
        } else if indiceActual + 1 < cola.count {
            indiceActual += 1
        } else if repetirModo == 1 {
            indiceActual = 0
        } else {
            pausar()
            return
        }

        reproducir(cola[indiceActual])
    }

    func anterior() {
        guard !cola.isEmpty else { return }

        if progreso > 0.05 {
            cambiarProgreso(a: 0)
            return
        }

        if indiceActual > 0 {
            indiceActual -= 1
        } else if repetirModo == 1 {
            indiceActual = cola.count - 1
        } else {
            cambiarProgreso(a: 0)
            return
        }

        reproducir(cola[indiceActual])
    }

    func alternarAleatorio() {
        aleatorio.toggle()
    }

    func cambiarRepeticion() {
        repetirModo = (repetirModo + 1) % 3
    }

    // MARK: - FIN DE CANCIÓN

    private func configurarFinDeCancion() {
        if let observadorFinal {
            NotificationCenter.default.removeObserver(observadorFinal)
        }

        guard let item = player?.currentItem else { return }

        observadorFinal = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }

            if self.repetirModo == 2 {
                self.cambiarProgreso(a: 0)
                self.reanudar()
            } else {
                self.siguiente()
            }
        }
    }

    // MARK: - LETRAS AUTOMÁTICAS

    func cargarLetra(_ cancion: Cancion) {
        letra = ""
        cargandoLetra = true
        letraNoEncontrada = false

        var componentes = URLComponents(
            string: "https://lrclib.net/api/get"
        )

        componentes?.queryItems = [
            URLQueryItem(name: "track_name", value: cancion.titulo),
            URLQueryItem(name: "artist_name", value: cancion.artista)
        ]

        guard let url = componentes?.url else {
            cargandoLetra = false
            letraNoEncontrada = true
            return
        }

        var solicitud = URLRequest(url: url)
        solicitud.setValue(
            "StreamifyPRO",
            forHTTPHeaderField: "User-Agent"
        )

        URLSession.shared.dataTask(with: solicitud) { [weak self] data, response, error in
            guard let self else { return }

            guard error == nil,
                  let data,
                  let http = response as? HTTPURLResponse,
                  http.statusCode == 200,
                  let respuesta = try? JSONDecoder().decode(
                    RespuestaLetra.self,
                    from: data
                  ) else {
                DispatchQueue.main.async {
                    self.cargandoLetra = false
                    self.letraNoEncontrada = true
                }
                return
            }

            let texto = respuesta.syncedLyrics ?? respuesta.plainLyrics ?? ""

            DispatchQueue.main.async {
                // Evita colocar la letra de una canción anterior.
                guard self.cancionActual?.clave == cancion.clave else {
                    return
                }

                self.letra = texto
                self.cargandoLetra = false
                self.letraNoEncontrada = texto.isEmpty
            }
        }.resume()
    }

    // MARK: - PLAY / PAUSA

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
        guard let player else { return }

        let seguro = min(max(valor, 0), 1)
        let segundos = duracion * seguro

        player.seek(to: CMTime(
            seconds: segundos,
            preferredTimescale: 600
        ))

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
            guard let self,
                  let player = self.player else { return }

            let actual = CMTimeGetSeconds(player.currentTime())

            if let dur = player.currentItem?.duration.seconds,
               dur.isFinite, dur > 0 {
                self.duracion = dur
                self.progreso = min(max(actual / dur, 0), 1)
            }

            self.reproduciendo =
                player.timeControlStatus == .playing
        }
    }

    // MARK: - PANTALLA BLOQUEADA

    private func actualizarInfoPantallaBloqueo(_ cancion: Cancion) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: cancion.titulo,
            MPMediaItemPropertyArtist: cancion.artista,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        guard let url = URL(string: cancion.urlPortada) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data,
                  let imagen = UIImage(data: data) else { return }

            info[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: imagen.size) { _ in imagen }

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

        centro.nextTrackCommand.addTarget { [weak self] _ in
            self?.siguiente()
            return .success
        }

        centro.previousTrackCommand.addTarget { [weak self] _ in
            self?.anterior()
            return .success
        }
    }
}
