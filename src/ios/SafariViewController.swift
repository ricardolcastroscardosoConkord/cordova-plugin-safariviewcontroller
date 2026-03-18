import Foundation
import SafariServices

@objc(SafariViewController)
class SafariViewController: CDVPlugin, SFSafariViewControllerDelegate {

    var safariVC: SFSafariViewController?

    @objc(isAvailable:)
    func isAvailable(command: CDVInvokedUrlCommand) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK)
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

        DispatchQueue.main.async {
            let vc = SFSafariViewController(url: url)
            vc.delegate = self
            self.safariVC = vc
            self.viewController.present(vc, animated: true) {
                let result = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
    }

    @objc(hide:)
    func hide(command: CDVInvokedUrlCommand) {
        DispatchQueue.main.async {
            if let vc = self.safariVC {
                vc.dismiss(animated: true) {
                    self.safariVC = nil
                    let result = CDVPluginResult(status: CDVCommandStatus_OK)
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
            } else {
                let result = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate.send(result, callbackId: command.callbackId)
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
    }
}