import UIKit
import AVFoundation

// MARK: - Delegates

/// Delegate to handle the captured code.
public protocol BarcodeScannerCodeDelegate: class {
  func barcodeScanner(controller: BarcodeScannerController, didCapturedCode code: String, type: String)
}

/// Delegate to report errors.
public protocol BarcodeScannerErrorDelegate: class {
  func barcodeScanner(controller: BarcodeScannerController, didReceiveError error: ErrorType)
}

/// Delegate to dismiss barcode scanner when the close button has been pressed.
public protocol BarcodeScannerDismissalDelegate: class {
  func barcodeScannerDidDismiss(controller: BarcodeScannerController)
}

// MARK: - Controller

/**
 Barcode scanner controller with 4 sates:
 - Scanning mode
 - Processing animation
 - Unauthorized mode
 - Not found error message
 */
public class BarcodeScannerController: UIViewController {

  /// Video capture device.
  lazy var captureDevice: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)

  /// Capture session.
  lazy var captureSession: AVCaptureSession = AVCaptureSession()

  /// Header view with title and close button.
  lazy var headerView: HeaderView = HeaderView()

  /// Information view with description label.
  lazy var infoView: InfoView = InfoView()

  /// Button to change torch mode.
  lazy var flashButton: UIButton = { [unowned self] in
    let button = UIButton(type: .Custom)
    button.addTarget(self, action: #selector(flashButtonDidPress), forControlEvents: .TouchUpInside)

    return button
    }()

  /// Animated focus view.
  lazy var focusView: UIView = {
    let view = UIView()
    view.layer.borderColor = UIColor.whiteColor().CGColor
    view.layer.borderWidth = 2
    view.layer.cornerRadius = 5
    view.layer.shadowColor = UIColor.whiteColor().CGColor
    view.layer.shadowRadius = 10.0
    view.layer.shadowOpacity = 0.9
    view.layer.shadowOffset = CGSize.zero
    view.layer.masksToBounds = false

    return view
  }()

  /// Button that opens settings to allow camera usage.
  lazy var settingsButton: UIButton = { [unowned self] in
    let button = UIButton(type: .System)
    let title = NSAttributedString(string: SettingsButton.text,
      attributes: [
        NSFontAttributeName : SettingsButton.font,
        NSForegroundColorAttributeName : SettingsButton.color,
      ])

    button.setAttributedTitle(title, forState: .Normal)
    button.sizeToFit()
    button.addTarget(self, action: #selector(settingsButtonDidPress), forControlEvents: .TouchUpInside)

    return button
    }()

  /// Video preview layer.
  lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = { [unowned self] in
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResize

    return videoPreviewLayer
    }()

  /// The current controller's status mode.
  var status: Status = Status(.Scanning) {
    didSet {
      let duration = status.animated &&
        (status.state == .Processing
          || oldValue.state == .Processing
          || oldValue.state == .NotFound
        ) ? 0.5 : 0.0

      guard status.state != .NotFound else {
        infoView.status = status

        dispatch_after(
          dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))),
          dispatch_get_main_queue()) {
            self.status = Status(.Scanning)
        }

        return
      }

      let delayReset = oldValue.state == .Processing || oldValue.state == .NotFound

      if !delayReset {
        resetState()
      }

      UIView.animateWithDuration(duration,
        animations: {
          self.infoView.frame = self.infoFrame
          self.infoView.status = self.status
        },
        completion: { _ in
          if delayReset {
            self.resetState()
          }

          self.infoView.layer.removeAllAnimations()
          if self.status.state == .Processing {
            self.infoView.animateLoading()
          }
      })
    }
  }

  /// The current torch mode on the capture device.
  var torchMode: TorchMode = .Off {
    didSet {
      guard captureDevice.hasFlash else { return }

      do {
        try captureDevice.lockForConfiguration()
        captureDevice.torchMode = torchMode.captureTorchMode
        captureDevice.unlockForConfiguration()
      } catch {}

      flashButton.setImage(torchMode.image, forState: .Normal)
    }
  }

  /// Calculated frame for the info view.
  var infoFrame: CGRect {
    let height = status.state != .Processing ? 75 : view.bounds.height
    return CGRect(x: 0, y: view.bounds.height - height,
      width: view.bounds.width, height: height)
  }

  /// When the flag is set to `true` controller returns a captured code
  /// and waits for the next reset action.
  public var oneTimeSearch = true

  /// Delegate to handle the captured code.
  public weak var codeDelegate: BarcodeScannerCodeDelegate?

  /// Delegate to report errors.
  public weak var errorDelegate: BarcodeScannerErrorDelegate?

  /// Delegate to dismiss barcode scanner when the close button has been pressed.
  public weak var dismissalDelegate: BarcodeScannerDismissalDelegate?

  /// Flag to lock session from capturing.
  var locked = false

  // MARK: - Initialization

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  // MARK: - View lifecycle

  public override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = UIColor.blackColor()
    view.layer.addSublayer(videoPreviewLayer)

    [infoView, headerView, settingsButton, flashButton, focusView].forEach {
      view.addSubview($0)
      view.bringSubviewToFront($0)
    }

    torchMode = .Off
    focusView.hidden = true
    headerView.delegate = self

    setupCamera()

    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(appWillEnterForeground),
      name: UIApplicationWillEnterForegroundNotification, object: nil)
  }

  public override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    setupFrames()
    infoView.setupFrames()
    headerView.hidden = !isBeingPresented()
  }

  public override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    animateFocusView()
  }

  /**
   `UIApplicationWillEnterForegroundNotification` action.
   */
  func appWillEnterForeground() {
    torchMode = .Off
    animateFocusView()
  }

  // MARK: - Configuration

  /**
   Sets up camera and checks for camera permissions.
   */
  func setupCamera() {
    let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)

    if authorizationStatus == .Authorized {
      setupSession()
      status = Status(.Scanning)
    } else if authorizationStatus == .NotDetermined {
      AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
        completionHandler: { (granted: Bool) -> Void in
          dispatch_async(dispatch_get_main_queue()) {
            if granted {
              self.setupSession()
            }

            self.status = granted ? Status(.Scanning) : Status(.Unauthorized)
          }
      })
    } else {
      status = Status(.Unauthorized)
    }
  }

  /**
   Sets up capture input, output and session.
   */
  func setupSession() {
    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession.addInput(input)
    } catch {
      errorDelegate?.barcodeScanner(self, didReceiveError: error)
    }

    let output = AVCaptureMetadataOutput()
    captureSession.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    output.metadataObjectTypes = metadata
    videoPreviewLayer.session = captureSession

    setupFrames()
  }

  // MARK: - Reset

  /**
   Shows error message and goes back to the scanning mode.

   - Parameter message: Error message that overrides the message from the config.
   */
  public func resetWithError(message: String? = nil) {
    status = Status(.NotFound, text: message)
  }

  /**
   Resets the controller to the scanning mode.

   - Parameter animated: Flag to show scanner with or without animation.
   */
  public func reset(animated animated: Bool = true) {
    status = Status(.Scanning, animated: animated)
  }

  /**
   Resets the current state.
   */
  func resetState() {
    let alpha: CGFloat = status.state == .Scanning ? 1 : 0

    torchMode = .Off
    locked = status.state == .Processing && oneTimeSearch

    status.state == .Scanning
      ? captureSession.startRunning()
      : captureSession.stopRunning()

    focusView.alpha = alpha
    flashButton.alpha = alpha
    settingsButton.hidden = status.state != .Unauthorized
  }

  // MARK: - Layout

  /**
   Sets frames of the subviews.
   */
  func setupFrames() {
    headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 64)
    flashButton.frame = CGRect(x: view.frame.width - 50, y: 73, width: 37, height: 37)
    infoView.frame = infoFrame
    videoPreviewLayer.frame = view.layer.bounds

    if videoPreviewLayer.connection != nil {
      videoPreviewLayer.connection.videoOrientation = .Portrait
    }

    centerSubview(focusView, size: CGSize(width: 218, height: 150))
    centerSubview(settingsButton, size: CGSize(width: 150, height: 50))
  }

  /**
   Sets a new size and center aligns subview's position.

   - Parameter subview: The subview.
   - Parameter size: A new size.
  */
  func centerSubview(subview: UIView, size: CGSize) {
    subview.frame = CGRect(
      x: (view.frame.width - size.width) / 2,
      y: (view.frame.height - size.height) / 2,
      width: size.width,
      height: size.height)
  }

  // MARK: - Orientation

  public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    return .Portrait
  }

  // MARK: - Animations

  /**
   Simulates flash animation.

   - Parameter processing: Flag to set the current state to `.Processing`.
   */
  func animateFlash(processing: Bool = false) {
    let flashView = UIView(frame: view.bounds)
    flashView.backgroundColor = UIColor.whiteColor()
    flashView.alpha = 1

    view.addSubview(flashView)
    view.bringSubviewToFront(flashView)

    UIView.animateWithDuration(0.2,
      animations: {
        flashView.alpha = 0.0
      },
      completion: { _ in
        flashView.removeFromSuperview()

        if processing {
          self.status = Status(.Processing)
        }
    })
  }

  /**
   Performs focus view animation.
   */
  func animateFocusView() {
    focusView.layer.removeAllAnimations()
    focusView.hidden = false

    setupFrames()

    UIView.animateWithDuration(1.0, delay:0,
      options: [.Repeat, .Autoreverse, .BeginFromCurrentState],
      animations: {
        self.centerSubview(self.focusView, size: CGSize(width: 280, height: 80))
      }, completion: nil)
  }

  // MARK: - Actions

  /**
   Opens setting to allow camera usage.
   */
  func settingsButtonDidPress() {
    dispatch_async(dispatch_get_main_queue()) {
      if let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString) {
        UIApplication.sharedApplication().openURL(settingsURL)
      }
    }
  }

  /**
   Sets the next torch mode.
   */
  func flashButtonDidPress() {
    torchMode = torchMode.next
  }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerController: AVCaptureMetadataOutputObjectsDelegate {

  public func captureOutput(captureOutput: AVCaptureOutput!,
    didOutputMetadataObjects metadataObjects: [AnyObject]!,
    fromConnection connection: AVCaptureConnection!) {
      guard !locked else { return }

      guard metadataObjects != nil && !metadataObjects.isEmpty else { return }

      guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
        code = metadataObj.stringValue
        where metadata.contains(metadataObj.type) else { return }

      if oneTimeSearch {
        locked = true
      }

      animateFlash(oneTimeSearch)
      codeDelegate?.barcodeScanner(self, didCapturedCode: code, type: metadataObj.type)
  }
}

// MARK: - HeaderViewDelegate

extension BarcodeScannerController: HeaderViewDelegate {

  func headerViewDidPressClose(hederView: HeaderView) {
    dismissalDelegate?.barcodeScannerDidDismiss(self)
  }
}
