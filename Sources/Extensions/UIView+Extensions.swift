import UIKit

extension UIView {
  var viewInsets: UIEdgeInsets {
    if #available(iOS 11, *) {
      return safeAreaInsets
    }
    
    return .zero
  }

  func addSubviews(_ subviews: UIView...) {
    addSubviews(subviews)
  }

  func addSubviews(_ subviews: [UIView]) {
    subviews.forEach {
      addSubview($0)
    }
  }
}
