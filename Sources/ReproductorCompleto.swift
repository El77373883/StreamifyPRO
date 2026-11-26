
import SwiftUI
import UIKit

struct ReproductorCompleto: View {

    @ObservedObject var reproductor: Reproductor
    @Environment(\.dismiss) private var dismiss

    @State private var progresoLocal: Double = 0
    @State private var arrastrando = false

    private var cancion: Cancion? {
        reproductor.cancionActual
    }

    private var favorita: Bool {
        guard let cancion = cancion else { return false }
        return reproductor.esFavorita(cancion)
    }

    private var descargada: Bool {
        guard let cancion = cancion else { return false }
        return reproductor.estaDescargada(cancion)
    }

    private var descargando: Bool {
        guard let cancion = cancion else { return false }
        return reproductor.descargandoKeys.contains(cancion.clave)
    }

    private var avanceDescarga: Double {
        guard let cancion = cancion else { return 0 }
        return reproductor.progresoDescarga[cancion.clave] ?? 0
    }

    var body: some View {

        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.07)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                // ENCABEZADO

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

                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .padding()

                Spacer(minLength: 15)

                // PORTADA

                PortadaCancion(
                    url: cancion?.urlPortada ?? ""
                )
                .frame(width: 320, height: 320)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(
                        Color.white.opacity(0.12),
                        lineWidth: 2
                    )
                )
                .shadow(
                    color: .black.opacity(0.5),
                    radius: 20,
                    y: 10
                )
                .padding(.bottom, 35)

                // NOMBRE Y BOTONES

                HStack {

                    VStack(alignment: .leading, spacing: 6) {

                        Text(cancion?.titulo ?? "Sin canción")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(cancion?.artista ?? "")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    Spacer()

                    // DESCARGAR

                    Button {

                        if let cancion = cancion {
                            reproductor.descargar(cancion)
                        }

                    } label: {

                        if descargando {
                            ProgressView()
                                .tint(.green)
                                .scaleEffect(1.3)
                                .frame(width: 34, height: 34)

                        } else {
                            Image(
                                systemName: descargada
                                ? "checkmark.circle.fill"
                                : "arrow.down.circle"
                            )
                            .font(.system(size: 30))
                            .foregroundColor(
                                descargada ? .green : .white
                            )
                        }
                    }
                    .disabled(descargada || descargando)

                    // FAVORITOS

                    Button {

                        if let cancion = cancion {
                            reproductor.alternarFavorito(cancion)
                        }

                    } label: {

                        Image(
                            systemName: favorita
                            ? "heart.fill"
                            : "plus.circle"
                        )
                        .font(.system(size: 30))
                        .foregroundColor(
                            favorita ? .green : .white
                        )
                    }
                }
                .padding(.horizontal, 24)

                // MENSAJE DE DESCARGA

                if !reproductor.mensajeDescarga.isEmpty {
                    Text(reproductor.mensajeDescarga)
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                // ANIMACIÓN Y PROGRESO DE DESCARGA

                if descargando {

                    VStack(spacing: 9) {

                        HStack {
                            ProgressView()
                                .tint(.green)

                            Text("Descargando música...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))

                            Spacer()

                            if avanceDescarga > 0 {
                                Text(
                                    "\(Int(avanceDescarga * 100))%"
                                )
                                .font(.caption.bold().monospacedDigit())
                                .foregroundColor(.green)
                            } else {
                                Text("Preparando")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }

                        if avanceDescarga > 0 {
                            ProgressView(value: avanceDescarga)
                                .tint(.green)
                                .animation(
                                    .easeInOut(duration: 0.2),
                                    value: avanceDescarga
                                )
                        } else {
                            ProgressView()
                                .tint(.green)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }

                // PROGRESO DE REPRODUCCIÓN

                VStack(spacing: 8) {

                    Slider(
                        value: $progresoLocal,
                        in: 0...1,
                        onEditingChanged: { editing in

                            arrastrando = editing

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
                                reproductor.duracion *
                                (1 - progresoLocal)
                            )
                        )
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .onChange(of: reproductor.progreso) { nuevo in
                    if !arrastrando {
                        progresoLocal = nuevo
                    }
                }

                // CONTROLES

                HStack(spacing: 30) {

                    Image(systemName: "shuffle")
                        .font(.title2)
                        .foregroundColor(.green)

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
                                .fill(.white)
                                .frame(width: 76, height: 76)

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

                    Image(systemName: "repeat")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding(.top, 30)

                Spacer()

                // OPCIONES

                HStack {
                    Image(systemName: "quote.bubble")
                        .font(.title3)
                        .foregroundColor(.green)

                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .foregroundColor(.white)

                    Image(systemName: "list.bullet")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // LETRAS

                VStack(alignment: .leading, spacing: 0) {

                    Text("Vista previa de la letra")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .background(
                            Color(red: 0.2, green: 0.3, blue: 0.2)
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
                }
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            progresoLocal = reproductor.progreso
        }
    }

    // MARK: - FORMATO DE TIEMPO

    private func tiempo(_ segundos: Double) -> String {

        guard segundos.isFinite, segundos >= 0 else {
            return "0:00"
        }

        return String(
            format: "%d:%02d",
            Int(segundos) / 60,
            Int(segundos) % 60
        )
    }
}
