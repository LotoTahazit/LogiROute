# ✅ ПРАВИЛЬНАЯ настройка reCAPTCHA для Firebase App Check

## ❌ ВЫ ОТКРЫЛИ НЕ ТОТ ИНТЕРФЕЙС!

На скриншоте вы открыли **Google Cloud Console** (console.cloud.google.com)  
Но нужен **Firebase Console** (console.firebase.google.com)

Это РАЗНЫЕ интерфейсы!

---

## ✅ ПРАВИЛЬНАЯ ИНСТРУКЦИЯ

### Шаг 1: Получить Secret Key из reCAPTCHA Admin

1. Откройте https://www.google.com/recaptcha/admin
2. Найдите **LogiRoute Web App**
3. Нажмите на кнопку **"Ключи reCAPTCHA"** или раскройте секцию с ключами
4. Вы увидите:

```
Site Key (Ключ сайта):     6Lci2bwqAAAAAHLnGRKaFpoX-J7Jg-Z7PrRjrMEg
Secret Key (Секретный ключ): 6Lci2bwqAAAAAXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

5. **СКОПИРУЙТЕ Secret Key** (вторая строка)

---

### Шаг 2: Добавить Secret Key в FIREBASE Console (НЕ Google Cloud!)

⚠️ **ВАЖНО**: Открывайте именно Firebase Console, а не Google Cloud Console!

1. Откройте **https://console.firebase.google.com/** (НЕ console.cloud.google.com!)
2. Выберите проект **logiroute-app**
3. В левом меню нажмите **Build** → **App Check**
4. Вы увидите список приложений:
   - `com.logiroute.app` (Android) - Play Integrity
   - `LogiRoute Web` (Web) - должен быть reCAPTCHA
5. Найдите **Web app** (не Android!)
6. Справа от него нажмите на **три точки ⋮** или кнопку **Configure**
7. Выберите **reCAPTCHA v3** (если еще не выбрано)
8. В поле **reCAPTCHA secret key** вставьте Secret Key
9. Нажмите **Save**

---

### Шаг 3: Проверка

1. В Firebase Console → App Check → Apps
2. Должно быть:
   - **LogiRoute Web** (Web)
   - Provider: **reCAPTCHA v3**
   - Status: **Registered** (зеленая галочка)

3. Подождите 2-3 минуты
4. Очистите кэш браузера (Ctrl+Shift+Delete)
5. Обновите https://logiroute-app.web.app
6. Ошибка должна исчезнуть

---

## 🔍 Как отличить интерфейсы?

| Интерфейс | URL | Для чего |
|-----------|-----|----------|
| **Firebase Console** | console.firebase.google.com | Настройка Firebase (App Check, Firestore, Auth) |
| **Google Cloud Console** | console.cloud.google.com | Настройка GCP (Compute Engine, APIs, IAM) |
| **reCAPTCHA Admin** | google.com/recaptcha/admin | Управление reCAPTCHA сайтами |

---

## 📸 Что вы сделали неправильно?

На вашем скриншоте:
- URL: `console.cloud.google.com/security/recaptcha`
- Это **Google Cloud Console**, а не Firebase Console
- В Google Cloud Console нельзя настроить App Check для Firebase!

---

## ✅ Что нужно сделать?

1. Закройте Google Cloud Console
2. Откройте **https://console.firebase.google.com/**
3. Выберите проект **logiroute-app**
4. Перейдите в **Build** → **App Check**
5. Настройте reCAPTCHA для Web app

---

## 🎯 Итоговый чеклист

- [ ] Получен Secret Key из https://www.google.com/recaptcha/admin
- [ ] Открыт **Firebase Console** (console.firebase.google.com)
- [ ] Выбран проект **logiroute-app**
- [ ] Открыт раздел **Build** → **App Check**
- [ ] Найдено приложение **LogiRoute Web** (Web)
- [ ] Добавлен Secret Key в настройки reCAPTCHA
- [ ] Сохранено
- [ ] Подождали 2-3 минуты
- [ ] Очищен кэш браузера
- [ ] Проверено на https://logiroute-app.web.app

---

## 🆘 Если все еще не работает

Пришлите скриншот страницы:
**https://console.firebase.google.com/project/logiroute-app/appcheck**

Именно эта страница, а не Google Cloud Console!
