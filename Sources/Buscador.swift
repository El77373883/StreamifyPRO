
import Foundation
import SwiftUI

class Buscador: ObservableObject {

    @Published var resultados: [Cancion] = []
    @Published var buscando = false
    @Published var errorBusqueda = ""

    func buscar(_ termino: String) {

        let texto = termino.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !texto.isEmpty else {
            resultados = []
            return
        }

        buscando = true
        errorBusqueda = ""

        var componentes = URLComponents(
            string: "https://api.deezer.com/search"
        )

        componentes?.queryItems = [
            URLQueryItem(name: "q", value: texto),
            URLQueryItem(name: "limit", value: "50")
        ]

        guard let url = componentes?.url else {
            buscando = false
            errorBusqueda = "Búsqueda no válida"
            return
        }

        URLSession.shared.dataTask(with: url) {
            [weak self] data, response, error in

            guard let self = self else { return }

            guard error == nil,
                  let data = data,
                  let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {

                DispatchQueue.main.async {
                    self.buscando = false
                    self.errorBusqueda = "No se pudo conectar."
                }
                return
            }

            do {
                let respuesta = try JSONDecoder().decode(
                    DeezerResponse.self,
                    from: data
                )

                let canciones = respuesta.data.map { item in
                    Cancion(
                        titulo: item.title,
                        artista: item.artist.name,
                        album: item.album.title,
                        urlPortada: item.album.cover_medium,
                        urlAudio: item.preview
                    )
                }

                DispatchQueue.main.async {
                    self.resultados = canciones
                    self.buscando = false
                }

            } catch {
                DispatchQueue.main.async {
                    self.buscando = false
                    self.errorBusqueda = "Error al cargar canciones."
                }
            }

        }.resume()
    }
}
