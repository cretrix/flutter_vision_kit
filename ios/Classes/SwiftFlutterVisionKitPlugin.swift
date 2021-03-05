import Flutter
import UIKit

public class SwiftFlutterVisionKitPlugin: NSObject, FlutterPlugin {
    var visionController:VisionKitController?
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_vision_kit", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterVisionKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? Dictionary<String, Any>
        let simulatorImagePath = args?["simulatorImagePath"] as? String

        guard simulatorImagePath != nil else { result([]); return  }

        let appImagesPath: String! = simulatorImagePath
        
        if (call.method != "pickDocument"){
            result(FlutterError(code: "not_implemented", message: "\(call.method) is not implemented", details: nil))
            return
        }
        #if targetEnvironment(simulator)
        result(FlutterError(code: "not_implemented", message: "Can not run on Simulator", details: nil))
        return
        #else
        visionController = VisionKitController()
        visionController?.pickDocument{ [weak self] pickerResult in
            guard let self = self else { return }

            switch(pickerResult){
            case .success(let pickerResult):
                switch pickerResult {
                case .success(images: let images):
                    self.saveImaged(images: images, appImagesPath: appImagesPath, result: result)
                case .canceled:
                    result([])
                }
            case .failure(let error):
                result(FlutterError(code: "code", message: error.localizedDescription, details: nil))
            }
        }
        #endif
    }
    private func saveImaged(images:[UIImage], appImagesPath: String, result: @escaping FlutterResult){
        DispatchQueue.global(qos: .userInitiated).async {
            // let tempDirUrl = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let tempDirUrl = NSURL(fileURLWithPath: appImagesPath, isDirectory: true)

            var imagePaths:[String] = []
            for image in images {
                let uuid = UUID().uuidString
                if let data = image.pngData(), let tempFileURL = tempDirUrl.appendingPathComponent("vision_kit_\(uuid).png"){
                    do{
                        try data.write(to: tempFileURL)
                        imagePaths.append(tempFileURL.absoluteString)
                    }catch let error{
                        result(FlutterError(code: "create_file_error", message: error.localizedDescription, details: nil))
                    }

                }
            }
            DispatchQueue.main.async {
                result(imagePaths)
            }
            result(imagePaths)
        }
    }
}
