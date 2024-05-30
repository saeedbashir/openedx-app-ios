//
//  CourseUpgradeHelper.swift
//  Core
//
//  Created by Saeed Bashir on 4/24/24.
//

import Foundation
import StoreKit
import SwiftUI
import MessageUI

public struct CourseUpgradeHelperModel {
    let courseID: String
    let blockID: String?
    let screen: CourseUpgradeScreen
}

public enum UpgradeCompletionState {
    case initial
    case payment
    case fulfillment(showLoader: Bool)
    case success(_ courseID: String, _ componentID: String?)
    case error(UpgradeError)
}

// These error actions are used to send in analytics
public enum UpgradeErrorAction: String {
    case refreshToRetry = "refresh"
    case reloadPrice = "reload_price"
    case emailSupport = "get_help"
    case close = "close"
}

// These alert actions are used to send in analytics
public enum UpgradeAlertAction: String {
    case close
    case continueWithoutUpdate = "continue_without_update"
    case getHelp = "get_help"
    case refresh
}

public enum Pacing: String {
    case selfPace = "self"
    case instructor
}

public protocol CourseUpgradeHelperDelegate: AnyObject {
    func hideAlertAction()
}

public class CourseUpgradeHelper: CourseUpgradeHelperProtocol {
    
    weak private(set) var delegate: CourseUpgradeHelperDelegate?
    private(set) var completion: (() -> Void)?
    private(set) var helperModel: CourseUpgradeHelperModel?
    private(set) var config: ConfigProtocol
    private(set) var analytics: CoreAnalytics
    
    private var pacing: String?
    private var courseID: String?
    private var blockID: String?
    private var screen: CourseUpgradeScreen = .unknown
    private var localizedCoursePrice: String?
    weak private(set) var upgradeHadler: CourseUpgradeHandler?
    private let router: BaseRouter
    
    public init(
        config: ConfigProtocol,
        analytics: CoreAnalytics,
        router: BaseRouter
    ) {
        self.config = config
        self.analytics = analytics
        self.router = router
    }
    
    public func setData(
        courseID: String,
        pacing: String,
        blockID: String? = nil,
        localizedCoursePrice: String,
        screen: CourseUpgradeScreen
    ) {
        self.courseID = courseID
        self.pacing = pacing
        self.blockID = blockID
        self.localizedCoursePrice = localizedCoursePrice
        self.screen = screen
    }
    
    public func handleCourseUpgrade(
        upgradeHadler: CourseUpgradeHandler,
        state: UpgradeCompletionState,
        delegate: CourseUpgradeHelperDelegate? = nil
    ) {
        self.delegate = delegate
        self.upgradeHadler = upgradeHadler
        
        switch state {
        case .fulfillment(let show):
            if show {
                showLoader()
            }
        case .success(let courseID, let blockID):
            helperModel = CourseUpgradeHelperModel(courseID: courseID, blockID: blockID, screen: screen)
            if upgradeHadler.upgradeMode == .userInitiated {
                removeLoader(success: true, removeView: true)
                postSuccessNotification()
            } else {
                showSilentRefreshAlert()
            }
        case .error(let error):
            if case .paymentError = error {
                if error.isCancelled {
                    analytics.trackCourseUpgradePaymentError(
                        .courseUpgradePaymentCancelError,
                        biValue: .courseUpgradePaymentCancelError,
                        courseID: courseID ?? "",
                        blockID: blockID,
                        pacing: pacing ?? "",
                        coursePrice: localizedCoursePrice ?? "",
                        screen: screen,
                        error: error.formattedError
                    )
                } else {
                    analytics.trackCourseUpgradePaymentError(
                        .courseUpgradePaymentError,
                        biValue: .courseUpgradePaymentError,
                        courseID: courseID ?? "",
                        blockID: blockID,
                        pacing: pacing ?? "",
                        coursePrice: localizedCoursePrice ?? "",
                        screen: screen,
                        error: error.formattedError
                    )
                }
            } else {
                analytics.trackCourseUpgradeError(
                    courseID: courseID ?? "",
                    blockID: blockID,
                    pacing: pacing ?? "",
                    coursePrice: localizedCoursePrice ?? "",
                    screen: screen,
                    error: error.formattedError,
                    flowType: upgradeHadler.upgradeMode.rawValue
                )
            }
            
            var shouldRemove: Bool = false
            if case .verifyReceiptError = error {
                shouldRemove = false
            } else {
                shouldRemove = true
            }
            
            removeLoader(success: false, removeView: shouldRemove)
        
        default:
            break
        }
    }
    
    private func postSuccessNotification() {
        NotificationCenter.default.post(name: .courseUpgradeCompletionNotification, object: nil)
    }
    
    public func resetUpgradeModel() {
        helperModel = nil
        delegate = nil
    }
    
    private func reset() {
        pacing = nil
        courseID = nil
        blockID = nil
        localizedCoursePrice = nil
        screen = .unknown
        resetUpgradeModel()
    }
}

extension CourseUpgradeHelper {
    func showSuccess() {
        //TODO: show snack bar via router
        
//        topController.showBottomActionSnackBar(
//            message: CoreLocalization.CourseUpgrade.successMessage,
//            textSize: .xSmall,
//            autoDismiss: true,
//            duration: 3
//        )

        analytics.trackCourseUpgradeSuccess(
            courseID: courseID ?? "",
            blockID: blockID,
            pacing: pacing ?? "",
            coursePrice: localizedCoursePrice ?? "",
            screen: screen,
            flowType: upgradeHadler?.upgradeMode.rawValue ?? ""
        )
        reset()
    }
    
