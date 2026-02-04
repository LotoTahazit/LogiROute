# 🚨 КРИТИЧЕСКОЕ ПРЕДУПРЕЖДЕНИЕ БЕЗОПАСНОСТИ

## ⚠️ ОБНАРУЖЕНЫ ОТКРЫТЫЕ API КЛЮЧИ В РЕПОЗИТОРИИ!

### 🔴 Проблема
Ваши API ключи **ОТКРЫТО ХРАНЯТСЯ** в репозитории и доступны всем, кто имеет доступ к коду!

### 📍 Где находятся ключи:

1. **`.env`** - содержит Google Maps API ключи
   - `GOOGLE_MAPS_WEB_KEY=AIzaSyAw65vr-ynlQjOWWJv-bqN6x9S0onAQGW8`
   - `GOOGLE_MAPS_ANDROID_KEY=AIzaSyDs_vewHuQ2DK5r8yqvJ4W2jvUAusC3SkY`

2. **`lib/firebase_options.dart`** - содержит Firebase API ключи
   - Web: `AIzaSyAw65vr-ynlQjOWWJv-bqN6x9S0onAQGW8`
   - Android: `AIzaSyCaIoP-a6upfSUbpWp5v1iq-U37QjRDK4w`
   - iOS: `AIzaSyD-mwIOlMyBKfH-NH50WMnRIkhBitwZJec`

### 🚨 НЕМЕДЛЕННЫЕ ДЕЙСТВИЯ (ВЫПОЛНИТЕ СЕЙЧАС):

#### 1. Удалите .env из Git истории
```bash
# Удалите файл из Git (но оставьте локально)
git rm --cached .env

# Закоммитьте изменения
git commit -m "Remove .env from repository"

# Отправьте изменения
git push
```

#### 2. Ротация API ключей Google Maps
1. Перейдите в [Google Cloud Console](https://console.cloud.google.com/)
2. Откройте раздел "APIs & Services" → "Credentials"
3. **УДАЛИТЕ** старые ключи:
   - `AIzaSyAw65vr-ynlQjOWWJv-bqN6x9S0onAQGW8`
   - `AIzaSyDs_vewHuQ2DK5r8yqvJ4W2jvUAusC3SkY`
4. Создайте **НОВЫЕ** ключи
5. Настройте ограничения для новых ключей:
   - Application restrictions (HTTP referrers для Web, Android apps для Android)
   - API restrictions (только необходимые API)

#### 3. Проверьте Firebase ключи
Firebase API ключи для клиентских приложений обычно не секретны, НО:
1. Перейдите в [Firebase Console](https://console.firebase.google.com/)
2. Проверьте **Security Rules** для Firestore и Storage
3. Убедитесь, что правила защищают ваши данные
4. Проверьте **Authentication** настройки

#### 4. Обновите .gitignore
Убедитесь, что `.env` в `.gitignore`:
```bash
# Проверьте
cat .gitignore | grep .env

# Если нет, добавьте
echo ".env" >> .gitignore
```

#### 5. Используйте .env.example
```bash
# Скопируйте пример
cp .env.example .env

# Добавьте НОВЫЕ ключи в .env
nano .env  # или любой редактор
```

### 📋 ДОЛГОСРОЧНЫЕ МЕРЫ БЕЗОПАСНОСТИ:

#### 1. Настройте ограничения для API ключей

**Google Maps Web Key:**
```
Application restrictions:
- HTTP referrers
- Добавьте ваши домены: yourdomain.com/*, localhost:*

API restrictions:
- Maps JavaScript API
- Geocoding API
- Directions API
- Places API
```

**Google Maps Android Key:**
```
Application restrictions:
- Android apps
- Добавьте SHA-1 fingerprint вашего приложения

API restrictions:
- Maps SDK for Android
- Geocoding API
- Directions API
```

#### 2. Мониторинг использования API
1. Настройте **квоты** в Google Cloud Console
2. Настройте **алерты** при превышении лимитов
3. Регулярно проверяйте **Usage reports**

#### 3. Firebase Security Rules
Убедитесь, что у вас настроены правила:

**Firestore Rules (пример):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Только аутентифицированные пользователи
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Пользователи могут читать только свои данные
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

#### 4. Environment Variables для CI/CD
Если используете CI/CD (GitHub Actions, GitLab CI и т.д.):
1. Добавьте секреты в настройках репозитория
2. Используйте их в pipeline
3. Никогда не логируйте секреты

### ✅ ЧЕКЛИСТ БЕЗОПАСНОСТИ:

- [ ] Удален `.env` из Git истории
- [ ] Ротированы Google Maps API ключи
- [ ] Настроены ограничения для API ключей
- [ ] Проверены Firebase Security Rules
- [ ] Настроены квоты и алерты
- [ ] Обновлен `.env` с новыми ключами
- [ ] Проверен `.gitignore`
- [ ] Создан `.env.example` для команды
- [ ] Документированы инструкции для команды

### 📚 ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ:

- [Google Maps API Security Best Practices](https://developers.google.com/maps/api-security-best-practices)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Git Remove Sensitive Data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

### ⚠️ ВАЖНО:
После ротации ключей, обновите их во всех местах:
1. Локальный `.env` файл
2. Production сервер (если есть)
3. CI/CD секреты
4. Документация для команды

---

**Дата обнаружения:** 2026-02-04  
**Статус:** 🔴 КРИТИЧНО - Требует немедленных действий  
**Ответственный:** Владелец проекта
