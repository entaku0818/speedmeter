//
//  PurchaseManager.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import StoreKit
import RevenueCat
import Combine
import os.log

protocol PurchaseManagerProtocol {
    func fetchAllPlans() async throws -> [PlanInfo]
    func purchase(plan: PlanType) async throws
    func restorePurchases() async throws
}

class PurchaseManager: PurchaseManagerProtocol, ObservableObject {
    private let logger = OSLog(subsystem: "com.entaku.speedmeter", category: "Purchase")
    static let shared = PurchaseManager()

    @Published var isPremium: Bool = false

    private init() {
        isPremium = UserDefaults.standard.bool(forKey: "hasPurchasedPremium")
    }

    enum PurchaseError: Error, LocalizedError {
        case productNotFound
        case purchaseFailed
        case noEntitlements

        var errorDescription: String? {
            switch self {
            case .productNotFound:
                return "製品が見つかりません"
            case .purchaseFailed:
                return "購入に失敗しました"
            case .noEntitlements:
                return "有効なサブスクリプションが見つかりません"
            }
        }
    }

    func fetchAllPlans() async throws -> [PlanInfo] {
        os_log("=== Fetch All Plans Start ===", log: logger, type: .debug)
        let offerings = try await Purchases.shared.offerings()

        guard let offering = offerings.current else {
            os_log("No current offering found", log: logger, type: .error)
            throw PurchaseError.productNotFound
        }

        var plans: [PlanInfo] = []

        // 年額プラン
        if let annualPackage = offering.availablePackages.first(where: { $0.identifier == "$rc_annual" }) {
            let plan = PlanInfo(
                type: .annual,
                name: annualPackage.storeProduct.localizedTitle,
                price: annualPackage.localizedPriceString,
                period: "年額",
                savings: "2ヶ月分お得"
            )
            plans.append(plan)
            os_log("Found annual package: %{public}@", log: logger, type: .debug, annualPackage.identifier)
        }

        // 月額プラン
        if let monthlyPackage = offering.availablePackages.first(where: { $0.identifier == "$rc_monthly" }) {
            let plan = PlanInfo(
                type: .monthly,
                name: monthlyPackage.storeProduct.localizedTitle,
                price: monthlyPackage.localizedPriceString,
                period: "月額",
                savings: nil
            )
            plans.append(plan)
            os_log("Found monthly package: %{public}@", log: logger, type: .debug, monthlyPackage.identifier)
        }

        if plans.isEmpty {
            throw PurchaseError.productNotFound
        }

        return plans
    }

    // 古いAPI（互換性のため）
    func fetchProPlan() async throws -> (name: String, price: String) {
        let plans = try await fetchAllPlans()
        guard let monthly = plans.first(where: { $0.type == .monthly }) else {
            throw PurchaseError.productNotFound
        }
        return (name: monthly.name, price: monthly.price)
    }

    func purchase(plan: PlanType) async throws {
        os_log("=== Purchase %{public}@ Start ===", log: logger, type: .debug, plan.rawValue)
        let offerings = try await Purchases.shared.offerings()

        guard let offering = offerings.current,
              let package = offering.availablePackages.first(where: { $0.identifier == plan.identifier }) else {
            os_log("Package not found: %{public}@", log: logger, type: .error, plan.identifier)
            throw PurchaseError.productNotFound
        }

        do {
            let (_, customerInfo, _) = try await Purchases.shared.purchase(package: package)

            if customerInfo.entitlements["Speedmeter Premium"]?.isActive == true {
                await MainActor.run {
                    self.isPremium = true
                    UserDefaults.standard.set(true, forKey: "hasPurchasedPremium")
                }
                os_log("Purchase successful", log: logger, type: .debug)
            } else {
                os_log("Purchase failed: premium not active", log: logger, type: .error)
                throw PurchaseError.purchaseFailed
            }
        } catch {
            os_log("Purchase failed: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw PurchaseError.purchaseFailed
        }
    }

    // 古いAPI（互換性のため）
    func purchasePro() async throws {
        try await purchase(plan: .monthly)
    }

    func restorePurchases() async throws {
        os_log("=== Restore Purchases Start ===", log: logger, type: .debug)
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            if customerInfo.entitlements["Speedmeter Premium"]?.isActive == true {
                await MainActor.run {
                    self.isPremium = true
                    UserDefaults.standard.set(true, forKey: "hasPurchasedPremium")
                }
                os_log("Restore successful", log: logger, type: .debug)
            } else {
                os_log("Restore failed: no entitlements found", log: logger, type: .error)
                throw PurchaseError.noEntitlements
            }
        } catch {
            os_log("Restore failed: %{public}@", log: logger, type: .error, error.localizedDescription)
            throw error
        }
    }

    func checkPremiumStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            let isActive = customerInfo.entitlements["Speedmeter Premium"]?.isActive == true
            await MainActor.run {
                let wasPremiun = self.isPremium
                self.isPremium = isActive
                UserDefaults.standard.set(isActive, forKey: "hasPurchasedPremium")

                // 解約時（Premium→Free）は設定をリセット
                if wasPremiun && !isActive {
                    self.resetSettingsToFree()
                }
            }
        } catch {
            os_log("Failed to check premium status: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
    }

    /// 解約時に設定を無料版にリセット
    private func resetSettingsToFree() {
        FontSettings.shared.resetToFree()
        PremiumSettings.shared.resetToFree()
        os_log("Settings reset to free tier", log: logger, type: .debug)
    }
}
