import AppKit
import Carbon.HIToolbox
import SwiftData
import SwiftUI

enum StealthShortcutAction: Int, CaseIterable, Identifiable {
    case previous = 1
    case next = 2
    case hide = 3

    var id: Int { rawValue }
}

enum StealthShortcut: String, CaseIterable, Identifiable {
    case f7
    case f8
    case f9
    case optionCommandLeft
    case optionCommandRight
    case optionCommandH
    case optionCommandJ
    case optionCommandK
    case optionCommandBracketLeft
    case optionCommandBracketRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .f7: "F7"
        case .f8: "F8"
        case .f9: "F9"
        case .optionCommandLeft: "⌃⌥←"
        case .optionCommandRight: "⌃⌥→"
        case .optionCommandH: "⌃⌥H"
        case .optionCommandJ: "⌃⌥J"
        case .optionCommandK: "⌃⌥K"
        case .optionCommandBracketLeft: "⌃⌥["
        case .optionCommandBracketRight: "⌃⌥]"
        }
    }

    var keyCode: UInt32 {
        switch self {
        case .f7: UInt32(kVK_F7)
        case .f8: UInt32(kVK_F8)
        case .f9: UInt32(kVK_F9)
        case .optionCommandLeft: UInt32(kVK_LeftArrow)
        case .optionCommandRight: UInt32(kVK_RightArrow)
        case .optionCommandH: UInt32(kVK_ANSI_H)
        case .optionCommandJ: UInt32(kVK_ANSI_J)
        case .optionCommandK: UInt32(kVK_ANSI_K)
        case .optionCommandBracketLeft: UInt32(kVK_ANSI_LeftBracket)
        case .optionCommandBracketRight: UInt32(kVK_ANSI_RightBracket)
        }
    }

    var modifiers: UInt32 {
        switch self {
        case .f7, .f8, .f9: 0
        default: UInt32(controlKey | optionKey)
        }
    }
}

struct SuperStealthDisplaySize: Equatable {
    static let widthRange: ClosedRange<CGFloat> = 260...1800
    // Supports a single readable line at the largest supported reader font size.
    static let heightRange: ClosedRange<CGFloat> = 42...600
    static let `default` = SuperStealthDisplaySize(width: 620, maximumWidth: 1000, height: 180)

    let width: CGFloat
    let maximumWidth: CGFloat
    let height: CGFloat

    init(width: CGFloat, maximumWidth: CGFloat = Self.widthRange.upperBound, height: CGFloat) {
        let clampedWidth = min(max(width, Self.widthRange.lowerBound), Self.widthRange.upperBound)
        self.width = clampedWidth
        self.maximumWidth = min(max(maximumWidth, clampedWidth), Self.widthRange.upperBound)
        self.height = min(max(height, Self.heightRange.lowerBound), Self.heightRange.upperBound)
    }
}

enum FloatingReaderFocusShieldSettings {
    static let delayRange: ClosedRange<Double> = 0...1.5
    static let defaultDelay = 0.0
    static let defaultUsesFade = true
    private static let delayKey = "stealthReader.focusShieldDelay"
    private static let usesFadeKey = "stealthReader.focusShieldUsesFade"

    static func delay(in defaults: UserDefaults = .standard) -> Double {
        min(max(defaults.object(forKey: delayKey) as? Double ?? defaultDelay, delayRange.lowerBound), delayRange.upperBound)
    }

    static func usesFade(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: usesFadeKey) as? Bool ?? defaultUsesFade
    }

    static func save(delay: Double, usesFade: Bool, to defaults: UserDefaults = .standard) {
        defaults.set(min(max(delay, delayRange.lowerBound), delayRange.upperBound), forKey: delayKey)
        defaults.set(usesFade, forKey: usesFadeKey)
    }
}

enum FloatingReaderVisibilityAction {
    static func shouldShow(isVisible: Bool) -> Bool { !isVisible }
}

enum StealthShortcutRoute: Equatable {
    case floatingReader
    case officeWorkspace
    case toggleFloatingReader
    case none
}

