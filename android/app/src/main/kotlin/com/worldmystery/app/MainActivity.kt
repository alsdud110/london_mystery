package com.worldmystery.app

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var launch: MethodChannel? = null

    /// The system bars as the game has them, kept while the launch reveal
    /// shows them in the launch screen's colour (see [launchBars]).
    private var gameBars: Pair<Int, Int>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launchBars()
        // Android 12+: the system splash leaves at once when the game draws
        // its first frame (the same glass, where the splash had it) instead
        // of fading out over it, and the title's launch reveal is told it
        // may begin (it would otherwise run hidden under the splash).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view ->
                view.remove()
                launch?.invokeMethod("splashGone", null)
            }
        }
    }

    /// The status and navigation bars in the launch screen's navy, so they
    /// do not change as the game takes over from the splash; the game's own
    /// bars come back once the title's room is up ("gameBars" below).
    @Suppress("DEPRECATION") // ignored where the system draws the bars itself (Android 15+)
    private fun launchBars() {
        gameBars = Pair(window.statusBarColor, window.navigationBarColor)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = LAUNCH_NAVY
    }

    @Suppress("DEPRECATION")
    private fun restoreGameBars() {
        val bars = gameBars ?: return
        gameBars = null
        window.statusBarColor = bars.first
        window.navigationBarColor = bars.second
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The title's launch reveal draws the glass as this Android's splash
        // did (the Android 12+ system splash draws it smaller), and gives the
        // bars back to the game when it ends.
        launch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "world_mystery/launch")
        launch?.setMethodCallHandler { call, result ->
            when (call.method) {
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                "gameBars" -> {
                    restoreGameBars()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private companion object {
        /// The launch screen's background (flutter_native_splash `color`).
        const val LAUNCH_NAVY = 0xFF151D30.toInt()
    }
}
