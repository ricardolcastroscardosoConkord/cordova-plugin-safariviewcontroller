import Foundation
import SafariServices

@objc(SafariViewController)
class SafariViewController: CDVPlugin, SFSafariViewControllerDelegate {

    var safariVC: SFSafariViewController?
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

        DispatchQueue.main.async {
            self.sendEvent(callbackId: command.callbackId, event: "opened", keep: true)

            let vc = SFSafariViewController(url: url)
            vc.delegate = self
            self.safariVC = vc

            self.viewController.present(vc, animated: true) {
                self.sendEvent(callbackId: command.callbackId, event: "loaded", keep: true)
            }
        }
    }

    @objc(hide:)
    func hide(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async {
            if let vc = self.safariVC {
                vc.dismiss(animated: true) {
                    self.safariVC = nil
                    self.sendEvent(callbackId: command.callbackId, event: "closed", keep: false)
                }
            } else {
                self.sendEvent(callbackId: command.callbackId, event: "closed", keep: false)
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
            self.sendEvent(callbackId: callbackId, event: "closed", keep: false)
            self.currentCallbackId = nil
        }
    }

    private func sendEvent(callbackId: String, event: String, keep: Bool) {
        let payload: [String: Any] = ["event": event]
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: payload)
        result?.setKeepCallbackAs(keep)
        self.commandDelegate.send(result, callbackId: callbackId)
    }
}
