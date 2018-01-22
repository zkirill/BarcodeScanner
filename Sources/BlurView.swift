import UIKit

public final class BlurView: UIView {
  let effectView: UIVisualEffectView = .init(effect: UIBlurEffect(style: .extraLight))

  // MARK: - Init

  public override init(frame: CGRect) {
    super.init(frame: .zero)
    insertSubview(effectView, at: 0)
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  // MARK: - Subviews

  public override func addSubview(_ view: UIView) {
    effectView.contentView.addSubview(view)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    effectView.frame = bounds
  }
}
