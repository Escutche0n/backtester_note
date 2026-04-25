import SwiftUI

struct SettingsSheet: View {
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
            SettingsRow(title: "导入模板", value: "3 个", systemImage: "square.and.arrow.down")
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
}

private struct SettingsRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(BNTokens.Colors.foregroundSecondary)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
        }
        .listRowBackground(BNTokens.Colors.surface)
    }
}

#Preview {
    SettingsSheet()
}
