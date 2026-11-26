import Foundation
import AVFoundation
import MediaPlayer
import Combine

class Reproductor: ObservableObject {
    @Published var cancionActual: Cancion? = nil
    @Published var reproduciendo: Bool = false
    @Published var progreso: Double = 0.0
    @Published var duracion: Double = 1.0
    
    private var player: AVPlayer?
    private var timer: AnyCancellable?
    
    init() { configurarControlesRemotos() }
    
    func reproducir(_ cancion: Cancion) {
        self.cancionActual = cancion
        guard let url = URL(string: cancion.urlAudio) else { return }
        
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
        player?.play()
        reproduciendo = true
        actualizarEstadoBloqueo()
    }
    
    func alternarPlayPausa() {
        if reproduciendo { pausar() } else { reanudar() }
    }
    
    func cambiarProgreso(a valor: Double) {
        guard let player = player else { return }
        let nuevaDuracion = duracion * valor
        let nuevoTiempo = CMTime(seconds: nuevaDuracion, preferredTimescale: 1)
        player.seek(to: nuevoTiempo)
        self.progreso = valor
    }
    
    private func iniciarTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let player = self.player else { return }
                let actual = CMTimeGetSeconds(player.currentTime())
                if let dur = player.currentItem?.duration.seconds, !dur.isNaN {
                    self.duracion = dur
                    self.progreso = actual / dur
                }
            }
    }
    
    private func actualizarInfoPantallaBloqueo(_ cancion: Cancion) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: cancion.titulo,
            MPMediaItemPropertyArtist: cancion.artista,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]
        
        if let url = URL(string: cancion.urlPortada) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            }.resume()
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
    
    private func actualizarEstadoBloqueo() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = reproduciendo ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    private func configurarControlesRemotos() {
        let centro = MPRemoteCommandCenter.shared()
        centro.playCommand.addTarget { [weak self] _ in self?.reanudar(); return .success }
        centro.pauseCommand.addTarget { [weak self] _ in self?.pausar(); return .success }
        centro.togglePlayPauseCommand.addTarget { [weak self] _ in self?.alternarPlayPausa(); return .success }
    }
}