
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
        guard let cancion else { return false }
        return reproductor.esFavorita(cancion)
    }

    private var descargada: Bool {
        guard let cancion else { return false }
        return reproductor.estaDescargada(cancion)
    }

    private var descargando: Bool {
        guard let cancion else { return false }
        return reproductor.descargandoKeys.contains(cancion.clave)
    }

    private var avanceDescarga: Double {
        guard let cancion else { return 0 }
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

                    Text("Reproduciendo")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .padding()

                Spacer(minLength: 12)

                // PORTADA CUADRADA
                PortadaCancion(url: cancion?.urlPortada ?? "")
                    .frame(width: 320, height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                    .padding(.bottom, 30)

                // INFORMACIÓN
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

                    Button {
                        if let cancion {
                            reproductor.descargar(cancion)
                        }
                    } label: {
                        if descargando {
                            ProgressView()
                                .tint(.green)
                                .frame(width: 34, height: 34)
                        } else {
                            Image(systemName: descargada
                                  ? "checkmark.circle.fill"
                                  : "arrow.down.circle")
                                .font(.system(size: 30))
                                .foregroundColor(descargada ? .green : .white)
                        }
                    }
                    .disabled(descargada || descargando)

                    Button {
                        if let cancion {
                            reproductor.alternarFavorito(cancion)
                        }
                    } label: {
                        Image(systemName: favorita ? "heart.fill" : "plus.circle")
                            .font(.system(size: 30))
                            .foregroundColor(favorita ? .green : .white)
                    }
                }
                .padding(.horizontal, 24)

                if !reproductor.mensajeDescarga.isEmpty {
                    Text(reproductor.mensajeDescarga)
                        .font(.caption)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                if descargando {
                    VStack(spacing: 9) {
                        HStack {
                            ProgressView().tint(.green)

                            Text("Descargando música...")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.85))

                            Spacer()

                            Text(avanceDescarga > 0
                                 ? "\(Int(avanceDescarga * 100))%"
                                 : "Preparando")
                                .font(.caption.bold().monospacedDigit())
                                .foregroundColor(.green)
                        }

                        ProgressView(value: avanceDescarga)
                            .tint(.green)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }

                // BARRA DE PROGRESO
                VStack(spacing: 8) {
                    Slider(
                        value: $progresoLocal,
                        in: 0...1,
                        onEditingChanged: { editing in
                            arrastrando = editing

                            if !editing {
                                reproductor.cambiarProgreso(a: progresoLocal)
                            }
                        }
                    )
                    .tint(.white)

                    HStack {
                        Text(tiempo(progresoLocal * reproductor.duracion))
                        Spacer()
                        Text("-" + tiempo(
                            reproductor.duracion * (1 - progresoLocal)
                        ))
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
                HStack(spacing: 25) {

                    Button {
                        reproductor.alternarAleatorio()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.title2)
                            .foregroundColor(
                                reproductor.aleatorio ? .green : .gray
                            )
                    }

                    Button {
                        reproductor.anterior()
                    } label: {
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

                            Image(systemName: reproductor.reproduciendo
                                  ? "pause.fill" : "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.black)
                        }
                    }

                    Button {
                        reproductor.siguiente()
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }

                    Button {
                        reproductor.cambiarRepeticion()
                    } label: {
                        Image(systemName: reproductor.repetirModo == 2
                              ? "repeat.1" : "repeat")
                            .font(.title2)
                            .foregroundColor(
                                reproductor.repetirModo == 0 ? .gray : .green
                            )
                    }
                }
                .padding(.top, 28)

                Spacer(minLength: 12)

                // LETRAS
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "quote.bubble")
                            .foregroundColor(.green)

                        Text("Letra de la canción")
                            .font(.headline)
                            .foregroundColor(.white)

                        Spacer()

                        if reproductor.cargandoLetra {
                            ProgressView().tint(.white)
                        }
                    }
                    .padding()

                    Divider().overlay(Color.white.opacity(0.1))

                    ScrollView {
                        Group {
                            if reproductor.cargandoLetra {
                                Text("Buscando letra...")
                                    .foregroundColor(.white.opacity(0.7))
                            } else if reproductor.letraNoEncontrada {
                                Text("No encontramos la letra de esta canción.")
                                    .foregroundColor(.white.opacity(0.7))
                            } else {
                                Text(reproductor.letra)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                        }
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 155)
                }
                .background(Color(red: 0.15, green: 0.25, blue: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            progresoLocal = reproductor.progreso
        }
        .onChange(of: reproductor.cancionActual?.clave) { _ in
            progresoLocal = 0
        }
    }

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
