import UIKit
import AVFoundation

public protocol BarcodeScannerControllerDelegate: class {
  func barcodeScannerController(controller: BarcodeScannerController, didReceiveError error: ErrorType)
  func barcodeScannerController(controller: BarcodeScannerController, didCapturedCode code: String)
}

enum State {
  case Scanning, Processing
}

public class BarcodeScannerController: UIViewController {

  lazy var headerView: HeaderView = {
    let view = HeaderView()
    view.backgroundColor = .whiteColor()

    return view
  }()

  lazy var footerView: FooterView = {
    let blurEffect = UIBlurEffect(style: .ExtraLight)
    let view = FooterView(effect: blurEffect)

    return view
  }()

  lazy var flashButton: UIButton = {
    let button = UIButton(type: .Custom)
    button.addTarget(self, action: "flashButtonDidPress", forControlEvents: .TouchUpInside)

    return button
  }()

  lazy var focusView: UIImageView = {
    let view = UIImageView(image: imageNamed("focus"))
    return view
  }()

  lazy var videoPreviewLayer: AVCaptureVideoPreviewLayer = { [unowned self] in
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    videoPreviewLayer.videoGravity = AVLayerVideoGravityResize

    return videoPreviewLayer
    }()

  lazy var captureDevice: AVCaptureDevice = {
    let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    return captureDevice
  }()

  lazy var captureSession: AVCaptureSession = {
    let captureSession = AVCaptureSession()
    return captureSession
  }()

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
  public weak var delegate: BarcodeScannerControllerDelegate?
  var presented = false
  var animating = false

  var state: State = .Scanning {
    didSet {
      let alpha: CGFloat = state == .Scanning ? 1 : 0
      animating = true

      UIView.animateWithDuration(0.5, animations: {
        self.focusView.alpha = alpha
        self.flashButton.alpha = alpha
        self.footerView.frame = self.footerFrame
        self.animating = false
        self.footerView.state = self.state
        }) { _ in
          if self.state == .Processing {
            UIView.animateWithDuration(1.0, delay:0, options: [.Repeat, .Autoreverse], animations: {
              self.footerView.effect = UIBlurEffect(style: .Light)
              }, completion: nil)
          } else {
            self.footerView.layer.removeAllAnimations()
          }
      }
    }
  }

  var flashMode: FlashMode = .Auto {
    didSet {
      guard captureDevice.hasFlash else { return }

      do {
        try captureDevice.lockForConfiguration()
      } catch {}

      captureDevice.flashMode = flashMode.captureFlashMode
      flashButton.setImage(flashMode.image, forState: .Normal)
    }
  }

  var footerFrame: CGRect {
    let headerHeight = presented ? headerView.frame.height : 0
    let height = state == .Scanning
      ? view.frame.height / 3 - 20
      : view.bounds.height - headerHeight
    let y = state == .Scanning
      ? view.bounds.height - height
      : presented ? headerHeight : 0

    return CGRect(x: 0, y: y,
      width: view.bounds.width, height: height)
  }

  // MARK: - View lifecycle

  public override func viewDidLoad() {
    super.viewDidLoad()

    let input: AVCaptureInput

    do {
      input = try AVCaptureDeviceInput(device: captureDevice)
    } catch {
      delegate?.barcodeScannerController(self, didReceiveError: error)
      return
    }

    let output = AVCaptureMetadataOutput()

    captureSession.addInput(input)
    captureSession.addOutput(output)

    output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
    output.metadataObjectTypes = readableCodeTypes

    view.layer.addSublayer(videoPreviewLayer)

    [headerView, footerView, flashButton, focusView].forEach {
      view.addSubview($0)
      view.bringSubviewToFront($0)
    }

    captureSession.startRunning()
    flashMode = .Auto
    state = .Scanning
    footerView.state = state
  }

  public override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    presented = isBeingPresented()
    headerView.hidden = !presented
  }

  // MARK: - Layout

  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    let orientation = UIApplication.sharedApplication().statusBarOrientation

    headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 64)

    if !animating {
      footerView.frame = footerFrame
    }

    flashButton.frame = CGRect(x: view.frame.width - 50, y: 73, width: 37, height: 37)
    videoPreviewLayer.frame = view.layer.bounds
    videoPreviewLayer.connection.videoOrientation = orientation.captureOrientation
  }

  // MARK: - Orientation

  public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    videoPreviewLayer.frame.size = size
  }

  // MARK: - Animations

  func showFlashAnimation() {
    let flashView = UIView(frame: view.bounds)
    flashView.backgroundColor = UIColor.whiteColor()
    flashView.alpha = 1

    view.addSubview(flashView)
    view.bringSubviewToFront(flashView)

    UIView.animateWithDuration(0.1, animations: {
      flashView.alpha = 0.0
      }, completion: {(finished:Bool) in
        flashView.removeFromSuperview()
        self.state = .Processing
    })
  }

  // MARK: - Actions

  func flashButtonDidPress() {
    flashMode = flashMode.next
  }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeScannerController: AVCaptureMetadataOutputObjectsDelegate {

  public func captureOutput(captureOutput: AVCaptureOutput!,
    didOutputMetadataObjects metadataObjects: [AnyObject]!,
    fromConnection connection: AVCaptureConnection!) {

      guard metadataObjects != nil && metadataObjects.count > 0 else {
        focusView.frame = CGRectZero
        return
      }

      let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

      guard readableCodeTypes.contains(metadataObj.type) else {
        return
      }

      let barCodeObject = videoPreviewLayer.transformedMetadataObjectForMetadataObject(metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject

      focusView.frame = barCodeObject.bounds

      guard let code = metadataObj.stringValue else { return }

      showFlashAnimation()

      if oneTimeSearch {
        captureSession.stopRunning()
      }

      delegate?.barcodeScannerController(self, didCapturedCode: code)
  }
}
