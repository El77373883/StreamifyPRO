
import SwiftUI
import UIKit

struct ReproductorCompleto: View {
    @ObservedObject var reproductor: Reproductor
    @Environment(\.dismiss) private var dismiss

    @State private var arrastrandoProgreso = false
    @State private var progresoLocal: Double = 0.0

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.1)
                .ignoresSafeArea()

            VStack(spacing: 0) {
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
                        .font(.caption.bold())
                        .foregroundColor(.white)

                    Spacer()

                    Button {} label: {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding()

                Spacer(minLength: 20)

                AsyncImage(
                    url: URL(string: reproductor.cancionActual?.urlPortada ?? "")
                ) { img in
                    img.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 320, height: 320)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(Color.white.opacity(0.1), lineWidth: 2)
                )
                .shadow(
                    color: .black.opacity(0.5),
                    radius: 20,
                    x: 0,
                    y: 10
                )
                .padding(.bottom, 40)

                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reproductor.cancionActual?.titulo ?? "")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(reproductor.cancionActual?.artista ?? "")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {} label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }

                    Button {} label: {
                        Image(systemName: "plus.circle")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 24)

                VStack(spacing: 8) {
                    Slider(
                        value: $progresoLocal,
                        in: 0...1,
                        onEditingChanged: { editing in
                            arrastrandoProgreso = editing

                            if !editing {
                                reproductor.cambiarProgreso(a: progresoLocal)
                            }
                        }
                    )
                    .tint(.white)

                    HStack {
                        Text(tiempo(progresoLocal * reproductor.duracion))

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

                HStack(spacing: 40) {
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
                                ? "pause.fill" : "play.fill"
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

                Spacer()

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

                VStack(alignment: .leading) {
                    Text("Vista previa de la letra")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.2, green: 0.3, blue: 0.2))
                        .cornerRadius(15, corners: [.topLeft, .topRight])

                    Text("Letra próximamente...")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(red: 0.15, green: 0.25, blue: 0.15))
                        .cornerRadius(15, corners: [.bottomLeft, .bottomRight])
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
    }

    func tiempo(_ segundos: Double) -> String {
        guard segundos.isFinite, segundos >= 0 else {
            return "0:00"
        }

        let minutos = Int(segundos) / 60
        let segundosRestantes = Int(segundos) % 60

        return String(format: "%d:%02d", minutos, segundosRestantes)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
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
            cornerRadii: CGSize(width: radius, height: radius)
        )

        return Path(path.cgPath)
    }
}
