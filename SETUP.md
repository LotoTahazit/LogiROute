#  Инструкция по настройке API ключей LogiRoute

##  Быстрый старт

### 1. Создайте файл .env

Скопируйте файл-шаблон:
```
cp .env.example .env
```

Или создайте новый файл .env в корне проекта.

### 2. Получите Google Maps API ключи

1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Создайте новый проект или выберите существующий
3. Включите следующие API:
   - Maps JavaScript API (для Web)
   - Maps SDK for Android
   - Directions API
   - Places API
   - Geocoding API
   - Roads API

4. Создайте API ключи:
   - **Web API Key**: ограничьте по HTTP referrers (домены вашего сайта)
   - **Android API Key**: ограничьте по SHA-1 сертификату приложения

### 3. Заполните файл .env

```env
GOOGLE_MAPS_WEB_KEY=ваш_web_api_ключ
GOOGLE_MAPS_ANDROID_KEY=ваш_android_api_ключ
OSRM_BASE_URL=https://router.project-osrm.org/route/v1/driving
```

### 4. Установите зависимости

```bash
flutter pub get
```

### 5. Запустите приложение

```bash
flutter run
```

##  Важная информация по безопасности

###  ДЕЛАЙТЕ:
-  Храните API ключи в файле .env
-  Добавьте .env в .gitignore (уже сделано)
-  Используйте разные ключи для dev/prod окружений
-  Ограничивайте ключи по доменам/приложениям в Google Console
-  Регулярно ротируйте ключи

###  НЕ ДЕЛАЙТЕ:
-  Не коммитьте файл .env в Git
-  Не храните ключи прямо в коде
-  Не публикуйте ключи в Issues/PR
-  Не используйте production ключи в development

##  Что делать, если ключи утекли?

1. **Немедленно отзовите скомпрометированные ключи** в Google Cloud Console
2. Создайте новые ключи
3. Обновите файл .env
4. Если ключи попали в Git историю:
   ```bash
   # Удалите файл из истории Git
   python git-filter-repo --path .env --invert-paths --force
   
   # Принудительно обновите удаленный репозиторий
   git push --force origin main
   ```

##  Решение проблем

### Ошибка: "GOOGLE_MAPS_WEB_KEY не найден в .env файле"
- Проверьте, что файл .env существует в корне проекта
- Убедитесь, что ключи прописаны без кавычек
- Перезапустите приложение после изменения .env

### Карты не загружаются
- Проверьте правильность API ключей
- Убедитесь, что нужные API включены в Google Console
- Проверьте ограничения ключей (referrers, bundle ID)

### Ошибка при запуске на Web
- Убедитесь, что используется GOOGLE_MAPS_WEB_KEY
- Проверьте, что домен добавлен в список разрешенных в Google Console

##  Дополнительные ресурсы

- [Google Maps Platform](https://developers.google.com/maps)
- [Flutter Dotenv Package](https://pub.dev/packages/flutter_dotenv)
- [Securing API Keys](https://cloud.google.com/docs/authentication/api-keys)