enum StealthShortcutRouter {
    static func route(
        for action: StealthShortcutAction,
        isFloatingReaderVisible: Bool,
        isGridnoteActive: Bool
    ) -> StealthShortcutRoute {
        switch action {
        case .hide:
            return .toggleFloatingReader
        case .previous, .next:
            if isFloatingReaderVisible { return .floatingReader }
            return isGridnoteActive ? .officeWorkspace : .none
        }
    }
}

@MainActor
final class StealthOverlayController: NSObject, NSWindowDelegate, ObservableObject {
    let viewModel: StealthReaderViewModel
    @Published private(set) var superStealthMode: Bool
    @Published private(set) var previousShortcut: StealthShortcut
    @Published private(set) var nextShortcut: StealthShortcut
    @Published private(set) var toggleShortcut: StealthShortcut
    @Published private(set) var hidesOnAppResignActive: Bool
    @Published private(set) var focusShieldDelay: Double
    @Published private(set) var usesFocusShieldFade: Bool
    @Published private(set) var superStealthDisplaySize: SuperStealthDisplaySize
    private var panel: NSPanel?
    private var loadTask: Task<Void, Never>?
    private var keyboardMonitor: Any?
    private var globalHotKeyReferences: [EventHotKeyRef] = []
    private var globalHotKeyHandler: EventHandlerRef?
    private var appResignObserver: NSObjectProtocol?
    private var readerSettingsObserver: NSObjectProtocol?
    private var readingProgressObserver: NSObjectProtocol?
    private var focusHideTask: Task<Void, Never>?
    private var lastBookID: UUID?
    private let defaults: UserDefaults

    private enum Keys {
        static let superStealthMode = "stealthReader.superStealthMode"
        static let previousShortcut = "stealthReader.previousShortcut"
        static let nextShortcut = "stealthReader.nextShortcut"
        static let toggleShortcut = "stealthReader.toggleShortcut"
        static let shortcutProfileVersion = "stealthReader.shortcutProfileVersion"
        static let hidesOnAppResignActive = "stealthReader.hidesOnAppResignActive"
        static let superStealthWidth = "stealthReader.superStealthWidth"
        static let superStealthMaximumWidth = "stealthReader.superStealthMaximumWidth"
        static let superStealthHeight = "stealthReader.superStealthHeight"
    }

