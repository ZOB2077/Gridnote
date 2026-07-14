import SwiftUI

struct StealthOverlayView: View {
    @ObservedObject var controller: StealthOverlayController
    @ObservedObject var viewModel: StealthReaderViewModel
    @State private var showsSettings = false
    @State private var showsSearch = false
    @State private var showsBookmarks = false
    @State private var showsChapters = false
    @State private var isHovering = false
    @State private var sliderValue = 0.0
    @State private var searchQuery = ""

    var body: some View {
        Group {
            if controller.superStealthMode {
                content
            } else {
                VStack(spacing: 0) {
                    header
                    if showsSearch { searchBar }
                    Divider().opacity(0.6)
                    content
                    footer
                }
            }
        }
        .foregroundStyle(foregroundColor)
        .background {
            if controller.superStealthMode {
                Color.clear
            } else {
                background
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: controller.superStealthMode ? 0 : 12, style: .continuous))
        .overlay {
            if !controller.superStealthMode {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .overlay(alignment: .topTrailing) {
            if !controller.superStealthMode && (isHovering || showsSettings || showsSearch || showsBookmarks || showsChapters) {
                hoverControls
                    .padding(9)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .shadow(color: .black.opacity(controller.superStealthMode ? 0 : 0.18), radius: 18, y: 7)
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.16), value: isHovering)
        .onChange(of: viewModel.progressFraction) { _, value in sliderValue = value }
        .onReceive(NotificationCenter.default.publisher(for: .gridnoteStealthSearchRequested)) { _ in
            showsSearch = true
        }
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.width < -55 { viewModel.next() }
                    if value.translation.width > 55 { viewModel.previous() }
                }
        )
        .accessibilityIdentifier("stealth-reader-overlay")
    }

