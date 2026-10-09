import AVFoundation
import Flutter
import MediaPlayer
import UIKit
import UserNotifications
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  static weak var shared: AppDelegate?
  private var notificationChannel: FlutterMethodChannel?
  private var widgetChannel: FlutterMethodChannel?
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

  // Campfire DSP properties
  private var fireRoarFilterState: Float = 0.0
  private var fireHissFilterState: Float = 0.0
  private var fireSnapEnv: Float = 0.0
  private var fireSnapPhase: Float = 0.0
  private var fireSnapFreq: Float = 1600.0
  private var fireCrackleEnv: Float = 0.0

  // White / Pink noise DSP properties (Paul Kellet 3-pole IIR filter)
  private var pinkB0: Float = 0.0
  private var pinkB1: Float = 0.0
  private var pinkB2: Float = 0.0

  // Ambient soundscape playlist order for lock screen cycling
  private let ambientPresetsList = ["rain", "fire", "noise", "waves", "cafe", "vinyl"]
  private var isRemoteCommandsConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AppDelegate.shared = self
    UNUserNotificationCenter.current().delegate = self
    setupRemoteCommands()
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

    let widgetChan = FlutterMethodChannel(
      name: "com.helltrilla.todoapp/widgets",
      binaryMessenger: messenger
    )
    widgetChan.setMethodCallHandler { [weak self] call, result in
      self?.handleWidgetCall(call: call, result: result)
    }
    self.widgetChannel = widgetChan
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

    case "pauseAmbientSound":
      result(nil)
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.pauseAmbientAudio()
      }

    case "resumeAmbientSound":
      result(nil)
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        self?.resumeAmbientAudio()
      }

    case "getAmbientSoundState":
      let isPlaying = (audioEngine?.isRunning ?? false) && currentAmbientSound != "off"
      result([
        "sound": currentAmbientSound,
        "volume": Double(ambientVolume),
        "isPlaying": isPlaying
      ])

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

    case "shareFile":
      guard let args = call.arguments as? [String: Any],
            let fileName = args["fileName"] as? String,
            let content = args["content"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing fileName or content", details: nil))
        return
      }

      DispatchQueue.main.async { [weak self] in
        guard let self = self, let presenter = self.topViewController() else {
          result(nil)
          return
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
          try content.write(to: tempURL, atomically: true, encoding: .utf8)
          let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
          if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
          }
          presenter.present(activityVC, animated: true) {
            result(true)
          }
        } catch {
          result(FlutterError(code: "WRITE_ERROR", message: error.localizedDescription, details: nil))
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private let appGroupIdentifier = "group.com.helltrilla.todoapp"

  func dispatchWidgetTaskToggled(_ taskId: Int) {
    widgetChannel?.invokeMethod("onWidgetTaskToggled", arguments: taskId)
  }

  private func handleWidgetCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? UserDefaults.standard

    switch call.method {
    case "syncWidgetData":
      guard let payload = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing widget payload", details: nil))
        return
      }

      if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) {
        defaults.set(jsonData, forKey: "widget_snapshot_data")
        defaults.synchronize()
      }

      if #available(iOS 14.0, *) {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
      }
      result(true)

    case "getPendingToggledTaskIds":
      let pending = defaults.array(forKey: "widget_pending_toggled_ids") as? [Int] ?? []
      result(pending)

    case "clearPendingToggledTaskIds":
      defaults.removeObject(forKey: "widget_pending_toggled_ids")
      defaults.synchronize()
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "todoapp" {
      if url.host == "toggle", let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
        if let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
           let taskId = Int(idString) {
          dispatchWidgetTaskToggled(taskId)
          return true
        }
      }
    }
    return super.application(app, open: url, options: options)
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
      updateNowPlayingInfo(isPlaying: false)
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

          case "fire":
            // 2. Warm crackling campfire:
            // Low frequency flame roar (wood combustion sub-rumble)
            self.fireRoarFilterState = 0.985 * self.fireRoarFilterState + 0.015 * white
            self.lfoPhase += (twoPi * 1.8) / sampleRate
            if self.lfoPhase > twoPi { self.lfoPhase -= twoPi }
            let flameTurbulence: Float = 0.75 + 0.25 * sin(self.lfoPhase)
            let roar = self.fireRoarFilterState * flameTurbulence * 2.2

            // High sizzle / ash hiss
            self.fireHissFilterState = 0.70 * self.fireHissFilterState + 0.30 * white
            let hiss = (white - self.fireHissFilterState) * 0.12

            // Wood snap / ember burst (distinct wood popping impulse)
            if self.fireSnapEnv < 0.001 && Float.random(in: 0.0...1.0) > 0.9992 {
              self.fireSnapEnv = Float.random(in: 0.55...1.0)
              self.fireSnapFreq = Float.random(in: 1100.0...2800.0)
              self.fireSnapPhase = 0.0
            }
            var snap: Float = 0.0
            if self.fireSnapEnv > 0.001 {
              self.fireSnapPhase += (twoPi * self.fireSnapFreq) / sampleRate
              snap = sin(self.fireSnapPhase) * self.fireSnapEnv * 0.85
              self.fireSnapEnv *= 0.988 // fast natural wood damping
            }

            // Frequent delicate ember crackles
            if self.fireCrackleEnv < 0.01 && Float.random(in: 0.0...1.0) > 0.9975 {
              self.fireCrackleEnv = Float.random(in: 0.25...0.7)
            }
            var crackle: Float = 0.0
            if self.fireCrackleEnv > 0.01 {
              crackle = white * self.fireCrackleEnv * 0.45
              self.fireCrackleEnv *= 0.92
            }

            sample = (roar + hiss + snap + crackle) * gain * 1.35

          case "noise":
            // 3. Soothing Pink / White Noise (Paul Kellet's 3-pole IIR pinking filter)
            // Equal energy per octave for continuous deep concentration masking
            self.pinkB0 = 0.99886 * self.pinkB0 + white * 0.0555179
            self.pinkB1 = 0.99332 * self.pinkB1 + white * 0.0750759
            self.pinkB2 = 0.96900 * self.pinkB2 + white * 0.1538520
            let pink = self.pinkB0 + self.pinkB1 + self.pinkB2 + white * 0.5362
            sample = pink * 0.16 * gain * 1.4

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
    updateNowPlayingInfo(isPlaying: true)
  }

  private func titleForAmbientSound(_ sound: String) -> String {
    switch sound {
    case "rain": return "🌧 Дождь"
    case "fire": return "🔥 Костер"
    case "noise": return "💨 Белый шум"
    case "waves": return "🌊 Прибой"
    case "cafe": return "☕️ Кафе"
    case "vinyl": return "💿 Винил"
    default: return "Режим фокуса"
    }
  }

  private func setupRemoteCommands() {
    guard !isRemoteCommandsConfigured else { return }
    isRemoteCommandsConfigured = true

    let commandCenter = MPRemoteCommandCenter.shared()

    commandCenter.playCommand.isEnabled = true
    commandCenter.playCommand.addTarget { [weak self] _ in
      guard let self = self else { return .commandFailed }
      self.resumeAmbientAudio()
      return .success
    }

    commandCenter.pauseCommand.isEnabled = true
    commandCenter.pauseCommand.addTarget { [weak self] _ in
      guard let self = self else { return .commandFailed }
      self.pauseAmbientAudio()
      return .success
    }

    commandCenter.togglePlayPauseCommand.isEnabled = true
    commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
      guard let self = self else { return .commandFailed }
      if self.audioEngine?.isRunning == true && self.currentAmbientSound != "off" {
        self.pauseAmbientAudio()
      } else {
        self.resumeAmbientAudio()
      }
      return .success
    }

    commandCenter.nextTrackCommand.isEnabled = true
    commandCenter.nextTrackCommand.addTarget { [weak self] _ in
      guard let self = self else { return .commandFailed }
      self.cycleAmbientPreset(forward: true)
      return .success
    }

    commandCenter.previousTrackCommand.isEnabled = true
    commandCenter.previousTrackCommand.addTarget { [weak self] _ in
      guard let self = self else { return .commandFailed }
      self.cycleAmbientPreset(forward: false)
      return .success
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAudioInterruption),
      name: AVAudioSession.interruptionNotification,
      object: nil
    )
  }

  @objc private func handleAudioInterruption(notification: Notification) {
    guard let userInfo = notification.userInfo,
          let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
          let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

    if type == .began {
      audioEngine?.pause()
      updateNowPlayingInfo(isPlaying: false)
      notifyFlutterAmbientChange()
    } else if type == .ended {
      if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        if options.contains(.shouldResume) && currentAmbientSound != "off" {
          try? audioEngine?.start()
          updateNowPlayingInfo(isPlaying: true)
          notifyFlutterAmbientChange()
        }
      }
    }
  }

  private func updateNowPlayingInfo(isPlaying: Bool) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if self.currentAmbientSound == "off" || !isPlaying {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        return
      }

      var info = [String: Any]()
      info[MPMediaItemPropertyTitle] = self.titleForAmbientSound(self.currentAmbientSound)
      info[MPMediaItemPropertyArtist] = "TodoApp • Режим фокуса"
      info[MPMediaItemPropertyAlbumTitle] = "Фоновые звуки"
      info[MPNowPlayingInfoPropertyIsLiveStream] = true
      info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

      MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
  }

  private func cycleAmbientPreset(forward: Bool) {
    let list = ambientPresetsList
    let currentIndex = list.firstIndex(of: currentAmbientSound) ?? -1
    let nextIndex: Int
    if forward {
      nextIndex = (currentIndex + 1) % list.count
    } else {
      nextIndex = currentIndex <= 0 ? list.count - 1 : currentIndex - 1
    }
    let newSound = list[nextIndex]
    configureAmbientAudio(sound: newSound, volume: ambientVolume)
    notifyFlutterAmbientChange()
  }

  private func notifyFlutterAmbientChange() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.notificationChannel?.invokeMethod("onAmbientSoundChanged", arguments: [
        "sound": self.currentAmbientSound,
        "volume": Double(self.ambientVolume),
        "isPlaying": (self.audioEngine?.isRunning ?? false) && self.currentAmbientSound != "off"
      ])
    }
  }

  private func pauseAmbientAudio() {
    audioEngine?.pause()
    updateNowPlayingInfo(isPlaying: false)
    notifyFlutterAmbientChange()
  }

  private func resumeAmbientAudio() {
    if currentAmbientSound == "off" {
      configureAmbientAudio(sound: "rain", volume: ambientVolume)
    } else {
      try? audioEngine?.start()
      updateNowPlayingInfo(isPlaying: true)
    }
    notifyFlutterAmbientChange()
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

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    if url.scheme == "todoapp" {
      if url.host == "toggle", let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
        if let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
           let taskId = Int(idString) {
          AppDelegate.shared?.dispatchWidgetTaskToggled(taskId)
        }
      }
    }
  }
}
