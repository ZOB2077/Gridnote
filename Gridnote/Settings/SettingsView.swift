import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @EnvironmentObject private var stealthController: StealthOverlayController

    var body: some View {
        SettingsContent(context: modelContext, bookID: appState.selectedBookID, stealthController: stealthController)
            .overlay(alignment: .topTrailing) {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .background(.regularMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.09), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("关闭设置")
                .accessibilityLabel("关闭设置")
                .accessibilityIdentifier("close-settings")
                .padding(16)
            }
    }
}

private struct SettingsContent: View {
    @StateObject private var viewModel: SettingsViewModel
    @ObservedObject private var stealthController: StealthOverlayController
    @ObservedObject private var readerViewModel: StealthReaderViewModel
    @State private var selectedPane: SettingsPane = .floatingReader

    init(context: ModelContext, bookID: UUID?, stealthController: StealthOverlayController) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(context: context, bookID: bookID))
        self.stealthController = stealthController
        self.readerViewModel = stealthController.viewModel
    }

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar
            Divider()
            Group {
                switch selectedPane {
                case .floatingReader: floatingReaderPage
                case .officeDisguise: officeDisguisePage
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 820, idealWidth: 880, maxWidth: 980, minHeight: 640, idealHeight: 720, maxHeight: 860)
        .task { viewModel.load() }
        .onChange(of: readerViewModel.textColor) { _, _ in
            NotificationCenter.default.post(name: .gridnoteReaderSettingsDidChange, object: nil)
        }
        .onChange(of: readerViewModel.textOpacity) { _, _ in
            NotificationCenter.default.post(name: .gridnoteReaderSettingsDidChange, object: nil)
        }
        .alert("设置", isPresented: Binding(get: { viewModel.message != nil }, set: { if !$0 { viewModel.message = nil } })) {
            Button("确定", role: .cancel) { viewModel.message = nil }
        } message: { Text(viewModel.message ?? "") }
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("设置")
                .font(.title2.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.bottom, 14)

            ForEach(SettingsPane.allCases) { pane in
                Button {
                    selectedPane = pane
                } label: {
                    Label(pane.title, systemImage: pane.systemImage)
                        .font(.body.weight(selectedPane == pane ? .semibold : .regular))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedPane == pane ? Color.accentColor.opacity(0.14) : .clear)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedPane == pane ? Color.accentColor : Color.primary)
            }

            Spacer()
            Label("所有设置仅保存在本机", systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(12)
        }
        .padding(.top, 24)
        .padding(.horizontal, 12)
        .frame(width: 190)
        .background(.regularMaterial)
    }

    private var floatingReaderPage: some View {
        settingsPage(
            title: "悬浮阅读",
            subtitle: "调整文字外观、隐蔽行为与全局操作方式。"
        ) {
            settingsSection("文字外观", systemImage: "textformat") {
                Picker("面板样式", selection: $readerViewModel.appearance) {
                    ForEach(StealthAppearance.allCases) { appearance in
                        Text(verbatim: appearance.title).tag(appearance)
                    }
                }
                .pickerStyle(.segmented)
                Picker("阅读密度", selection: Binding(
                    get: { readerViewModel.density },
                    set: { readerViewModel.applyDensity($0) }
                )) {
                    ForEach(FloatingReaderDensity.allCases) { density in
                        Text(verbatim: density.title).tag(density)
                    }
                }
                .pickerStyle(.segmented)
                LabeledContent("字体风格") {
                    Picker("字体风格", selection: $readerViewModel.fontFamily) {
                        ForEach(ReaderFontFamily.allCases) { family in
                            Text(family.title).tag(family)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 210)
                }
                LabeledContent("字重") {
                    Picker("字重", selection: $readerViewModel.fontWeight) {
                        ForEach(ReaderFontWeight.allCases) { weight in
                            Text(weight.title).tag(weight)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 210)
                }
                responsiveSlider("字号", value: $readerViewModel.fontSize, range: 10...28) {
                    "\(Int($0.rounded())) pt"
                }
                responsiveSlider("行距", value: $readerViewModel.lineSpacing, range: 0...12) {
                    "\(Int($0.rounded())) pt"
                }
                responsiveSlider("字距", value: $readerViewModel.letterSpacing, range: -0.5...2, step: 0.1) {
                    String(format: "%.1f pt", $0)
                }
                ColorPicker("文字颜色", selection: $readerViewModel.textColor, supportsOpacity: false)
                responsiveSlider("文字透明度", value: $readerViewModel.textOpacity, range: 0...1) {
                    "\(Int(($0 * 100).rounded()))%"
                }
                responsiveSlider("背景透明度", value: $readerViewModel.backgroundOpacity, range: 0...1) {
                    "\(Int(($0 * 100).rounded()))%"
                }
                helpText("同时应用于悬浮阅读和表格顶部编辑栏。")
                Label("所有调整即时生效并自动保存在本机", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            settingsSection("超级隐蔽模式", systemImage: "eye.slash") {
                Toggle("启用超级隐蔽模式", isOn: Binding(
                    get: { stealthController.superStealthMode },
                    set: { stealthController.setSuperStealthMode($0) }
                ))
                helpText("移除悬浮窗背景、边框和控制组件，通过菜单栏或全局快捷键操作。")
                superStealthPreview
                if stealthController.superStealthMode {
                    Divider()
                    superStealthSizeSlider("最小显示宽度", value: Binding(
                        get: { Double(stealthController.superStealthDisplaySize.width) },
                        set: { stealthController.setSuperStealthDisplaySize(width: CGFloat($0), height: stealthController.superStealthDisplaySize.height) }
                    ), range: SuperStealthDisplaySize.widthRange)
                    superStealthSizeSlider("最大显示宽度", value: Binding(
                        get: { Double(stealthController.superStealthDisplaySize.maximumWidth) },
                        set: { stealthController.setSuperStealthMaximumWidth(CGFloat($0)) }
                    ), range: stealthController.superStealthDisplaySize.width...SuperStealthDisplaySize.widthRange.upperBound)
                    superStealthSizeSlider("显示高度", value: Binding(
                        get: { Double(stealthController.superStealthDisplaySize.height) },
                        set: { stealthController.setSuperStealthDisplaySize(width: stealthController.superStealthDisplaySize.width, height: CGFloat($0)) }
                    ), range: SuperStealthDisplaySize.heightRange)
                    helpText("宽度会在设定下限和屏幕安全范围之间自动调整。")
                }
            }

            settingsSection("失焦保护", systemImage: "rectangle.badge.xmark") {
                Toggle("应用失去焦点时隐藏悬浮阅读", isOn: Binding(
                    get: { stealthController.hidesOnAppResignActive },
                    set: { stealthController.setHidesOnAppResignActive($0) }
                ))
                if stealthController.hidesOnAppResignActive {
                    Toggle("失焦时使用渐隐", isOn: Binding(
                        get: { stealthController.usesFocusShieldFade },
                        set: { stealthController.setFocusShield(delay: stealthController.focusShieldDelay, usesFade: $0) }
                    ))
                    responsiveSlider("遮蔽延迟", value: Binding(
                        get: { stealthController.focusShieldDelay },
                        set: { stealthController.setFocusShield(delay: $0, usesFade: stealthController.usesFocusShieldFade) }
                    ), range: FloatingReaderFocusShieldSettings.delayRange, step: 0.1) {
                        String(format: "%.1f 秒", $0)
                    }
                    helpText("默认立即遮蔽；延迟后悬浮文字淡出，顶部编辑栏立即恢复业务备注。")
                }
            }

            settingsSection("全局快捷键", systemImage: "keyboard") {
                shortcutPicker("上一页", action: .previous)
                shortcutPicker("下一页", action: .next)
                shortcutPicker("显示或隐藏", action: .hide)
            }
        }
    }

    private var superStealthPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("实时预览", systemImage: "eye")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(stealthController.superStealthDisplaySize.width))–\(Int(stealthController.superStealthDisplaySize.maximumWidth)) px")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                let upperBound = max(SuperStealthDisplaySize.widthRange.upperBound, 1)
                let widthRatio = min(max(stealthController.superStealthDisplaySize.maximumWidth / upperBound, 0.32), 1)
                let previewWidth = max(180, proxy.size.width * widthRatio)
                let heightRatio = min(max(stealthController.superStealthDisplaySize.height / SuperStealthDisplaySize.heightRange.upperBound, 0.32), 1)
                let previewHeight = max(30, 58 * heightRatio)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.025))
                    HStack(spacing: 0) {
                        Text("项目记录已同步，等待复核。")
                            .font(.system(
                                size: min(readerViewModel.fontSize, 17),
                                weight: readerViewModel.fontWeight.swiftUIWeight,
                                design: readerViewModel.fontFamily.design
                            ))
                            .tracking(readerViewModel.letterSpacing)
                            .foregroundStyle(readerViewModel.textColor.opacity(readerViewModel.textOpacity))
                            .fixedSize(horizontal: true, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .frame(width: previewWidth, height: previewHeight, alignment: .leading)
                    .clipped()
                    .overlay {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .foregroundStyle(Color.secondary.opacity(0.28))
                    }
                    .padding(8)
                }
            }
            .frame(height: 76)
            helpText("虚线范围模拟纯文字窗口；调整宽度、高度、字体和透明度时会立即更新。")
        }
        .padding(12)
        .background(Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var officeDisguisePage: some View {
        settingsPage(
            title: "办公伪装",
            subtitle: "管理工作簿外观、演示数据和顶部编辑栏隐私。"
        ) {
            settingsSection("书籍伪装", systemImage: "doc.badge.gearshape") {
                if viewModel.bookID != nil {
                    TextField("显示别名", text: $viewModel.aliasTitle)
                        .accessibilityIdentifier("alias-title")
                    TextField("工作簿标题", text: $viewModel.workbookTitle)
                        .accessibilityIdentifier("workbook-title")
                    TextField("工作表名称", text: $viewModel.sheetName)
                        .accessibilityIdentifier("sheet-name")
                    actionButton("保存伪装设置") { viewModel.saveAlias() }
                        .accessibilityIdentifier("save-alias")
                } else {
                    Label("导入并选择书籍后可设置显示别名", systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                }
            }

            settingsSection("办公数据", systemImage: "tablecells") {
                Picker("演示数据主题", selection: $viewModel.officeTemplateFamily) {
                    ForEach(OfficeTemplateFamily.allCases, id: \.self) { template in
                        Text(template.disguiseTitle).tag(template)
                    }
                }
                .frame(maxWidth: 300)
                helpText("切换后以纯虚构演示数据替换当前表格，不影响阅读进度和书签。")
            }

            settingsSection("顶部编辑栏隐私", systemImage: "text.rectangle") {
                Toggle("自动遮蔽阅读正文", isOn: $viewModel.autoMaskFormulaBar)
                Picker("阅读行数", selection: $viewModel.formulaBarLineCount) {
                    ForEach(OfficeFormulaMaskSettings.lineCountRange, id: \.self) { count in
                        Text("\(count) 行").tag(count)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                if viewModel.autoMaskFormulaBar {
                    responsiveSlider("自动遮蔽延迟", value: $viewModel.formulaBarMaskDelay, range: OfficeFormulaMaskSettings.delayRange, step: 1) {
                        "\(Int($0.rounded())) 秒"
                    }
                }
                Toggle("鼠标离开后遮蔽", isOn: $viewModel.maskFormulaBarOnPointerExit)
                if viewModel.autoMaskFormulaBar && viewModel.maskFormulaBarOnPointerExit {
                    responsiveSlider("离开后遮蔽延迟", value: $viewModel.formulaBarPointerExitDelay, range: OfficeFormulaMaskSettings.pointerExitDelayRange, step: 0.05) {
                        String(format: "%.2f 秒", $0)
                    }
                }
                helpText("停止操作后正文替换为业务备注；翻页、查找或点击编辑栏可立即恢复。")
                actionButton("保存办公隐私设置") { viewModel.saveOfficePrivacySettings() }
            }
        }
    }

    private func settingsPage<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.largeTitle.weight(.semibold))
                    Text(subtitle).font(.callout).foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)
                content()
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private func settingsSection<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            Divider()
            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        HStack {
            Spacer()
            Button(title, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
        }
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
        .frame(maxWidth: 300)
    }

    private func superStealthSizeSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<CGFloat>
    ) -> some View {
        responsiveSlider(title, value: value, range: Double(range.lowerBound)...Double(range.upperBound), step: 10) {
            "\(Int($0.rounded())) px"
        }
    }

    private func responsiveSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double? = nil,
        valueText: @escaping (Double) -> String
    ) -> some View {
        LabeledContent(title) {
            HStack(spacing: 10) {
                if let step {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
                Text(valueText(value.wrappedValue))
                    .monospacedDigit()
                    .lineLimit(1)
                    .frame(minWidth: 52, alignment: .trailing)
            }
            .frame(minWidth: 200, maxWidth: 320)
        }
    }

    private func helpText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private enum SettingsPane: String, CaseIterable, Identifiable {
    case floatingReader
    case officeDisguise

    var id: String { rawValue }

    var title: String {
        switch self {
        case .floatingReader: "悬浮阅读"
        case .officeDisguise: "办公伪装"
        }
    }

    var systemImage: String {
        switch self {
        case .floatingReader: "rectangle.on.rectangle"
        case .officeDisguise: "tablecells"
        }
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    let bookID: UUID?
    @Published var aliasTitle = "季度计划"
    @Published var workbookTitle = "运营数据看板.xlsx"
    @Published var sheetName = "订单明细"
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
