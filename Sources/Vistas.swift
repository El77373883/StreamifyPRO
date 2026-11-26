
import SwiftUI

// MARK: - VISTA PRINCIPAL
struct MainView: View {
    @StateObject private var reproductor = Reproductor()
    @StateObject private var buscador = Buscador()
    @State private var mostrarReproductorCompleto = false

    var body: some View {
        TabView {
            InicioView(reproductor: reproductor)
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }

            BuscarView(
                buscador: buscador,
                reproductor: reproductor
            )
            .tabItem {
                Label("Buscar", systemImage: "magnifyingglass")
            }

            BibliotecaView(reproductor: reproductor)
                .tabItem {
                    Label("Tu biblioteca", systemImage: "books.vertical.fill")
                }

            CuentaView()
                .tabItem {
                    Label("Premium", systemImage: "crown.fill")
                }

            CategoriasView()
                .tabItem {
                    Label("Crear", systemImage: "plus")
                }
        }
        .environmentObject(reproductor)
        .safeAreaInset(edge: .bottom) {
            if reproductor.cancionActual != nil {
                MiniReproductor(
                    reproductor: reproductor,
                    mostrarCompleto: $mostrarReproductorCompleto
                )
            }
        }
        .fullScreenCover(isPresented: $mostrarReproductorCompleto) {
            ReproductorCompleto(reproductor: reproductor)
        }
    }
}

// MARK: - INICIO
struct InicioView: View {
    @ObservedObject var reproductor: Reproductor

    let recomendados = [
        Cancion(
            titulo: "Amanecido y Regañado",
            artista: "Chuyin, Calle 24, Jorsshh",
            album: "Sencillo",
            urlPortada: "https://i.scdn.co/image/ab67616d0000b2732fc2e4c97820adf4db122e86",
            urlAudio: "https://archive.org/download/chuyin-x-calle-24-x-jorsshh-amanecido-y-reganado-official-video/Chuyin%20X%20Calle24%20X%20Jorsshh%20-%20Amanecido%20y%20Regan%CC%83ado%20%5BOfficial%20Video%5D.mp3"
        ),
        Cancion(
            titulo: "Midnight City",
            artista: "M83",
            album: "Hurry Up",
            urlPortada: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=600&q=80",
            urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
        ),
        Cancion(
            titulo: "Blinding Lights",
            artista: "The Weeknd",
            album: "After Hours",
            urlPortada: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=600&q=80",
            urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"
        ),
        Cancion(
            titulo: "Levitating",
            artista: "Dua Lipa",
            album: "Future Nostalgia",
            urlPortada: "https://images.unsplash.com/photo-1493225457124-a1a2a5956093?w=600&q=80",
            urlAudio: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Buenas tardes")
                        .font(.largeTitle.bold())
                        .padding(.horizontal)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: 16
                    ) {
                        ForEach(recomendados) { cancion in
                            Button {
                                reproductor.reproducir(cancion)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    AsyncImage(
                                        url: URL(string: cancion.urlPortada)
                                    ) { img in
                                        img.resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.gray
                                    }
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(10)

                                    Text(cancion.titulo)
                                        .font(.headline)
                                        .lineLimit(1)
                                        .foregroundColor(.primary)

                                    Text(cancion.artista)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
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

// MARK: - BUSCAR
struct BuscarView: View {
    @ObservedObject var buscador: Buscador
    @ObservedObject var reproductor: Reproductor

    @State private var termino = ""

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("Canciones o artistas...", text: $termino)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            buscador.buscar(termino)
                        }

                    Button {
                        buscador.buscar(termino)
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .padding()

                if buscador.buscando {
                    ProgressView("Buscando música...")
                        .padding()
                }

                List(buscador.resultados) { cancion in
                    Button {
                        reproductor.reproducir(cancion)
                    } label: {
                        HStack(spacing: 12) {
                            AsyncImage(
                                url: URL(string: cancion.urlPortada)
                            ) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 55, height: 55)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading) {
                                Text(cancion.titulo)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(cancion.artista)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Buscar")
        }
    }
}

// MARK: - BIBLIOTECA
struct BibliotecaView: View {
    @ObservedObject var reproductor: Reproductor

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 55))
                    .foregroundColor(.green)

                Text("Tu biblioteca")
                    .font(.title.bold())

                if let cancion = reproductor.cancionActual {
                    Text("Reproduciendo actualmente")
                        .foregroundColor(.secondary)

                    Text(cancion.titulo)
                        .font(.headline)

                    Text(cancion.artista)
                        .foregroundColor(.secondary)
                } else {
                    Text("Todavía no estás reproduciendo música")
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Tu biblioteca")
        }
    }
}

// MARK: - PREMIUM
struct CuentaView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 65))
                    .foregroundColor(.yellow)

                Text("Streamify Premium")
                    .font(.largeTitle.bold())

                Text("Tu música, tu estilo.")
                    .foregroundColor(.secondary)

                Text("Próximamente")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Premium")
        }
    }
}

// MARK: - CATEGORÍAS
struct CategoriasView: View {
    private let categorias = [
        "Pop",
        "Rock",
        "Reggaetón",
        "Electrónica",
        "Regional mexicano",
        "Rap",
        "Románticas",
        "Clásicas"
    ]

    var body: some View {
        NavigationStack {
            List(categorias, id: \.self) { categoria in
                HStack {
                    Image(systemName: "music.note")
                        .foregroundColor(.green)

                    Text(categoria)
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("Explorar géneros")
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
                AsyncImage(
                    url: URL(string: cancion.urlPortada)
                ) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 45, height: 45)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                Button {
                    mostrarCompleto = true
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(cancion.titulo)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(cancion.artista)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    reproductor.alternarPlayPausa()
                } label: {
                    Image(
                        systemName: reproductor.reproduciendo
                        ? "pause.fill" : "play.fill"
                    )
                    .font(.title2)
                    .foregroundColor(.white)
                }

                Button {
                    mostrarCompleto = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(10)
            .background(Color(red: 0.16, green: 0.16, blue: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 8)
        }
    }
}
