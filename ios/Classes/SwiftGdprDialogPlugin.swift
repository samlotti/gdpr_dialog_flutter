import Flutter
import UIKit
import PersonalizedAdConsent

//import PersonalizedAdConsent гугловская библиотека
public class SwiftGdprDialogPlugin: NSObject, FlutterPlugin {
        
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gdpr_dialog", binaryMessenger: registrar.messenger())
    let instance = SwiftGdprDialogPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch (call.method) {
      case "gdpr.activate":
        let arg = call.arguments as? NSDictionary
        let pubId = arg!["publisherId"] as? String;
        let url = arg!["privacyUrl"] as? String;
        
        self.checkConsent(result: result, publisherId: pubId!, privacyUrl: url!)

       case "gdpr.setUnknown":
        self.setConsentToUnknown(result: result);
        
        case "gdpr.setConsentToNonPersonal":
         self.setConsentToNonPersonal(result: result);
        
        case "gdpr.getConsentStatus":
         self.getConsentStatus(result: result);
        
        case "gdpr.setConsentToPersonal":
         self.setConsentToPersonal(result: result);
        
        case "gdpr.requestLocation":
            let arg = call.arguments as? NSDictionary
            let pubId = arg!["publisherId"] as? String;
            
         self.isUserFromEea(result: result, publisherId: pubId!);
        
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    private func setConsentToUnknown(result: @escaping FlutterResult) {
        PACConsentInformation.sharedInstance.consentStatus = .unknown;
         print("consent == UNKNOWN");
        result(true);
    }
    
    private func setConsentToNonPersonal(result: @escaping FlutterResult) {
        PACConsentInformation.sharedInstance.consentStatus = .nonPersonalized;
         print("consent == NON_PERSONAL");
        result(true);
    }
    
    private func setConsentToPersonal(result: @escaping FlutterResult) {
        PACConsentInformation.sharedInstance.consentStatus = .personalized;
         print("consent == PERSONAL");
        result(true);
    }
    
    private func isUserFromEea(result: @escaping FlutterResult,  publisherId: String) {
        
        PACConsentInformation.sharedInstance.requestConsentInfoUpdate(
            forPublisherIdentifiers: [publisherId])
        {(_ error: Error?) -> Void in
            if let error = error {
                print("ERROR \(error)")
                result(FlutterError(code:"GDPR1", message: error.localizedDescription, details: nil))
            } else {
                result(PACConsentInformation.sharedInstance.isRequestLocationInEEAOrUnknown);
            }
        }
    }
    
    private func getConsentStatus(result: @escaping FlutterResult) {
        var statusResult = "ERROR"
        let status = PACConsentInformation.sharedInstance.consentStatus
         if status == .nonPersonalized {
            print("nonPersonalized");
            statusResult = "NON_PERSONALIZED"
         } else if status == .personalized {
            print(".personalized");
            statusResult = "PERSONALIZED"
         } else if status == .unknown {
            print(".unknown");
            statusResult = "UNKNOWN"
        }
        
        result(statusResult)
    }

    private func checkConsent(result: @escaping FlutterResult, publisherId: String, privacyUrl: String) {
    
            showConsent(publisherId: publisherId, privacyUrl: privacyUrl) { consentResult in
                switch consentResult {
                case .failure(let error):
                    result(FlutterError(code:"GDPR2", message: error.localizedDescription, details: nil))
                case .success(let value):
                    result(value)
                }
            };

    }
    
    func showConsent(publisherId: String, privacyUrl: String, checkBool : @escaping(Result<Bool, Error>) -> Void)
    {
    
        PACConsentInformation.sharedInstance.requestConsentInfoUpdate(
            forPublisherIdentifiers: [publisherId])
        {(_ error: Error?) -> Void in
            if let error = error {
                print("ERROR \(error)")
                checkBool(.failure(error))
            } else {
                print("Success GDPG")
                if PACConsentInformation.sharedInstance.isRequestLocationInEEAOrUnknown == true {
                
                let url = URL(string: privacyUrl)!
                let form = PACConsentForm(applicationPrivacyPolicyURL: url)!
                    form.shouldOfferPersonalizedAds = true
                        form.shouldOfferNonPersonalizedAds = true
                
                form.load { (Error) in
                    if Error != nil {
                        // checkBool(.success(false))
                        // print("ERROR === 1 \(String(describing: Error))")
                        checkBool(.failure(Error!))
                    } else  {
                        form.present(from: (UIApplication.shared.delegate?.window?!.rootViewController)!) { (error, user) in
                            if error != nil {
                                checkBool(.success(false))
                            } else {
                                let status = PACConsentInformation.sharedInstance.consentStatus
                                 if status == .nonPersonalized {
                                    print("nonPersonalized");
                                    checkBool(.success(false))
                                }
                                if status == .personalized{
                                    print("personalized");
                                    checkBool(.success(true))
                                }
                            }
                        }
                    }
                 }
                } else {
                    print("ne iz evropi")
                    checkBool(.success(true))
                }
            }
        }
    }
}
