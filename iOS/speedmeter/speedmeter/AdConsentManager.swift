//
//  AdConsentManager.swift
//  speedmeter
//
//  UMP (User Messaging Platform) の同意フロー。
//  EEA/UK/規制対象の米州では、同意情報が無いまま広告をリクエストすると
//  配信できる需要が大きく減り、充填率(fill rate)が落ちる。
//

import Combine
import Foundation
import UserMessagingPlatform
import UIKit
import os.log

@MainActor
final class AdConsentManager: ObservableObject {
    static let shared = AdConsentManager()

    private let logger = OSLog(subsystem: "com.entaku.speedmeter", category: "AdConsent")

    /// 広告をリクエストしてよいか（EEA外では既定で true）
    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    /// 設定画面に「プライバシー設定」を出す必要があるか（EEA等でのみ true）
    var isPrivacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private init() {}

    /// 同意情報を更新し、必要ならフォームを提示する。
    /// エラーが出ても握りつぶして続行する（同意不要地域では何も起きない）。
    func gatherConsent() async {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        #if DEBUG
        // シミュレータをEEA扱いにして同意フォームを検証できるようにする
        let debugSettings = DebugSettings()
        debugSettings.geography = .disabled
        parameters.debugSettings = debugSettings
        #endif

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
        } catch {
            os_log("requestConsentInfoUpdate failed: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
            return
        }

        guard let rootViewController = Self.topViewController() else {
            os_log("No root view controller for consent form", log: logger, type: .error)
            return
        }

        do {
            try await ConsentForm.loadAndPresentIfRequired(from: rootViewController)
        } catch {
            os_log("loadAndPresentIfRequired failed: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
        }

        os_log("Consent gathered. canRequestAds=%{public}@",
               log: logger, type: .debug, String(describing: canRequestAds))
    }

    /// 設定画面から呼ぶ。ユーザーが同意内容を変更できる。
    func presentPrivacyOptionsForm() async {
        guard let rootViewController = Self.topViewController() else { return }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: rootViewController)
        } catch {
            os_log("presentPrivacyOptionsForm failed: %{public}@",
                   log: logger, type: .error, error.localizedDescription)
        }
    }

    static func topViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        var controller = keyWindow?.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        return controller
    }
}
