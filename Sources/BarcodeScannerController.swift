import UIKit
import AVFoundation

public protocol BarcodeScannerControllerDelegate: class {
  func barcodeScannerController(controller: BarcodeScannerController, didReceiveError error: ErrorType)
  func barcodeScannerController(controller: BarcodeScannerController, didCapturedCode code: String)
}

public class BarcodeScannerController: UIViewController {

  lazy var headerView: HeaderView = {
    let view = HeaderView()
    view.backgroundColor = .whiteColor()

    return view
  }()

  lazy var footerView: FooterView = {
    let blurEffect = UIBlurEffect(style: .Light)
    let view = FooterView(effect: blurEffect)
    view.backgroundColor = .whiteColor()

    return view
  }()

  lazy var focusView: UIView = {
    let view = UIView()
    view.layer.borderColor = UIColor.redColor().CGColor
    view.layer.borderWidth = 2
    view.autoresizingMask = [
      .FlexibleTopMargin, .FlexibleBottomMargin,
      .FlexibleLeftMargin, .FlexibleRightMargin
    ]

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

    [headerView, footerView, focusView].forEach {
      view.addSubview($0)
      view.bringSubviewToFront($0)
    }

    captureSession.startRunning()
  }

  // MARK: - Layout

  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    let footerViewHeight = view.frame.height / 3
    let orientation = UIApplication.sharedApplication().statusBarOrientation

    headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 64)
    footerView.frame = CGRect(x: 0, y: view.bounds.height - footerViewHeight,
      width: view.bounds.width, height: footerViewHeight)
    videoPreviewLayer.frame = view.layer.bounds
    videoPreviewLayer.connection.videoOrientation = orientation.captureOrientation
  }

  // MARK: - Orientation

  public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    videoPreviewLayer.frame.size = size
  }

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
    })
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
