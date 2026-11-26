
import SwiftUI

// MARK: - PORTADAS

struct PortadaCancion: View {

    let url: String

    var body: some View {

        AsyncImage(url: URL(string: url)) { phase in

            switch phase {

            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)

            case .empty:
                ZStack {
                    Color(white: 0.15)
                    ProgressView().tint(.green)
                }

            case .failure:
                ZStack {
                    Color(white: 0.15)
                    Image(systemName: "music.note")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                }

            @unknown default:
                Color.gray
            }
        }
        .aspectRatio(contentMode: .fill)
        .clipped()
    }
}

// MARK: - MAIN VIEW

struct MainView: View {

    @StateObject private var reproductor = Reproductor()
    @StateObject private var buscador = Buscador()

    @State private var mostrarCompleto = false

    @ViewBuilder
    private var miniPlayer: some View {

        if reproductor.cancionActual != nil {

            MiniReproductor(
                reproductor: reproductor,
                mostrarCompleto: $mostrarCompleto
            )
            .padding(.horizontal, 8)
            .padding(.top, 5)
            .padding(.bottom, 5)
            .background(Color.black)
        }
    }

    var body: some View {

        TabView {

            InicioView(reproductor: reproductor)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    miniPlayer
                }
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }

            BuscarView(
                buscador: buscador,
                reproductor: reproductor
            )
            .safeAreaInset(edge: .bottom, spacing: 0) {
                miniPlayer
            }
            .tabItem {
                Label("Buscar", systemImage: "magnifyingglass")
            }

            BibliotecaView(reproductor: reproductor)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    miniPlayer
                }
                .tabItem {
                    Label("Tu biblioteca", systemImage: "books.vertical.fill")
                }

            PremiumView()
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    miniPlayer
                }
                .tabItem {
                    Label("Premium", systemImage: "crown.fill")
                }

            CuentaView(reproductor: reproductor)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    miniPlayer
                }
                .tabItem {
                    Label("Mi cuenta", systemImage: "person.crop.circle.fill")
                }
        }
        .environmentObject(reproductor)
        .tint(.green)
        .fullScreenCover(isPresented: $mostrarCompleto) {
            ReproductorCompleto(reproductor: reproductor)
        }
    }
}

// MARK: - INICIO

struct InicioView: View {

    @ObservedObject var reproductor: Reproductor

    private let recomendados = [

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

    private let columnas = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(alignment: .leading, spacing: 22) {

                    Text("Buenas tardes")
                        .font(.largeTitle.bold())
                        .padding(.horizontal)

                    Text("Tus recomendaciones")
                        .font(.title2.bold())
                        .padding(.horizontal)

                    LazyVGrid(columns: columnas, spacing: 18) {

                        ForEach(recomendados) { cancion in

                            Button {
                                reproductor.reproducir(cancion)
                            } label: {

                                VStack(alignment: .leading, spacing: 8) {

                                    PortadaCancion(
                                        url: cancion.urlPortada
                                    )
                                    .frame(height: 155)
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 10)
                                    )

                                    Text(cancion.titulo)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text(cancion.artista)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.black)
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

                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField(
                        "¿Qué quieres escuchar?",
                        text: $termino
                    )
                    .submitLabel(.search)
                    .onSubmit {
                        buscador.buscar(termino)
                    }

                    Button {
                        buscador.buscar(termino)
                    } label: {
                        Text("Buscar")
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(white: 0.16))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

                if buscador.buscando {
                    ProgressView()
                        .tint(.green)
                }

                if !buscador.errorBusqueda.isEmpty {
                    Text(buscador.errorBusqueda)
                        .foregroundColor(.red)
                        .padding()
                }

                List(buscador.resultados) { cancion in

                    Button {
                        reproductor.reproducir(cancion)
                    } label: {

                        HStack(spacing: 12) {

                            PortadaCancion(url: cancion.urlPortada)
                                .frame(width: 55, height: 55)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 5) {

                                Text(cancion.titulo)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .lineLimit(1)

                                Text(cancion.artista)
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "play.circle")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                    }
                    .listRowBackground(Color.black)
                }
                .scrollContentBackground(.hidden)
            }
            .background(Color.black)
            .navigationTitle("Buscar")
        }
    }
}

// MARK: - BIBLIOTECA

struct BibliotecaView: View {

    @ObservedObject var reproductor: Reproductor

