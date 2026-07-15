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
                    Divider().opacity(0.42)
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
        .shadow(color: .black.opacity(controller.superStealthMode ? 0 : 0.14), radius: 20, y: 8)
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
            Image(systemName: headerIcon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 20, height: 20)
                .background(statusColor.opacity(0.09), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(headerTitle)
                    .font(.system(size: 11, weight: .semibold, design: headerDesign))
                Text(headerSubtitle)
                    .font(.system(size: 9, weight: .regular, design: headerDesign))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("已同步")
                .font(.system(size: 9, weight: .medium, design: headerDesign))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.primary.opacity(0.045), in: Capsule())
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 13)
        .frame(height: 41)
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
                        .font(.system(size: viewModel.fontSize, weight: viewModel.fontWeight.swiftUIWeight, design: viewModel.fontFamily.design))
                        .tracking(viewModel.letterSpacing)
                        .lineSpacing(viewModel.lineSpacing)
                        .foregroundStyle(viewModel.textColor.opacity(viewModel.textOpacity))
                        .lineLimit(controller.superStealthMode ? 1 : nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                        .padding(.horizontal, 17)
                        .padding(.vertical, controller.superStealthMode ? 4 : 15)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .transition(pageTransition)
                }
                .clipped()
                .animation(controller.superStealthMode ? nil : .easeOut(duration: 0.08), value: viewModel.pageRevision)
                .onAppear { fitPage(to: proxy.size) }
                .onChange(of: proxy.size) { _, size in fitPage(to: size) }
                .onChange(of: viewModel.fontSize) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.lineSpacing) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.letterSpacing) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.fontFamily) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.fontWeight) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.appearance) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: viewModel.pageRevision) { _, _ in fitPage(to: proxy.size) }
                .onChange(of: controller.superStealthMode) { _, _ in fitPage(to: proxy.size) }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var footer: some View {
        HStack(spacing: 9) {
            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.progressText)
                Text(viewModel.progressDetailText).foregroundStyle(.tertiary)
            }
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 150, alignment: .leading)
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
            Text("\(Int((viewModel.progressFraction * 100).rounded()))%")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 13)
        .frame(height: 32)
        .background(footerColor)
    }

    private var hoverControls: some View {
        HStack(spacing: 4) {
            controlButton("chevron.backward", action: viewModel.previous)
                .disabled(!viewModel.canGoPrevious)
                .help("Previous record")
            controlButton("chevron.forward", action: viewModel.next)
                .disabled(!viewModel.canGoNext)
                .help("Next record")
            controlButton("magnifyingglass") { showsSearch.toggle() }
                .help("Search")
            controlButton(viewModel.isCurrentLocationBookmarked ? "bookmark.fill" : "bookmark", action: viewModel.toggleBookmark)
            .help("Toggle bookmark")
            controlButton("bookmark.square.fill") { showsBookmarks.toggle() }
                .popover(isPresented: $showsBookmarks) { bookmarkList }
            controlButton("list.bullet.rectangle") { showsChapters.toggle() }
                .disabled(viewModel.chapters.isEmpty)
                .help("Chapters")
                .popover(isPresented: $showsChapters) { chapterList }
            Divider().frame(height: 18).padding(.horizontal, 2)
            controlButton("slider.horizontal.3") { showsSettings.toggle() }
                .popover(isPresented: $showsSettings) { settings }
            controlButton("xmark", action: controller.hide)
                .help("Close panel")
        }
        .buttonStyle(.plain)
        .padding(5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(borderColor.opacity(0.65), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }

    private func controlButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 27, height: 25)
                .contentShape(Rectangle())
        }
        .background(isHovering ? Color.primary.opacity(0.05) : Color.clear, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text("阅读外观").font(.headline)
                Text("调整会立即应用并保存在本机").font(.caption).foregroundStyle(.secondary)
            }
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
            Divider()
            LabeledContent("字体风格") {
                Picker("字体风格", selection: $viewModel.fontFamily) {
                    ForEach(ReaderFontFamily.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                .frame(width: 170)
            }
            LabeledContent("字重") {
                Picker("字重", selection: $viewModel.fontWeight) {
                    ForEach(ReaderFontWeight.allCases) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 170)
            }
            settingSlider("Font size", value: $viewModel.fontSize, range: 10...28, format: "%.0f pt")
            settingSlider("Line spacing", value: $viewModel.lineSpacing, range: 0...12, format: "%.0f pt")
            settingSlider("字距", value: $viewModel.letterSpacing, range: -0.5...2, format: "%.1f pt")
            ColorPicker("Text color", selection: $viewModel.textColor, supportsOpacity: false)
            settingSlider("Text opacity", value: $viewModel.textOpacity, range: 0...1, format: "%.0f%%", multiplier: 100)
            settingSlider("Background opacity", value: $viewModel.backgroundOpacity, range: 0...1, format: "%.0f%%", multiplier: 100)
            Text("Page size follows the floating window dimensions.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 380)
    }

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            if !viewModel.searchContext.isEmpty {
                Text(viewModel.searchContext)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 22)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
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
        case .activity: "记录详情"
        case .report: "周报备注"
        case .console: String(localized: "workspace / activity.log")
        }
    }

    private var headerSubtitle: String {
        switch viewModel.appearance {
        case .activity: viewModel.progressDetailText.isEmpty ? "内部备注与处理记录" : viewModel.progressDetailText
        case .report: "本地草稿 · 自动保存"
        case .console: String(localized: "tailing local workspace events")
        }
    }

    private var headerIcon: String {
        switch viewModel.appearance {
        case .activity: "doc.text.magnifyingglass"
        case .report: "list.clipboard"
        case .console: "terminal"
        }
    }

    private var headerDesign: Font.Design { viewModel.appearance == .console ? .monospaced : .default }
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
