import UIKit
import AVFoundation

public class BarcodeScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

  lazy var messageLabel: UILabel = {
    let label = UILabel()
    label.backgroundColor = .whiteColor()
    return label
  }()

  lazy var videoView: UIView = UIView()


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

  var captureSession: AVCaptureSession?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  var focusView: UIView?
  var captureDevice: AVCaptureDevice?
  var capturedCode:String?
}
