package com.app.times

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (όχι σκέτο FlutterActivity): απαίτηση του
// `local_auth_android` — το biometric prompt θέλει FragmentActivity,
// αλλιώς `LocalAuthException(uiUnavailable)` (evidence συσκευή 30-09).
class MainActivity : FlutterFragmentActivity()