    var body: some View {

        NavigationStack {

            List {

                Section("Música descargada") {

                    if reproductor.descargas.isEmpty {

                        Text("Todavía no tienes descargas.")
                            .foregroundColor(.gray)

                    } else {

                        ForEach(reproductor.descargas) { cancion in

                            Button {
                                reproductor.reproducir(cancion)
                            } label: {

                                FilaCancion(cancion: cancion)
                            }
                        }
                    }
                }

                Section("Escuchando") {

                    if let cancion = reproductor.cancionActual {

                        Button {
                            reproductor.reproducir(cancion)
                        } label: {
                            FilaCancion(cancion: cancion)
                        }

                    } else {

                        Text("Todavía no reproduces música.")
                            .foregroundColor(.gray)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Tu biblioteca")
        }
    }
}

// MARK: - FILA DE CANCIÓN

struct FilaCancion: View {

    let cancion: Cancion

    var body: some View {

        HStack(spacing: 12) {

            PortadaCancion(url: cancion.urlPortada)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {

                Text(cancion.titulo)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(cancion.artista)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "play.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
        }
    }
}

// MARK: - MI CUENTA

struct CuentaView: View {

    @ObservedObject var reproductor: Reproductor

    var body: some View {

        NavigationStack {

            ScrollView {

                VStack(spacing: 22) {

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 85))
                        .foregroundColor(.green)
                        .padding(.top, 25)

                    Text("Mi cuenta")
                        .font(.largeTitle.bold())

                    Text("Tu música, a tu manera")
                        .foregroundColor(.gray)

                    // ESTADÍSTICAS

                    HStack(spacing: 12) {

                        estadistica(
                            icono: "heart.fill",
                            numero: reproductor.favoritos.count,
                            nombre: "Favoritos"
                        )

                        estadistica(
                            icono: "arrow.down.circle.fill",
                            numero: reproductor.descargas.count,
                            nombre: "Descargas"
                        )
                    }

                    // FAVORITOS

                    VStack(alignment: .leading, spacing: 15) {

                        Text("❤️ Mis favoritos")
                            .font(.title2.bold())

                        if reproductor.favoritos.isEmpty {

                            Text("Aquí aparecerán tus canciones favoritas.")
                                .foregroundColor(.gray)

                        } else {

                            ForEach(reproductor.favoritos) { cancion in

                                Button {
                                    reproductor.reproducir(cancion)
                                } label: {

                                    FilaCancion(cancion: cancion)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // DESCARGAS

                    VStack(alignment: .leading, spacing: 15) {

                        Text("⬇️ Música descargada")
                            .font(.title2.bold())

                        if reproductor.descargas.isEmpty {

                            Text("Aquí aparecerán tus descargas.")
                                .foregroundColor(.gray)

                        } else {

                            ForEach(reproductor.descargas) { cancion in

                                Button {
                                    reproductor.reproducir(cancion)
                                } label: {

                                    FilaCancion(cancion: cancion)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func estadistica(
        icono: String,
        numero: Int,
        nombre: String
    ) -> some View {

        VStack(spacing: 8) {

            Image(systemName: icono)
                .font(.title2)
                .foregroundColor(.green)

            Text("\(numero)")
                .font(.title.bold())

            Text(nombre)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

// MARK: - PREMIUM

struct PremiumView: View {

    var body: some View {

        NavigationStack {

            VStack(spacing: 20) {

                Image(systemName: "crown.fill")
                    .font(.system(size: 75))
                    .foregroundColor(.green)

                Text("Streamify Premium")
                    .font(.largeTitle.bold())

                Text("Tu experiencia musical.")
                    .foregroundColor(.gray)

                Text("Próximamente más funciones.")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .navigationTitle("Premium")
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

                Button {
                    mostrarCompleto = true
                } label: {

                    HStack(spacing: 12) {

                        PortadaCancion(url: cancion.urlPortada)
                            .frame(width: 55, height: 55)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 4) {

                            Text(cancion.titulo)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Text(cancion.artista)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 5)

                Button {
                    reproductor.alternarPlayPausa()
                } label: {

                    Image(
                        systemName: reproductor.reproduciendo
                        ? "pause.fill"
                        : "play.fill"
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
                        .padding(.leading, 8)
                }
            }
            .padding(12)
            .background(Color(white: 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(Rectangle())
        }
    }
}
