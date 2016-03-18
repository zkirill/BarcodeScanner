import UIKit
import AVFoundation

public class BarcodeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

  lazy var infoView: UILabel = {
    let label = UILabel()
    label.backgroundColor = .whiteColor()
    return label
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

  var infoViewFrame: CGRect {
    let height = view.frame.height / 3

    return CGRect(x: 0, y: view.bounds.height - height,
      width: view.bounds.width, height: height)
  }

  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var focusView: UIView?
  var captureDevice: AVCaptureDevice?
  var capturedCode:String?

  // MARK: - View lifecycle

  public override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(infoView)
  }

  // MARK: - Layout

  public override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    infoView.frame = infoViewFrame
    videoPreviewLayer?.frame = view.layer.bounds

    let orientation = UIApplication.sharedApplication().statusBarOrientation
    videoPreviewLayer?.connection.videoOrientation = orientation.captureOrientation
  }

  // MARK: - Orientation

  public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    videoPreviewLayer?.frame.size = size
  }
}
