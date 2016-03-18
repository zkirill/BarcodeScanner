import UIKit
import BarcodeScanner

class ViewController: UIViewController {

  lazy var button: UIButton = {
    let button = UIButton(type: .System)
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

    button.frame.size = CGSize(width: 100, height: 50)
    button.center = view.center
  }

  func buttonDidPress() {
    let controller = ScannerViewController()
    presentViewController(controller, animated: true, completion: nil)
  }
}

