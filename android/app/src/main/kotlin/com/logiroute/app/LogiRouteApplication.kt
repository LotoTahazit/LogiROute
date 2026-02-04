package com.logiroute.app

import android.app.Application
import androidx.multidex.MultiDexApplication

/**
 * Кастомный Application класс для LogiRoute
 * Наследуется от MultiDexApplication для поддержки Firebase и большого количества методов
 */
class LogiRouteApplication : MultiDexApplication() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Здесь можно добавить дополнительную инициализацию если нужно
        // Например, FlutterFire уже инициализирует Firebase автоматически
    }
}

