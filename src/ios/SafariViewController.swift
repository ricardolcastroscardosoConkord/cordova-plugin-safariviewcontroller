import Foundation
import SafariServices
import AuthenticationServices

@objc(SafariViewController)
class SafariViewController: CDVPlugin, SFSafariViewControllerDelegate, ASWebAuthenticationPresentationContextProviding {

    var safariVC: SFSafariViewController?
    var authSession: ASWebAuthenticationSession?
    var currentCallbackId: String?

    @objc(isAvailable:)
    func isAvailable(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: true)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(show:)
    func show(command: CDVInvokedUrlCommand) {
        guard let dict = command.arguments.first as? [String: Any],
              let urlString = dict["url"] as? String,
              let url = URL(string: urlString) else {
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Missing url")
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }

        self.currentCallbackId = command.callbackId

        let callbackURLScheme = dict["callbackURLScheme"] as? String
        let prefersEphemeral = (dict["prefersEphemeralWebBrowserSession"] as? Bool) ?? false

        if let callbackScheme = callbackURLScheme, !callbackScheme.trimmingCharacters(in: .whitespaces).isEmpty {
            openAuthenticationSession(
                command: command,
                url: url,
                callbackURLScheme: callbackScheme,
                prefersEphemeralWebBrowserSession: prefersEphemeral
            )
        } else {
            openSafariViewController(command: command, url: url)
        }
    }

    private func openSafariViewController(command: CDVInvokedUrlCommand, url: URL) {
        DispatchQueue.main.async {
            self.sendEvent(callbackId: command.callbackId, payload: [
                "event": "opened"
            ], keep: true)

            let vc = SFSafariViewController(url: url)
            vc.delegate = self
            self.safariVC = vc

            self.viewController.present(vc, animated: true) {
                self.sendEvent(callbackId: command.callbackId, payload: [
                    "event": "loaded"
                ], keep: true)
            }
        }
    }

    private func openAuthenticationSession(
        command: CDVInvokedUrlCommand,
        url: URL,
        callbackURLScheme: String,
        prefersEphemeralWebBrowserSession: Bool
    ) {
        DispatchQueue.main.async {
            self.sendEvent(callbackId: command.callbackId, payload: [
                "event": "opened"
            ], keep: true)

            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in

                if let nsError = error as NSError? {
                    if nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        self.sendEvent(callbackId: command.callbackId, payload: [
                            "event": "closed"
                        ], keep: false)
                    } else {
                        let result = CDVPluginResult(
                            status: CDVCommandStatus_ERROR,
                            messageAs: "ASWebAuthenticationSession error: \(nsError.localizedDescription)"
                        )
                        self.commandDelegate.send(result, callbackId: command.callbackId)
                    }

                    self.authSession = nil
                    self.currentCallbackId = nil
                    return
                }

                let callbackUrlString = callbackURL?.absoluteString ?? ""

                self.sendEvent(callbackId: command.callbackId, payload: [
                    "event": "loaded",
                    "url": callbackUrlString
                ], keep: false)

                self.authSession = nil
                self.currentCallbackId = nil
            }

            session.presentationContextProvider = self

            if #available(iOS 13.0, *) {
                session.prefersEphemeralWebBrowserSession = prefersEphemeralWebBrowserSession
            }

            self.authSession = session

            let started = session.start()
            if !started {
                let result = CDVPluginResult(
                    status: CDVCommandStatus_ERROR,
                    messageAs: "Failed to start ASWebAuthenticationSession"
                )
                self.commandDelegate.send(result, callbackId: command.callbackId)
                self.authSession = nil
                self.currentCallbackId = nil
            }
        }
    }

    @objc(hide:)
    func hide(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async {
            if let auth = self.authSession {
                auth.cancel()
                self.authSession = nil
                self.currentCallbackId = nil
                self.sendEvent(callbackId: command.callbackId, payload: [
                    "event": "closed"
                ], keep: false)
                return
            }

            if let vc = self.safariVC {
                vc.dismiss(animated: true) {
                    self.safariVC = nil
                    self.sendEvent(callbackId: command.callbackId, payload: [
                        "event": "closed"
                    ], keep: false)
                }
            } else {
                self.sendEvent(callbackId: command.callbackId, payload: [
                    "event": "closed"
                ], keep: false)
            }
        }
    }

    @objc(connectToService:)
    func connectToService(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(warmUp:)
    func warmUp(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    @objc(mayLaunchUrl:)
    func mayLaunchUrl(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        self.safariVC = nil

        if let callbackId = self.currentCallbackId {
            self.sendEvent(callbackId: callbackId, payload: [
                "event": "closed"
            ], keep: false)
            self.currentCallbackId = nil
        }
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.viewController.view.window ?? ASPresentationAnchor()
    }

    private func sendEvent(callbackId: String, payload: [String: Any], keep: Bool) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: payload)
        result?.setKeepCallbackAs(keep)
        self.commandDelegate.send(result, callbackId: callbackId)
    }
}