    func showError() {
        // not showing any error if payment is canceled by user
        if case .error(let error) = upgradeHadler?.state {
            if error.isCancelled { return }
            
            var actions: [UIAlertAction] = []
            
            if case .verifyReceiptError(let nestedError) = error, nestedError.errorCode != 409 {
                actions.append(
                    UIAlertAction(
                        title: CoreLocalization.CourseUpgrade.FailureAlert.refreshToRetry,
                        style: .default,
                        handler: { [weak self] _ in
                            guard let self = self else { return }
                            self.trackUpgradeErrorAction(errorAction: .refreshToRetry, error: error)
                            Task {
                                await self.upgradeHadler?.reverifyPayment()
                            }
                        }
                    )
                )
            }
            
            if case .complete = upgradeHadler?.state, completion != nil {
                actions.append(
                    UIAlertAction(
                        title: CoreLocalization.CourseUpgrade.FailureAlert.refreshToRetry,
                        style: .default,
                        handler: { [weak self] _ in
                            self?.trackUpgradeErrorAction(errorAction: .refreshToRetry, error: error)
                            self?.showLoader()
                            self?.completion?()
                            self?.completion = nil
                        }
                    )
                )
            }
            
            actions.append(
                UIAlertAction(
                    title: CoreLocalization.CourseUpgrade.FailureAlert.getHelp,
                    style: .default,
                    handler: { [weak self] _ in
                        guard let self = self else { return }
                        self.trackUpgradeErrorAction(errorAction: .emailSupport, error: error)
                        self.hideAlertAction()
                        Task { @MainActor in
                            await self.router.hideUpgradeLoaderView(animated: true)
                        }
                        self.launchEmailComposer(errorMessage: "Error: \(error.formattedError)")
                    }
                )
            )

            actions.append(
                UIAlertAction(
                    title: CoreLocalization.close,
                    style: .default,
                    handler: { [weak self] _ in
                        guard let self = self else { return }
                        Task { @MainActor in
                            await self.router.hideUpgradeLoaderView(animated: true)
                            self.trackUpgradeErrorAction(errorAction: .close, error: error)
                            self.hideAlertAction()
                        }
                    }
                )
            )

            router.presentNativeAlert(
                title: CoreLocalization.CourseUpgrade.FailureAlert.alertTitle,
                message: error.localizedDescription,
                actions: actions
            )
        }
    }
    
    private func hideAlertAction() {
        delegate?.hideAlertAction()
        reset()
    }
}

extension CourseUpgradeHelper {
    public func showLoader(animated: Bool = false, completion: (() -> Void)? = nil) {
        Task {@MainActor [weak self] in
            guard let self = self else { return }
            await self.router.hideUpgradeInfo(animated: false)
            await self.router.showUpgradeLoaderView(animated: animated)
            completion?()
        }
    }
    
    public func removeLoader(
        success: Bool? = false,
        removeView: Bool? = false,
        completion: (() -> Void)? = nil
    ) {
        self.completion = completion
        if success == true {
            helperModel = nil
        }
        
        if removeView == true {
            Task {@MainActor in
                await router.hideUpgradeLoaderView(animated: true)
            }
            
            helperModel = nil
            
            if success == true {
                showSuccess()
            } else {
                showError()
            }
        } else if success == false {
            showError()
        }
    }
}

extension CourseUpgradeHelper {
    private func showSilentRefreshAlert() {
        var actions: [UIAlertAction] = []

        actions.append(
            UIAlertAction(
                title: CoreLocalization.CourseUpgrade.SuccessAlert.silentAlertRefresh,
                style: .default
            ) { [weak self] _ in
                self?.showLoader(animated: false)
                //                self?.showLoader(forceShow: true)
                //            self?.popToEnrolledCourses()
            }
        )
        
        actions.append(
            UIAlertAction(
                title: CoreLocalization.CourseUpgrade.SuccessAlert.silentAlertContinue,
                style: .default
            ) { [weak self] _ in
                self?.reset()
            }
        )
        
        router.presentNativeAlert(
            title: CoreLocalization.CourseUpgrade.SuccessAlert.silentAlertTitle,
            message: CoreLocalization.CourseUpgrade.SuccessAlert.silentAlertMessage,
            actions: actions
        )
    }
}

extension CourseUpgradeHelper {
    private func trackUpgradeErrorAction(errorAction: UpgradeErrorAction, error: UpgradeError) {
        analytics.trackCourseUpgradeErrorAction(
            courseID: courseID ?? "",
            blockID: blockID,
            pacing: pacing ?? "",
            coursePrice: localizedCoursePrice,
            screen: screen,
            errorAction: errorAction.rawValue,
            error: error.formattedError,
            flowType: upgradeHadler?.upgradeMode.rawValue ?? ""
        )
    }
}

extension CourseUpgradeHelper {
    func launchEmailComposer(errorMessage: String) {
        guard let emailURL = EmailTemplates.contactSupport(
            email: config.feedbackEmail,
            emailSubject: CoreLocalization.CourseUpgrade.supportEmailSubject,
            errorMessage: errorMessage
        ), UIApplication.shared.canOpenURL(emailURL) else {
            
            router.presentAlert(
                alertTitle: CoreLocalization.CourseUpgrade.emailNotSetupTitle,
                alertMessage: CoreLocalization.Error.cannotSendEmail,
                positiveAction: "",
                onCloseTapped: {},
                okTapped: {},
                type: .paymentError(buttons: [AlertViewButton(title: CoreLocalization.ok, block: {})])
            )
            return
        }
        
        UIApplication.shared.open(emailURL)
    }
}

extension Error {
    var errorCode: Int {
        return (self as NSError).code
    }
}
