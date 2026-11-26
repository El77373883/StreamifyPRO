
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
