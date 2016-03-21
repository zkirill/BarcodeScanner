import UIKit
import BarcodeScanner

class ViewController: UIViewController {

  lazy var button: UIButton = {
    let button = UIButton(type: .System)
    button.backgroundColor = UIColor.blackColor()
    button.titleLabel?.font = UIFont.boldSystemFontOfSize(28)
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
    presentViewController(controller, animated: true, completion: nil)
  }
}

