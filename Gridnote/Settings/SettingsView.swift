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
                Toggle("Hide Floating Reader when Data Hub loses focus", isOn: Binding(
                    get: { stealthController.hidesOnAppResignActive },
                    set: { stealthController.setHidesOnAppResignActive($0) }
                ))
                if stealthController.hidesOnAppResignActive {
                    Toggle("失焦时使用渐隐", isOn: Binding(
                        get: { stealthController.usesFocusShieldFade },
                        set: { stealthController.setFocusShield(delay: stealthController.focusShieldDelay, usesFade: $0) }
                    ))
                    LabeledContent("失焦遮蔽延迟") {
                        HStack(spacing: 8) {
                            Slider(value: Binding(
                                get: { stealthController.focusShieldDelay },
                                set: { stealthController.setFocusShield(delay: $0, usesFade: stealthController.usesFocusShieldFade) }
                            ), in: FloatingReaderFocusShieldSettings.delayRange, step: 0.1)
                            Text(String(format: "%.1f 秒", stealthController.focusShieldDelay))
                                .monospacedDigit()
                                .frame(width: 46, alignment: .trailing)
                        }
                    }
                    Text("默认立即遮蔽。设置延迟后，悬浮阅读会在延迟结束时淡出；公式栏会立即切回业务备注。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
                Picker("办公数据主题", selection: $viewModel.officeTemplateFamily) {
                    ForEach(OfficeTemplateFamily.allCases, id: \.self) { template in
                        Text(template.disguiseTitle).tag(template)
                    }
                }
                Text("切换后会将当前表格替换为纯虚构的演示数据；阅读进度和书签不受影响。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                Toggle("鼠标离开公式栏后遮蔽", isOn: $viewModel.maskFormulaBarOnPointerExit)
                if viewModel.autoMaskFormulaBar && viewModel.maskFormulaBarOnPointerExit {
                    LabeledContent("离开后遮蔽延迟") {
                        HStack(spacing: 8) {
                            Slider(value: $viewModel.formulaBarPointerExitDelay, in: OfficeFormulaMaskSettings.pointerExitDelayRange, step: 0.05)
                            Text(String(format: "%.2f 秒", viewModel.formulaBarPointerExitDelay))
                                .monospacedDigit()
                                .frame(width: 50, alignment: .trailing)
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
    @Published var maskFormulaBarOnPointerExit = OfficeFormulaMaskSettings.masksOnPointerExit
    @Published var formulaBarPointerExitDelay = OfficeFormulaMaskSettings.pointerExitDelay
    @Published var officeTemplateFamily: OfficeTemplateFamily = .operations
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
            maskFormulaBarOnPointerExit = OfficeFormulaMaskSettings.masksOnPointerExit
            formulaBarPointerExitDelay = OfficeFormulaMaskSettings.pointerExitDelay
            officeTemplateFamily = OfficeDisguiseThemeSettings.templateFamily
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
            lineCount: formulaBarLineCount,
            masksOnPointerExit: maskFormulaBarOnPointerExit,
            pointerExitDelay: formulaBarPointerExitDelay
        )
        NotificationCenter.default.post(name: .gridnoteOfficePrivacySettingsDidChange, object: nil)
        OfficeDisguiseThemeSettings.save(templateFamily: officeTemplateFamily)
        NotificationCenter.default.post(name: .gridnoteOfficeTemplateRequested, object: officeTemplateFamily.rawValue)
        message = "办公隐私设置已保存"
    }
}

enum OfficeDisguiseThemeSettings {
    private static let key = "officePrivacy.disguiseTemplateFamily"

    static var templateFamily: OfficeTemplateFamily {
        OfficeTemplateFamily(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .operations
    }

    static func save(templateFamily: OfficeTemplateFamily, to defaults: UserDefaults = .standard) {
        defaults.set(templateFamily.rawValue, forKey: key)
    }
}

extension Notification.Name {
    static let gridnoteAliasDidChange = Notification.Name("GridnoteAliasDidChange")
    static let gridnoteReaderSettingsDidChange = Notification.Name("GridnoteReaderSettingsDidChange")
    static let gridnoteOfficePrivacySettingsDidChange = Notification.Name("GridnoteOfficePrivacySettingsDidChange")
    static let gridnoteOfficeTemplateRequested = Notification.Name("GridnoteOfficeTemplateRequested")
}
