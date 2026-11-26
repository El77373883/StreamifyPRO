

import SwiftUI
import UIKit

struct ReproductorCompleto: View {

    @ObservedObject var reproductor: Reproductor
    @Environment(\.dismiss) private var dismiss

    @State private var arrastrandoProgreso = false
    @State private var progresoLocal: Double = 0.0

    // MARK: - ESTADO DE DESCARGA

    private var cancionDescargando: Bool {
        guard let cancion = reproductor.cancionActual else {
            return false
        }

        let key = "\(cancion.titulo.lowercased())|\(cancion.artista.lowercased())"

        return reproductor.descargandoKeys.contains(key)
    }

    private var descargaCompletada: Bool {
        guard let cancion = reproductor.cancionActual else {
            return false
        }

        return reproductor.estaDescargada(cancion)
    }

    private var esFavorita: Bool {
        guard let cancion = reproductor.cancionActual else {
            return false
        }

        return reproductor.esFavorita(cancion)
    }

    var body: some View {

        ZStack {

            Color(red: 0.07, green: 0.07, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: - BARRA SUPERIOR

                HStack {

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Recomendaciones para ti")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button {} label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 15)

                Spacer(minLength: 25)

                // MARK: - PORTADA

                AsyncImage(
                    url: URL(
                        string: reproductor.cancionActual?.urlPortada ?? ""
                    )
                ) { image in

                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)

                } placeholder: {

                    ZStack {
                        Color.gray.opacity(0.3)

                        Image(systemName: "music.note")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 320, height: 320)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                )
                .shadow(
                    color: .black.opacity(0.5),
                    radius: 20,
                    x: 0,
                    y: 10
                )
                .padding(.bottom, 40)

                // MARK: - INFORMACIÓN DE CANCIÓN

                HStack(alignment: .center) {

                    VStack(alignment: .leading, spacing: 6) {

                        Text(reproductor.cancionActual?.titulo ?? "Sin canción")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(reproductor.cancionActual?.artista ?? "")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    Spacer()

                    // MARK: - BOTÓN DESCARGAR

                    Button {

                        if let cancion = reproductor.cancionActual {
                            reproductor.descargar(cancion)
                        }

                    } label: {

                        Group {

                            if cancionDescargando {

                                ProgressView()
                                    .tint(.green)
                                    .frame(width: 30, height: 30)

                            } else if descargaCompletada {

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)

                            } else {

                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(
                        reproductor.cancionActual == nil ||
                        cancionDescargando ||
                        descargaCompletada
                    )

                    // MARK: - BOTÓN FAVORITOS

                    Button {

                        if let cancion = reproductor.cancionActual {
                            reproductor.alternarFavorito(cancion)
                        }

                    } label: {

                        Image(
                            systemName: esFavorita
                            ? "heart.fill"
                            : "plus.circle"
                        )
                        .font(.system(size: 30))
                        .foregroundColor(
                            esFavorita ? .green : .white
                        )
                    }
                    .disabled(reproductor.cancionActual == nil)
                }
                .padding(.horizontal, 24)

                // MARK: - MENSAJE DE DESCARGA

                if !reproductor.mensajeDescarga.isEmpty {

                    Text(reproductor.mensajeDescarga)
                        .font(.caption)
                        .foregroundColor(.green)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                }

                // MARK: - BARRA DE PROGRESO

                VStack(spacing: 8) {

                    Slider(
                        value: $progresoLocal,
                        in: 0...1,
                        onEditingChanged: { editing in

                            arrastrandoProgreso = editing

                            if !editing {
                                reproductor.cambiarProgreso(
                                    a: progresoLocal
                                )
                            }
                        }
                    )
                    .tint(.white)

                    HStack {

                        Text(
                            tiempo(
                                progresoLocal * reproductor.duracion
                            )
                        )

                        Spacer()

                        Text(
                            "-" + tiempo(
                                reproductor.duracion -
                                (progresoLocal * reproductor.duracion)
                            )
                        )
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .onChange(of: reproductor.progreso) { nuevo in

                    if !arrastrandoProgreso {
                        progresoLocal = nuevo
                    }
                }

                // MARK: - CONTROLES DE MÚSICA

                HStack(spacing: 35) {

                    Button {} label: {
                        Image(systemName: "shuffle")
                            .font(.title2)
                            .foregroundColor(.green)
                    }

                    Button {} label: {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }

                    Button {

                        reproductor.alternarPlayPausa()

                    } label: {

                        ZStack {

                            Circle()
                                .fill(Color.white)
                                .frame(width: 75, height: 75)

                            Image(
                                systemName: reproductor.reproduciendo
                                ? "pause.fill"
                                : "play.fill"
                            )
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                        }
                    }

                    Button {} label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }

                    Button {} label: {
                        Image(systemName: "repeat")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 30)
                .padding(.horizontal, 15)

                Spacer()

                // MARK: - OPCIONES INFERIORES

                HStack {

                    Image(systemName: "quote.bubble")
                        .font(.title3)
                        .foregroundColor(.green)

                    Spacer()

                    HStack(spacing: 30) {

                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(.white)

                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // MARK: - LETRAS

                VStack(alignment: .leading, spacing: 0) {

                    Text("Vista previa de la letra")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding()

                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                        .background(
                            Color(red: 0.2, green: 0.3, blue: 0.2)
                        )

                        .cornerRadius(
                            15,
                            corners: [.topLeft, .topRight]
                        )

                    Text("Letra próximamente...")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()

                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                        .background(
                            Color(red: 0.15, green: 0.25, blue: 0.15)
                        )

                        .cornerRadius(
                            15,
                            corners: [.bottomLeft, .bottomRight]
                        )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            progresoLocal = reproductor.progreso
        }
    }

    // MARK: - FORMATO DE TIEMPO

    func tiempo(_ segundos: Double) -> String {

        guard segundos.isFinite, segundos >= 0 else {
            return "0:00"
        }

        let minutos = Int(segundos) / 60
        let segundosRestantes = Int(segundos) % 60

        return String(
            format: "%d:%02d",
            minutos,
            segundosRestantes
        )
    }
}

// MARK: - ESQUINAS REDONDEADAS

extension View {

    func cornerRadius(
        _ radius: CGFloat,
        corners: UIRectCorner
    ) -> some View {

        clipShape(
            RoundedCorner(
                radius: radius,
                corners: corners
            )
        )
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {

        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(
                width: radius,
                height: radius
            )
        )

        return Path(path.cgPath)
    }
}
