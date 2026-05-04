import SwiftUI
import SwiftData
import WidgetKit

struct ShelfEditorView: View {
    enum Mode {
        case create
        case edit(Shelf)
    }

    let mode: Mode
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var backgroundHex: String = ShelfStyle.defaultBackgroundHex
    @State private var preset: StylePreset = .flat
    @State private var customColor: Color = Color(hex: ShelfStyle.defaultBackgroundHex)
    @State private var useCustom = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.paper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        nameField
                        preview
                        colorSection
                        presetSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isEditing ? "Edit shelf" : "New shelf")
                        .font(.serif(20))
                        .foregroundStyle(AppTheme.ink)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.sans(14))
                        .tint(AppTheme.ink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(.sans(14, weight: .medium))
                        .tint(AppTheme.ink)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: load)
            .onChange(of: customColor) { _, new in
                if useCustom { backgroundHex = new.toHex }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true } else { return false }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Name").monoCaption().foregroundStyle(AppTheme.ink)
            TextField("Morning reads", text: $name)
                .font(.serif(28))
                .foregroundStyle(AppTheme.ink)
                .padding(.vertical, 10)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(AppTheme.hairline), alignment: .bottom)
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview").monoCaption().foregroundStyle(AppTheme.ink)
            ZStack(alignment: .bottom) {
                ShelfBackground(hex: backgroundHex, preset: preset)
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 5) {
                        ForEach(0..<5, id: \.self) { i in
                            BookCoverView(
                                coverId: nil,
                                title: ["Moby", "Sula", "1984", "Aria", "Orlando"][i],
                                fallbackTint: Color(hex: backgroundHex).contrastingInk().opacity(0.85)
                            )
                            .aspectRatio(2.0/3.0, contentMode: .fit)
                            .frame(height: 90)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                    ShelfPlank(hex: backgroundHex)
                }
            }
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color").monoCaption().foregroundStyle(AppTheme.ink)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(ShelfStyle.palette, id: \.hex) { swatch in
                    Button {
                        useCustom = false
                        backgroundHex = swatch.hex
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: swatch.hex))
                                .frame(height: 44)
                                .overlay(
                                    Circle()
                                        .strokeBorder(AppTheme.ink, lineWidth: backgroundHex == swatch.hex && !useCustom ? 1.5 : 0.5)
                                )
                            Text(swatch.name).font(.sans(10, weight: .light)).foregroundStyle(AppTheme.ink)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack(spacing: 10) {
                ColorPicker(selection: $customColor, supportsOpacity: false) {
                    Text("Custom").font(.sans(13)).foregroundStyle(AppTheme.ink)
                }
                .onChange(of: customColor) { _, _ in useCustom = true }
                Spacer()
                if useCustom {
                    Text(backgroundHex.uppercased())
                        .font(.mono(11))
                        .opacity(0.7)
                        .foregroundStyle(AppTheme.ink)
                }
            }
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Style").monoCaption().foregroundStyle(AppTheme.ink)
            HStack(spacing: 10) {
                ForEach(StylePreset.allCases, id: \.self) { p in
                    Button { preset = p } label: {
                        Text(p.displayName)
                            .font(.sans(13, weight: preset == p ? .medium : .light))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(preset == p ? AppTheme.ink : Color.clear)
                            .foregroundStyle(preset == p ? AppTheme.paper : AppTheme.ink)
                            .overlay(Capsule().stroke(AppTheme.ink, lineWidth: 1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func load() {
        if case .edit(let shelf) = mode {
            name = shelf.name
            backgroundHex = shelf.backgroundColorHex
            preset = shelf.preset
            customColor = Color(hex: shelf.backgroundColorHex)
            useCustom = !ShelfStyle.palette.contains(where: { $0.hex.lowercased() == shelf.backgroundColorHex.lowercased() })
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        switch mode {
        case .create:
            let count = (try? ctx.fetchCount(FetchDescriptor<Shelf>())) ?? 0
            let s = Shelf(
                name: trimmed,
                sortIndex: count,
                backgroundColorHex: backgroundHex,
                preset: preset
            )
            ctx.insert(s)
        case .edit(let shelf):
            shelf.name = trimmed
            shelf.backgroundColorHex = backgroundHex
            shelf.preset = preset
        }
        try? ctx.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
