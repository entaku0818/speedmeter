//
//  PaywallView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI

enum PlanType: String, CaseIterable {
    case monthly
    case annual

    var identifier: String {
        switch self {
        case .monthly: return "$rc_monthly"
        case .annual: return "$rc_annual"
        }
    }
}

struct PlanInfo {
    let type: PlanType
    let name: String
    let price: String
    let period: String
    let savings: String?
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var purchaseManager = PurchaseManager.shared

    @State private var selectedPlan: PlanType = .annual
    @State private var plans: [PlanInfo] = []
    @State private var isLoading = true
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)

                            Text("Speedmeter Pro")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("すべての機能をアンロック")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 32)

                        // Features
                        VStack(spacing: 12) {
                            FeatureRow(
                                icon: "xmark.circle.fill",
                                iconColor: .red,
                                title: "広告非表示",
                                description: "バナー広告を完全に削除"
                            )

                            FeatureRow(
                                icon: "clock.arrow.circlepath",
                                iconColor: .blue,
                                title: "履歴件数カスタマイズ",
                                description: "100件〜無制限まで自由に設定"
                            )

                            FeatureRow(
                                icon: "paintpalette.fill",
                                iconColor: .purple,
                                title: "テーマカスタマイズ",
                                description: "5種類の背景テーマから選択"
                            )

                            FeatureRow(
                                icon: "apps.iphone",
                                iconColor: .green,
                                title: "ウィジェット",
                                description: "ホーム画面に速度を表示（近日公開）"
                            )
                        }
                        .padding(.horizontal)

                        // Plan Selection
                        if isLoading {
                            ProgressView()
                                .padding()
                        } else {
                            HStack(spacing: 12) {
                                ForEach(plans, id: \.type) { plan in
                                    PlanCard(
                                        plan: plan,
                                        isSelected: selectedPlan == plan.type,
                                        onTap: { selectedPlan = plan.type }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Purchase Button
                        Button {
                            Task {
                                await purchase()
                            }
                        } label: {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Proにアップグレード")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isPurchasing || isLoading)
                        .padding(.horizontal)

                        // Restore Button
                        Button {
                            Task {
                                await restore()
                            }
                        } label: {
                            Text("購入を復元")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .disabled(isPurchasing)

                        // Terms
                        VStack(spacing: 4) {
                            Text("サブスクリプションはiTunesアカウントに請求されます。")
                            Text("期間終了の24時間前までにキャンセルしない限り自動更新されます。")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "不明なエラーが発生しました")
            }
            .task {
                await loadProducts()
            }
            .onChange(of: purchaseManager.isPremium) { _, isPremium in
                if isPremium {
                    dismiss()
                }
            }
        }
    }

    private func loadProducts() async {
        isLoading = true
        do {
            let loadedPlans = try await purchaseManager.fetchAllPlans()
            await MainActor.run {
                plans = loadedPlans
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func purchase() async {
        isPurchasing = true
        do {
            try await purchaseManager.purchase(plan: selectedPlan)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        await MainActor.run {
            isPurchasing = false
        }
    }

    private func restore() async {
        isPurchasing = true
        do {
            try await purchaseManager.restorePurchases()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        await MainActor.run {
            isPurchasing = false
        }
    }
}

struct PlanCard: View {
    let plan: PlanInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                if let savings = plan.savings {
                    Text(savings)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                } else {
                    Text(" ")
                        .font(.caption2)
                        .padding(.vertical, 4)
                }

                Text(plan.period)
                    .font(.headline)

                Text(plan.price)
                    .font(.title3)
                    .fontWeight(.bold)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground).opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(12)
    }
}

#Preview {
    PaywallView()
}
