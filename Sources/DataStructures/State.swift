import UIKit

// MARK: - Status

/// Status is a holder of the current state with a few additional configuration properties.
struct Status {
  /// The current state.
  let state: State
  /// Flag to enable/disable animation.
  let animated: Bool
  /// Text that overrides a text from the state.
  let text: String

  /**
   Creates a new instance of `Status`.
   - Parameter state: State value.
   - Parameter animated: Flag to enable/disable animation.
   - Parameter text: Text that overrides a text from the state.
   */
  init(state: State, animated: Bool = true, text: String? = nil) {
    self.state = state
    self.animated = animated
    self.text = text ?? state.text
  }
}

// MARK: - State

/// Barcode scanner state.
enum State {
  case scanning
  case processing
  case unauthorized
  case notFound

  /// State message.
  var text: String {
    switch self {
    case .scanning:
      return localizedString("INFO_DESCRIPTION_TEXT")
    case .processing:
      return localizedString("INFO_LOADING_TITLE")
    case .unauthorized:
      return localizedString("ASK_FOR_PERMISSION_TEXT")
    case .notFound:
      return localizedString("NO_PRODUCT_ERROR_TITLE")
    }
  }
}
