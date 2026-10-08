import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  static weak var shared: AppDelegate?
  private var notificationChannel: FlutterMethodChannel?
  private var pendingQuickAction: String?
  private var isFlutterReadyForQuickActions = false
  private var pendingImageResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AppDelegate.shared = self
    UNUserNotificationCenter.current().delegate = self
    if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
      pendingQuickAction = shortcutItem.type
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: "com.helltrilla.todoapp/notifications",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleNotificationCall(call: call, result: result)
    }
    self.notificationChannel = channel
  }

  func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) {
    let actionType = shortcutItem.type
    if isFlutterReadyForQuickActions, let channel = notificationChannel {
      channel.invokeMethod("onQuickAction", arguments: actionType)
    } else {
      pendingQuickAction = actionType
    }
  }

  override func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    handleQuickAction(shortcutItem)
    completionHandler(true)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }

  private func handleNotificationCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()

    switch call.method {
    case "consumeInitialQuickAction":
      isFlutterReadyForQuickActions = true
      let action = pendingQuickAction
      pendingQuickAction = nil
      result(action)

    case "requestPermissions":
      center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
        DispatchQueue.main.async {
          result(granted)
        }
      }

    case "scheduleNotification":
      guard let args = call.arguments as? [String: Any],
            let id = args["id"] as? String,
            let title = args["title"] as? String,
            let body = args["body"] as? String,
            let timestampNumber = args["timestampMs"] as? NSNumber else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing notification arguments", details: nil))
        return
      }

      let fireDate = Date(timeIntervalSince1970: timestampNumber.doubleValue / 1000.0)
      let interval = fireDate.timeIntervalSinceNow
      if interval <= -5.0 {
        result(nil)
        return
      }

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default

      let trigger: UNNotificationTrigger
      if interval <= 60.0 {
        trigger = UNTimeIntervalNotificationTrigger(
          timeInterval: max(1.0, interval),
          repeats: false
        )
      } else {
        let components = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute, .second],
          from: fireDate
        )
        trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      }

      let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
      center.add(request) { error in
        DispatchQueue.main.async {
          if let error = error {
            result(FlutterError(code: "SCHEDULE_ERR", message: error.localizedDescription, details: nil))
          } else {
            result(nil)
          }
        }
      }

    case "cancelTaskNotifications":
      if let args = call.arguments as? [String: Any],
         let ids = args["ids"] as? [String] {
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
      }
      result(nil)

    case "cancelAllNotifications":
      center.removeAllPendingNotificationRequests()
      center.removeAllDeliveredNotifications()
      result(nil)

    case "pickProfileImage":
      DispatchQueue.main.async {
        guard let presenter = self.topViewController() else {
          result(nil)
          return
        }
        self.pendingImageResult = result
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = self
        presenter.present(picker, animated: true)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    for scene in scenes {
      if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? scene.windows.first?.rootViewController {
        var current = root
        while let presented = current.presentedViewController {
          current = presented
        }
        return current
      }
    }
    return nil
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true)
    let chosen = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
    guard let image = chosen else {
      pendingImageResult?(nil)
      pendingImageResult = nil
      return
    }

    let targetSize = CGSize(width: 320, height: 320)
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resized = renderer.image { _ in
      let aspectWidth = targetSize.width / image.size.width
      let aspectHeight = targetSize.height / image.size.height
      let scale = max(aspectWidth, aspectHeight)
      let scaledWidth = image.size.width * scale
      let scaledHeight = image.size.height * scale
      let drawRect = CGRect(
        x: (targetSize.width - scaledWidth) / 2.0,
        y: (targetSize.height - scaledHeight) / 2.0,
        width: scaledWidth,
        height: scaledHeight
      )
      image.draw(in: drawRect)
    }

    let base64 = resized.jpegData(compressionQuality: 0.82)?.base64EncodedString()
    pendingImageResult?(base64)
    pendingImageResult = nil
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true)
    pendingImageResult?(nil)
    pendingImageResult = nil
  }
}

@objc class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let shortcutItem = connectionOptions.shortcutItem {
      AppDelegate.shared?.handleQuickAction(shortcutItem)
    }
  }

  override func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    AppDelegate.shared?.handleQuickAction(shortcutItem)
    completionHandler(true)
  }
}
