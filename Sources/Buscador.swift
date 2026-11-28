

import Foundation
import SwiftUI

class Buscador: ObservableObject {

    @Published var resultados: [Cancion] = []
    @Published var artistas: [Artista] = []
    @Published var recomendaciones: [Cancion] = []

    @Published var cancionesArtista: [Cancion] = []
    @Published var albumesArtista: [AlbumArtista] = []

    @Published var artistaSeleccionado: Artista?
    @Published var buscando = false
    @Published var cargandoArtista = false
    @Published var errorBusqueda = ""

    private var tareaBusqueda: DispatchWorkItem?

    private let artistasIniciales = [
        "Chuyin",
        "Calle 24",
        "Jorsshh",
        "Peso Pluma",
        "Junior H",
        "Natanael Cano"
    ]

    // MARK: - CARGA INICIAL

    func cargarInicio() {
        cargarArtistasPopulares()

        if recomendaciones.isEmpty {
            buscarCancionesIniciales()
        }
    }

    private func cargarArtistasPopulares() {
        let grupo = DispatchGroup()
        var encontrados: [Artista] = []

        for nombre in artistasIniciales {
            grupo.enter()

            consultarArtistas(nombre) { artistas in
                if let artista = artistas.first {
                    encontrados.append(artista)
                }
                grupo.leave()
            }
        }

        grupo.notify(queue: .main) {
            self.artistas = encontrados
        }
    }

    private func buscarCancionesIniciales() {
        let consultas = [
            "Chuyin",
            "Música mexicana popular",
            "Peso Pluma"
        ]

        let grupo = DispatchGroup()
        var canciones: [Cancion] = []

        for consulta in consultas {
            grupo.enter()

            consultarCanciones(consulta) { resultado in
                canciones.append(contentsOf: resultado)
                grupo.leave()
            }
        }

        grupo.notify(queue: .main) {
            self.recomendaciones = Array(
                canciones.reduce(into: [String: Cancion]()) {
                    $0[$1.clave] = $1
                }.values
            )
        }
    }

    // MARK: - BÚSQUEDA AUTOMÁTICA

    func buscar(_ termino: String) {
        tareaBusqueda?.cancel()

        let texto = termino.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !texto.isEmpty else {
            resultados = []
            artistas = []
            errorBusqueda = ""
            cargarInicio()
            return
        }

        buscando = true
        errorBusqueda = ""

        let tarea = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            let grupo = DispatchGroup()

            var cancionesEncontradas: [Cancion] = []
            var artistasEncontrados: [Artista] = []

            grupo.enter()
            self.consultarCanciones(texto) { canciones in
                cancionesEncontradas = canciones
                grupo.leave()
            }

            grupo.enter()
            self.consultarArtistas(texto) { artistas in
                artistasEncontrados = artistas
                grupo.leave()
            }

            grupo.notify(queue: .main) {
                self.resultados = cancionesEncontradas
                self.artistas = artistasEncontrados
                self.buscando = false

                if cancionesEncontradas.isEmpty &&
                    artistasEncontrados.isEmpty {
                    self.errorBusqueda = "No encontramos resultados."
                }
            }
        }

        tareaBusqueda = tarea

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.4,
            execute: tarea
        )
    }

    // MARK: - CONSULTAR CANCIONES

    private func consultarCanciones(
        _ termino: String,
        completion: @escaping ([Cancion]) -> Void
    ) {
        var componentes = URLComponents(
            string: "https://api.deezer.com/search"
        )

        componentes?.queryItems = [
            URLQueryItem(name: "q", value: termino),
            URLQueryItem(name: "limit", value: "30")
        ]

        guard let url = componentes?.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil,
                  let data = data,
                  let respuesta = try? JSONDecoder().decode(
                    DeezerResponse.self,
                    from: data
                  ) else {
                completion([])
                return
            }

            let canciones = respuesta.data.map { item in
                Cancion(
                    titulo: item.title,
                    artista: item.artist.name,
                    album: item.album.title,
                    urlPortada: item.album.cover_medium,
                    urlAudio: item.preview
                )
            }

            completion(canciones)
        }.resume()
    }

    // MARK: - CONSULTAR ARTISTAS

    private func consultarArtistas(
        _ termino: String,
        completion: @escaping ([Artista]) -> Void
    ) {
        var componentes = URLComponents(
            string: "https://api.deezer.com/search/artist"
        )

        componentes?.queryItems = [
            URLQueryItem(name: "q", value: termino),
            URLQueryItem(name: "limit", value: "15")
        ]

        guard let url = componentes?.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil,
                  let data = data,
                  let respuesta = try? JSONDecoder().decode(
                    RespuestaArtistas.self,
                    from: data
                  ) else {
                completion([])
                return
            }

            completion(respuesta.data)
        }.resume()
    }

    // MARK: - ABRIR PERFIL

    func abrirArtista(_ artista: Artista) {
        artistaSeleccionado = artista
        cargarPerfil(artista)
    }

    func cargarPerfil(_ artista: Artista) {
        cargandoArtista = true
        cancionesArtista = []
        albumesArtista = []

        let grupo = DispatchGroup()

        grupo.enter()

        consultarCancionesArtista(artista.id) { canciones in
            DispatchQueue.main.async {
                self.cancionesArtista = canciones
            }
            grupo.leave()
        }

        grupo.enter()

        consultarAlbumesArtista(artista.id) { albumes in
            DispatchQueue.main.async {
                self.albumesArtista = albumes
            }
            grupo.leave()
        }

        grupo.notify(queue: .main) {
            self.cargandoArtista = false
        }
    }

    // MARK: - TOP CANCIONES DEL ARTISTA

    private func consultarCancionesArtista(
        _ id: Int,
        completion: @escaping ([Cancion]) -> Void
    ) {
        let urlString =
        "https://api.deezer.com/artist/\(id)/top?limit=50"

        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil,
                  let data = data,
                  let respuesta = try? JSONDecoder().decode(
                    DeezerResponse.self,
                    from: data
                  ) else {
                completion([])
                return
            }

            let canciones = respuesta.data.map { item in
                Cancion(
                    titulo: item.title,
                    artista: item.artist.name,
                    album: item.album.title,
                    urlPortada: item.album.cover_medium,
                    urlAudio: item.preview
                )
            }

            completion(canciones)
        }.resume()
    }

    // MARK: - ÁLBUMES DEL ARTISTA

    private func consultarAlbumesArtista(
        _ id: Int,
        completion: @escaping ([AlbumArtista]) -> Void
    ) {
        let urlString =
        "https://api.deezer.com/artist/\(id)/albums?limit=50"

        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard error == nil,
                  let data = data,
                  let respuesta = try? JSONDecoder().decode(
                    RespuestaAlbumes.self,
                    from: data
                  ) else {
                completion([])
                return
            }

            completion(respuesta.data)
        }.resume()
    }
}
