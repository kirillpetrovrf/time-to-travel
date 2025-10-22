package com.timetotravel.app

import android.app.Application
import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Инициализация Yandex MapKit с API ключом
        MapKitFactory.setApiKey("2f1d6a75-b751-4077-b305-c6abaea0b542")
        MapKitFactory.setLocale("ru_RU") // Русский язык
        android.util.Log.i("MapKit", "✅ MapKitFactory инициализирован с API ключом")
    }
}
