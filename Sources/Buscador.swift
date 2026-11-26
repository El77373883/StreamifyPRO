import Foundation
import SwiftUI

class Buscador: ObservableObject {
    @Published var resultados: [Cancion] = []
    @Published var buscando = false
    
    func buscar(_ termino: String) {
        guard !termino.isEmpty else { return }
        buscando = true
        
        let query = termino.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.deezer.com/search?q=\(query)&limit=50"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { self?.buscando = false }
                return
            }
            
            do {
                let respuesta = try JSONDecoder().decode(DeezerResponse.self, from: data)
                let canciones = respuesta.data.map { item in
                    return Cancion(
                        titulo: item.title,
                        artista: item.artist.name,
                        album: item.album.title,
                        urlPortada: item.album.cover_medium,
                        urlAudio: item.preview
                    )
                }
                
                DispatchQueue.main.async {
                    self?.resultados = canciones
                    self?.buscando = false
                }
            } catch {
                print("Error decodificando Deezer: \(error)")
                DispatchQueue.main.async { self?.buscando = false }
            }
        }.resume()
    }
}
