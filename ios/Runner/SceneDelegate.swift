import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

}

// Flutter starts with .default before Dart's first overlay-style message.
// Match LaunchScreen during that gap; Flutter's explicit .lightContent and
// .darkContent requests retain control once received (no timer or delay).
class LaunchStatusBarFlutterViewController: FlutterViewController {
  override var preferredStatusBarStyle: UIStatusBarStyle {
    let style = super.preferredStatusBarStyle
    return style == .default ? .lightContent : style
  }
}
