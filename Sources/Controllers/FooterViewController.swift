import UIKit

final class FooterViewController: UIViewController {
  // Blur effect view.
  public private(set) lazy var blurView: BlurView = .init()
  /// Text label.
  public private(set) lazy var textLabel: UILabel = .init()
  /// Info image view.
  public private(set) lazy var imageView: UIImageView = .init()

  // MARK: - View lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(blurView)
    blurView.addSubviews(textLabel, imageView)
    setupSubviews()
  }

  // MARK: - Subviews

  private func setupSubviews() {
    textLabel.textColor = .black
    textLabel.font = UIFont.boldSystemFont(ofSize: 14)
    textLabel.numberOfLines = 3

    imageView.image = imageNamed("info").withRenderingMode(.alwaysTemplate)
    imageView.tintColor = .black
  }

  // MARK: - Layout

  private func setupConstraints() {
    let padding: CGFloat = 10

    NSLayoutConstraint.activate(
      imageView.centerYAnchor.constraint(equalTo: blurView.centerYAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 30),
      imageView.heightAnchor.constraint(equalToConstant: 27),

      textLabel.topAnchor.constraint(equalTo: imageView.topAnchor),
      textLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10)
    )

    if #available(iOS 11.0, *) {
      NSLayoutConstraint.activate(
        imageView.leadingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.leadingAnchor,
          constant: padding
        ),
        textLabel.trailingAnchor.constraint(
          equalTo: view.safeAreaLayoutGuide.trailingAnchor,
          constant: -padding
        )
      )
    } else {
      NSLayoutConstraint.activate(
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
        textLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding)
      )
    }
  }
}
