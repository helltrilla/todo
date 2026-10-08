import AVFoundation
import Flutter
import MediaPlayer
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  static weak var shared: AppDelegate?
  private var notificationChannel: FlutterMethodChannel?
  private var pendingQuickAction: String?
  private var isFlutterReadyForQuickActions = false
  private var pendingImageResult: FlutterResult?
  private var audioEngine: AVAudioEngine?
  private var sourceNode: AVAudioSourceNode?
  private var currentAmbientSound: String = "off"
  private var ambientVolume: Float = 0.45
  private var noiseFilterState: Float = 0.0
  private var secondaryFilterState: Float = 0.0
  private var lfoPhase: Float = 0.0

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

    case "setAmbientSound":
      let args = call.arguments as? [String: Any]
      let sound = (args?["sound"] as? String) ?? "off"
      let volume = (args?["volume"] as? NSNumber)?.floatValue ?? 0.45
      configureAmbientAudio(sound: sound, volume: volume)
      result(nil)

    case "openExternalUrl":
      let args = call.arguments as? [String: Any]
      let rawUrl = (args?["url"] as? String) ?? ""
      let fallbackUrl = args?["fallbackUrl"] as? String
      DispatchQueue.main.async {
        if let primary = URL(string: rawUrl) {
          UIApplication.shared.open(primary, options: [:]) { success in
            if success {
              result(true)
            } else if let fb = fallbackUrl, let fbUrl = URL(string: fb) {
              UIApplication.shared.open(fbUrl, options: [:]) { fbSuccess in
                result(fbSuccess)
              }
            } else {
              result(false)
            }
          }
        } else {
          result(false)
        }
      }

    case "sendMediaCommand":
      let args = call.arguments as? [String: Any]
      let command = (args?["command"] as? String) ?? "playPause"
      DispatchQueue.main.async {
        self.handleMediaCommand(command: command)
        result(nil)
      }

    case "getSystemVolume":
      let vol = Double(AVAudioSession.sharedInstance().outputVolume)
      result(vol)

    case "setSystemVolume":
      let args = call.arguments as? [String: Any]
      let vol = (args?["volume"] as? NSNumber)?.floatValue ?? 0.65
      DispatchQueue.main.async {
        self.setHardwareVolume(max(0.0, min(1.0, vol)))
        result(nil)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private var isExternalAudioPaused = false
  private var hiddenVolumeView: MPVolumeView?

  private func setHardwareVolume(_ volume: Float) {
    if hiddenVolumeView == nil {
      let vv = MPVolumeView(frame: CGRect(x: -2000, y: -2000, width: 100, height: 40))
      vv.alpha = 0.001
      vv.isUserInteractionEnabled = false
      if let rootView = topViewController()?.view {
        rootView.addSubview(vv)
      }
      hiddenVolumeView = vv
    }
    if let slider = hiddenVolumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider {
      slider.setValue(volume, animated: false)
      slider.sendActions(for: .valueChanged)
    }
  }

  private func sendSystemMediaRemoteCommand(_ command: UInt32) -> Bool {
    guard let handle = dlopen(
      "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
      RTLD_NOW
    ) else {
      return false
    }
    guard let sym = dlsym(handle, "MRMediaRemoteSendCommand") else {
      return false
    }
    typealias MRMediaRemoteSendCommandFn = @convention(c) (UInt32, UnsafeRawPointer?) -> Bool
    let sendCommand = unsafeBitCast(sym, to: MRMediaRemoteSendCommandFn.self)
    return sendCommand(command, nil)
  }

  private func handleMediaCommand(command: String) {
    let session = AVAudioSession.sharedInstance()

    switch command {
    case "previous":
      // kMRPreviousTrack = 5
      _ = sendSystemMediaRemoteCommand(5)
    case "next":
      // kMRNextTrack = 4
      _ = sendSystemMediaRemoteCommand(4)
    default:
      let wasOtherPlaying = session.isOtherAudioPlaying
      // kMRTogglePlayPause = 2
      _ = sendSystemMediaRemoteCommand(2)

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
        guard let self = self else { return }
        if session.isOtherAudioPlaying == wasOtherPlaying {
          self.toggleExternalAudioSession()
        }
      }
    }
  }

  private func toggleExternalAudioSession() {
    let session = AVAudioSession.sharedInstance()
    if session.isOtherAudioPlaying {
      audioEngine?.stop()
      try? session.setActive(false)
      do {
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        isExternalAudioPaused = true
        if currentAmbientSound != "off" && ambientVolume > 0.001 {
          try? audioEngine?.start()
        }
      } catch {}
    } else {
      audioEngine?.stop()
      do {
        if !isExternalAudioPaused {
          try? session.setCategory(.playback, mode: .default, options: [])
          try? session.setActive(true)
        }
        try session.setActive(false, options: [.notifyOthersOnDeactivation])
      } catch {}
      isExternalAudioPaused = false
      if currentAmbientSound != "off" && ambientVolume > 0.001 {
        let sound = currentAmbientSound
        let vol = ambientVolume
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
          self?.configureAmbientAudio(sound: sound, volume: vol)
        }
      }
    }
  }

  private func configureAmbientAudio(sound: String, volume: Float) {
    currentAmbientSound = sound
    ambientVolume = max(0.0, min(1.0, volume))

    if sound == "off" || ambientVolume <= 0.001 {
      audioEngine?.stop()
      return
    }

    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try session.setActive(true)
    } catch {
      // Ignore session errors and attempt engine playback
    }

    if audioEngine == nil {
      let engine = AVAudioEngine()
      let format = engine.outputNode.inputFormat(forBus: 0)
      let sampleRate = Float(format.sampleRate > 0 ? format.sampleRate : 44100.0)

      let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
        guard let self = self else { return noErr }
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let mode = self.currentAmbientSound
        let gain = self.ambientVolume * 0.22

        for frame in 0..<Int(frameCount) {
          let white = Float.random(in: -1.0...1.0)
          var sample: Float = 0.0

          switch mode {
          case "rain":
            // Warm rainfall: low-pass filtered noise + subtle droplet texture
            self.noiseFilterState = 0.90 * self.noiseFilterState + 0.10 * white
            self.secondaryFilterState = 0.72 * self.secondaryFilterState + 0.28 * (white - self.noiseFilterState)
            sample = (self.noiseFilterState * 0.65 + self.secondaryFilterState * 0.35) * gain

          case "waves":
            // Ocean surf swell with slow 0.13 Hz LFO
            self.lfoPhase += (2.0 * Float.pi * 0.13) / sampleRate
            if self.lfoPhase > 2.0 * Float.pi {
              self.lfoPhase -= 2.0 * Float.pi
            }
            let swell = 0.30 + 0.70 * (0.5 * (1.0 + sin(self.lfoPhase)))
            self.noiseFilterState = 0.965 * self.noiseFilterState + 0.035 * white
            sample = self.noiseFilterState * swell * gain * 1.35

          case "cafe":
            // Deep brown/pink comfort hum
            self.noiseFilterState = (self.noiseFilterState + 0.025 * white) / 1.025
            sample = self.noiseFilterState * gain * 2.2

          case "vinyl":
            // Cozy lo-fi warm static with occasional soft vinyl crackle
            self.noiseFilterState = 0.94 * self.noiseFilterState + 0.06 * white
            let crackle: Float = Float.random(in: 0.0...1.0) > 0.9985 ? Float.random(in: -0.45...0.45) : 0.0
            sample = (self.noiseFilterState * 0.75 + crackle * 0.25) * gain

          default:
            sample = 0.0
          }

          for buffer in ablPointer {
            let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
            if frame < buf.count {
              buf[frame] = sample
            }
          }
        }
        return noErr
      }

      engine.attach(node)
      engine.connect(node, to: engine.mainMixerNode, format: format)
      self.sourceNode = node
      self.audioEngine = engine
    }

    if let engine = audioEngine, !engine.isRunning {
      try? engine.start()
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
