import UIKit
import AVFoundation

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
  case Scanning, Processing
}

public class BarcodeScannerController: UIViewController {

  lazy var captureDevice: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
  lazy var captureSession: AVCaptureSession = AVCaptureSession()
  lazy var headerView: HeaderView = HeaderView()
  lazy var footerView: FooterView = FooterView()

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

  lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = { [unowned self] in
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResize

    return videoPreviewLayer
    }()

  var state: State = .Scanning {
    didSet {
      state == .Scanning
        ? captureSession.startRunning()
        : captureSession.stopRunning()

      locked = state == .Processing && oneTimeSearch

      let alpha: CGFloat = state == .Scanning ? 1 : 0

      focusView.alpha = alpha
      flashButton.alpha = alpha

      UIView.animateWithDuration(0.5,
        animations: {
          self.footerView.frame = self.footerFrame
          self.footerView.state = self.state
        },
        completion: { _ in
          if self.state == .Processing {
            self.footerView.animateLoading()
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

  var footerFrame: CGRect {
    let height = state == .Scanning ? 75 : view.bounds.height
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

    let input: AVCaptureInput

    do {
      input = try AVCaptureDeviceInput(device: captureDevice)
    } catch {
      errorDelegate?.barcodeScanner(self, didReceiveError: error)
      return
    }

    let output = AVCaptureMetadataOutput()

    captureSession.addInput(input)
    captureSession.addOutput(output)

    output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    output.metadataObjectTypes = readableCodeTypes

    view.layer.addSublayer(videoPreviewLayer)

    [footerView, headerView, flashButton, focusView].forEach {
      view.addSubview($0)
      view.bringSubviewToFront($0)
    }

    torchMode = .Off
    state = .Scanning
    focusView.hidden = true
    headerView.delegate = self

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "appWillEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
  }

  public override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    setupFrames()
    footerView.setupFrames()
    headerView.hidden = !isBeingPresented()
  }

  public override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    animateFocusView()
  }

  func appWillEnterForeground() {
    animateFocusView()
  }

  // MARK: - Layout

  public func setupFrames() {
    headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 64)
    flashButton.frame = CGRect(x: view.frame.width - 50, y: 73, width: 37, height: 37)
    footerView.frame = footerFrame
    videoPreviewLayer.frame = view.layer.bounds
    videoPreviewLayer.connection.videoOrientation = .Portrait

    updateFocusView(CGSize(width: 218, height: 150))
  }

  func updateFocusView(size: CGSize) {
    focusView.frame = CGRect(
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
        self.updateFocusView(CGSize(width: 280, height: 80))
      }, completion: nil)
  }

  // MARK: - Actions

  public func startScanning() {
    state = .Scanning
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
