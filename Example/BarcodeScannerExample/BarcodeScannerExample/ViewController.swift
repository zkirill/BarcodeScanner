import UIKit
import BarcodeScanner

class ViewController: UIViewController {

  lazy var button: UIButton = {
    let button = UIButton(type: .System)
    button.backgroundColor = UIColor(red: 52/255, green: 152/255, blue: 219/255, alpha: 1)
    button.titleLabel?.font = UIFont.systemFontOfSize(28)
    button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    button.setTitle("Scan", forState: .Normal)
    button.addTarget(self, action: "buttonDidPress", forControlEvents: .TouchUpInside)

    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.whiteColor()

    view.addSubview(button)
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()

    button.frame.size = CGSize(width: 250, height: 80)
    button.center = view.center
  }

  func buttonDidPress() {
    let controller = BarcodeScannerController()
    controller.codeDelegate = self
    controller.errorDelegate = self
    controller.dismissalDelegate = self

    presentViewController(controller, animated: true, completion: nil)
  }
}

extension ViewController: BarcodeScannerCodeDelegate {

  func barcodeScanner(controller: BarcodeScannerController, didCapturedCode code: String) {
    print(code)

    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
    dispatch_after(delayTime, dispatch_get_main_queue()) {
      controller.startScanning()
    }
  }
}

extension ViewController: BarcodeScannerErrorDelegate {

  func barcodeScanner(controller: BarcodeScannerController, didReceiveError error: ErrorType) {
    controller.dismissViewControllerAnimated(true, completion: nil)
  }
}

extension ViewController: BarcodeScannerDismissalDelegate {

  func barcodeScannerDidDismiss(controller: BarcodeScannerController) {
    controller.dismissViewControllerAnimated(true, completion: nil)
  }
}