    private var header: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
                .shadow(color: statusColor.opacity(0.5), radius: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(headerTitle)
                    .font(.system(size: 11, weight: .semibold, design: headerDesign))
                Text(headerSubtitle)
                    .font(.system(size: 9, weight: .regular, design: headerDesign))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("LOCAL")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.12), in: Capsule())
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 13)
        .frame(height: 43)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            HStack(spacing: 12) {
                ProgressView().controlSize(.small)
                Text(viewModel.pageText).font(.system(size: 12, design: headerDesign))
                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            GeometryReader { proxy in
                ZStack {
                    Text(displayedPageText)
                        .id(viewModel.pageRevision)
                        .font(.system(size: viewModel.fontSize, weight: .regular, design: bodyDesign))
                        .lineSpacing(viewModel.lineSpacing)
                        .foregroundStyle(viewModel.textColor.opacity(viewModel.textOpacity))
                        .lineLimit(controller.superStealthMode ? 1 : nil)
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                        .padding(.vertical, controller.superStealthMode ? 4 : 13)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .transition(pageTransition)
                }
                .clipped()
                .animation(controller.superStealthMode ? nil : .easeOut(duration: 0.08), value: viewModel.pageRevision)
                .onAppear { fitPage(to: proxy.size) }
                .onChange(of: proxy.size) { _, size in fitPage(to: size) }
                .onChange(of: viewModel.fontSize) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.lineSpacing) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.appearance) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.pageRevision) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: controller.superStealthMode) { _, _ in fitPage(to: proxy.size) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Text(viewModel.progressText)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 125, alignment: .leading)
            Slider(
                value: Binding(
                    get: { sliderValue },
                    set: { sliderValue = $0 }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing { viewModel.seek(to: sliderValue) }
                }
            )
            .controlSize(.mini)
            .disabled(viewModel.state != .ready)
            Text("Updated now")
                .font(.system(size: 9, design: headerDesign))
                .foregroundStyle(.tertiary)
            Text("\(Int((viewModel.progressFraction * 100).rounded()))%")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 13)
        .frame(height: 31)
        .background(footerColor)
    }

    private var hoverControls: some View {
        HStack(spacing: 9) {
            Button(action: viewModel.previous) { Image(systemName: "chevron.left") }
                .disabled(!viewModel.canGoPrevious)
                .help("Previous record")
            Button(action: viewModel.next) { Image(systemName: "chevron.right") }
                .disabled(!viewModel.canGoNext)
                .help("Next record")
            Button { showsSearch.toggle() } label: { Image(systemName: "magnifyingglass") }
                .help("Search")
            Button(action: viewModel.toggleBookmark) {
                Image(systemName: viewModel.isCurrentLocationBookmarked ? "bookmark.fill" : "bookmark")
            }
            .help("Toggle bookmark")
            Button { showsBookmarks.toggle() } label: { Image(systemName: "bookmark.square") }
                .popover(isPresented: $showsBookmarks) { bookmarkList }
            Button { showsChapters.toggle() } label: { Image(systemName: "list.bullet") }
                .disabled(viewModel.chapters.isEmpty)
                .help("Chapters")
                .popover(isPresented: $showsChapters) { chapterList }
            Button { showsSettings.toggle() } label: { Image(systemName: "ellipsis.circle") }
                .popover(isPresented: $showsSettings) { settings }
            Button(action: controller.hide) { Image(systemName: "xmark") }
                .help("Close panel")
        }
        .buttonStyle(.plain)
        .font(.system(size: 10, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(borderColor.opacity(0.7), lineWidth: 0.5))
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Workspace View").font(.headline)
            Picker("Appearance", selection: $viewModel.appearance) {
                ForEach(StealthAppearance.allCases) { Text(verbatim: $0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Reading density", selection: Binding(
                get: { viewModel.density },
                set: { viewModel.applyDensity($0) }
            )) {
                ForEach(FloatingReaderDensity.allCases) { density in
                    Text(verbatim: density.title).tag(density)
                }
            }
            .pickerStyle(.segmented)
            settingSlider("Font size", value: $viewModel.fontSize, range: 10...28, format: "%.0f pt")
            settingSlider("Line spacing", value: $viewModel.lineSpacing, range: 0...12, format: "%.0f pt")
            ColorPicker("Text color", selection: $viewModel.textColor, supportsOpacity: false)
            settingSlider("Text opacity", value: $viewModel.textOpacity, range: 0...1, format: "%.0f%%", multiplier: 100)
            settingSlider("Background opacity", value: $viewModel.backgroundOpacity, range: 0...1, format: "%.0f%%", multiplier: 100)
            Text("Page size follows the floating window dimensions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(width: 360)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search current book", text: $searchQuery)
                .textFieldStyle(.plain)
                .onSubmit { viewModel.search(for: searchQuery) }
            if !viewModel.searchResultText.isEmpty {
                Text(viewModel.searchResultText).font(.caption).foregroundStyle(.secondary)
            }
            Button("Go") { viewModel.search(for: searchQuery) }.buttonStyle(.bordered)
        }
        .padding(.horizontal, 13)
        .frame(height: 35)
        .background(footerColor)
    }

    private var bookmarkList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bookmarks").font(.headline)
            if viewModel.bookmarks.isEmpty {
                Text("No bookmarks").foregroundStyle(.secondary)
            } else {
                List(viewModel.bookmarks) { bookmark in
                    HStack {
                        Button(bookmark.excerpt) { showsBookmarks = false; viewModel.jump(to: bookmark) }
                            .buttonStyle(.plain)
                            .lineLimit(1)
                        Spacer()
                        Button(role: .destructive) { viewModel.deleteBookmark(bookmark) } label: { Image(systemName: "trash") }
                            .buttonStyle(.plain)
                    }
                }
                .frame(height: min(CGFloat(viewModel.bookmarks.count) * 38, 190))
            }
        }
        .padding(16)
        .frame(width: 330)
    }

    private var chapterList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Chapters").font(.headline)
            List(viewModel.chapters) { chapter in
                Button(chapter.title) {
                    showsChapters = false
                    viewModel.jump(to: chapter)
                }
                .buttonStyle(.plain)
                .lineLimit(1)
            }
            .frame(height: min(CGFloat(viewModel.chapters.count) * 34, 260))
        }
        .padding(16)
        .frame(width: 330)
    }

    private func settingSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: String,
        multiplier: Double = 1
    ) -> some View {
        LabeledContent(title) {
            HStack {
                Slider(value: value, in: range).frame(width: 130)
                Text(String(format: format, value.wrappedValue * multiplier))
                    .monospacedDigit()
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    private var headerTitle: String {
        switch viewModel.appearance {
        case .activity: String(localized: "OPERATIONS ACTIVITY")
        case .report: String(localized: "WEEKLY STATUS REPORT")
        case .console: String(localized: "workspace / activity.log")
        }
    }

    private var headerSubtitle: String {
        switch viewModel.appearance {
        case .activity: String(localized: "Record details and internal notes")
        case .report: String(localized: "Section notes · Draft autosaved")
        case .console: String(localized: "tailing local workspace events")
        }
    }

    private var headerDesign: Font.Design { viewModel.appearance == .console ? .monospaced : .default }
    private var bodyDesign: Font.Design { viewModel.appearance == .console ? .monospaced : .rounded }
    private var statusColor: Color { viewModel.appearance == .console ? .orange : Color(red: 0.05, green: 0.52, blue: 0.34) }
    private var foregroundColor: Color { viewModel.appearance == .console ? Color(red: 0.78, green: 0.90, blue: 0.80) : .primary }
    private var borderColor: Color { viewModel.appearance == .console ? .green.opacity(0.25) : .primary.opacity(0.13) }
    private var footerColor: Color { viewModel.appearance == .console ? .black.opacity(0.26) : .primary.opacity(0.035) }

    private var pageTransition: AnyTransition {
        controller.superStealthMode ? .identity : .opacity
    }

    private func fitPage(to size: CGSize) {
        if controller.superStealthMode {
            viewModel.fitSingleLinePage(
                maximumTextWidth: controller.maximumSuperStealthTextWidth,
                monospaced: viewModel.appearance == .console
            )
            controller.adjustSuperStealthWidth(for: viewModel.currentPageMeasuredWidth)
        } else {
            viewModel.fitPage(to: size)
        }
    }

    private var displayedPageText: String {
        guard controller.superStealthMode else { return viewModel.pageText }
        return viewModel.pageText
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }

    @ViewBuilder
    private var background: some View {
        if viewModel.appearance == .console {
            Color(red: 0.055, green: 0.072, blue: 0.061).opacity(viewModel.backgroundOpacity)
        } else {
            Rectangle().fill(.regularMaterial).opacity(viewModel.backgroundOpacity)
        }
    }
}
