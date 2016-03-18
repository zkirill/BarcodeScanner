import UIKit

class InfoView: UIVisualEffectView {

  lazy var label: UILabel = {
    let label = UILabel()
    label.backgroundColor = .whiteColor()

    return label
  }()

  lazy var imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.backgroundColor = .whiteColor()

    return imageView
  }()
}
