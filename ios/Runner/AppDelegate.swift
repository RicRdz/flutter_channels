import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterStreamHandler {
    let sendFromFlutterToNativeChannelName = "sendFromFlutterToNativeChannel"
    let sendFromNativeToFlutterChannelName = "sendFromNativeToFlutterChannel"
    let counterReadingEventChannelName = "counterReadingEventChannel"
    
    private var eventSink: FlutterEventSink?
    
    private var count = 1
    private var handler: DispatchQueue?
    
    func run() {
        let TOTAL_COUNT = 500
        if count > TOTAL_COUNT {
            eventSink?(FlutterEndOfEventStream)
        } else {
            let percentage = Double(count) / Double(TOTAL_COUNT)
            eventSink?(percentage)
        }
        count += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.run()
        }
    }
    
    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
    
        GeneratedPluginRegistrant.register(with: self)
        let controller = window.rootViewController as! FlutterViewController
        
        let sendFromFlutterToNativeChannel = FlutterMethodChannel(name: sendFromFlutterToNativeChannelName, binaryMessenger: controller.binaryMessenger)
        sendFromFlutterToNativeChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            
            guard call.method == "showToastNative" else {
              result(FlutterMethodNotImplemented)
              return
            }
            if let args = call.arguments as? Dictionary<String, String>,
                let message = args["message"] as? String {
                self?.showToast(message: message)
                return
            }
            result(FlutterMethodNotImplemented)
            
        })
        
        let sendFromNativeToFlutterChannel = FlutterMethodChannel(name: sendFromNativeToFlutterChannelName, binaryMessenger: controller.binaryMessenger)
        sendFromNativeToFlutterChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
            
            guard call.method == "tellMeSomethingNative" else {
              result(FlutterMethodNotImplemented)
              return
            }
            result("Hey Flutter, hello from native side")
        })
        
        let eventChannel = FlutterEventChannel(name: counterReadingEventChannelName, binaryMessenger: controller.binaryMessenger)
        eventChannel.setStreamHandler(self)
    
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    
    public func onListen(withArguments arguments: Any?,
                         eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        count = 1
        handler = DispatchQueue.main
        run()
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        count = 1
        eventSink = nil
        handler = nil
        return nil
    }
      
     func showToast(message: String) {
         guard let window = UIApplication.shared.keyWindow else {
             return
         }
         
         let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
         window.rootViewController?.present(alertController, animated: true, completion: nil)
         
         DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
             alertController.dismiss(animated: true, completion: nil)
         }
     }
}