    init(context: ModelContext, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.integer(forKey: Keys.shortcutProfileVersion) < 2 {
            defaults.set(StealthShortcut.f7.rawValue, forKey: Keys.previousShortcut)
            defaults.set(StealthShortcut.f8.rawValue, forKey: Keys.nextShortcut)
            defaults.set(StealthShortcut.f9.rawValue, forKey: Keys.toggleShortcut)
            defaults.set(2, forKey: Keys.shortcutProfileVersion)
        }
        superStealthMode = defaults.bool(forKey: Keys.superStealthMode)
        previousShortcut = StealthShortcut(rawValue: defaults.string(forKey: Keys.previousShortcut) ?? "") ?? .f7
        nextShortcut = StealthShortcut(rawValue: defaults.string(forKey: Keys.nextShortcut) ?? "") ?? .f8
        toggleShortcut = StealthShortcut(rawValue: defaults.string(forKey: Keys.toggleShortcut) ?? "") ?? .f9
        hidesOnAppResignActive = defaults.object(forKey: Keys.hidesOnAppResignActive) as? Bool ?? true
        focusShieldDelay = FloatingReaderFocusShieldSettings.delay(in: defaults)
        usesFocusShieldFade = FloatingReaderFocusShieldSettings.usesFade(in: defaults)
        superStealthDisplaySize = SuperStealthDisplaySize(
            width: CGFloat(defaults.object(forKey: Keys.superStealthWidth) as? Double ?? Double(SuperStealthDisplaySize.default.width)),
            maximumWidth: CGFloat(defaults.object(forKey: Keys.superStealthMaximumWidth) as? Double ?? Double(SuperStealthDisplaySize.default.maximumWidth)),
            height: CGFloat(defaults.object(forKey: Keys.superStealthHeight) as? Double ?? Double(SuperStealthDisplaySize.default.height))
        )
        viewModel = StealthReaderViewModel(context: context, defaults: defaults)
        super.init()
        keyboardMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if self.panel?.isVisible == true {
                return self.handleKeyboardEvent(event) ? nil : event
            }
            return self.handleOfficeKeyboardEvent(event) ? nil : event
        }
        installGlobalHotKeyHandler()
        registerGlobalHotKeys()
        appResignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: NSApp,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.hideForFocusLoss() }
        }
        readerSettingsObserver = NotificationCenter.default.addObserver(
            forName: .gridnoteReaderSettingsDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.viewModel.reloadPresentationSettings() }
        }
        readingProgressObserver = NotificationCenter.default.addObserver(
            forName: .gridnoteReadingProgressDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard notification.object as? String != ReadingProgressSyncSource.floatingReader.rawValue,
                  let bookID = notification.userInfo?[ReadingProgressSync.bookIDKey] as? UUID else { return }
            Task { @MainActor in self?.viewModel.syncProgressFromOffice(bookID: bookID) }
        }
    }

    func show(bookID: UUID?) {
        let panel = panel ?? makePanel()
        focusHideTask?.cancel()
        panel.alphaValue = usesFocusShieldFade ? 0 : 1
        panel.orderFrontRegardless()
        if usesFocusShieldFade {
            Task { @MainActor in
                await NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.16
                    panel.animator().alphaValue = 1
                }
            }
        }
        lastBookID = bookID ?? lastBookID
        loadTask?.cancel()
        loadTask = Task { await viewModel.load(bookID: bookID) }
    }

    func hide() {
        focusHideTask?.cancel()
        panel?.orderOut(nil)
        panel?.alphaValue = 1
        NotificationCenter.default.post(name: .gridnotePrivacyShieldRequested, object: nil)
    }

    func next() { viewModel.next() }
    func previous() { viewModel.previous() }

    func setCurrentBook(_ bookID: UUID?) {
        lastBookID = bookID
    }

    func toggleVisibility() {
        if FloatingReaderVisibilityAction.shouldShow(isVisible: panel?.isVisible == true) {
            show(bookID: lastBookID)
        } else {
            hide()
        }
    }

    func setSuperStealthMode(_ enabled: Bool) {
        superStealthMode = enabled
        defaults.set(enabled, forKey: Keys.superStealthMode)
        panel?.hasShadow = !enabled
        updatePanelSizingForCurrentMode()
    }

    func setSuperStealthDisplaySize(width: CGFloat, height: CGFloat) {
        let size = SuperStealthDisplaySize(width: width, maximumWidth: superStealthDisplaySize.maximumWidth, height: height)
        superStealthDisplaySize = size
        defaults.set(Double(size.width), forKey: Keys.superStealthWidth)
        defaults.set(Double(size.maximumWidth), forKey: Keys.superStealthMaximumWidth)
        defaults.set(Double(size.height), forKey: Keys.superStealthHeight)
        guard superStealthMode else { return }
        applyPanelSize(size: NSSize(width: size.width, height: size.height))
    }

    func setSuperStealthMaximumWidth(_ maximumWidth: CGFloat) {
        let size = SuperStealthDisplaySize(
            width: superStealthDisplaySize.width,
            maximumWidth: maximumWidth,
            height: superStealthDisplaySize.height
        )
        superStealthDisplaySize = size
        defaults.set(Double(size.maximumWidth), forKey: Keys.superStealthMaximumWidth)
        guard superStealthMode else { return }
        panel?.maxSize.width = size.maximumWidth
        if let panel, panel.frame.width > size.maximumWidth {
            applyPanelSize(size: NSSize(width: size.maximumWidth, height: panel.frame.height), to: panel)
        }
    }

    var maximumSuperStealthTextWidth: CGFloat {
        guard let panel else { return superStealthDisplaySize.maximumWidth - 32 }
        let screenWidth = (panel.screen ?? NSScreen.main)?.visibleFrame.width ?? superStealthDisplaySize.maximumWidth
        return max(120, min(screenWidth - 28, superStealthDisplaySize.maximumWidth) - 32)
    }

    func adjustSuperStealthWidth(for measuredTextWidth: CGFloat) {
        guard superStealthMode, let panel else { return }
        let screenWidth = (panel.screen ?? NSScreen.main)?.visibleFrame.width ?? SuperStealthDisplaySize.widthRange.upperBound
        let availableWidth = min(screenWidth - 28, superStealthDisplaySize.maximumWidth)
        let minimumWidth = min(superStealthDisplaySize.width, availableWidth)
        let targetWidth = min(max(measuredTextWidth + 32, minimumWidth), availableWidth)
        guard abs(panel.frame.width - targetWidth) > 2 else { return }
        applyPanelSize(size: NSSize(width: targetWidth, height: panel.frame.height))
    }

    func setHidesOnAppResignActive(_ enabled: Bool) {
        hidesOnAppResignActive = enabled
        defaults.set(enabled, forKey: Keys.hidesOnAppResignActive)
        // Focus loss is handled manually to allow an optional short fade-out.
        panel?.hidesOnDeactivate = false
    }

    func setFocusShield(delay: Double, usesFade: Bool) {
        focusShieldDelay = min(max(delay, FloatingReaderFocusShieldSettings.delayRange.lowerBound), FloatingReaderFocusShieldSettings.delayRange.upperBound)
        usesFocusShieldFade = usesFade
        FloatingReaderFocusShieldSettings.save(delay: focusShieldDelay, usesFade: usesFade, to: defaults)
    }

    func setShortcut(_ selectedShortcut: StealthShortcut, for action: StealthShortcutAction) {
        let current = shortcut(for: action)
        guard current != selectedShortcut else { return }

        if let occupiedAction = StealthShortcutAction.allCases.first(where: { $0 != action && self.shortcut(for: $0) == selectedShortcut }) {
            assign(current, to: occupiedAction)
        }
        assign(selectedShortcut, to: action)
        registerGlobalHotKeys()
    }

    func shortcut(for action: StealthShortcutAction) -> StealthShortcut {
        switch action {
        case .previous: previousShortcut
        case .next: nextShortcut
        case .hide: toggleShortcut
        }
    }

    private func handleKeyboardEvent(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers == [.command], event.charactersIgnoringModifiers?.lowercased() == "f" {
            NotificationCenter.default.post(name: .gridnoteStealthSearchRequested, object: nil)
            return true
        }
        if modifiers == [.command], event.charactersIgnoringModifiers?.lowercased() == "b" {
            viewModel.toggleBookmark()
            return true
        }
        guard modifiers.isEmpty else { return false }
        switch event.keyCode {
        case 123: viewModel.previous(); return true // Left arrow.
        case 124, 49: viewModel.next(); return true // Right arrow or space.
        case 53: hide(); return true // Escape.
        default: return false
        }
    }

    private func handleOfficeKeyboardEvent(_ event: NSEvent) -> Bool {
        guard NSApp.isActive else { return false }
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers == [.command] else { return false }
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "f":
            NotificationCenter.default.post(name: .gridnoteOfficeSearchRequested, object: nil)
            return true
        case "b":
            NotificationCenter.default.post(name: .gridnoteOfficeBookmarkRequested, object: nil)
            return true
        default:
            return false
        }
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 230),
            styleMask: [.nonactivatingPanel, .borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: StealthOverlayView(controller: self, viewModel: viewModel))
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = !superStealthMode
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.delegate = self
        panel.hidesOnDeactivate = false
        panel.isRestorable = false
        updatePanelSizingForCurrentMode(panel)

        if let visibleFrame = NSScreen.main?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x: visibleFrame.midX - panel.frame.width / 2, y: visibleFrame.maxY - panel.frame.height - 28))
        }
        self.panel = panel
        return panel
    }

    private func updatePanelSizingForCurrentMode(_ targetPanel: NSPanel? = nil) {
        guard let panel = targetPanel ?? panel else { return }
        if superStealthMode {
            panel.minSize = NSSize(width: SuperStealthDisplaySize.widthRange.lowerBound, height: SuperStealthDisplaySize.heightRange.lowerBound)
            panel.maxSize = NSSize(width: superStealthDisplaySize.maximumWidth, height: SuperStealthDisplaySize.heightRange.upperBound)
            applyPanelSize(size: NSSize(width: superStealthDisplaySize.width, height: superStealthDisplaySize.height), to: panel)
        } else {
            panel.minSize = NSSize(width: 520, height: 190)
            panel.maxSize = NSSize(width: 1400, height: 720)
            let size = NSSize(width: max(panel.frame.width, 520), height: max(panel.frame.height, 190))
            applyPanelSize(size: size, to: panel)
        }
    }

    private func applyPanelSize(size: NSSize, to targetPanel: NSPanel? = nil) {
        guard let panel = targetPanel ?? panel else { return }
        let currentFrame = panel.frame
        // Keep the text's top edge stable while the visible range grows or shrinks.
        let frame = NSRect(
            x: currentFrame.minX,
            y: currentFrame.maxY - size.height,
            width: size.width,
            height: size.height
        )
        panel.setFrame(frame, display: true, animate: false)
    }

    private func assign(_ shortcut: StealthShortcut, to action: StealthShortcutAction) {
        switch action {
        case .previous:
            previousShortcut = shortcut
            defaults.set(shortcut.rawValue, forKey: Keys.previousShortcut)
        case .next:
            nextShortcut = shortcut
            defaults.set(shortcut.rawValue, forKey: Keys.nextShortcut)
        case .hide:
            toggleShortcut = shortcut
            defaults.set(shortcut.rawValue, forKey: Keys.toggleShortcut)
        }
    }

    private func installGlobalHotKeyHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }
                var identifier = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &identifier
                )
                guard status == noErr, let action = StealthShortcutAction(rawValue: Int(identifier.id)) else { return noErr }
                let controller = Unmanaged<StealthOverlayController>.fromOpaque(userData).takeUnretainedValue()
                Task { @MainActor in controller.performGlobalAction(action) }
                return noErr
            },
            1,
            &eventType,
            context,
            &globalHotKeyHandler
        )
    }

    private func registerGlobalHotKeys() {
        globalHotKeyReferences.forEach { UnregisterEventHotKey($0) }
        globalHotKeyReferences.removeAll()
        for action in StealthShortcutAction.allCases {
            let shortcut = shortcut(for: action)
            var reference: EventHotKeyRef?
            let identifier = EventHotKeyID(signature: OSType(0x474E5354), id: UInt32(action.rawValue)) // "GNST"
            let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, identifier, GetApplicationEventTarget(), 0, &reference)
            if status == noErr, let reference { globalHotKeyReferences.append(reference) }
        }
    }

    private func performGlobalAction(_ action: StealthShortcutAction) {
        switch StealthShortcutRouter.route(
            for: action,
            isFloatingReaderVisible: panel?.isVisible == true,
            isGridnoteActive: NSApp.isActive
        ) {
        case .floatingReader:
            if action == .previous { previous() }
            if action == .next { next() }
        case .officeWorkspace:
            let notification: Notification.Name = action == .previous
                ? .gridnoteOfficePreviousExcerptRequested
                : .gridnoteOfficeNextExcerptRequested
            NotificationCenter.default.post(name: notification, object: nil)
        case .toggleFloatingReader:
            toggleVisibility()
        case .none:
            break
        }
    }

    private func hideForFocusLoss() {
        guard hidesOnAppResignActive else { return }
        NotificationCenter.default.post(name: .gridnotePrivacyShieldRequested, object: nil)
        guard let panel, panel.isVisible else { return }
        focusHideTask?.cancel()
        let delay = focusShieldDelay
        let usesFade = usesFocusShieldFade
        focusHideTask = Task { @MainActor in
            if delay > 0 {
                try? await Task.sleep(for: .seconds(delay))
            }
            guard !Task.isCancelled else { return }
            if usesFade {
                await NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.14
                    panel.animator().alphaValue = 0
                }
                guard !Task.isCancelled else { return }
            }
            panel.orderOut(nil)
            panel.alphaValue = 1
        }
    }
}

extension Notification.Name {
    static let gridnoteStealthSearchRequested = Notification.Name("GridnoteStealthSearchRequested")
    static let gridnotePrivacyShieldRequested = Notification.Name("GridnotePrivacyShieldRequested")
    static let gridnoteOfficePreviousExcerptRequested = Notification.Name("GridnoteOfficePreviousExcerptRequested")
    static let gridnoteOfficeNextExcerptRequested = Notification.Name("GridnoteOfficeNextExcerptRequested")
    static let gridnoteOfficeSearchRequested = Notification.Name("GridnoteOfficeSearchRequested")
    static let gridnoteOfficeBookmarkRequested = Notification.Name("GridnoteOfficeBookmarkRequested")
}
