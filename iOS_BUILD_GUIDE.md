# 🍎 Руководство по сборке iOS приложения

## Требования

### 1. **Mac компьютер** (обязательно)
iOS приложения можно собирать только на macOS с установленным Xcode.

### 2. **Xcode** (обязательно)
- Скачайте и установите [Xcode](https://developer.apple.com/xcode/) из App Store
- Откройте Xcode и примите лицензионное соглашение
- Установите дополнительные компоненты (iOS Simulator, Command Line Tools)

### 3. **Apple Developer Account** (для публикации)
- [Apple Developer Program](https://developer.apple.com/programs/) - $99/год
- Или бесплатный аккаунт для тестирования на устройствах

### 4. **CocoaPods**
```bash
sudo gem install cocoapods
```

## Сборка приложения

### Автоматическая сборка
```bash
# Linux/macOS
./build_ios.sh

# Windows (требует WSL или Mac)
build_ios.bat
```

### Ручная сборка
```bash
# 1. Установка зависимостей
cd ios
pod install
cd ..

# 2. Сборка приложения
flutter build ios --release
```

## Создание IPA файла

### Вариант 1: Через Xcode (рекомендуется)
1. Откройте `ios/Runner.xcworkspace` в Xcode
2. Выберите устройство или "Any iOS Device"
3. Product → Archive
4. В окне Organizer нажмите "Distribute App"
5. Выберите "Ad Hoc" или "App Store Connect"
6. Настройте подпись кода (Code Signing)
7. Экспортируйте IPA файл

### Вариант 2: Через командную строку
```bash
# Создание архива
xcodebuild -workspace ios/Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -archivePath build/ios/Runner.xcarchive \
           archive

# Экспорт IPA
xcodebuild -exportArchive \
           -archivePath build/ios/Runner.xcarchive \
           -exportPath build/ios/ipa \
           -exportOptionsPlist ios/ExportOptions.plist
```

## Настройка подписи кода

### 1. **Bundle Identifier**
Откройте `ios/Runner.xcworkspace` в Xcode:
- Runner → Signing & Capabilities
- Измените Bundle Identifier на уникальный (например: `com.yourcompany.logiroute`)

### 2. **Team и Provisioning Profile**
- Выберите вашу Apple Developer Team
- Xcode автоматически создаст Provisioning Profile
- Или создайте вручную в [Apple Developer Portal](https://developer.apple.com/account/)

## Различия с Android

| Параметр | Android | iOS |
|----------|---------|-----|
| **Файл** | APK | IPA |
| **Платформа** | Любая | Только macOS |
| **Подпись** | Keystore | Apple Developer Certificate |
| **Магазин** | Google Play | App Store |
| **Тестирование** | APK файл | TestFlight или Ad Hoc |
| **Стоимость** | $25 (однократно) | $99/год |

## Проблемы и решения

### Ошибка "No iOS Development Team"
- Откройте Xcode → Preferences → Accounts
- Добавьте ваш Apple ID
- В проекте выберите Team

### Ошибка "Code signing is required"
- Настройте Bundle Identifier
- Выберите Development Team
- Создайте Provisioning Profile

### Ошибка CocoaPods
```bash
sudo gem install cocoapods
cd ios
pod repo update
pod install
```

## Тестирование

### На симуляторе
```bash
flutter run -d ios
```

### На устройстве
1. Подключите iPhone/iPad через USB
2. Доверьте компьютеру на устройстве
3. В Xcode выберите ваше устройство
4. Запустите приложение

## Публикация в App Store

1. **Подготовка**
   - Создайте App Store Connect запись
   - Настройте Bundle ID
   - Добавьте иконки и скриншоты

2. **Архив и загрузка**
   - Product → Archive в Xcode
   - Distribute App → App Store Connect
   - Загрузите IPA файл

3. **Релиз**
   - Заполните метаданные в App Store Connect
   - Отправьте на ревью
   - После одобрения - публикация

## Важные файлы iOS

- `ios/Runner/Info.plist` - конфигурация приложения
- `ios/Runner.xcworkspace` - проект Xcode
- `ios/Podfile` - зависимости CocoaPods
- `ios/ExportOptions.plist` - настройки экспорта
