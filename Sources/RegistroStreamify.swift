
import SwiftUI
import PhotosUI

// MARK: - DATOS DEL REGISTRO

struct AvatarOpcion: Identifiable {
    let id: Int
    let url: String
}

let avataresStreamify: [AvatarOpcion] = [
    AvatarOpcion(id: 1, url: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300"),
    AvatarOpcion(id: 2, url: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=300"),
    AvatarOpcion(id: 3, url: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=300"),
    AvatarOpcion(id: 4, url: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300"),
    AvatarOpcion(id: 5, url: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300"),
    AvatarOpcion(id: 6, url: "https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=300"),
    AvatarOpcion(id: 7, url: "https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=300"),
    AvatarOpcion(id: 8, url: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=300")
]

// MARK: - AVATAR

struct AvatarStreamify: View {
    var tamano: CGFloat = 100

    @AppStorage("streamify_avatar_url")
    private var avatarURL = ""

    @AppStorage("streamify_avatar_data")
    private var avatarData = ""

    var body: some View {
        Group {
            if !avatarData.isEmpty,
               let data = Data(base64Encoded: avatarData),
               let imagen = UIImage(data: data) {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFill()
            } else if !avatarURL.isEmpty,
                      let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        avatarPredeterminado
                    }
                }
            } else {
                avatarPredeterminado
            }
        }
        .frame(width: tamano, height: tamano)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.green, lineWidth: 3))
    }

    private var avatarPredeterminado: some View {
        ZStack {
            Color(white: 0.16)
            Image(systemName: "person.fill")
                .font(.system(size: tamano * 0.4))
                .foregroundColor(.green)
        }
    }
}

// MARK: - CONTROL DE BIENVENIDA

struct InicioStreamify: View {
    @AppStorage("streamify_registrado")
    private var registrado = false

    var body: some View {
        Group {
            if registrado {
                MainView()
            } else {
                RegistroStreamify()
            }
        }
        .animation(.easeInOut, value: registrado)
    }
}

// MARK: - REGISTRO

struct RegistroStreamify: View {
    @AppStorage("streamify_registrado")
    private var registrado = false

    @AppStorage("streamify_nombre")
    private var nombreGuardado = ""

    @AppStorage("streamify_avatar_url")
    private var avatarURL = ""

    @AppStorage("streamify_avatar_data")
    private var avatarData = ""

    @AppStorage("streamify_terminos_aceptados")
    private var terminosAceptados = false

    @State private var nombre = ""
    @State private var avatarElegido = 1
    @State private var aceptarTerminos = false
    @State private var mostrarTerminos = false
    @State private var fotoSeleccionada: PhotosPickerItem?
    @State private var error = ""

    private let columnas = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // LOGO E INTRO

                    VStack(spacing: 13) {
                        Image(systemName: "waveform")
                            .font(.system(size: 58, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, Color.mint],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("STREAMIFY")
                            .font(.system(size: 38, weight: .black))
                            .italic()
                            .foregroundColor(.white)

                        Text("Toda tu música, en un solo lugar.")
                            .font(.title3.bold())
                            .multilineTextAlignment(.center)

                        Text("Descubre. Escucha. Disfruta.")
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 35)

                    // BIENVENIDA

                    VStack(spacing: 8) {
                        Text("¡Bienvenido a Streamify!")
                            .font(.system(size: 27, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text("Crea tu perfil y comienza a disfrutar.")
                            .foregroundColor(.gray)
                    }

                    // NOMBRE

                    VStack(alignment: .leading, spacing: 10) {
                        Text("¿Cómo te llamas?")
                            .font(.headline)

                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.green)

                            TextField("Escribe tu nombre", text: $nombre)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color(white: 0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // AVATARES REALES

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Elige tu avatar")
                            .font(.title2.bold())

                        LazyVGrid(columns: columnas, spacing: 15) {
                            ForEach(avataresStreamify) { avatar in
                                Button {
                                    avatarElegido = avatar.id
                                    avatarURL = avatar.url
                                    avatarData = ""
                                } label: {
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(
                                            url: URL(string: avatar.url)
                                        ) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } else {
                                                Color(white: 0.2)
                                                    .overlay {
                                                        ProgressView()
                                                            .tint(.green)
                                                    }
                                            }
                                        }
                                        .frame(height: 76)
                                        .clipShape(Circle())
                                        .overlay {
                                            Circle()
                                                .stroke(
                                                    avatarElegido == avatar.id &&
                                                    avatarData.isEmpty
                                                    ? Color.green : Color.gray.opacity(0.4),
                                                    lineWidth: avatarElegido == avatar.id &&
                                                    avatarData.isEmpty ? 4 : 1
                                                )
                                        }

                                        if avatarElegido == avatar.id &&
                                            avatarData.isEmpty {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .background(Color.black.clipShape(Circle()))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // FOTO PERSONAL

                        PhotosPicker(
                            selection: $fotoSeleccionada,
                            matching: .images
                        ) {
                            Label(
                                "Elegir una foto de mi galería",
                                systemImage: "photo.on.rectangle"
                            )
                            .font(.headline)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(white: 0.13))
                            .clipShape(RoundedRectangle(cornerRadius: 13))
                        }
                        .onChange(of: fotoSeleccionada) { nuevaFoto in
                            guard let nuevaFoto = nuevaFoto else { return }

                            Task {
                                if let data = try? await nuevaFoto.loadTransferable(type: Data.self),
                                   let imagen = UIImage(data: data),
                                   let comprimida = imagen.jpegData(compressionQuality: 0.75) {
                                    await MainActor.run {
                                        avatarData = comprimida.base64EncodedString()
                                        avatarURL = ""
                                    }
                                }
                            }
                        }

                        if !avatarData.isEmpty {
                            HStack {
                                AvatarStreamify(tamano: 65)
                                Text("Tu foto está seleccionada")
                                    .foregroundColor(.green)
                            }
                        }
                    }

                    // TÉRMINOS

                    Button {
                        mostrarTerminos = true
                    } label: {
                        HStack(spacing: 13) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title)
                                .foregroundColor(.green)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Términos y condiciones")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text("Lee las condiciones y el aviso de privacidad.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(white: 0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Toggle(isOn: $aceptarTerminos) {
                        Text("He leído y acepto los términos y condiciones.")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .tint(.green)

                    if !error.isEmpty {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    // CREAR CUENTA

                    Button {
                        crearCuenta()
                    } label: {
                        Text("CREAR MI CUENTA")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(Capsule())
                    }

                    Text("Tu perfil se guardará en este iPhone.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 25)
                }
                .padding(.horizontal, 22)
            }
        }
        .sheet(isPresented: $mostrarTerminos) {
            TerminosStreamify()
                .preferredColorScheme(.dark)
        }
    }

    private func crearCuenta() {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nombreLimpio.isEmpty else {
            error = "Escribe tu nombre para continuar."
            return
        }

        guard aceptarTerminos else {
            error = "Debes aceptar los términos y condiciones."
            return
        }

        if avatarData.isEmpty {
            avatarURL = avataresStreamify.first {
                $0.id == avatarElegido
            }?.url ?? avataresStreamify[0].url
        }

        nombreGuardado = nombreLimpio
        terminosAceptados = true
        registrado = true
    }
}

// MARK: - TÉRMINOS Y CONDICIONES

struct TerminosStreamify: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Términos y condiciones de Streamify")
                        .font(.title.bold())

                    Text("Última actualización: noviembre de 2026")
                        .foregroundColor(.gray)

                    apartado("1. Uso de la aplicación",
                             "Streamify permite explorar y reproducir contenido musical disponible mediante las fuentes integradas en la aplicación. El usuario se compromete a utilizarla de forma responsable y legal.")

                    apartado("2. Cuenta y perfil",
                             "El nombre y la imagen elegidos se guardan localmente en el dispositivo. Esta versión no cuenta con sincronización entre dispositivos ni autenticación mediante servidores.")

                    apartado("3. Fotografías",
                             "El usuario es responsable de contar con autorización para utilizar las fotografías que seleccione como imagen de perfil.")

                    apartado("4. Música y derechos",
                             "Los derechos de las canciones, grabaciones, portadas y demás contenidos pertenecen a sus respectivos titulares. Streamify no transfiere la propiedad de dichos contenidos.")

                    apartado("5. Privacidad",
                             "La información del perfil de esta versión se almacena en el dispositivo. El comportamiento de servicios externos depende de sus propios proveedores y políticas.")

                    apartado("6. Disponibilidad",
                             "La aplicación puede cambiar, actualizarse o dejar de ofrecer determinadas funciones. No se garantiza la disponibilidad permanente de fuentes externas.")

                    apartado("7. Aceptación",
                             "Al crear tu perfil declaras que has leído y aceptas estas condiciones.")
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Condiciones")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }

    private func apartado(_ titulo: String, _ contenido: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(titulo)
                .font(.headline)
                .foregroundColor(.green)

            Text(contenido)
                .foregroundColor(.white.opacity(0.85))
        }
    }
}
