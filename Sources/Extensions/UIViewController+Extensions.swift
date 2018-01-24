import UIKit

extension UIViewController {
  func add(childViewController: UIViewController) {
    childViewController.willMove(toParentViewController: self)
    addChildViewController(childViewController)
    view.addSubview(childViewController.view)
    childViewController.didMove(toParentViewController: self)
  }

  func remove(childViewController: UIViewController) {
    childViewController.willMove(toParentViewController: nil)
    childViewController.view.removeFromSuperview()
    childViewController.removeFromParentViewController()
  }
}
