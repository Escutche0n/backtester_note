import SwiftUI

struct DataMaintenanceView: View {
    @EnvironmentObject private var portfolioService: PortfolioService
    @EnvironmentObject private var fundNAVService: FundNAVService

    @State private var selectedCode = ""
    @State private var selectedDate = Date()
    @State private var navText = ""
    @State private var message: MaintenanceMessage?
    @State private var recordPendingDeletion: FundDailyNAVRecord?

    private var fundCodes: [String] {
        let holdings = portfolioService.accounts.flatMap { account in
            account.snapshots.flatMap(\.holdings)
        }
        let flows = portfolioService.accounts.flatMap { account in
            account.flows.map(\.code)
        }
        return Array(Set(holdings.map(\.code) + flows)).sorted()
    }

    private var records: [FundDailyNAVRecord] {
        fundNAVService.records.sorted {
            if $0.code == $1.code { return $0.date > $1.date }
            return $0.code < $1.code
        }
    }

    var body: some View {
        List {
            entrySection
            recordsSection
        }
        .scrollContentBackground(.hidden)
        .background(BNTokens.Colors.backgroundElevated)
        .navigationTitle("数据维护")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear(perform: selectDefaultCode)
        .alert(item: $message) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.body),
                dismissButton: .default(Text("知道了"))
            )
        }
        .confirmationDialog(
            "删除这条日净值？",
            isPresented: deletionPresented,
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive, action: deletePendingRecord)
            Button("取消", role: .cancel) {}
        } message: {
            if let recordPendingDeletion {
                Text("\(recordPendingDeletion.code) · \(recordPendingDeletion.dateKey) · \(FundNAVDecimal.string(recordPendingDeletion.nav))")
            }
        }
    }

    private var entrySection: some View {
        Section("手动日净值") {
            if fundCodes.isEmpty {
                Text("导入持仓后可录入基金日净值")
                    .font(BNTokens.Typography.text(size: 13))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                    .listRowBackground(BNTokens.Colors.surface)
            } else {
                Picker("基金代码", selection: $selectedCode) {
                    ForEach(fundCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .listRowBackground(BNTokens.Colors.surface)

                DatePicker("日期", selection: $selectedDate, displayedComponents: .date)
                    .listRowBackground(BNTokens.Colors.surface)

                TextField("净值，最多 4 位小数", text: $navText)
                    .keyboardType(.decimalPad)
                    .font(BNTokens.Typography.number(size: 16, weight: .semibold))
                    .listRowBackground(BNTokens.Colors.surface)

                Button(action: saveRecord) {
                    SettingsActionRow(title: "保存日净值", systemImage: "checkmark.circle.fill")
                }
                .disabled(!canSave)
                .buttonStyle(.plain)
                .listRowBackground(BNTokens.Colors.surface)
            }
        }
    }

    private var recordsSection: some View {
        Section("已录入") {
            if records.isEmpty {
                Text("暂无日净值")
                    .font(BNTokens.Typography.text(size: 13))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                    .listRowBackground(BNTokens.Colors.surface)
            } else {
                ForEach(records) { record in
                    FundNAVRecordRow(record: record) {
                        edit(record)
                    } onDelete: {
                        recordPendingDeletion = record
                    }
                    .listRowBackground(BNTokens.Colors.surface)
                }
            }
        }
    }

    private var canSave: Bool {
        !selectedCode.isEmpty && parsedNAV != nil
    }

    private var parsedNAV: Decimal? {
        let trimmed = navText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, decimalScale(trimmed) <= 4 else {
            return nil
        }
        return FundNAVDecimal.parse(trimmed.replacingOccurrences(of: ",", with: "."))
    }

    private var deletionPresented: Binding<Bool> {
        Binding(
            get: { recordPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    recordPendingDeletion = nil
                }
            }
        )
    }

    private func selectDefaultCode() {
        if selectedCode.isEmpty {
            selectedCode = fundCodes.first ?? ""
        }
    }

    private func saveRecord() {
        guard let nav = parsedNAV else {
            message = MaintenanceMessage(title: "净值格式不正确", body: "请输入大于 0 且最多 4 位小数的日净值。")
            return
        }

        do {
            let record = try fundNAVService.upsert(code: selectedCode, date: selectedDate, nav: nav)
            navText = FundNAVDecimal.string(record.nav)
            message = MaintenanceMessage(title: "已保存", body: "\(record.code) · \(record.dateKey) · \(FundNAVDecimal.string(record.nav))")
            BNHaptics.success()
        } catch {
            message = MaintenanceMessage(title: "保存失败", body: error.localizedDescription)
        }
    }

    private func edit(_ record: FundDailyNAVRecord) {
        selectedCode = record.code
        selectedDate = record.date
        navText = FundNAVDecimal.string(record.nav)
        BNHaptics.tap()
    }

    private func deletePendingRecord() {
        guard let record = recordPendingDeletion else { return }
        do {
            try fundNAVService.delete(code: record.code, date: record.date)
            recordPendingDeletion = nil
            message = MaintenanceMessage(title: "已删除", body: "\(record.code) · \(record.dateKey)")
            BNHaptics.success()
        } catch {
            message = MaintenanceMessage(title: "删除失败", body: error.localizedDescription)
        }
    }

    private func decimalScale(_ text: String) -> Int {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        guard let dot = normalized.firstIndex(of: ".") else {
            return 0
        }
        return normalized.distance(from: normalized.index(after: dot), to: normalized.endIndex)
    }
}

private struct FundNAVRecordRow: View {
    let record: FundDailyNAVRecord
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.code)
                    .font(BNTokens.Typography.text(size: 14))
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                Text(record.dateKey)
                    .font(BNTokens.Typography.text(size: 12))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)
            }

            Spacer()

            Text(FundNAVDecimal.string(record.nav))
                .font(BNTokens.Typography.number(size: 16, weight: .semibold))
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .font(BNTokens.Typography.text(size: 14))
                    .foregroundStyle(BNTokens.Colors.up)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}

private struct SettingsActionRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(BNTokens.Colors.accent)
                .frame(width: 24)
            Text(title)
                .font(BNTokens.Typography.text(size: 14))
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)
            Spacer()
        }
    }
}

private struct MaintenanceMessage: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}
