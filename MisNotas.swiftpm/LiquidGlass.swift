import SwiftUI

// Estilos Liquid Glass de toda la app. Úsalos en cualquier pantalla para que todo se vea igual.

extension View {
    /// Fondo de degradado animado detrás de una pantalla, para que el vidrio tenga qué refractar.
    func glassScreen(_ colors: [Color] = [.indigo, .pink, .teal], animated: Bool = true) -> some View {
        background { GlassBackdrop(colors: colors, animated: animated) }
    }

    /// Tarjeta de vidrio con esquinas redondeadas.
    func glassCard(cornerRadius: CGFloat = 26, tint: Color? = nil, padding: CGFloat = 18) -> some View {
        let glass: Glass = if let tint { .regular.tint(tint.opacity(0.25)) } else { .regular }
        return self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(glass, in: .rect(cornerRadius: cornerRadius))
    }
}

/// Bloque de vidrio con título, como las secciones de un formulario.
struct GlassSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
        .glassCard()
    }
}

/// Campo de texto en una cápsula de vidrio.
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var systemImage = "pencil"

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .submitLabel(.done)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Borrar texto")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .capsule)
    }
}

/// Selector de colores: el aro de vidrio se "derrite" de un color al otro al cambiar.
struct GlassColorPicker: View {
    @Binding var selection: Int
    @Namespace private var glass

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            HStack(spacing: 14) {
                ForEach(Notebook.covers.indices, id: \.self) { index in
                    let selected = selection == index
                    Circle()
                        .fill(Notebook.covers[index].gradient)
                        .frame(width: 34, height: 34)
                        .padding(6)
                        .modifier(SelectedGlass(isOn: selected, id: "aro", namespace: glass))
                        .contentShape(Circle())
                        .onTapGesture {
                            withAnimation(.bouncy) { selection = index }
                        }
                        .accessibilityLabel(Notebook.coverNames[index])
                        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }
}

/// Selector de tipo de hoja con mini-hojas dentro de baldosas de vidrio.
struct GlassPaperPicker: View {
    @Binding var selection: PaperStyle
    @Namespace private var glass

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 12) {
                ForEach(PaperStyle.allCases) { style in
                    let selected = selection == style
                    VStack(spacing: 8) {
                        PaperPreview(style: style)
                            .frame(width: 54, height: 76)
                        Text(style.name)
                            .font(.caption.weight(selected ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .glassEffect(
                        selected ? .regular.tint(Color.accentColor.opacity(0.35)).interactive() : .regular.interactive(),
                        in: .rect(cornerRadius: 18)
                    )
                    .glassEffectID(style.id, in: glass)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.bouncy) { selection = style }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
                }
            }
        }
    }
}

/// Hoja en miniatura con su fondo (líneas, cuadrícula, puntos).
struct PaperPreview: View {
    let style: PaperStyle

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            context.withCGContext { cg in
                style.render(in: cg, size: size)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
    }
}

/// Pone vidrio solo en el elemento seleccionado; con `glassEffectID` el vidrio viaja entre ellos.
private struct SelectedGlass: ViewModifier {
    let isOn: Bool
    let id: String
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if isOn {
            content
                .glassEffect(.regular.interactive(), in: .circle)
                .glassEffectID(id, in: namespace)
        } else {
            content
        }
    }
}
