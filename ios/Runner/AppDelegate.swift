import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var notificationChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
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

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
