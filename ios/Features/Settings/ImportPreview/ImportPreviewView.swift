import SwiftUI

struct ImportPreviewView: View {
    let preview: ImportPreview

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
            Button("确认写入（Persistence 待 1d 接入）") {}
                .disabled(true)
        } footer: {
            Text("本阶段只做预览与校验，不写入持久化存储。")
        }
        .listRowBackground(BNTokens.Colors.surface)
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
}
