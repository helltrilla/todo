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
  private var lfoPhase2: Float = 0.0
  private var drop1Env: Float = 0.0
  private var drop1Phase: Float = 0.0
  private var drop1Freq: Float = 1100.0
  private var drop2Env: Float = 0.0
  private var drop2Phase: Float = 0.0
  private var drop2Freq: Float = 1900.0
  private var chordPhase1: Float = 0.0
  private var chordPhase2: Float = 0.0
  private var chordPhase3: Float = 0.0
  private var chordPhase4: Float = 0.0
  private var clinkEnv: Float = 0.0
  private var clinkPhase: Float = 0.0
  private var clinkFreq: Float = 2400.0
  private var vinylPopEnv: Float = 0.0
  private var vinylPopPhase: Float = 0.0
  private var vinylPopFreq: Float = 2100.0
  private var vinylCrackleEnv: Float = 0.0

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
      result(nil)
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.configureAmbientAudio(sound: sound, volume: volume)
      }

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
      result(nil)
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.handleMediaCommand(command: command)
      }

    case "getMediaPlaybackState":
      let session = AVAudioSession.sharedInstance()
      result(session.isOtherAudioPlaying)

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

  private static let mediaRemoteFn: (@convention(c) (UInt32, UnsafeRawPointer?) -> Bool)? = {
    guard let handle = dlopen(
      "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
      RTLD_NOW
    ) else {
      return nil
    }
    guard let sym = dlsym(handle, "MRMediaRemoteSendCommand") else {
      return nil
    }
    typealias Fn = @convention(c) (UInt32, UnsafeRawPointer?) -> Bool
    return unsafeBitCast(sym, to: Fn.self)
  }()

  private func sendSystemMediaRemoteCommand(_ command: UInt32) -> Bool {
    return AppDelegate.mediaRemoteFn?(command, nil) ?? false
  }

  private func handleMediaCommand(command: String) {
    switch command {
    case "play":
      // kMRPlay = 0
      _ = sendSystemMediaRemoteCommand(0)
    case "pause":
      // kMRPause = 1
      _ = sendSystemMediaRemoteCommand(1)
    case "previous":
      // kMRPreviousTrack = 5
      _ = sendSystemMediaRemoteCommand(5)
    case "next":
      // kMRNextTrack = 4
      _ = sendSystemMediaRemoteCommand(4)
    default:
      // kMRTogglePlayPause = 2
      _ = sendSystemMediaRemoteCommand(2)
    }
  }

  private func configureAmbientAudio(sound: String, volume: Float) {
    currentAmbientSound = sound
    ambientVolume = max(0.0, min(1.0, volume))

    if sound == "off" || ambientVolume <= 0.001 {
      audioEngine?.stop()
      return
    }

    let session = AVAudioSession.sharedInstance()
    if session.category != .playback || !session.categoryOptions.contains(.mixWithOthers) {
      do {
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
      } catch {
        // Ignore session errors and attempt engine playback
      }
    }

    if audioEngine == nil {
      let engine = AVAudioEngine()
      let format = engine.outputNode.inputFormat(forBus: 0)
      let sampleRate = Float(format.sampleRate > 0 ? format.sampleRate : 44100.0)

      let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
        guard let self = self else { return noErr }
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let mode = self.currentAmbientSound
        let gain = self.ambientVolume * 0.28
        let twoPi = 2.0 * Float.pi

        for frame in 0..<Int(frameCount) {
          let white = Float.random(in: -1.0...1.0)
          var sample: Float = 0.0

          switch mode {
          case "rain":
            // 1. Soft steady rain shower + distinct resonant water droplets (plops & window patters)
            self.noiseFilterState = 0.86 * self.noiseFilterState + 0.14 * white
            let showerBed = (white - self.noiseFilterState) * 0.18 + self.noiseFilterState * 0.22

            // Trigger droplet 1 (medium water plop with upward bubble pitch chirp)
            if self.drop1Env < 0.001 && Float.random(in: 0.0...1.0) > 0.99945 {
              self.drop1Env = Float.random(in: 0.55...1.0)
              self.drop1Freq = Float.random(in: 680.0...1350.0)
              self.drop1Phase = 0.0
            }
            // Trigger droplet 2 (crisp high window patter)
            if self.drop2Env < 0.001 && Float.random(in: 0.0...1.0) > 0.99935 {
              self.drop2Env = Float.random(in: 0.45...0.9)
              self.drop2Freq = Float.random(in: 1550.0...2650.0)
              self.drop2Phase = 0.0
            }

            var drops: Float = 0.0
            if self.drop1Env > 0.001 {
              self.drop1Freq *= 1.00025 // upward bubble chirp
              self.drop1Phase += (twoPi * self.drop1Freq) / sampleRate
              drops += sin(self.drop1Phase) * self.drop1Env * 0.55
              self.drop1Env *= 0.9962
            }
            if self.drop2Env > 0.001 {
              self.drop2Freq *= 1.00018
              self.drop2Phase += (twoPi * self.drop2Freq) / sampleRate
              drops += sin(self.drop2Phase) * self.drop2Env * 0.42
              self.drop2Env *= 0.9945
            }

            sample = (showerBed + drops) * gain

          case "waves":
            // 2. Dramatic coastal ocean waves: calm trough -> rising swell -> bright foamy crash -> retreat
            self.lfoPhase += (twoPi * 0.105) / sampleRate
            if self.lfoPhase > twoPi { self.lfoPhase -= twoPi }
            self.lfoPhase2 += (twoPi * 0.037) / sampleRate
            if self.lfoPhase2 > twoPi { self.lfoPhase2 -= twoPi }

            let rawWave = 0.5 * (1.0 + sin(self.lfoPhase + 0.35 * sin(self.lfoPhase2)))
            // Sharpen wave crest so there is quiet calm between waves
            let waveCrest = powf(rawWave, 2.8)
            // Dynamic filter cutoff sweeps from deep bass rumble (0.008) to foamy splash (0.36)
            let cutoff: Float = 0.008 + 0.35 * waveCrest
            self.noiseFilterState = (1.0 - cutoff) * self.noiseFilterState + cutoff * white
            // Deep sub-surf undertow
            self.secondaryFilterState = 0.992 * self.secondaryFilterState + 0.008 * white
            let surf = self.noiseFilterState * (0.06 + 0.94 * waveCrest) + self.secondaryFilterState * 0.45
            sample = surf * gain * 1.45

          case "cafe":
            // 3. Cozy Lo-Fi Cafe Lounge: warm Rhodes electric piano chord pad + occasional porcelain cup clinks
            self.lfoPhase += (twoPi * 0.22) / sampleRate
            if self.lfoPhase > twoPi { self.lfoPhase -= twoPi }
            let vibrato: Float = 1.0 + 0.0018 * sin(self.lfoPhase)
            let breathe: Float = 0.72 + 0.28 * sin(self.lfoPhase * 0.5)

            // Warm Dm9 / Fmaj7 chord (D3, F3, A3, C4, E4)
            self.chordPhase1 += (twoPi * 146.83 * vibrato) / sampleRate
            self.chordPhase2 += (twoPi * 174.61 * vibrato) / sampleRate
            self.chordPhase3 += (twoPi * 220.00) / sampleRate
            self.chordPhase4 += (twoPi * 261.63 * vibrato) / sampleRate
            if self.chordPhase1 > twoPi { self.chordPhase1 -= twoPi }
            if self.chordPhase2 > twoPi { self.chordPhase2 -= twoPi }
            if self.chordPhase3 > twoPi { self.chordPhase3 -= twoPi }
            if self.chordPhase4 > twoPi { self.chordPhase4 -= twoPi }

            let chord = (
              sin(self.chordPhase1) * 0.28 +
              sin(self.chordPhase2) * 0.24 +
              sin(self.chordPhase3) * 0.22 +
              sin(self.chordPhase4) * 0.20
            ) * breathe * 0.38

            // Occasional ceramic coffee cup / spoon clink bell
            if self.clinkEnv < 0.0008 && Float.random(in: 0.0...1.0) > 0.999982 {
              self.clinkEnv = Float.random(in: 0.35...0.75)
              self.clinkFreq = Float.random(in: 2150.0...2850.0)
              self.clinkPhase = 0.0
            }
            var clink: Float = 0.0
            if self.clinkEnv > 0.0008 {
              self.clinkPhase += (twoPi * self.clinkFreq) / sampleRate
              clink = (sin(self.clinkPhase) * 0.65 + sin(self.clinkPhase * 1.618) * 0.35) * self.clinkEnv * 0.35
              self.clinkEnv *= 0.9982
            }

            // Very soft warm room murmur (no high hiss)
            self.noiseFilterState = 0.991 * self.noiseFilterState + 0.009 * white
            sample = (chord + clink + self.noiseFilterState * 0.25) * gain

          case "vinyl":
            // 4. Authentic Vinyl Turntable: crisp needle dust pops, surface crackles, and 33.3 RPM analog warmth
            self.lfoPhase += (twoPi * 0.55) / sampleRate // 33.3 RPM platter rotation
            if self.lfoPhase > twoPi { self.lfoPhase -= twoPi }
            self.chordPhase1 += (twoPi * 60.0) / sampleRate
            if self.chordPhase1 > twoPi { self.chordPhase1 -= twoPi }

            // Subtle turntable motor & groove sub-warmth
            let platterWarmth = sin(self.chordPhase1) * (0.04 + 0.03 * sin(self.lfoPhase))

            // Trigger distinct vinyl dust pop (resonant damped impulse at 1400..3200 Hz)
            if self.vinylPopEnv < 0.002 && Float.random(in: 0.0...1.0) > 0.99955 {
              self.vinylPopEnv = Float.random(in: 0.55...1.0)
              self.vinylPopFreq = Float.random(in: 1400.0...3200.0)
              self.vinylPopPhase = 0.0
            }
            var popSample: Float = 0.0
            if self.vinylPopEnv > 0.002 {
              self.vinylPopPhase += (twoPi * self.vinylPopFreq) / sampleRate
              popSample = sin(self.vinylPopPhase) * self.vinylPopEnv * 0.75
              self.vinylPopEnv *= 0.986
            }

            // Frequent fine needle crackle ticks
            if self.vinylCrackleEnv < 0.01 && Float.random(in: 0.0...1.0) > 0.9972 {
              self.vinylCrackleEnv = Float.random(in: 0.20...0.65)
            }
            var crackleSample: Float = 0.0
            if self.vinylCrackleEnv > 0.01 {
              crackleSample = white * self.vinylCrackleEnv * 0.55
              self.vinylCrackleEnv *= 0.91
            }

            sample = (platterWarmth + popSample + crackleSample) * gain * 1.25

          default:
            sample = 0.0
          }

          let clamped = max(-0.95, min(0.95, sample))
          for buffer in ablPointer {
            let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
            if frame < buf.count {
              buf[frame] = clamped
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
