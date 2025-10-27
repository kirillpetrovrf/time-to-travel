package com.timetotravel.app

import android.app.Application
// import com.yandex.mapkit.MapKitFactory

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // ❌ ЗАКОММЕНТИРОВАНО: Инициализация MapKit перенесена в main.dart
        // Нативная инициализация несовместима с Flutter Plugin API
        // и вызывает SIGSEGV при создании SearchSuggestSessionSuggestListener
        
        /*
        android.util.Log.i("MapKit", "🔄 Начинаем инициализацию MapKit...")
        
        // Инициализация Yandex MapKit с API ключом
        MapKitFactory.setApiKey("2f1d6a75-b751-4077-b305-c6abaea0b542")
        android.util.Log.i("MapKit", "✅ API ключ установлен")
        
        MapKitFactory.setLocale("ru_RU") // Русский язык
        android.util.Log.i("MapKit", "✅ Локаль установлена: ru_RU")
        
        // КРИТИЧЕСКИ ВАЖНО: Инициализируем MapKit!
        MapKitFactory.initialize(this)
        android.util.Log.i("MapKit", "✅ MapKitFactory.initialize() вызван успешно!")
        
        android.util.Log.i("MapKit", "🎉 MapKit полностью инициализирован и готов к работе")
        */
        
        android.util.Log.i("MapKit", "ℹ️ MapKit будет инициализирован в main.dart через Flutter Plugin API")
    }
}
