

import Foundation

struct Cancion: Identifiable, Codable, Equatable {
    var id: UUID
    var titulo: String
    var artista: String
    var album: String
    var urlPortada: String
    var urlAudio: String

    init(
        id: UUID = UUID(),
        titulo: String,
        artista: String,
        album: String = "Sencillo",
        urlPortada: String,
        urlAudio: String
    ) {
        self.id = id
        self.titulo = titulo
        self.artista = artista
        self.album = album
        self.urlPortada = urlPortada
        self.urlAudio = urlAudio
    }

    var clave: String {
        "\(titulo.lowercased())|\(artista.lowercased())"
    }
}

// MARK: - ARTISTAS

struct Artista: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let picture_medium: String?
    let picture_big: String?
    let nb_fan: Int?
    let nb_album: Int?

    var fotografia: String {
        picture_big ?? picture_medium ?? ""
    }

    var fansTexto: String {
        guard let fans = nb_fan else { return "Fans no disponibles" }
        return "\(fans.formatted()) fans"
    }
}

struct RespuestaArtistas: Codable {
    let data: [Artista]
}

// MARK: - RESPUESTA DE CANCIONES

struct DeezerResponse: Codable {
    let data: [DeezerItem]
}

struct DeezerItem: Codable, Identifiable {
    let id: Int
    let title: String
    let artist: DeezerArtist
    let album: DeezerAlbum
    let preview: String

    struct DeezerArtist: Codable {
        let name: String
    }

    struct DeezerAlbum: Codable {
        let title: String
        let cover_medium: String
    }
}

// MARK: - ÁLBUMES

struct AlbumArtista: Codable, Identifiable {
    let id: Int
    let title: String
    let cover_medium: String?
    let release_date: String?

    var portada: String {
        cover_medium ?? ""
    }
}

struct RespuestaAlbumes: Codable {
    let data: [AlbumArtista]
}
