import UIKit

extension UIViewController {
  func add(childViewController: UIViewController) {
    childViewController.willMove(toParentViewController: self)
    addChildViewController(childViewController)
    view.addSubview(childViewController.view)
    layout(childViewController: childViewController)
    childViewController.didMove(toParentViewController: self)
  }

  func remove(childViewController: UIViewController) {
    childViewController.willMove(toParentViewController: nil)
    childViewController.view.removeFromSuperview()
    childViewController.removeFromParentViewController()
  }

  private func layout(childViewController: UIViewController) {
    let childView = childViewController.view
    childView?.translatesAutoresizingMaskIntoConstraints = true
    childView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    childView?.frame = view.bounds
  }
}
