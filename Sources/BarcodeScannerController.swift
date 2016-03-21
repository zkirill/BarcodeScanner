import UIKit
import AVFoundation
import Sugar

// MARK: - Delegates

public protocol BarcodeScannerCodeDelegate: class {
  func barcodeScanner(controller: BarcodeScannerController, didCapturedCode code: String)
}

public protocol BarcodeScannerErrorDelegate: class {
  func barcodeScanner(controller: BarcodeScannerController, didReceiveError error: ErrorType)
}

public protocol BarcodeScannerDismissalDelegate: class {
  func barcodeScannerDidDismiss(controller: BarcodeScannerController)
}

enum State {
  case Scanning, Processing, Unauthorized, NotFound
}

// MARK: - Controller

public class BarcodeScannerController: UIViewController {

  lazy var captureDevice: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
  lazy var captureSession: AVCaptureSession = AVCaptureSession()
  lazy var headerView: HeaderView = HeaderView()
  lazy var infoView: InfoView = InfoView()

  lazy var flashButton: UIButton = { [unowned self] in
    let button = UIButton(type: .Custom)
    button.addTarget(self, action: "flashButtonDidPress", forControlEvents: .TouchUpInside)

    return button
    }()

  lazy var focusView: UIView = {
    let view = UIView()
    view.layer.borderColor = UIColor.whiteColor().CGColor
    view.layer.borderWidth = 2
    view.layer.cornerRadius = 5
    view.layer.shadowColor = UIColor.whiteColor().CGColor
    view.layer.shadowRadius = 10.0
    view.layer.shadowOpacity = 0.9
    view.layer.shadowOffset = CGSizeZero
    view.layer.masksToBounds = false

    return view
  }()

  lazy var settingsButton: UIButton = { [unowned self] in
    let button = UIButton(type: .System)
    let title = NSAttributedString(string: SettingsButton.text,
      attributes: [
        NSFontAttributeName : SettingsButton.font,
        NSForegroundColorAttributeName : SettingsButton.color,
      ])

    button.setAttributedTitle(title, forState: .Normal)
    button.sizeToFit()
    button.addTarget(self, action: "settingsButtonDidPress", forControlEvents: .TouchUpInside)

    return button
    }()

  lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = { [unowned self] in
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResize

    return videoPreviewLayer
    }()

  var state: State = .Scanning {
    didSet {
      let duration = state == .Processing
        || oldValue == .Processing
        || oldValue == .NotFound ? 0.5 : 0.0

      guard state != .NotFound else {
        infoView.state = state

        delay(2.0) {
          self.state = .Scanning
        }

        return
      }

      let delayReset = oldValue == .Processing || oldValue == .NotFound

      if !delayReset {
        resetState()
      }

      UIView.animateWithDuration(duration,
        animations: {
          self.infoView.frame = self.infoFrame
          self.infoView.state = self.state
        },
        completion: { _ in
          if delayReset {
            self.resetState()
          }

          self.infoView.layer.removeAllAnimations()
          if self.state == .Processing {
            self.infoView.animateLoading()
          }
      })
    }
  }

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

  var infoFrame: CGRect {
    let height = state != .Processing ? 75 : view.bounds.height
    return CGRect(x: 0, y: view.bounds.height - height,
      width: view.bounds.width, height: height)
  }

  private var readableCodeTypes = [
    AVMetadataObjectTypeUPCECode,
    AVMetadataObjectTypeCode39Code,
    AVMetadataObjectTypeCode39Mod43Code,
    AVMetadataObjectTypeEAN13Code,
    AVMetadataObjectTypeEAN8Code,
    AVMetadataObjectTypeCode93Code,
    AVMetadataObjectTypeCode128Code,
    AVMetadataObjectTypePDF417Code,
    AVMetadataObjectTypeQRCode,
    AVMetadataObjectTypeAztecCode
  ]

  public var oneTimeSearch = true
  public weak var codeDelegate: BarcodeScannerCodeDelegate?
  public weak var errorDelegate: BarcodeScannerErrorDelegate?
  public weak var dismissalDelegate: BarcodeScannerDismissalDelegate?
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

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterForeground",
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

  func appWillEnterForeground() {
    torchMode = .Off
    animateFocusView()
  }

  // MARK: - Configuration

  func setupCamera() {
    let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)

    if authorizationStatus == .Authorized {
      setupSession()
      state = .Scanning
    } else if authorizationStatus == .NotDetermined {
      AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
        completionHandler: { (granted: Bool) -> Void in
          dispatch {
            if granted {
              self.setupSession()
            }

            self.state = granted ? .Scanning : .Unauthorized
          }
      })
    } else {
      state = .Unauthorized
    }
  }

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
    output.metadataObjectTypes = readableCodeTypes

    videoPreviewLayer.session = captureSession
    setupFrames()
  }

  // MARK: - Reset

  public func resetWithError() {
    state = .NotFound
  }

  public func reset() {
    state = .Scanning
  }

  func resetState() {
    let alpha: CGFloat = state == .Scanning ? 1 : 0

    torchMode = .Off
    locked = state == .Processing && oneTimeSearch

    state == .Scanning
      ? captureSession.startRunning()
      : captureSession.stopRunning()

    focusView.alpha = alpha
    flashButton.alpha = alpha
    settingsButton.hidden = state != .Unauthorized
  }

  // MARK: - Layout

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
          self.state = .Processing
        }
    })
  }

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

  func settingsButtonDidPress() {
    dispatch {
      if let settingsURL = NSURL(string: UIApplicationOpenSettingsURLString) {
        UIApplication.sharedApplication().openURL(settingsURL)
      }
    }
  }

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

      guard metadataObjects != nil && metadataObjects.count > 0 else { return }

      guard let metadataObj = metadataObjects[0] as? AVMetadataMachineReadableCodeObject,
        code = metadataObj.stringValue
        where readableCodeTypes.contains(metadataObj.type) else { return }

      if oneTimeSearch {
        locked = true
      }

      animateFlash(oneTimeSearch)
      codeDelegate?.barcodeScanner(self, didCapturedCode: code)
  }
}

// MARK: - HeaderViewDelegate

extension BarcodeScannerController: HeaderViewDelegate {

  func headerViewDidPressClose(hederView: HeaderView) {
    dismissalDelegate?.barcodeScannerDidDismiss(self)
  }
}
