package com.timetotravel.app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Устанавливаем черную тему перед super.onCreate()
        setTheme(android.R.style.Theme_Black_NoTitleBar_Fullscreen)
        super.onCreate(savedInstanceState)
    }
}
