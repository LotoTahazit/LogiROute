# Настройка Google Maps API

## Получение API ключа

1. **Перейдите в Google Cloud Console:**
   - https://console.cloud.google.com/

2. **Создайте новый проект или выберите существующий**

3. **Включите необходимые API:**
   - Maps SDK for Android
   - Maps SDK for iOS (если планируете iOS)
   - Maps JavaScript API (для Web)

4. **Создайте API ключ:**
   - Перейдите в раздел "Credentials" (Учетные данные)
   - Нажмите "Create credentials" → "API key"
   - Скопируйте полученный ключ

5. **Ограничьте ключ (рекомендуется):**
   - Для Android: ограничьте по имени пакета и SHA-1
   - Для Web: ограничьте по домену

## Установка в проект

### Android (текущая платформа)

Откройте файл `android/app/src/main/AndroidManifest.xml` и замените:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

на:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="ВАШ_API_КЛЮЧ_ЗДЕСЬ"/>
```

### iOS (опционально)

В файле `ios/Runner/AppDelegate.swift` добавьте:

```swift
import GoogleMaps

GMSServices.provideAPIKey("ВАШ_API_КЛЮЧ_ЗДЕСЬ")
```

### Web (опционально)

В файле `web/index.html` добавьте в `<head>`:

```html
<script src="https://maps.googleapis.com/maps/api/js?key=ВАШ_API_КЛЮЧ_ЗДЕСЬ"></script>
```

## Функции карты в LogiRoute

✅ **Отображение точек доставки** с цветовыми маркерами:
- 🔵 Синий - ожидание (pending)
- 🟠 Оранжевый - срочный (urgent)
- 🟢 Зеленый - выполнено (completed)
- 🔴 Красный - отменено (cancelled)

✅ **Линии маршрута** - пунктирные линии соединяют точки в порядке доставки

✅ **Автоматическое масштабирование** - карта подстраивается под все точки

✅ **Текущая позиция водителя** - с разрешением геолокации

## Бесплатный лимит Google Maps

- **200$ кредитов** ежемесячно (≈28,500 загрузок карты)
- Для небольших проектов этого достаточно
- Настройте биллинг-уведомления для контроля

## Альтернатива (без API ключа)

Если карта не критична, приложение работает без неё - диспетчер может добавлять точки вручную, координаты будут генерироваться автоматически для демонстрации.

