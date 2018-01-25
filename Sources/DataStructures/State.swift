import UIKit

// MARK: - Status

/**
 Status is a holder of the current state
 with a few additional configuration properties.
 */
struct Status {
  /// The current state.
  let state: State

  /// A flag to enable/disable animation.
  let animated: Bool

  /// A text that overrides a text from the state.
  let text: String

  /**
   Creates a new instance of `Status`.

   - Parameter state: A state.
   - Parameter animated: A flag to enable/disable animation.
   - Parameter text: A text that overrides a text from the state.
   */
  init(state: State, animated: Bool = true, text: String? = nil) {
    self.state = state
    self.animated = animated
    self.text = text ?? state.text
  }
}

// MARK: - State.

/**
 Barcode scanner state.
 */
enum State {
  case scanning, processing, unauthorized, notFound

  typealias Styles = (tint: UIColor, font: UIFont, alignment: NSTextAlignment)

  /// State message.
  var text: String {
    let string: String

    switch self {
    case .scanning:
      string = localizedString("INFO_DESCRIPTION_TEXT")
    case .processing:
      string = localizedString("INFO_LOADING_TITLE")
    case .unauthorized:
      string = localizedString("ASK_FOR_PERMISSION_TEXT")
    case .notFound:
      string = localizedString("NO_PRODUCT_ERROR_TITLE")
    }

    return string
  }
}
