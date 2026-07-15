import AppKit
import SwiftUI

struct StealthMenuBarView: View {
    @EnvironmentObject private var stealthController: StealthOverlayController

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            header
            progressCard
            primaryControls

            if stealthController.superStealthMode {
                stealthStatus
            }

            if !stealthController.viewModel.chapters.isEmpty {
                chapterMenu
            }

            Divider()
            Button {
                openDataHub()
            } label: {
                Label("打开数据中心", systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(15)
        .frame(width: 320)
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.accentColor.gradient)
                Image(systemName: "tablecells")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("工作区控制").font(.headline)
                Text(stealthController.superStealthMode ? "精简显示已开启" : "记录面板待命")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("本地")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05), in: Capsule())
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stealthController.viewModel.progressDetailText.isEmpty ? "尚未开始阅读" : stealthController.viewModel.progressDetailText)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Text("\(Int((stealthController.viewModel.progressFraction * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: stealthController.viewModel.progressFraction)
                .progressViewStyle(.linear)
                .controlSize(.small)
        }
        .padding(12)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var primaryControls: some View {
        HStack(spacing: 8) {
            controlButton("chevron.backward", title: "上一页", shortcut: stealthController.previousShortcut.title) {
                stealthController.previous()
            }
            controlButton("rectangle.on.rectangle", title: "显示", shortcut: stealthController.toggleShortcut.title) {
                stealthController.toggleVisibility()
            }
            controlButton("chevron.forward", title: "下一页", shortcut: stealthController.nextShortcut.title) {
                stealthController.next()
            }
        }
    }

    private func controlButton(_ icon: String, title: String, shortcut: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(title).font(.caption.weight(.medium))
                Text(shortcut).font(.system(size: 9, design: .monospaced)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var stealthStatus: some View {
        Label("精简显示中，边框与组件已隐藏", systemImage: "rectangle.dashed")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
    }

    private var chapterMenu: some View {
        Menu {
            ForEach(stealthController.viewModel.chapters) { chapter in
                Button(chapter.title) { stealthController.viewModel.jump(to: chapter) }
            }
        } label: {
            Label("跳转章节", systemImage: "list.bullet.rectangle")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .menuStyle(.borderlessButton)
    }

    private func openDataHub() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
    }
}
