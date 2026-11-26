import SwiftUI

// MARK: - VISTA PRINCIPAL (Con la barra de 5 iconos)
struct MainView: View {
    @StateObject private var reproductor = Reproductor()
    @StateObject private var buscador = Buscador()
    @State private var mostrarReproductorCompleto = false
    
    var body: some View {
        TabView {
            InicioView(reproductor: reproductor)
                .tabItem { Label("Inicio", systemImage: "house.fill") }
            
            BuscarView(buscador: buscador, reproductor: reproductor)
                .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
            
            BibliotecaView(reproductor: reproductor)
                .tabItem { Label("Tu biblioteca", systemImage: "books.vertical.fill") }
            
            CuentaView()
                .tabItem { Label("Premium", systemImage: "crown.fill") }
            
            CategoriasView()
                .tabItem { Label("Crear", systemImage: "plus") }
        }
        .environmentObject(reproductor)
        .safeAreaInset(edge: .bottom) {
            if let actual = reproductor.cancionActual {
                MiniReproductor(reproductor: reproductor, mostrarCompleto: $mostrarReproductorCompleto)
            }
        }
        .fullScreenCover(isPresented: $mostrarReproductorCompleto) {
            ReproductorCompleto(reproductor: reproductor)
        }
    }
}

// MARK: - VISTA DE INICIO
struct InicioView: View {
    @ObservedObject var reproductor: Reproductor
    
    let recomendados = [
        // AQUÍ ESTÁ TU CANCIÓN AGREGADA CON SUS LINKS
        Cancion(
            titulo: "Amanecido y Regañado",
            artista: "Chuyin, Calle 24, Jorsshh",
            album: "Sencillo",
            urlPortada: "https://i.scdn.co/image/ab67616d0000b2732fc2e4c97820adf4db122e86",
            urlAudio: "https://archive.org/download/chuyin-x-calle-24-x-jorsshh-amanecido-y-reganado-official-video/Chuyin%20X%20Calle24%20X%20Jorsshh%20-%20Amanecido%20y%20Regan%CC%83ado%20%5BOfficial%20Video%5D.mp3"
        ),
        Cancion(titulo: "Midnight City", artista: "M83", album: "Hurry Up", urlPortada: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
        Cancion(titulo: "Blinding Lights", artista: "The Weeknd", album: "After Hours", urlPortada: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"),
        Cancion(titulo: "Levitating", artista: "Dua Lipa", album: "Future Nostalgia", urlPortada: "https://images.unsplash.com/photo-1493225457124-a1a2a5956093?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Buenas tardes")
                        .font(.largeTitle.bold())
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(recomendados) { cancion in
                            Button {
                                reproductor.reproducir(cancion)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    AsyncImage(url: URL(string: cancion.urlPortada)) { img in
                                        img.resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(10)
                                    
                                    Text(cancion.titulo).font(.headline).lineLimit(1).foregroundColor(.primary)
                                    Text(cancion.artista).font(.caption).foregroundColor(.secondary).lineLimit(1)
                                }
                            }
                        }
                    }
                    .padding(.horizontal) 
                }
                .padding(.vertical)
            }
            .navigationTitle("Inicio")
        }
    }
}

// ... El resto del código (BuscarView, BibliotecaView, CuentaView, CategoriasView, MiniReproductor) se queda exactamente igual que en el mensaje anterior.
