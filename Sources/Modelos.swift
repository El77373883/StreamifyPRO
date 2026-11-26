import Foundation

struct Cancion: Identifiable, Codable, Equatable {
    let id: UUID
    let titulo: String
    let artista: String
    let album: String
    let urlPortada: String
    let urlAudio: String
    
    init(id: UUID = UUID(), titulo: String, artista: String, album: String = "Sencillo", urlPortada: String, urlAudio: String) {
        self.id = id
        self.titulo = titulo
        self.artista = artista
        self.album = album
        self.urlPortada = urlPortada
        self.urlAudio = urlAudio
    }
}

// Estructuras para la API de Deezer
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
