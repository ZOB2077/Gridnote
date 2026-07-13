import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState

    @EnvironmentObject private var stealthController: StealthOverlayController

    var body: some View { SettingsContent(context: modelContext, bookID: appState.selectedBookID, stealthController: stealthController) }
}

private struct SettingsContent: View {
    @StateObject private var viewModel: SettingsViewModel
    @ObservedObject private var stealthController: StealthOverlayController

    init(context: ModelContext, bookID: UUID?, stealthController: StealthOverlayController) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(context: context, bookID: bookID))
        self.stealthController = stealthController
    }

    var body: some View {
        TabView {
            Form {
                ColorPicker("Text color", selection: $viewModel.textColor, supportsOpacity: false)
                LabeledContent("Text opacity") {
                    Slider(value: $viewModel.textOpacity, in: 0...1)
                    Text("\(Int((viewModel.textOpacity * 100).rounded()))%").frame(width: 42)
                }
                Text("Applies to Floating Reader and spreadsheet notes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Save Text Appearance") { viewModel.saveReadingSettings() }
                    .accessibilityIdentifier("save-reading-settings")

                Divider()
                Toggle("Super Stealth Mode", isOn: Binding(
                    get: { stealthController.superStealthMode },
                    set: { stealthController.setSuperStealthMode($0) }
                ))
                Text("Removes the floating window background, border, and controls. Use the menu bar or global shortcuts to control it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if stealthController.superStealthMode {
                    superStealthSizeSlider("Super Stealth display width", value: Binding(
                        get: { Double(stealthController.superStealthDisplaySize.width) },
                        set: { stealthController.setSuperStealthDisplaySize(width: CGFloat($0), height: stealthController.superStealthDisplaySize.height) }
                    ), range: SuperStealthDisplaySize.widthRange)
                    superStealthSizeSlider("Super Stealth display height", value: Binding(
                        get: { Double(stealthController.superStealthDisplaySize.height) },
                        set: { stealthController.setSuperStealthDisplaySize(width: stealthController.superStealthDisplaySize.width, height: CGFloat($0)) }
                    ), range: SuperStealthDisplaySize.heightRange)
                }
                Toggle("Hide Floating Reader when Gridnote loses focus", isOn: Binding(
                    get: { stealthController.hidesOnAppResignActive },
                    set: { stealthController.setHidesOnAppResignActive($0) }
                ))
                Toggle("Snap Floating Reader to screen edges", isOn: Binding(
                    get: { stealthController.snapsToScreenEdges },
                    set: { stealthController.setSnapsToScreenEdges($0) }
                ))
                shortcutPicker("Previous page", action: .previous)
                shortcutPicker("Next page", action: .next)
                shortcutPicker("Show / hide", action: .hide)
            }
            .padding(20)
            .tabItem { Label("Floating Reader", systemImage: "rectangle.on.rectangle") }

            Form {
                if viewModel.bookID != nil {
                    TextField("Display alias", text: $viewModel.aliasTitle)
                        .accessibilityIdentifier("alias-title")
                    TextField("Workbook title", text: $viewModel.workbookTitle)
                        .accessibilityIdentifier("workbook-title")
                    TextField("Sheet name", text: $viewModel.sheetName)
                        .accessibilityIdentifier("sheet-name")
                    Button("Save Disguise") { viewModel.saveAlias() }
                        .accessibilityIdentifier("save-alias")
                } else {
                    ContentUnavailableView("No active book", systemImage: "doc")
                }

                Divider()
                Toggle("自动遮蔽公式栏正文", isOn: $viewModel.autoMaskFormulaBar)
                Picker("公式栏阅读行数", selection: $viewModel.formulaBarLineCount) {
                    ForEach(OfficeFormulaMaskSettings.lineCountRange, id: \.self) { count in
                        Text("\(count) 行").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                if viewModel.autoMaskFormulaBar {
                    LabeledContent("自动遮蔽延迟") {
                        HStack(spacing: 8) {
                            Slider(value: $viewModel.formulaBarMaskDelay, in: OfficeFormulaMaskSettings.delayRange, step: 1)
                            Text("\(Int(viewModel.formulaBarMaskDelay.rounded())) 秒")
                                .monospacedDigit()
                                .frame(width: 42, alignment: .trailing)
                        }
                    }
                }
                Text("停止操作后，公式栏正文会替换为业务备注。翻页、查找或点击公式栏可立即恢复。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("保存办公隐私设置") { viewModel.saveOfficePrivacySettings() }
            }
            .padding(20)
            .tabItem { Label("Office", systemImage: "tablecells") }
        }
        .frame(width: 560, height: 620)
        .task { viewModel.load() }
        .alert("Settings", isPresented: Binding(get: { viewModel.message != nil }, set: { if !$0 { viewModel.message = nil } })) {
            Button("OK", role: .cancel) { viewModel.message = nil }
        } message: { Text(viewModel.message ?? "") }
    }

    private func shortcutPicker(_ title: String, action: StealthShortcutAction) -> some View {
        Picker(title, selection: Binding(
            get: { stealthController.shortcut(for: action) },
            set: { stealthController.setShortcut($0, for: action) }
        )) {
            ForEach(StealthShortcut.allCases) { shortcut in
                Text(shortcut.title).tag(shortcut)
            }
        }
    }

    private func superStealthSizeSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<CGFloat>
    ) -> some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Slider(value: value, in: Double(range.lowerBound)...Double(range.upperBound), step: 10)
                Text("\(Int(value.wrappedValue.rounded())) px")
                    .monospacedDigit()
                    .frame(width: 58, alignment: .trailing)
            }
        }
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    let bookID: UUID?
    @Published var aliasTitle = "Quarterly Plan"
    @Published var workbookTitle = "Operations Dashboard.xlsx"
    @Published var sheetName = "Overview"
    @Published var fontSize = 18.0
    @Published var lineHeight = 8.0
    @Published var theme = "system"
    @Published var autoSwitch = false
    @Published var textColor = ReaderPresentationSettings.textColor
    @Published var textOpacity = ReaderPresentationSettings.textOpacity
    @Published var autoMaskFormulaBar = OfficeFormulaMaskSettings.isEnabled
    @Published var formulaBarMaskDelay = OfficeFormulaMaskSettings.delay
    @Published var formulaBarLineCount = OfficeFormulaMaskSettings.lineCount
    @Published var message: String?
    private let context: ModelContext

    init(context: ModelContext, bookID: UUID?) { self.context = context; self.bookID = bookID }

    func load() {
        do {
            let settings = try AppSettingsRepository(context: context).fetchOrCreate()
            fontSize = settings.standardReaderFontSize
            lineHeight = settings.standardReaderLineHeight ?? 8
            theme = settings.readerThemeRawValue
            autoSwitch = settings.resignToOfficeOnDeactivate
            textColor = ReaderPresentationSettings.textColor
            textOpacity = ReaderPresentationSettings.textOpacity
            autoMaskFormulaBar = OfficeFormulaMaskSettings.isEnabled
            formulaBarMaskDelay = OfficeFormulaMaskSettings.delay
            formulaBarLineCount = OfficeFormulaMaskSettings.lineCount
            if let bookID, let alias = try AliasProfileRepository(context: context).fetch(bookID: bookID) {
                aliasTitle = alias.aliasTitle
                workbookTitle = alias.workbookTitle
                sheetName = alias.sheetName
            }
        } catch { message = error.localizedDescription }
    }

    func saveAlias() {
        guard let bookID else { return }
        do {
            _ = try AliasProfileRepository(context: context).upsert(bookID: bookID, profile: .init(aliasTitle: aliasTitle, workbookTitle: workbookTitle, sheetName: sheetName))
            NotificationCenter.default.post(name: .gridnoteAliasDidChange, object: bookID)
            message = String(localized: "Disguise saved")
        } catch { message = error.localizedDescription }
    }

    func saveReadingSettings() {
        do {
            try AppSettingsRepository(context: context).updateReader(fontSize: fontSize, lineHeight: lineHeight, theme: theme)
            ReaderPresentationSettings.save(color: textColor, opacity: textOpacity)
            NotificationCenter.default.post(name: .gridnoteReaderSettingsDidChange, object: nil)
            message = String(localized: "Reading settings saved")
        } catch { message = error.localizedDescription }
    }

    func saveOfficeSettings() {
        do {
            try AppSettingsRepository(context: context).updateResignToOfficeOnDeactivate(autoSwitch)
            message = String(localized: "Office settings saved")
        } catch { message = error.localizedDescription }
    }

    func saveOfficePrivacySettings() {
        OfficeFormulaMaskSettings.save(
            enabled: autoMaskFormulaBar,
            delay: formulaBarMaskDelay,
            lineCount: formulaBarLineCount
        )
        NotificationCenter.default.post(name: .gridnoteOfficePrivacySettingsDidChange, object: nil)
        message = "办公隐私设置已保存"
    }
}

extension Notification.Name {
    static let gridnoteAliasDidChange = Notification.Name("GridnoteAliasDidChange")
    static let gridnoteReaderSettingsDidChange = Notification.Name("GridnoteReaderSettingsDidChange")
    static let gridnoteOfficePrivacySettingsDidChange = Notification.Name("GridnoteOfficePrivacySettingsDidChange")
}
