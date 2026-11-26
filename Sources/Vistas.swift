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
        Cancion(titulo: "Midnight City", artista: "M83", album: "Hurry Up", urlPortada: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
        Cancion(titulo: "Blinding Lights", artista: "The Weeknd", album: "After Hours", urlPortada: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"),
        Cancion(titulo: "Levitating", artista: "Dua Lipa", album: "Future Nostalgia", urlPortada: "https://images.unsplash.com/photo-1493225457124-a1a2a5956093?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"),
        Cancion(titulo: "Starboy", artista: "The Weeknd", album: "Starboy", urlPortada: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&q=80", urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3")
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
                                    .frame(maxWidth: .infinity) // CORRECCIÓN: Evita que se salga de la pantalla
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

// MARK: - VISTA DE BUSCAR
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
                } else if buscador.resultados.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Busca canciones, artistas o álbumes")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
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
                    .listStyle(.plain)
                }
            }
            .searchable(text: $texto, prompt: "¿Qué quieres escuchar?")
            .onSubmit(of: .search) { buscador.buscar(texto) }
            .navigationTitle("Buscar")
        }
    }
}

// MARK: - VISTA DE BIBLIOTECA
struct BibliotecaView: View {
    @ObservedObject var reproductor: Reproductor
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "music.note.house")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
                Text("Aquí aparecerán tus descargas")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Tu biblioteca")
        }
    }
}

// MARK: - VISTAS EXTRA (Cuenta y Categorías)
struct CuentaView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Tu cuenta")) {
                    HStack {
                        Image(systemName: "person.circle.fill").font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("Usuario Streamify").font(.headline)
                            Text("Versión Gratis").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                Section(header: Text("Mi Plan")) {
                    Button("Cambiar a Premium") { }
                }
            }
            .navigationTitle("Premium")
        }
    }
}

struct CategoriasView: View {
    let categorias = ["Pop", "Rock", "Hip-Hop", "Reggaeton", "Electrónica", "Latina", "Indie", "Jazz"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(categorias, id: \.self) { cat in
                        Text(cat)
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Crear")
        }
    }
}

// MARK: - MINI REPRODUCTOR
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
