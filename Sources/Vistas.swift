
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

                                    PortadaCancion(url: cancion.urlPortada)
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

    @AppStorage("streamify_nombre") private var nombre = "Usuario Streamify"
    @AppStorage("streamify_correo") private var correo = ""
    @AppStorage("streamify_plan") private var plan = "Gratis"

    @State private var destino: DestinoCuenta?
    @State private var mostrarAviso = false

    enum DestinoCuenta: String, Identifiable {
        case perfil
        case configuracion
        case privacidad
        case planes
        case ayuda
        case acerca

        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 90))
                        .foregroundColor(.green)
                        .padding(.top, 25)

                    Text("Mi cuenta")
                        .font(.largeTitle.bold())

                    Text(nombre)
                        .font(.title3.bold())

                    Text(correo.isEmpty ? "Tu música, a tu manera" : correo)
                        .foregroundColor(.gray)

                    Button {
                        destino = .perfil
                    } label: {
                        Label("Editar perfil", systemImage: "pencil")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

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

                    // MI PLAN

                    VStack(alignment: .leading, spacing: 12) {
                        Text("👑 Mi plan")
                            .font(.title2.bold())

                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Streamify \(plan)")
                                    .font(.title3.bold())

                                Text(plan == "Gratis"
                                     ? "Estás usando el plan gratuito"
                                     : "Plan seleccionado")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "crown.fill")
                                .font(.largeTitle)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(white: 0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 15))

                        Button {
                            destino = .planes
                        } label: {
                            Text("Ver todos los planes")
                                .font(.headline)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(white: 0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

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

                    Divider()

                    // OPCIONES DE CUENTA

                    VStack(alignment: .leading, spacing: 5) {
                        Text("⚙️ Tu cuenta")
                            .font(.title2.bold())
                            .padding(.bottom, 8)

                        opcion(
                            "Configuración",
                            icono: "gearshape.fill",
                            destino: .configuracion
                        )

                        opcion(
                            "Privacidad y seguridad",
                            icono: "lock.shield.fill",
                            destino: .privacidad
                        )

                        opcion(
                            "Planes y suscripciones",
                            icono: "crown.fill",
                            destino: .planes
                        )

                        opcion(
                            "Ayuda y soporte",
                            icono: "questionmark.circle.fill",
                            destino: .ayuda
                        )

                        opcion(
                            "Acerca de Streamify",
                            icono: "info.circle.fill",
                            destino: .acerca
                        )

                        Button {
                            mostrarAviso = true
                        } label: {
                            Label(
                                "Cerrar sesión",
                                systemImage: "rectangle.portrait.and.arrow.right"
                            )
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .background(Color.black)
            .foregroundColor(.white)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $destino) { seleccion in
                NavigationStack {
                    pantalla(seleccion)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Listo") {
                                    destino = nil
                                }
                                .foregroundColor(.green)
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
            .alert("Streamify", isPresented: $mostrarAviso) {
                Button("Entendido", role: .cancel) { }
            } message: {
                Text("Esta versión todavía no tiene un sistema de inicio de sesión conectado.")
            }
        }
    }

    private func opcion(
        _ titulo: String,
        icono: String,
        destino seleccion: DestinoCuenta
    ) -> some View {
        Button {
            destino = seleccion
        } label: {
            HStack(spacing: 15) {
                Image(systemName: icono)
                    .font(.title3)
                    .foregroundColor(.green)
                    .frame(width: 28)

                Text(titulo)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func pantalla(_ seleccion: DestinoCuenta) -> some View {
        switch seleccion {
        case .perfil:
            PerfilStreamify(nombre: $nombre, correo: $correo)

        case .configuracion:
            ConfiguracionStreamify()

        case .privacidad:
            PrivacidadStreamify()

        case .planes:
            PlanesStreamify(plan: $plan)

        case .ayuda:
            InformacionStreamify(
                titulo: "Ayuda y soporte",
                mensaje: "Gracias por utilizar Streamify. Próximamente tendrás más opciones de soporte."
            )

        case .acerca:
            InformacionStreamify(
                titulo: "Acerca de Streamify",
                mensaje: "Streamify es tu espacio para descubrir, reproducir y guardar tu música favorita."
            )
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

// MARK: - EDITAR PERFIL

struct PerfilStreamify: View {

    @Binding var nombre: String
    @Binding var correo: String

    var body: some View {
        Form {
            Section("Información personal") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 55))
                        .foregroundColor(.green)

                    VStack(alignment: .leading) {
                        Text(nombre)
                            .font(.headline)

                        Text("Perfil de Streamify")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 10)

                TextField("Nombre de usuario", text: $nombre)

                TextField("Correo electrónico", text: $correo)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            Section {
                Text("Tus cambios se guardan automáticamente en este dispositivo.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Editar perfil")
    }
}

// MARK: - CONFIGURACIÓN

struct ConfiguracionStreamify: View {

    @AppStorage("streamify_calidad_alta") private var calidadAlta = false
    @AppStorage("streamify_reproduccion") private var reproduccion = true
    @AppStorage("streamify_notificaciones") private var notificaciones = true

    var body: some View {
        Form {
            Section("Reproducción") {
                Toggle("Reproducción automática", isOn: $reproduccion)

                Toggle("Calidad de audio alta", isOn: $calidadAlta)
            }

            Section("Notificaciones") {
                Toggle("Notificaciones", isOn: $notificaciones)
            }

            Section {
                Text("Estas preferencias se guardan en este dispositivo. Algunas opciones todavía no están conectadas al reproductor.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Configuración")
    }
}

// MARK: - PRIVACIDAD

struct PrivacidadStreamify: View {

    @AppStorage("streamify_actividad") private var actividad = true
    @AppStorage("streamify_perfil_visible") private var perfilVisible = false

    var body: some View {
        Form {
            Section("Privacidad") {
                Toggle("Compartir actividad musical", isOn: $actividad)

                Toggle("Mostrar perfil públicamente", isOn: $perfilVisible)
            }

            Section("Seguridad") {
                Label(
                    "Tu información permanece en este dispositivo",
                    systemImage: "lock.fill"
                )

                Text("La autenticación y la administración de datos en la nube todavía no están implementadas.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Privacidad")
    }
}

// MARK: - PLANES

struct PlanesStreamify: View {

    @Binding var plan: String

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {

                Image(systemName: "crown.fill")
                    .font(.system(size: 65))
                    .foregroundColor(.green)
                    .padding(.top, 20)

                Text("Elige tu experiencia")
                    .font(.title.bold())

                Text("Tu plan actual: \(plan)")
                    .foregroundColor(.gray)

                tarjeta(
                    nombre: "Gratis",
                    descripcion: "Tu música en Streamify",
                    icono: "music.note"
                )

                tarjeta(
                    nombre: "Premium",
                    descripcion: "Plan individual",
                    icono: "crown.fill"
                )

                tarjeta(
                    nombre: "Familiar",
                    descripcion: "Una opción para compartir en familia",
                    icono: "person.2.fill"
                )

                Text("Los planes Premium y Familiar son opciones visuales por ahora. No hay pagos ni suscripciones activas conectadas.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Planes")
    }

    private func tarjeta(
        nombre: String,
        descripcion: String,
        icono: String
    ) -> some View {
        VStack(spacing: 12) {

            Image(systemName: icono)
                .font(.largeTitle)
                .foregroundColor(.green)

            Text("Streamify \(nombre)")
                .font(.title2.bold())

            Text(descripcion)
                .foregroundColor(.gray)

            if plan == nombre {
                Text("PLAN ACTUAL")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            } else {
                Button {
                    if nombre == "Gratis" {
                        plan = "Gratis"
                    }
                } label: {
                    Text(nombre == "Gratis" ? "Seleccionar" : "Próximamente")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(nombre != "Gratis")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - INFORMACIÓN

struct InformacionStreamify: View {

    let titulo: String
    let mensaje: String

    var body: some View {
        VStack(spacing: 20) {

            Image(systemName: "music.note")
                .font(.system(size: 65))
                .foregroundColor(.green)

            Text(titulo)
                .font(.title.bold())

            Text(mensaje)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .navigationTitle(titulo)
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
