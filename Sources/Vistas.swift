import SwiftUI

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
            
            BibliotecaView()
                .tabItem { Label("Biblioteca", systemImage: "music.note.list") }
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

struct InicioView: View {
    @ObservedObject var reproductor: Reproductor
    
    let recomendados = [
        Cancion(titulo: "Midnight City", artista: "M83", album: "Hurry Up", urlPortada: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
        Cancion(titulo: "Blinding Lights", artista: "The Weeknd", album: "After Hours", urlPortada: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3")
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
                                        img.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: { Color.gray }
                                    .frame(height: 160).clipped().cornerRadius(10)
                                    
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

struct BuscarView: View {
    @ObservedObject var buscador: Buscador
    @ObservedObject var reproductor: Reproductor
    @State private var texto = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if buscador.buscando {
                    ProgressView("Buscando...")
                } else if buscador.resultados.isEmpty && !texto.isEmpty {
                    Text("No se encontraron resultados").foregroundColor(.secondary)
                } else {
                    List(buscador.resultados) { cancion in
                        Button {
                            reproductor.reproducir(cancion)
                        } label: {
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: cancion.urlPortada)) { img in
                                    img.resizable()
                                } placeholder: { Color.gray }
                                .frame(width: 55, height: 55).cornerRadius(6)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(cancion.titulo).font(.headline).foregroundColor(.primary).lineLimit(1)
                                    Text(cancion.artista).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $texto, prompt: "Buscar canciones o artistas...")
            .onSubmit(of: .search) { buscador.buscar(texto) }
            .navigationTitle("Buscar")
        }
    }
}

struct BibliotecaView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "music.note.house").font(.system(size: 50)).foregroundColor(.secondary)
                Text("Aquí aparecerán tus descargas").foregroundColor(.secondary)
            }
            .navigationTitle("Biblioteca")
        }
    }
}

struct MiniReproductor: View {
    @ObservedObject var reproductor: Reproductor
    @Binding var mostrarCompleto: Bool
    
    var body: some View {
        if let cancion = reproductor.cancionActual {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: cancion.urlPortada)) { img in
                    img.resizable()
                } placeholder: { Color.gray }
                .frame(width: 45, height: 45).cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(cancion.titulo).font(.subheadline).bold().lineLimit(1)
                    Text(cancion.artista).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
                Spacer()
                
                Button {
                    reproductor.alternarPlayPausa()
                } label: {
                    Image(systemName: reproductor.reproduciendo ? "pause.fill" : "play.fill").font(.title2)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .onTapGesture { mostrarCompleto = true }
        }
    }
}