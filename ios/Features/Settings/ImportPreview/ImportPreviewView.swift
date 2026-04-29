import SwiftUI

struct ImportPreviewView: View {
    let preview: ImportPreview
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var portfolioService: PortfolioService
    @State private var commitSummary: PortfolioCommitSummary?
    @State private var commitError: String?
    @State private var pendingPlan: PortfolioCommitPlan?

    var body: some View {
        NavigationStack {
            List {
                summarySection

                if !preview.fatalIssues.isEmpty {
                    issueSection("必须修复", issues: preview.fatalIssues, color: BNTokens.Colors.up)
                }

                if !preview.warnings.isEmpty {
                    issueSection("提示", issues: preview.warnings, color: BNTokens.Colors.accent)
                }

                accountsSection
                commitSection
            }
            .scrollContentBackground(.hidden)
            .background(BNTokens.Colors.backgroundElevated)
            .navigationTitle("导入预览")
            .preferredColorScheme(.dark)
            .alert("写入失败", isPresented: commitErrorBinding) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(commitError ?? "")
            }
            .confirmationDialog(
                "确认写入",
                isPresented: pendingPlanBinding,
                titleVisibility: .visible
            ) {
                Button("继续写入", role: .destructive) {
                    commitPreview(allowOverwriteAfterLoadFailure: true)
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text(pendingPlanMessage)
            }
        }
    }

    private var summarySection: some View {
        Section("摘要") {
            LabeledContent("状态", value: preview.canCommit ? "可导入" : "不可导入")
            LabeledContent("账户", value: "\(preview.accountSummaries.count)")
            LabeledContent("快照", value: "\(preview.snapshotCount)")
            LabeledContent("流水", value: "\(preview.flowCount)")
        }
        .listRowBackground(BNTokens.Colors.surface)
    }

    private func issueSection(_ title: String, issues: [ImportIssue], color: Color) -> some View {
        Section(title) {
            ForEach(issues) { issue in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 7, height: 7)
                        .padding(.top, 6)

                    Text(issue.message)
                        .font(BNTokens.Typography.text(size: 13))
                        .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                }
            }
        }
        .listRowBackground(BNTokens.Colors.surface)
    }

    private var accountsSection: some View {
        Section("将写入 / 更新") {
            ForEach(preview.accountSummaries) { account in
                VStack(alignment: .leading, spacing: 6) {
                    Text(account.displayName)
                        .font(BNTokens.Typography.text(size: 15))
                        .foregroundStyle(BNTokens.Colors.foregroundPrimary)

                    if let baselineDate = account.baselineDate {
                        Text("baseline \(ImportDateFormatter.dayString(baselineDate))")
                            .bnNumeric(12)
                            .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                    }

                    Text("\(account.snapshotCount) snapshots · \(account.flowCount) flows · \(account.holdingCount) holdings")
                        .bnNumeric(12)
                        .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .listRowBackground(BNTokens.Colors.surface)
    }

    private var commitSection: some View {
        Section {
            if let commitSummary {
                commitResult(summary: commitSummary)
            } else {
                Button("确认写入") {
                    beginCommit()
                }
                .disabled(!preview.canCommit)
            }
        } footer: {
            Text("确认后会写入本机 PortfolioService；预览阶段不会改动本地数据。")
        }
        .listRowBackground(BNTokens.Colors.surface)
    }

    private func commitResult(summary: PortfolioCommitSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已写入")
                .font(BNTokens.Typography.text(size: 15))
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)

            Text("新增快照 \(summary.insertedSnapshots)，更新快照 \(summary.updatedSnapshots)，新增流水 \(summary.insertedFlows)，跳过重复流水 \(summary.skippedFlows)")
                .bnNumeric(12)
                .foregroundStyle(BNTokens.Colors.foregroundSecondary)

            if summary.baselineMoved,
               let oldDate = summary.oldBaselineDate,
               let newDate = summary.newBaselineDate {
                Text("XIRR 基准日 \(ImportDateFormatter.dayString(oldDate)) → \(ImportDateFormatter.dayString(newDate))")
                    .bnNumeric(12)
                    .foregroundStyle(BNTokens.Colors.accent)
            }

            Button("完成") {
                dismiss()
            }
        }
        .padding(.vertical, 4)
    }

    private var commitErrorBinding: Binding<Bool> {
        Binding(
            get: { commitError != nil },
            set: { isPresented in
                if !isPresented {
                    commitError = nil
                }
            }
        )
    }

    private var pendingPlanBinding: Binding<Bool> {
        Binding(
            get: { pendingPlan != nil },
            set: { isPresented in
                if !isPresented {
                    pendingPlan = nil
                }
            }
        )
    }

    private var pendingPlanMessage: String {
        guard let pendingPlan else { return "" }

        var messages: [String] = []
        if pendingPlan.summary.baselineMoved,
           let oldDate = pendingPlan.summary.oldBaselineDate,
           let newDate = pendingPlan.summary.newBaselineDate {
            messages.append("XIRR 基准日将从 \(ImportDateFormatter.dayString(oldDate)) 改为 \(ImportDateFormatter.dayString(newDate))，历史 NAV 曲线会重算，是否继续？")
        }
        if pendingPlan.hasStoreLoadError {
            messages.append("本地持仓文件加载失败。继续写入会覆盖当前损坏文件。")
        }
        return messages.joined(separator: "\n\n")
    }

    private func beginCommit() {
        do {
            let plan = try portfolioService.previewCommit(preview)
            if plan.needsConfirmation {
                pendingPlan = plan
            } else {
                commitPreview(allowOverwriteAfterLoadFailure: false)
            }
        } catch {
            commitError = error.localizedDescription
        }
    }

    private func commitPreview(allowOverwriteAfterLoadFailure: Bool) {
        do {
            BNHaptics.success()
            pendingPlan = nil
            commitSummary = try portfolioService.commit(
                preview,
                allowOverwriteAfterLoadFailure: allowOverwriteAfterLoadFailure
            )
        } catch {
            commitError = error.localizedDescription
        }
    }
}

#Preview {
    ImportPreviewView(
        preview: ImportService.preview(
            data: """
            {
              "schema": "backtester-note/import/v1",
              "exported_at": "2026-04-25T00:00:00+08:00",
              "source": "user_manual",
              "accounts": [{
                "account_id": "default",
                "display_name": "主账户",
                "currency": "CNY",
                "snapshots": [{
                  "date": "2024-01-01",
                  "is_baseline": true,
                  "holdings": [{
                    "code": "510300",
                    "name": "沪深300ETF",
                    "shares": 1000,
                    "value": 4200
                  }]
                }],
                "flows": []
              }]
            }
            """.data(using: .utf8)!
        )
    )
    .environmentObject(
        PortfolioService(
            store: PortfolioFileStore(
                fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("preview.json")
            )
        )
    )
}
