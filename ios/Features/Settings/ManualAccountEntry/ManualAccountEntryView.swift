import SwiftUI

struct ManualAccountEntryView: View {
    @EnvironmentObject private var portfolioService: PortfolioService
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ManualAccountDraft()
    @State private var message: EntryMessage?
    @State private var isSaving = false

    private var hasExistingAccount: Bool {
        !portfolioService.accounts.isEmpty
    }

    var body: some View {
        List {
            if hasExistingAccount {
                existingAccountSection
            } else {
                accountSection
                holdingsSection
                actionSection
            }
        }
        .scrollContentBackground(.hidden)
        .background(BNTokens.Colors.backgroundElevated)
        .navigationTitle("手动建账")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .alert(item: $message) { entry in
            Alert(
                title: Text(entry.title),
                message: Text(entry.body),
                dismissButton: .default(Text(entry.dismiss)) {
                    if entry.dismissDismissesView { dismiss() }
                }
            )
        }
    }

    private var accountSection: some View {
        Section("账户") {
            TextField("账户名称", text: $draft.displayName)
                .listRowBackground(BNTokens.Colors.surface)

            DatePicker("基线日期", selection: $draft.baselineDate, displayedComponents: .date)
                .listRowBackground(BNTokens.Colors.surface)

            HStack {
                Text("货币")
                    .font(BNTokens.Typography.text(size: 14))
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                Spacer()
                Text(draft.currency)
                    .font(BNTokens.Typography.text(size: 14))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)
            }
            .listRowBackground(BNTokens.Colors.surface)

            TextField("备注（可选）", text: $draft.note)
                .listRowBackground(BNTokens.Colors.surface)
        }
    }

    private var holdingsSection: some View {
        Section {
            ForEach($draft.holdings) { $holding in
                HoldingRowEditor(holding: $holding) {
                    remove(holding)
                }
                .listRowBackground(BNTokens.Colors.surface)
            }

            Button(action: addHolding) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(BNTokens.Colors.accent)
                    Text("添加持仓")
                        .font(BNTokens.Typography.text(size: 14))
                        .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(BNTokens.Colors.surface)
        } header: {
            Text("持仓")
        } footer: {
            Text("份额必填；市值与日净值二选一即可（同时填会按市值入账，nav 仅供参考）。")
                .font(BNTokens.Typography.text(size: 11))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
        }
    }

    private var actionSection: some View {
        Section {
            Button(action: save) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(BNTokens.Colors.accent)
                    Text(isSaving ? "保存中…" : "保存为 baseline 快照")
                        .font(BNTokens.Typography.text(size: 14))
                        .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
            .listRowBackground(BNTokens.Colors.surface)
        }
    }

    private var existingAccountSection: some View {
        Section("已建账户") {
            ForEach(portfolioService.accounts) { account in
                let baseline = account.snapshots.first(where: \.isBaseline)
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.displayName)
                        .font(BNTokens.Typography.text(size: 14))
                        .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                    Text(detail(for: account, baseline: baseline))
                        .font(BNTokens.Typography.text(size: 12))
                        .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                }
                .listRowBackground(BNTokens.Colors.surface)
            }

            Text("当前版本仅支持首次建账。后续编辑/添加持仓请走 JSON 导入，或等待下一刀。")
                .font(BNTokens.Typography.text(size: 11))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                .listRowBackground(BNTokens.Colors.surface)
        }
    }

    private func detail(for account: PortfolioAccount, baseline: PortfolioSnapshot?) -> String {
        let baselineText: String
        if let baseline {
            baselineText = "baseline \(ImportDateFormatter.dayString(baseline.date)) · \(baseline.holdings.count) 持仓"
        } else {
            baselineText = "无 baseline"
        }
        return "\(account.accountID) · \(baselineText)"
    }

    private func addHolding() {
        BNHaptics.tap()
        draft.holdings.append(ManualHoldingDraft())
    }

    private func remove(_ holding: ManualHoldingDraft) {
        guard draft.holdings.count > 1 else { return }
        draft.holdings.removeAll { $0.id == holding.id }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let data = try draft.makeImportJSONData()
            let preview = ImportService.preview(data: data)
            guard preview.canCommit else {
                let detail = preview.fatalIssues.map(\.message).joined(separator: "\n")
                message = EntryMessage(title: "校验未通过", body: detail.isEmpty ? "请检查表单内容。" : detail)
                return
            }

            let summary = try portfolioService.commit(preview)
            BNHaptics.success()
            message = EntryMessage(
                title: "已保存",
                body: "\(draft.displayName) · baseline \(ImportDateFormatter.dayString(draft.baselineDate))，\(summary.insertedSnapshots) 快照写入。",
                dismiss: "完成",
                dismissDismissesView: true
            )
        } catch let error as ManualAccountDraft.DraftError {
            message = EntryMessage(title: "表单不完整", body: error.localizedDescription ?? "请检查输入。")
        } catch {
            message = EntryMessage(title: "保存失败", body: error.localizedDescription)
        }
    }
}

private struct HoldingRowEditor: View {
    @Binding var holding: ManualHoldingDraft
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("代码（如 510300）", text: $holding.code)
                    .font(BNTokens.Typography.number(size: 14, weight: .medium))
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "minus.circle")
                        .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                }
                .buttonStyle(.plain)
            }

            TextField("基金名称（可选）", text: $holding.name)
                .font(BNTokens.Typography.text(size: 13))

            HStack {
                TextField("份额", text: $holding.sharesText)
                    .keyboardType(.decimalPad)
                    .font(BNTokens.Typography.number(size: 14))
                TextField("市值（元）", text: $holding.valueText)
                    .keyboardType(.decimalPad)
                    .font(BNTokens.Typography.number(size: 14))
                TextField("日净值", text: $holding.navText)
                    .keyboardType(.decimalPad)
                    .font(BNTokens.Typography.number(size: 14))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct EntryMessage: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    var dismiss: String = "知道了"
    var dismissDismissesView: Bool = false
}
