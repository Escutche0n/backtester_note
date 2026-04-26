import SwiftUI
import UniformTypeIdentifiers

struct SettingsSheet: View {
    @State private var importing = false
    @State private var preview: ImportPreview?
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            List {
                accountSection
                dataSection
                cacheSection
                shortcutsSection
                widgetsSection
                appearanceSection
                subscriptionSection
            }
            .scrollContentBackground(.hidden)
            .background(BNTokens.Colors.backgroundElevated)
            .navigationTitle("设置")
            .preferredColorScheme(.dark)
            .fileImporter(
                isPresented: $importing,
                allowedContentTypes: [.json, .plainText],
                allowsMultipleSelection: false,
                onCompletion: handleImportResult
            )
            .sheet(item: $preview) { preview in
                ImportPreviewView(preview: preview)
            }
            .alert("导入失败", isPresented: importErrorBinding) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(importError ?? "")
            }
        }
    }

    private var accountSection: some View {
        Section("账户") {
            SettingsRow(title: "主账户", value: "elvis · 默认", systemImage: "person.crop.circle")
            SettingsRow(title: "账户数量", value: "1 / 3", systemImage: "tray.full")
        }
    }

    private var dataSection: some View {
        Section("数据维护") {
            SettingsRow(title: "快照 / 流水 / 对账", value: "待核对 2 条", systemImage: "checklist")
            SettingsRow(title: "官方净值更新", value: "今天 15:32", systemImage: "arrow.triangle.2.circlepath")
            SettingsRow(title: "盘中估值", value: "手动刷新", systemImage: "clock")
        }
    }

    private var cacheSection: some View {
        Section("缓存") {
            SettingsRow(title: "本地缓存", value: "128.4 MB", systemImage: "internaldrive")
            SettingsRow(title: "历史净值窗口", value: "最近 1 年", systemImage: "calendar")
        }
    }

    private var shortcutsSection: some View {
        Section("快捷指令 & JSON 导入") {
            Button {
                BNHaptics.tap()
                importing = true
            } label: {
                SettingsRow(title: "选择 JSON 文件", value: "预览", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.plain)
            SettingsRow(title: "最近导入", value: "暂无", systemImage: "doc.text")
        }
    }

    private var widgetsSection: some View {
        Section("Widgets 管理 & 同步状态") {
            SettingsRow(title: "组件同步", value: "iOS 默认", systemImage: "square.grid.2x2")
            SettingsRow(title: "最近同步", value: "04-25 15:32", systemImage: "wave.3.right")
        }
    }

    private var appearanceSection: some View {
        Section("外观") {
            SettingsRow(title: "密度 / 填充 / 强调色", value: "Pro 占位", systemImage: "paintpalette")
        }
    }

    private var subscriptionSection: some View {
        Section("订阅") {
            SettingsRow(title: "Pro", value: "即将推出", systemImage: "sparkles")
        }
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { isPresented in
                if !isPresented {
                    importError = nil
                }
            }
        )
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else {
                return
            }

            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            preview = ImportService.preview(data: data)
        } catch {
            importError = error.localizedDescription
        }
    }
}

private struct SettingsRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(BNTokens.Typography.text(size: 15))
                .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                .frame(width: 24)

            Text(title)
                .font(BNTokens.Typography.text(size: 14))
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)

            Spacer()

            Text(value)
                .font(BNTokens.Typography.text(size: 12))
                .foregroundStyle(BNTokens.Colors.foregroundSecondary)

            Image(systemName: "chevron.right")
                .font(BNTokens.Typography.text(size: 11))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
        }
        .listRowBackground(BNTokens.Colors.surface)
    }
}

#Preview {
    SettingsSheet()
}
