# 🔐 Release Keystore Information

**ВАЖНО**: Храните этот файл в безопасном месте! Без keystore невозможно обновить приложение в Google Play.

---

## 📱 Keystore Details

### Файл:
- **Путь**: `android/release-keystore.jks`
- **Размер**: ~2 KB
- **Алгоритм**: RSA 2048 bit
- **Срок действия**: 10,000 дней (~27 лет)

### Credentials:
- **Store Password**: `LogiRoute2026!`
- **Key Password**: `LogiRoute2026!`
- **Alias**: `release`

### Certificate Information:
- **CN** (Common Name): LogiRoute
- **OU** (Organizational Unit): Logistics
- **O** (Organization): Y.C. Plast
- **L** (Locality): Israel
- **ST** (State): Israel
- **C** (Country): IL

---

## 🔑 Fingerprints

### SHA-1 (для Google APIs):
```
DA:07:1D:16:95:F1:5D:8A:86:55:9A:B3:13:37:89:77:16:F4:6D:D2
```

### SHA-256 (для Firebase):
```
1B:A3:22:1B:24:90:A1:E6:58:D0:5A:5C:09:93:47:D7:85:3E:30:FE:B6:47:84:FC:48:66:DA:0F:A9:C0:E4:EC
```

---

## 📋 Где добавить fingerprints

### 1. Google Cloud Console (Google Maps API)
1. Откройте [Google Cloud Console](https://console.cloud.google.com/)
2. Перейдите в **APIs & Services** → **Credentials**
3. Выберите Android API Key
4. В разделе **Application restrictions** → **Android apps**
5. Нажмите **Add an item**
6. Введите:
   - **Package name**: `com.logiroute.app`
   - **SHA-1 certificate fingerprint**: `DA:07:1D:16:95:F1:5D:8A:86:55:9A:B3:13:37:89:77:16:F4:6D:D2`
7. Нажмите **Done** → **Save**

### 2. Firebase Console
1. Откройте [Firebase Console](https://console.firebase.google.com/)
2. Выберите проект **LogiRoute**
3. Перейдите в **Project Settings** (⚙️)
4. Вкладка **General**
5. Найдите Android приложение `com.logiroute.app`
6. Нажмите **Add fingerprint**
7. Вставьте SHA-1: `DA:07:1D:16:95:F1:5D:8A:86:55:9A:B3:13:37:89:77:16:F4:6D:D2`
8. Нажмите **Add fingerprint** еще раз
9. Вставьте SHA-256: `1B:A3:22:1B:24:90:A1:E6:58:D0:5A:5C:09:93:47:D7:85:3E:30:FE:B6:47:84:FC:48:66:DA:0F:A9:C0:E4:EC`
10. Нажмите **Save**

### 3. Google Play Console (при публикации)
Google Play автоматически создаст App Signing key. Вам нужно будет:
1. Загрузить APK/AAB подписанный этим keystore
2. Получить SHA-1 от Play App Signing key из консоли
3. Добавить его тоже в Google Cloud и Firebase

---

## 🔨 Сборка Release APK

### С новым keystore:
```bash
flutter build apk --release
```

APK будет подписан автоматически используя `android/key.properties`.

### Проверка подписи:
```bash
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk
```

Должен показать:
- Owner: CN=LogiRoute, OU=Logistics, O=Y.C. Plast...
- SHA1: DA:07:1D:16:95:F1:5D:8A:86:55:9A:B3:13:37:89:77:16:F4:6D:D2

---

## 💾 Backup Keystore

### ⚠️ КРИТИЧЕСКИ ВАЖНО:

1. **Сделайте резервную копию** `android/release-keystore.jks`
2. **Храните в безопасном месте**:
   - Облачное хранилище (Google Drive, Dropbox)
   - Внешний жесткий диск
   - Password manager (1Password, LastPass)
3. **НЕ ТЕРЯЙТЕ KEYSTORE**:
   - Без него невозможно обновить приложение в Google Play
   - Придется создавать новое приложение с новым package name

### Рекомендуемые места для backup:
- ✅ Google Drive (зашифрованная папка)
- ✅ Внешний USB диск
- ✅ Password manager
- ✅ Корпоративный сервер
- ❌ НЕ коммитить в Git (уже в .gitignore)

---

## 🔒 Безопасность

### Файл добавлен в .gitignore:
```gitignore
# Keystore files
*.jks
*.keystore
key.properties
```

### Проверка:
```bash
git status
```

Файл `release-keystore.jks` НЕ должен появляться в списке.

---

## 📝 Получение fingerprints (справка)

### SHA-1:
```bash
keytool -list -v -keystore android/release-keystore.jks -alias release -storepass "LogiRoute2026!"
```

### Только SHA-1 и SHA-256:
```bash
keytool -list -v -keystore android/release-keystore.jks -alias release -storepass "LogiRoute2026!" | findstr "SHA1: SHA256:"
```

---

## 🚀 Публикация в Google Play

### Шаги:

1. **Создать аккаунт Google Play Developer** ($25 единоразово)
2. **Создать приложение** в Play Console
3. **Загрузить APK/AAB**:
   ```bash
   flutter build appbundle --release
   ```
4. **Заполнить информацию**:
   - Описание приложения
   - Скриншоты
   - Иконка
   - Privacy Policy
5. **Отправить на проверку**

### После публикации:
1. Google Play создаст App Signing key
2. Получите SHA-1 из Play Console → Setup → App signing
3. Добавьте в Google Cloud и Firebase

---

## ✅ Чеклист

- [x] Release keystore создан
- [x] SHA-1 и SHA-256 получены
- [ ] SHA-1 добавлен в Google Cloud Console
- [ ] SHA-1 и SHA-256 добавлены в Firebase Console
- [ ] Keystore сохранен в безопасном месте (backup)
- [ ] Пароли сохранены в password manager
- [ ] Проверена сборка release APK
- [ ] Проверена подпись APK

---

## 📞 Важные контакты

**В случае потери keystore**:
- Невозможно восстановить
- Нужно создавать новое приложение
- Пользователи не смогут обновиться

**Поэтому**:
- ✅ Сделайте backup СЕЙЧАС
- ✅ Храните в 2-3 местах
- ✅ Запишите пароли

---

**Дата создания**: 14 февраля 2026  
**Срок действия**: до 2053 года  
**Статус**: ✅ ГОТОВ К PRODUCTION
