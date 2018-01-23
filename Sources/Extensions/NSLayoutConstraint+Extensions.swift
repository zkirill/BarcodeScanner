import UIKit

extension NSLayoutConstraint {
  static func activate(_ constraints: NSLayoutConstraint? ...) {
    for case let constraint in constraints {
      guard let constraint = constraint else {
        continue
      }

      (constraint.firstItem as? UIView)?.translatesAutoresizingMaskIntoConstraints = false
      constraint.isActive = true
    }
  }
}
