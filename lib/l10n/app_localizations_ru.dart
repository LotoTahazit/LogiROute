// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get routeHistoryTitle => 'История маршрутов';

  @override
  String get routeHistoryEmpty => 'Завершённых маршрутов пока нет';

  @override
  String get vatRegimeLabel => 'Тип плательщика (печать)';

  @override
  String get vatRegimeAuthorized => 'עוסק מורשה';

  @override
  String get vatRegimeExempt => 'עוסק פטור';

  @override
  String get vatRegimeCompany => 'חברה בע״מ';

  @override
  String get israelInvoiceStatusTitle => 'מערכת חשבוניות ישראל';

  @override
  String get israelInvoicePlatformNotConfigured =>
      'Платформа не настроена — нужны ISRAEL_INVOICE_* в functions/.env';

  @override
  String get israelInvoiceCompanyConnected => 'Подключено к רשות המסים';

  @override
  String get israelInvoiceCompanyNotConnected => 'Не подключено — OAuth';

  @override
  String get israelInvoiceConnect => 'Подключить «Хешбониёт Исраэль»';

  @override
  String get israelInvoiceConnectHint =>
      'Разовая авторизация компании в налоговой для номеров הקצאה. Откроется страница входа רשות המסים.';

  @override
  String get autoDistributePallets => 'Авто-распределить паллеты';

  @override
  String get autoDistributeSuccess =>
      'Паллеты автоматически распределены по водителям!';

  @override
  String get autoDistributeError => 'Ошибка автосплита';

  @override
  String get appTitle => 'LogiRoute';

  @override
  String get login => 'Войти';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get logout => 'Выйти';

  @override
  String get admin => 'Администратор';

  @override
  String get dispatcher => 'Диспетчер';

  @override
  String get driver => 'Водитель';

  @override
  String get viewAs => 'Режим просмотра';

  @override
  String get dashboard => 'Панель управления';

  @override
  String get users => 'Пользователи';

  @override
  String get routes => 'Маршруты';

  @override
  String get deliveryPoints => 'Точки доставки';

  @override
  String get addPoint => 'Добавить точку';

  @override
  String get createRoute => 'Создать маршрут';

  @override
  String createRouteFromSelected(int count) {
    return 'Из выбранных ($count)';
  }

  @override
  String get createRouteByZone => 'Маршрут по зоне';

  @override
  String get clearSelection => 'Сбросить выбор';

  @override
  String selectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get noZoneLabel => 'Без района';

  @override
  String selectedClientsDifferentZonesWarning(String zones) {
    return 'Выбраны клиенты из разных районов: $zones. Маршрут всё равно создать?';
  }

  @override
  String get address => 'Адрес';

  @override
  String get clientName => 'Имя клиента';

  @override
  String get clientNumber => 'Номер клиента';

  @override
  String get clientManagement => 'Управление клиентами';

  @override
  String get editClient => 'Редактировать клиента';

  @override
  String get createClient => 'Создать нового клиента';

  @override
  String get clientCreated => 'Клиент успешно создан';

  @override
  String get clientUpdated => 'Клиент успешно обновлен';

  @override
  String get noClientsFound => 'Клиенты не найдены';

  @override
  String get searchClientHint => 'Поиск по имени, номеру или адресу';

  @override
  String get addressWillBeGeocoded => 'Адрес будет преобразован в координаты';

  @override
  String get addressNotFound => 'Адрес не найден';

  @override
  String get geocodingError => 'Ошибка геокодирования';

  @override
  String get contactPerson => 'Контактное лицо';

  @override
  String get phone => 'Телефон';

  @override
  String get required => 'Обязательно';

  @override
  String get search => 'Поиск';

  @override
  String get urgency => 'Срочность';

  @override
  String get pallets => 'Паллеты';

  @override
  String get boxes => 'Коробки';

  @override
  String get boxesPerPallet => 'Коробок на паллете';

  @override
  String get openingTime => 'Время открытия';

  @override
  String get status => 'Статус';

  @override
  String get pending => 'Ожидает';

  @override
  String get assigned => 'Назначено';

  @override
  String get inProgress => 'В процессе';

  @override
  String get completed => 'Завершено';

  @override
  String get cancelled => 'Отменено';

  @override
  String get navigate => 'Навигация';

  @override
  String get openInMaps => 'Открыть в картах';

  @override
  String get selectDriver => 'Выбрать водителя';

  @override
  String get addUser => 'Добавить пользователя';

  @override
  String get addNewUser => 'Добавить нового пользователя';

  @override
  String get fullName => 'Полное имя';

  @override
  String get role => 'Роль';

  @override
  String get palletCapacity => 'Вместимость паллет';

  @override
  String get truckWeight => 'Тоннаж (тонн)';

  @override
  String get cancel => 'Отмена';

  @override
  String get add => 'Добавить';

  @override
  String get error => 'Ошибка';

  @override
  String get fillAllFields => 'Необходимо заполнить все обязательные поля';

  @override
  String get userAddedSuccessfully => 'Пользователь успешно добавлен';

  @override
  String get errorCreatingUser => 'Ошибка создания пользователя';

  @override
  String get emailAlreadyInUse => 'Адрес электронной почты уже используется';

  @override
  String get weakPassword => 'Пароль слишком слабый';

  @override
  String get warehouse => 'Склад';

  @override
  String get invalidEmail => 'Неверный адрес электронной почты';

  @override
  String get invalidLoginCredentials => 'Неверный email или пароль';

  @override
  String get authUserNotFound => 'Пользователь с таким email не найден';

  @override
  String get authUserDisabled =>
      'Аккаунт отключён. Обратитесь к администратору';

  @override
  String get authNetworkError => 'Нет связи с сервером. Проверьте интернет';

  @override
  String get authOperationNotAllowed =>
      'Вход по email отключён в настройках проекта';

  @override
  String get authInvalidApiKey =>
      'Ошибка конфигурации приложения (API key). Обратитесь к администратору';

  @override
  String get authAppNotAuthorized =>
      'Android не авторизован в Firebase. Добавьте SHA-1 release-ключа в Firebase Console → Project settings → Android app';

  @override
  String get authInternalError =>
      'Ошибка сервера авторизации. Попробуйте позже';

  @override
  String get authProfileNotFound =>
      'Профиль не найден или не настроен. Обратитесь к администратору';

  @override
  String get authUnknownError =>
      'Не удалось выполнить вход. Проверьте данные или попробуйте позже';

  @override
  String get authPasswordResetFailed =>
      'Не удалось отправить письмо для сброса пароля. Проверьте email или обратитесь к администратору';

  @override
  String get tooManyRequests => 'Слишком много попыток. Попробуйте позже';

  @override
  String get systemManager => 'Системный администратор';

  @override
  String get ok => 'ОК';

  @override
  String get noDriversAvailable => 'Нет доступных водителей';

  @override
  String get filterByDriver => 'Фильтр по водителю';

  @override
  String get allDrivers => 'Все водители';

  @override
  String get viewingAs => 'Вы находитесь в режиме просмотра как';

  @override
  String get backToAdmin => 'Вернуться к админу';

  @override
  String get cancelPoint => 'Отменить точку';

  @override
  String get currentLocation => 'Текущее местоположение';

  @override
  String get distance => 'Расстояние';

  @override
  String get km => 'км';

  @override
  String get language => 'Язык';

  @override
  String get hebrew => 'Иврит';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'Английский';

  @override
  String get themeLight => 'Светлая тема';

  @override
  String get themeDark => 'Тёмная тема';

  @override
  String get themeSystem => 'Как в системе';

  @override
  String get capacity => 'Вместимость';

  @override
  String get totalPallets => 'Всего паллет';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get save => 'Сохранить';

  @override
  String get deliveryWindowTitle => 'Окно доставки';

  @override
  String get deliveryWindowFrom => 'С';

  @override
  String get deliveryWindowTo => 'По';

  @override
  String get deliveryWindowNotSet => 'Не задано';

  @override
  String get deliveryWindowClear => 'Очистить окно';

  @override
  String routeLateBy(int minutes) {
    return 'Опоздание $minutes мин';
  }

  @override
  String get routeOnTime => 'Успевает';

  @override
  String avgMinutesPerPoint(int minutes) {
    return '~$minutes мин/точку';
  }

  @override
  String get requirePodPhoto => 'Требовать фото доставки (POD)';

  @override
  String get requirePodPhotoHint =>
      'Скрывает закрытие в один тап и отключает автозакрытие — на каждую доставку нужно фото.';

  @override
  String get autoCloseEnabledTitle => 'Автозакрытие точек по GPS';

  @override
  String get autoCloseEnabledHint =>
      'Точка закрывается сама, когда водитель стоит у клиента. Выключите, если хотите, чтобы водитель закрывал точки только вручную.';

  @override
  String get deliverySection => 'Доставка';

  @override
  String get pointDone => 'Точка выполнена';

  @override
  String get noActivePoints => 'Нет активных точек';

  @override
  String get pointCompleted => 'Точка завершена';

  @override
  String get autoCloseToggle => 'Авто';

  @override
  String get bgLocationTitle => 'Геолокация в фоне';

  @override
  String get bgLocationBody =>
      'Чтобы маршрут водителя записывался полностью (даже когда экран заблокирован), включите доступ к геолокации «Разрешать всегда» в настройках приложения.';

  @override
  String get bgLocationOpenSettings => 'Открыть настройки';

  @override
  String get androidSetupTitle => 'Настройка Android для смены';

  @override
  String get androidSetupIntro =>
      'Чтобы смена и GPS работали в фоне (когда экран заблокирован), включите 3 настройки:';

  @override
  String get androidSetupLocationTitle => 'Геолокация: «Разрешить всегда»';

  @override
  String get androidSetupLocationDesc =>
      'Без этого GPS пропадает, когда экран заблокирован.';

  @override
  String get androidSetupBatteryTitle => 'Батарея: без ограничений';

  @override
  String get androidSetupBatteryDesc =>
      'Чтобы система не выгружала фоновый сервис смены.';

  @override
  String get androidSetupAutostartTitle =>
      'Автозапуск (Xiaomi/MIUI, Huawei, Oppo…)';

  @override
  String get androidSetupAutostartDesc =>
      'Разрешите автозапуск приложения — иначе сервис не стартует после перезагрузки. Проверьте вручную в настройках приложения.';

  @override
  String get androidSetupEnable => 'Включить';

  @override
  String get androidSetupDone => 'Готово';

  @override
  String get androidSetupGranted => 'Включено';

  @override
  String get androidSetupMenu => 'Настройка Android (фон)';

  @override
  String get closeWithPhoto => 'Закрыть с фото';

  @override
  String get fixLocationButton => 'Неверное место';

  @override
  String get fixLocationTitle => 'Обновить координаты клиента?';

  @override
  String fixLocationBody(String clientName) {
    return 'Сохранить ваше текущее местоположение как координаты клиента «$clientName»? Это исправит точку для будущих доставок.';
  }

  @override
  String get fixLocationSuccess => 'Координаты клиента обновлены';

  @override
  String get fixLocationGpsError => 'Нет точного GPS или место вне Израиля';

  @override
  String get fixLocationClientMissing => 'Клиент не найден';

  @override
  String get autoCloseUndoMessage => 'Точка закрыта автоматически';

  @override
  String get undo => 'Отменить';

  @override
  String get podTitle => 'Подтверждение доставки';

  @override
  String get podTakePhoto => 'Сделать фото';

  @override
  String get podRetake => 'Переснять';

  @override
  String get podConfirm => 'Подтвердить доставку';

  @override
  String get podGps => 'Ваш GPS';

  @override
  String get podTime => 'Время';

  @override
  String get podDistance => 'До клиента';

  @override
  String get podPhotoRequired => 'Нужно фото доставки';

  @override
  String get podGpsUnavailable => 'GPS недоступен — включите геолокацию';

  @override
  String get podUploadFailed =>
      'Не удалось загрузить фото — проверьте интернет и повторите';

  @override
  String get podViewerTooltip => 'Фото доставки';

  @override
  String get podViewerNoPhoto => 'Фото не прикреплено — точка закрыта без фото';

  @override
  String get podViewerPhotoError => 'Не удалось загрузить фото';

  @override
  String get podViewerAutoClosed => 'Закрыто автоматически по GPS';

  @override
  String get podSharePhoto => 'Поделиться';

  @override
  String get routeArchiveTitle => 'Архив маршрутов';

  @override
  String get routeArchiveHint =>
      'Доставки за последние 90 дней. Фото доступны всё это время, затем остаются GPS и время.';

  @override
  String get routeArchiveEmpty => 'Архив пуст за этот период';

  @override
  String get routeArchiveSearchHint => 'Поиск по клиенту, водителю или адресу';

  @override
  String routeArchivePointsCount(Object count) {
    return '$count точек';
  }

  @override
  String get routeArchiveGpsOnly => 'только GPS';

  @override
  String get next => 'Далее';

  @override
  String get pointAdded => 'Точка добавлена';

  @override
  String get noPointsForRoute => 'Нет точек для создания маршрута';

  @override
  String get routeCreated => 'Маршрут создан';

  @override
  String get noDeliveryPoints => 'Нет точек доставки';

  @override
  String get markComplete => 'Отметить как выполнено';

  @override
  String get mapViewRequiresApi => 'Вид карты требует Google Maps API';

  @override
  String get unknownDriver => 'Неизвестный водитель';

  @override
  String get fixExistingRoutes => 'Исправить маршруты';

  @override
  String get printRoute => 'Печать маршрута';

  @override
  String get routesFixed => 'Маршруты исправлены!';

  @override
  String get statusPending => 'ожидает';

  @override
  String get statusAssigned => 'назначен';

  @override
  String get statusInProgress => 'в процессе';

  @override
  String get statusCompleted => 'завершён';

  @override
  String get statusCancelled => 'отменён';

  @override
  String get statusActive => 'Активен';

  @override
  String get roleDriver => 'водитель';

  @override
  String get cancelAction => 'отменить';

  @override
  String get completeAction => 'выполнить';

  @override
  String get boxesHint => '1–672 коробок';

  @override
  String get urgencyNormal => 'Обычная';

  @override
  String get urgencyUrgent => 'Срочная';

  @override
  String get changeDriver => 'Сменить водителя';

  @override
  String get cancelRoute => 'Отменить маршрут';

  @override
  String get cancelRouteTitle => 'Отменить маршрут?';

  @override
  String get cancelRouteDescription =>
      'Все точки будут возвращены в статус \'Ожидает\'. Продолжить?';

  @override
  String get routeCancelled => 'Маршрут отменён, точки возвращены в ожидание';

  @override
  String get routePointsReordered => 'Порядок точек и ETA обновлены';

  @override
  String get optimizeTime => 'Оптимизация времени';

  @override
  String get routeAlreadyOptimal => 'Маршрут уже оптимален';

  @override
  String get routeOptimized => 'Маршрут оптимизирован';

  @override
  String get routeOptimizationFailed => 'Ошибка оптимизации';

  @override
  String get routeTimeNotOptimal => 'Время маршрута не оптимально';

  @override
  String get selectNewDriver => 'Выберите нового водителя';

  @override
  String get noAvailableDrivers => 'Нет доступных водителей';

  @override
  String driverChangedTo(Object name) {
    return 'Водитель изменён на $name';
  }

  @override
  String get noUsersFound => 'Пользователи не найдены';

  @override
  String get palletStatistics => 'Статистика по паллетам';

  @override
  String get total => 'Всего';

  @override
  String get delivered => 'Доставлено';

  @override
  String get completionRate => 'Процент выполнения';

  @override
  String get activeRoutes => 'Активные маршруты';

  @override
  String get order => 'Порядок';

  @override
  String get roleAdmin => 'Администратор';

  @override
  String get roleDispatcher => 'Диспетчер';

  @override
  String get roleWarehouseKeeper => 'Кладовщик';

  @override
  String get roleAccountant => 'Бухгалтер';

  @override
  String get roleOwner => 'Владелец';

  @override
  String get refresh => 'Обновить';

  @override
  String get analytics => 'Аналитика';

  @override
  String get settings => 'Настройки';

  @override
  String get lastUpdated => 'Последнее обновление';

  @override
  String get routeCopiedToClipboard => 'Маршрут скопирован в буфер обмена';

  @override
  String printError(String error) {
    return '❌ Ошибка печати: $error';
  }

  @override
  String get no => 'Нет';

  @override
  String get routeNotFound => 'Маршрут не найден';

  @override
  String get map => 'Карта';

  @override
  String get noRoutesYet => 'Пока нет маршрутов';

  @override
  String get points => 'точек';

  @override
  String get refreshMap => 'Обновить карту';

  @override
  String get clientNumberLabel => 'Номер клиента (6 цифр)';

  @override
  String get delete => 'Удалить';

  @override
  String get deletePoint => 'Удалить точку';

  @override
  String get pointDeleted => 'Точка удалена';

  @override
  String get assignDriver => 'Назначить водителя';

  @override
  String get pointAssigned => 'Точка назначена';

  @override
  String addressNotFoundDescription(String address) {
    return 'Не удалось найти координаты для адреса:\n\"$address\"\n\nСистема попробовала множество вариантов, но геокодирование не удалось.\n\nПопробуйте:\n• Проверить правильность написания адреса\n• Использовать полный адрес с городом\n• Проверить существование адреса в картах\n• Обратиться к администратору за помощью';
  }

  @override
  String get fixAddress => 'Исправить адрес';

  @override
  String get fixOldCoordinates => 'Исправить старые координаты';

  @override
  String get fixOldCoordinatesDescription =>
      'Это удалит точки со старыми координатами Иерусалима. Продолжить?';

  @override
  String get oldCoordinatesFixed => 'Старые координаты исправлены';

  @override
  String get fixHebrewSearch => 'Исправить поиск на иврите';

  @override
  String get fixHebrewSearchDescription =>
      'Это исправит поисковый индекс для имен клиентов на иврите. Продолжить?';

  @override
  String get hebrewSearchFixed => 'Поисковый индекс на иврите исправлен';

  @override
  String get clientNumberRequired => 'Введите номер клиента';

  @override
  String get clientNumberLength => 'Номер должен содержать 6 цифр';

  @override
  String get bridgeHeightError => 'Ошибка высоты моста';

  @override
  String get bridgeHeightErrorDescription =>
      'Маршрут заблокирован низким мостом (высота < 4м). Обратитесь к диспетчеру для выбора альтернативного маршрута.';

  @override
  String get routeBlockedByBridge => 'Маршрут заблокирован мостом';

  @override
  String get alternativeRouteFound => 'Найден альтернативный маршрут';

  @override
  String get navigation => 'Навигация';

  @override
  String get loadingNavigation => 'Загрузка маршрута...';

  @override
  String get navigationError => 'Ошибка навигации';

  @override
  String get noNavigationRoute => 'Маршрут не найден';

  @override
  String get retry => 'Повторить';

  @override
  String get previous => 'Назад';

  @override
  String get showMap => 'Показать карту';

  @override
  String get pointCancelled => 'Точка отменена';

  @override
  String get removeFromRoute => 'Убрать из маршрута';

  @override
  String get pointRemovedFromRoute => 'Точка убрана из маршрута';

  @override
  String removeFromRouteConfirm(String name) {
    return 'Убрать \"$name\" из маршрута и вернуть в ожидающие?';
  }

  @override
  String get temporaryAddress => 'Временный адрес';

  @override
  String get temporaryAddressHint => 'Адрес только для этой доставки...';

  @override
  String get temporaryAddressHelper => 'Не изменяет основной адрес клиента';

  @override
  String get temporaryAddressTooltip =>
      'Этот адрес будет использован только для текущей доставки. Основной адрес клиента останется неизменным.';

  @override
  String get originalAddress => 'Основной адрес';

  @override
  String get active => 'Активен';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get passwordResetEmailSent =>
      'Если email зарегистрирован, проверьте почту и спам — там будет ссылка для сброса';

  @override
  String get resetPasswordTitle => 'Новый пароль';

  @override
  String get resetPasswordHint => 'Введите новый пароль для вашего аккаунта';

  @override
  String get newPasswordLabel => 'Новый пароль';

  @override
  String get confirmPasswordLabel => 'Подтвердите пароль';

  @override
  String get saveNewPassword => 'Сохранить пароль';

  @override
  String get passwordResetSuccess => 'Пароль изменён. Войдите с новым паролем';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get invalidResetLink =>
      'Ссылка для сброса недействительна. Запросите новую на экране входа';

  @override
  String get emailTypoGmail =>
      'Вы имели в виду @gmail.com? @google.com — не почтовый домен';

  @override
  String get emailTypoCon => 'Опечатка в домене: .con вместо .com?';

  @override
  String get companyId => 'Компания';

  @override
  String get gpsTrackingActive => 'GPS отслеживание активно';

  @override
  String get gpsTrackingStopped => 'GPS отслеживание остановлено';

  @override
  String get weekendDay => 'Выходной день';

  @override
  String get workDayEnded => 'Рабочий день закончен';

  @override
  String workStartsIn(int minutes) {
    return 'Работа начнется через $minutes минут';
  }

  @override
  String workEndsIn(int minutes) {
    return 'Работа закончится через $minutes минут';
  }

  @override
  String get edit => 'Редактировать';

  @override
  String editUser(String name) {
    return 'Редактировать $name';
  }

  @override
  String deleteUser(String name) {
    return 'Удалить $name?';
  }

  @override
  String get leaveEmptyToKeep => 'оставьте пустым, чтобы не менять';

  @override
  String get userUpdated => 'Пользователь обновлен';

  @override
  String get userDeleted => 'Пользователь удален';

  @override
  String get updateError => 'Ошибка обновления';

  @override
  String get deleteError => 'Ошибка удаления';

  @override
  String get noPermissionToEdit =>
      'У вас нет прав для редактирования этого пользователя';

  @override
  String get warehouseStartPoint => 'Начальная точка всех маршрутов';

  @override
  String get vehicleNumber => 'Номер машины';

  @override
  String get biometricLoginTitle => 'Включить вход по отпечатку?';

  @override
  String get biometricLoginMessage =>
      'Вы сможете входить в приложение используя отпечаток пальца вместо пароля.';

  @override
  String get biometricLoginYes => 'Да, включить';

  @override
  String get biometricLoginNo => 'Нет';

  @override
  String get biometricLoginEnabled => '✅ Вход по отпечатку включён';

  @override
  String get biometricLoginCancelled => 'Аутентификация отменена';

  @override
  String get biometricLoginError => 'Ошибка биометрии';

  @override
  String get biometricLoginButton => 'Войти с отпечатком';

  @override
  String get biometricLoginButtonFace => 'Войти с Face ID';

  @override
  String get biometricLoginOr => 'или';

  @override
  String get biometricAuthReason => 'Войдите с помощью отпечатка пальца';

  @override
  String get viewModeWarehouse => 'Режим просмотра: Кладовщик';

  @override
  String get returnToAdmin => 'Вернуться';

  @override
  String get manageBoxTypes => 'Управление справочником типов';

  @override
  String get boxTypesManager => 'Управление справочником типов';

  @override
  String get noBoxTypesInCatalog => 'Нет типов в справочнике';

  @override
  String get editBoxType => 'Редактировать тип';

  @override
  String get deleteBoxType => 'Удалить тип';

  @override
  String deleteBoxTypeConfirm(Object number, Object type) {
    return 'Удалить $type $number из справочника?';
  }

  @override
  String get boxTypeUpdated => 'Тип успешно обновлен!';

  @override
  String get boxTypeDeleted => 'Тип успешно удален!';

  @override
  String get addNewBoxType => 'Добавить новый тип в справочник';

  @override
  String get newBoxTypeAdded => 'Новый тип успешно добавлен на склад!';

  @override
  String get typeLabel => 'Тип (бутылка, крышка, стакан)';

  @override
  String get numberLabel => 'Номер (100, 200, и т.д.)';

  @override
  String get volumeMlLabel => 'Объем в мл (необязательно)';

  @override
  String get quantityLabel => 'Количество (единиц)';

  @override
  String get quantityPerPalletLabel => 'Количество на паллете';

  @override
  String get diameterLabel => 'Диаметр (необязательно)';

  @override
  String get piecesPerBoxLabel =>
      'Упаковка - количество в коробке (необязательно)';

  @override
  String get additionalInfoLabel => 'Дополнительная информация (необязательно)';

  @override
  String get requiredField => 'Обязательное поле';

  @override
  String get close => 'Закрыть';

  @override
  String formatHours(int hours) {
    return '$hours ч';
  }

  @override
  String formatMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get setWarehouseLocation => 'Установить местоположение склада';

  @override
  String get latitudeWarehouse => 'Широта (склад в Мишмарот)';

  @override
  String get longitudeWarehouse => 'Долгота (склад в Мишмарот)';

  @override
  String get clearPendingPoints => 'Очистить ожидающие точки';

  @override
  String get clearPendingPointsConfirm =>
      'Это удалит только ожидающие точки доставки (не активные маршруты). Продолжить?';

  @override
  String get clearPending => 'Очистить ожидающие';

  @override
  String get clearAllData => 'Очистить все данные';

  @override
  String get clearAllDataConfirm =>
      'Это удалит ВСЕ точки доставки. Вы уверены?';

  @override
  String get deleteAll => 'Удалить все';

  @override
  String get fixRouteNumbers => 'Исправить номера маршрутов';

  @override
  String get fixRouteNumbersConfirm =>
      'Это пересчитает номера маршрутов для всех водителей (1, 2, 3...). Продолжить?';

  @override
  String get fixNumbers => 'Исправить номера';

  @override
  String get dataMigration => 'Миграция данных';

  @override
  String get daysToMigrate => 'Дней для миграции';

  @override
  String get oneTimeSetup => 'Одноразовая настройка';

  @override
  String get migrationDescription =>
      'Это создаст сводные документы для существующих счетов и доставок.';

  @override
  String get migrationInstructions =>
      '• Запустите это ОДИН РАЗ после развертывания обновления\n• Занимает ~1 минуту для 30 дней данных\n• Безопасно запускать несколько раз (пересоздаст)';

  @override
  String get days => 'дней';

  @override
  String get warehouseInventoryManagement => 'Склад - управление инвентарем';

  @override
  String get addNewBoxTypeToCatalog => 'Добавить новый тип в справочник';

  @override
  String get showLowStockOnly => 'Показать только низкие остатки';

  @override
  String get changeHistory => 'История изменений';

  @override
  String get exportReport => 'Экспорт отчета';

  @override
  String get searchByTypeOrNumber => 'Поиск по типу или номеру...';

  @override
  String get noItemsToExport => 'Нет товаров для экспорта';

  @override
  String get reportExportedSuccessfully => 'Отчет успешно экспортирован';

  @override
  String get exportError => 'Ошибка экспорта';

  @override
  String get noItemsInInventory => 'Нет товаров на складе';

  @override
  String get noItemsFound => 'Товары не найдены';

  @override
  String get productCode => 'Артикул';

  @override
  String get productCodeLabel => 'Код товара *';

  @override
  String get productCodeHelper => 'Уникальный код для каждого товара';

  @override
  String get productCodeSearchHelper =>
      'Введите код товара для поиска в справочнике';

  @override
  String get productCodeFoundInCatalog => 'Код товара найден в справочнике';

  @override
  String get productCodeNotFoundInCatalog =>
      'Код товара не найден в справочнике';

  @override
  String get productCodeNotFoundAddFirst =>
      'Код товара не найден в справочнике. Сначала добавьте новый тип в справочник.';

  @override
  String get orSelectFromList => 'или выберите код товара из списка';

  @override
  String get selectFromFullList => 'Выбор из полного списка';

  @override
  String get lowStock => 'Низкий остаток!';

  @override
  String get limitedStock => 'Мало товара';

  @override
  String get volume => 'Объём (л)';

  @override
  String get ml => 'мл';

  @override
  String get diameter => 'Диаметр';

  @override
  String get packed => 'Упаковка';

  @override
  String get piecesInBox => 'шт. в коробке';

  @override
  String get quantityPerPallet => 'Количество на паллете';

  @override
  String get additionalInfo => 'Дополнительная информация';

  @override
  String get quantity => 'Количество';

  @override
  String get units => 'шт.';

  @override
  String remainingUnitsOnly(int count) {
    return 'Осталось всего $count единиц';
  }

  @override
  String get urgentOrderStock => 'Срочно! Необходимо заказать товар';

  @override
  String get updated => 'Обновлено';

  @override
  String get by => 'пользователем';

  @override
  String get addInventory => 'Добавить товар';

  @override
  String get inventoryUpdatedSuccessfully => 'Инвентарь успешно обновлен!';

  @override
  String get catalogEmpty =>
      'Справочник пуст. Сначала добавьте новый тип в справочник.';

  @override
  String get editItem => 'Редактировать товар';

  @override
  String get itemUpdatedSuccessfully => 'Товар успешно обновлен!';

  @override
  String get fillAllRequiredFields =>
      'Пожалуйста, заполните все обязательные поля';

  @override
  String get fillAllRequiredFieldsIncludingProductCode =>
      'Пожалуйста, заполните все обязательные поля (включая код товара)';

  @override
  String get typeUpdatedSuccessfully => 'Тип успешно обновлен!';

  @override
  String get deletedSuccessfully => 'Успешно удалено!';

  @override
  String get deleteConfirmation => 'Удалить';

  @override
  String get searchByProductCode => 'Поиск по коду товара, типу или номеру...';

  @override
  String get warehouseInventory => 'Склад';

  @override
  String get inventoryChangesReport => 'Отчет изменений склада';

  @override
  String get inventoryCountReportsTooltip => 'Отчеты инвентаризации';

  @override
  String get archiveManagement => 'Управление архивами';

  @override
  String get inventoryCount => 'Инвентаризация';

  @override
  String get inventoryCountReports => 'Отчеты по инвентаризации';

  @override
  String get startNewCount => 'Начать новую инвентаризацию';

  @override
  String get startNewCountConfirm =>
      'Начать новую инвентаризацию?\nЭто создаст список всех товаров на складе.';

  @override
  String get start => 'Начать';

  @override
  String get noActiveCount => 'Нет активной инвентаризации';

  @override
  String get countStarted => 'Новая инвентаризация начата';

  @override
  String get errorStartingCount => 'Ошибка начала инвентаризации';

  @override
  String get errorLoadingCount => 'Ошибка загрузки инвентаризации';

  @override
  String get errorUpdatingItem => 'Ошибка обновления товара';

  @override
  String get completeCount => 'Завершить инвентаризацию';

  @override
  String completeCountConfirm(int count) {
    return 'Еще $count товаров не подсчитаны.\nВсе равно завершить?';
  }

  @override
  String get finish => 'Завершить';

  @override
  String get countCompleted => 'Инвентаризация успешно завершена';

  @override
  String get errorCompletingCount => 'Ошибка завершения инвентаризации';

  @override
  String get showOnlyDifferences => 'Показать только расхождения';

  @override
  String get counted => 'Подсчитано';

  @override
  String get differences => 'Расхождения';

  @override
  String get shortage => 'Недостача';

  @override
  String get surplus => 'Излишек';

  @override
  String get searchByProductCodeTypeNumber => 'Поиск по коду / типу / номеру';

  @override
  String get noResults => 'Результаты не найдены';

  @override
  String get noDifferences => 'Нет расхождений';

  @override
  String get noItems => 'Нет товаров';

  @override
  String get expected => 'Ожидается';

  @override
  String get actualCounted => 'Подсчитано';

  @override
  String get difference => 'Разница';

  @override
  String get suspiciousOrders => 'Подозрительные заказы';

  @override
  String get notes => 'Заметки';

  @override
  String get notesOptional => 'Заметки (необязательно)';

  @override
  String get enterValidNumber => 'Введите корректное число';

  @override
  String get noCountReports => 'Нет отчетов по инвентаризации';

  @override
  String get countReport => 'Отчет по инвентаризации';

  @override
  String get performedBy => 'Выполнил';

  @override
  String get started => 'Начато';

  @override
  String get finished => 'Завершено';

  @override
  String get totalItems => 'Всего товаров';

  @override
  String get viewDetails => 'Просмотр деталей';

  @override
  String get approved => 'Утверждено';

  @override
  String get approveCount => 'Утвердить инвентаризацию';

  @override
  String get approveCountConfirm =>
      'Утвердить инвентаризацию и обновить склад?\nЭто обновит количество товаров в соответствии с подсчетом.';

  @override
  String get approveAndUpdate => 'Утвердить и обновить';

  @override
  String get countApproved => 'Инвентаризация утверждена и склад обновлен';

  @override
  String get errorApprovingCount => 'Ошибка утверждения инвентаризации';

  @override
  String get countNotFound => 'Отчет не найден';

  @override
  String get exportToExcel => 'Экспорт в Excel';

  @override
  String get exportToExcelSoon => 'Экспорт в Excel - скоро';

  @override
  String get countNotCompleted => 'Инвентаризация не завершена';

  @override
  String get errorLoadingReport => 'Ошибка загрузки отчета';

  @override
  String get items => 'Товары';

  @override
  String get selectDates => 'Выбрать даты';

  @override
  String get allPeriod => 'Весь период';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get thisWeek => 'Эта неделя';

  @override
  String get thisMonth => 'Этот месяц';

  @override
  String get all => 'Все';

  @override
  String get searchByProductCodeTypeNumberHint =>
      'Поиск по коду, типу или номеру...';

  @override
  String foundChanges(int count) {
    return 'Найдено: $count изменений';
  }

  @override
  String get added => 'Добавлено';

  @override
  String get deducted => 'Списано';

  @override
  String noResultsFor(String query) {
    return 'Нет результатов для \"$query\"';
  }

  @override
  String get noChangesInPeriod => 'Нет изменений за этот период';

  @override
  String get before => 'До';

  @override
  String get after => 'После';

  @override
  String get reason => 'Причина';

  @override
  String get statistics => 'Статистика';

  @override
  String get totalArchives => 'Всего архивов';

  @override
  String get totalSize => 'Общий размер';

  @override
  String get records => 'Записи';

  @override
  String get archiveActions => 'Действия архивирования';

  @override
  String get archiveInventoryHistory => 'Архивировать историю склада';

  @override
  String get archiveOrders => 'Архивировать заказы';

  @override
  String get existingArchives => 'Существующие архивы';

  @override
  String get noArchives => 'Нет архивов';

  @override
  String get archiveInventoryHistoryTitle => 'Архивирование истории склада';

  @override
  String get archiveInventoryHistoryConfirm =>
      'Архивировать старые записи за последние 3 месяца?\n\nЗаписи будут помечены как архивные и не будут удалены.';

  @override
  String get archiveCompletedOrdersTitle => 'Архивирование завершенных заказов';

  @override
  String get archiveCompletedOrdersConfirm =>
      'Архивировать заказы, завершенные месяц назад?\n\nЗаказы будут помечены как архивные и не будут удалены.';

  @override
  String get archive => 'Архивировать';

  @override
  String get errorLoadingArchives => 'Ошибка загрузки архивов';

  @override
  String get size => 'Размер';

  @override
  String get created => 'Создан';

  @override
  String get download => 'Скачать';

  @override
  String get mb => 'МБ';

  @override
  String get insufficientStock => 'Недостаточно товара на складе';

  @override
  String get cannotCreateOrderInsufficientStock =>
      'Невозможно создать заказ - недостаточно товара на складе:';

  @override
  String get pleaseContactWarehouseKeeper =>
      'Пожалуйста, обратитесь к кладовщику для обновления запасов.';

  @override
  String get understood => 'Понятно';

  @override
  String get available => 'Доступно';

  @override
  String get requested => 'Запрошено';

  @override
  String get itemNotFoundInInventory => 'Товар не найден в инвентаре';

  @override
  String get productCodeNotFound => 'Артикул не найден';

  @override
  String get companySettings => 'Настройки компании';

  @override
  String get companyDetails => 'Данные компании';

  @override
  String get companyNameHebrew => 'Название (иврит)';

  @override
  String get companyNameEnglish => 'Название (англ., необязательно)';

  @override
  String get taxId => 'ИНН';

  @override
  String get addressHebrew => 'Адрес (иврит)';

  @override
  String get addressEnglish => 'Адрес (английский)';

  @override
  String get poBox => 'Почтовый ящик';

  @override
  String get city => 'Город';

  @override
  String get zipCode => 'Индекс';

  @override
  String get contact => 'Контакты';

  @override
  String get fax => 'Факс';

  @override
  String get website => 'Сайт';

  @override
  String get defaultDriver => 'Водитель по умолчанию';

  @override
  String get driverName => 'Имя водителя';

  @override
  String get driverPhone => 'Телефон водителя';

  @override
  String get departureTime => 'Время выезда';

  @override
  String get invoice => 'Счёт';

  @override
  String get invoiceFooterText => 'Текст внизу счёта';

  @override
  String get paymentTerms => 'Условия оплаты';

  @override
  String get bankDetails => 'Банковские реквизиты';

  @override
  String get saveSettings => 'Сохранить настройки';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get errorSavingSettings => 'Ошибка сохранения настроек';

  @override
  String get errorLoadingSettings => 'Ошибка загрузки настроек';

  @override
  String get warning => 'Предупреждение';

  @override
  String get migrationWarning =>
      'Эта операция добавит ID компании ко всем существующим записям в базе данных. Убедитесь, что у вас есть резервная копия перед продолжением.';

  @override
  String get currentCompanyId => 'Текущий ID компании';

  @override
  String get startMigration => 'Начать миграцию';

  @override
  String get migrating => 'Миграция...';

  @override
  String get migrationStatistics => 'Статистика миграции';

  @override
  String get migrationLog => 'Журнал миграции';

  @override
  String get noMigrationYet => 'Миграция еще не выполнялась';

  @override
  String get overloadWarning => 'Предупреждение о перегрузке';

  @override
  String overloadWarningMessage(String driverName, int currentLoad, int newLoad,
      int totalLoad, int capacity) {
    return 'Водитель $driverName уже везёт $currentLoad паллет, добавление $newLoad паллет увеличит общую нагрузку до $totalLoad паллет (вместимость: $capacity паллет). Продолжить?';
  }

  @override
  String get continueAnyway => 'Продолжить всё равно';

  @override
  String get productManagement => 'Управление товарами';

  @override
  String get addProduct => 'Добавить товар';

  @override
  String get editProduct => 'Редактировать товар';

  @override
  String get deleteProduct => 'Удалить товар';

  @override
  String get productName => 'Название товара';

  @override
  String get category => 'Категория';

  @override
  String get unitsPerBox => 'Единиц в коробке';

  @override
  String get weight => 'Вес (кг)';

  @override
  String get inactive => 'Неактивен';

  @override
  String get showInactive => 'Показать неактивные';

  @override
  String get hideInactive => 'Скрыть неактивные';

  @override
  String get importFromExcel => 'Импорт из Excel';

  @override
  String get noProducts => 'Нет товаров';

  @override
  String get addFirstProduct => 'Добавить первый товар';

  @override
  String get productAdded => 'Товар добавлен';

  @override
  String get productUpdated => 'Товар обновлён';

  @override
  String get productDeleted => 'Товар удалён';

  @override
  String deleteProductConfirm(Object productName) {
    return 'Удалить $productName?';
  }

  @override
  String get allCategories => 'Все';

  @override
  String get categoryGeneral => 'Общие';

  @override
  String get categoryCups => 'Стаканы';

  @override
  String get categoryLids => 'Крышки';

  @override
  String get categoryContainers => 'Контейнеры';

  @override
  String get categoryBread => 'Хлеб';

  @override
  String get categoryDairy => 'Молочное';

  @override
  String get categoryShirts => 'Рубашки';

  @override
  String get categoryTrays => 'Подносы';

  @override
  String get categoryBottles => 'Бутылки';

  @override
  String get categoryBags => 'Пакеты';

  @override
  String get categoryBoxes => 'Коробки';

  @override
  String get terminology => 'Терминология';

  @override
  String get businessType => 'Тип бизнеса';

  @override
  String get selectBusinessType => 'Выберите тип бизнеса';

  @override
  String get businessTypePackaging => 'Упаковка и пластик';

  @override
  String get businessTypeFood => 'Продукты питания';

  @override
  String get businessTypeClothing => 'Одежда и текстиль';

  @override
  String get businessTypeConstruction => 'Стройматериалы';

  @override
  String get businessTypeCustom => 'Настроить вручную';

  @override
  String get unitName => 'Название единицы (ед.)';

  @override
  String get unitNamePlural => 'Название единицы (мн.)';

  @override
  String get palletName => 'Название паллеты (ед.)';

  @override
  String get palletNamePlural => 'Название паллеты (мн.)';

  @override
  String get usesPallets => 'Использует паллеты';

  @override
  String get capacityCalculation => 'Расчёт вместимости';

  @override
  String get capacityByUnits => 'По единицам';

  @override
  String get capacityByWeight => 'По весу';

  @override
  String get capacityByVolume => 'По объёму';

  @override
  String get terminologyUpdated => 'Терминология обновлена';

  @override
  String get applyTemplate => 'Применить шаблон';

  @override
  String get customTerminology => 'Своя терминология';

  @override
  String get invalidNumber => 'Неверное число';

  @override
  String get noCompanySelected => 'Компания не выбрана';

  @override
  String get addNewProduct => 'Добавить новый товар';

  @override
  String get terminologySettings => 'Настройки терминологии';

  @override
  String get selectTemplate => 'Выберите шаблон';

  @override
  String get or => 'или';

  @override
  String get customSettings => 'Свои настройки';

  @override
  String get downloadTemplate => 'Скачать шаблон';

  @override
  String importSuccess(Object count) {
    return 'Импортировано $count товаров';
  }

  @override
  String get importError => 'Ошибка импорта';

  @override
  String get exportSuccess => 'Файл скачан';

  @override
  String get templateDownloaded => 'Шаблон скачан';

  @override
  String get billingAndLocks => 'Биллинг и блокировки';

  @override
  String get billingPortal => 'Портал оплаты';

  @override
  String get moduleManagement => 'Управление модулями';

  @override
  String get subscriptionManagement => 'Управление подпиской';

  @override
  String get subscription => 'Подписка';

  @override
  String get currentPlan => 'Текущий план';

  @override
  String get changePlan => 'Сменить план';

  @override
  String get changePlanConfirm => 'Сменить план?';

  @override
  String get payNow => 'Оплатить';

  @override
  String get contactSupport => 'Связаться с поддержкой';

  @override
  String get paymentHistory => 'История платежей';

  @override
  String get noPaymentHistory => 'Нет истории платежей';

  @override
  String get reports => 'Отчёты';

  @override
  String get integrityCheck => 'Проверка целостности';

  @override
  String get documentType => 'Тип документа';

  @override
  String get checkRange => 'Диапазон проверки';

  @override
  String get backupManagement => 'Управление бэкапами';

  @override
  String get backupHistory => 'История бэкапов';

  @override
  String get noBackups => 'Нет бэкапов';

  @override
  String get createBackup => 'Создать бэкап';

  @override
  String get backupLocation => 'Расположение бэкапа';

  @override
  String get backupCreated => 'Бэкап создан успешно';

  @override
  String get restoreTest => 'Тест восстановления';

  @override
  String get restoreTestHistory => 'История тестов восстановления';

  @override
  String get complianceReport => 'Отчёт о соответствии';

  @override
  String get dataRetention => 'Политика хранения данных';

  @override
  String get retentionCheck => 'Проверка хранения';

  @override
  String get retentionHistory => 'История проверок';

  @override
  String get runCheck => 'Запустить проверку';

  @override
  String get compliant => 'Соответствует';

  @override
  String get notCompliant => 'Не соответствует';

  @override
  String get totalDocuments => 'Всего документов';

  @override
  String get oldestDocument => 'Самый старый документ';

  @override
  String get sequentialGaps => 'Пропуски в нумерации';

  @override
  String get notifications => 'Уведомления';

  @override
  String get markAllRead => 'Отметить все как прочитанные';

  @override
  String get noNotifications => 'Нет уведомлений';

  @override
  String get upgradePlan => 'Обновить план';

  @override
  String get accountSuspended => 'Аккаунт заблокирован';

  @override
  String get accountGrace => 'Льготный период';

  @override
  String get trialEnding => 'Пробный период заканчивается';

  @override
  String get savePlan => 'Сохранить';

  @override
  String get noAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get cancelAction2 => 'Отмена';

  @override
  String get reportsTitle => 'Отчёты';

  @override
  String get monthlyReport => 'Месячный отчёт';

  @override
  String get vatReport => 'Отчёт НДС';

  @override
  String get clientReport => 'Отчёт по клиентам';

  @override
  String get reportStockTab => 'Остатки склада';

  @override
  String get reportStockSku => 'Артикул';

  @override
  String get reportStockProduct => 'Товар';

  @override
  String get reportStockQty => 'Кол-во (шт)';

  @override
  String get reportStockPallets => 'Миштахи';

  @override
  String get reportStockTotalSkus => 'Позиций';

  @override
  String get reportStockTotalUnits => 'Всего единиц';

  @override
  String get reportStockTotalPallets => 'Всего миштахов';

  @override
  String get errorLoadingData => 'Ошибка загрузки данных';

  @override
  String get noDataToDisplay => 'Нет данных для отображения';

  @override
  String get exportCsv => 'Экспорт CSV';

  @override
  String get monthColumn => 'Месяц';

  @override
  String get documentsColumn => 'Документы';

  @override
  String get netAmount => 'Нетто (₪)';

  @override
  String get vatAmount => 'НДС (₪)';

  @override
  String get grossAmount => 'Брутто (₪)';

  @override
  String get csvCopiedToClipboard => 'CSV скопирован в буфер';

  @override
  String get totalVatForPeriod => 'Итого НДС за период';

  @override
  String get taxBase => 'Налоговая база';

  @override
  String get taxBaseAmount => 'Налоговая база (₪)';

  @override
  String get vatRateColumn => 'Ставка НДС';

  @override
  String get customerColumn => 'Клиент';

  @override
  String get taxIdShort => 'ИНН';

  @override
  String get unknownCustomer => 'Неизвестно';

  @override
  String customersCount(int count) {
    return '$count клиентов';
  }

  @override
  String get issuedDocuments => 'Выпущенные документы';

  @override
  String draftsCount(int count) {
    return 'Черновики: $count';
  }

  @override
  String get totalRevenueGross => 'Итого доход (Брутто)';

  @override
  String netLabel(String amount) {
    return 'Нетто: ₪$amount';
  }

  @override
  String get vatPercent => 'НДС (18%)';

  @override
  String get forTaxAuthorities => 'Для налоговой';

  @override
  String get creditNotes => 'Кредит-ноты';

  @override
  String get accountingDocuments => 'Бухгалтерские документы';

  @override
  String get createDocument => 'Создать документ';

  @override
  String get allFilter => 'Все';

  @override
  String get errorLoadingDocuments => 'Ошибка загрузки документов';

  @override
  String get noDocuments => 'Нет документов';

  @override
  String get columnType => 'Тип';

  @override
  String get columnNumber => 'Номер';

  @override
  String get columnCustomer => 'Клиент';

  @override
  String get columnAmount => 'Сумма';

  @override
  String get columnStatus => 'Статус';

  @override
  String get columnDate => 'Дата';

  @override
  String get columnActions => 'Действия';

  @override
  String get draftStatus => 'Черновик';

  @override
  String get issuedStatus => 'Выпущен';

  @override
  String get lockedStatus => 'Заблокирован';

  @override
  String get creditedStatus => 'Зачтён';

  @override
  String get voidedStatus => 'Аннулирован';

  @override
  String get taxInvoice => 'Налоговая накладная';

  @override
  String get receipt => 'Квитанция';

  @override
  String get taxInvoiceReceipt => 'Налоговая накладная/Квитанция';

  @override
  String get creditNote => 'Кредит-нота';

  @override
  String get editTooltip => 'Редактировать';

  @override
  String get issueTooltip => 'Выпустить';

  @override
  String get cancelTooltip => 'Отменить';

  @override
  String get createCreditNote => 'Создать кредит-ноту';

  @override
  String get issueDocumentTitle => 'Выпуск документа';

  @override
  String issueDocumentConfirm(String name) {
    return 'Выпустить документ \"$name\"?\n\nПосле выпуска ключевые поля (номер, дата, клиент, строки, суммы) станут неизменяемыми.';
  }

  @override
  String get issueButton => 'Выпустить';

  @override
  String get documentIssuedSuccess => 'Документ успешно выпущен';

  @override
  String errorIssuingDocument(String error) {
    return 'Ошибка выпуска документа: $error';
  }

  @override
  String get voidDocumentTitle => 'Аннулирование документа';

  @override
  String voidDocumentConfirm(String name) {
    return 'Аннулировать документ \"$name\"?';
  }

  @override
  String get voidReasonLabel => 'Причина аннулирования *';

  @override
  String get voidReasonRequired => 'Укажите причину аннулирования';

  @override
  String get backButton => 'Назад';

  @override
  String get voidDocumentButton => 'Аннулировать';

  @override
  String get documentVoidedSuccess => 'Документ успешно аннулирован';

  @override
  String errorVoidingDocument(String error) {
    return 'Ошибка аннулирования документа: $error';
  }

  @override
  String get immutableFieldsTooltip => 'Ключевые поля заблокированы';

  @override
  String get selectDocType => 'Выберите тип документа';

  @override
  String newDocumentTitle(String type) {
    return 'Новый документ — $type';
  }

  @override
  String get customerDetails => 'Данные клиента';

  @override
  String get customerNameRequired => 'Имя клиента *';

  @override
  String get taxIdLabel => 'ИНН';

  @override
  String get documentLines => 'Строки документа';

  @override
  String get addLine => 'Добавить строку';

  @override
  String descriptionN(int n) {
    return 'Описание $n';
  }

  @override
  String get quantityShort => 'Кол-во';

  @override
  String get unitPriceLabel => 'Цена за ед.';

  @override
  String get vatRateLabel => 'НДС';

  @override
  String get removeLine => 'Удалить строку';

  @override
  String get summaryTitle => 'Итого';

  @override
  String get netBeforeVat => 'Итого до НДС (Нетто)';

  @override
  String get vatLabelCalc => 'НДС';

  @override
  String get grossWithVat => 'Итого с НДС (Брутто)';

  @override
  String get saveDraft => 'Сохранить черновик';

  @override
  String get notesLabel => 'Заметки';

  @override
  String get invalidValue => 'Некорректно';

  @override
  String get documentCreatedSuccess => 'Документ успешно создан';

  @override
  String errorCreatingDoc(String error) {
    return 'Ошибка создания документа: $error';
  }

  @override
  String get documentChainTitle => 'Цепочка документов';

  @override
  String get errorLoadingChain => 'Ошибка загрузки цепочки документов';

  @override
  String get noRelatedDocs => 'Связанные документы не найдены';

  @override
  String get originalDocBadge => 'Оригинал';

  @override
  String get currentDocBadge => 'Текущий';

  @override
  String get totalSummary => 'Итого';

  @override
  String get loadingAdvice => 'Рекомендация по загрузке';

  @override
  String capacityLabel(Object count) {
    return 'Вместимость: $count поддонов';
  }

  @override
  String overCapacity(Object current, Object max) {
    return 'Превышение: $current/$max поддонов';
  }

  @override
  String canCombineAdjacent(Object names) {
    return '$names → 1 общий поддон';
  }

  @override
  String canCombineDistant(Object names) {
    return '$names → можно объединить, но водителю придётся перекладывать';
  }

  @override
  String savingPallets(Object count) {
    return 'Экономия: $count';
  }

  @override
  String get hideGpsTracks => 'Скрыть GPS-треки';

  @override
  String get showGpsTracks => 'Показать GPS-треки за 24ч';

  @override
  String get mapTooltipCurrentRoute => 'Текущий маршрут';

  @override
  String get mapTooltipPreviousRoute => 'Предыдущий маршрут';

  @override
  String get mapTooltipClearMap => 'Очистить карту';

  @override
  String get mapTooltipExitDemo => 'Выйти из демо';

  @override
  String get mapTooltipDemoMode => 'Демо-режим';

  @override
  String get mapBannerPreviousRouteShown => 'Показан предыдущий маршрут';

  @override
  String get mapDemoRoutesBuilt => 'Построено 3 оптимальных маршрута';

  @override
  String get mapDemoWarehouseCreatedDeliveries =>
      'Склад сформировал 12 доставок';

  @override
  String get mapDemoTruckLoading => 'Погрузка: 12 доставок загружено со склада';

  @override
  String get mapDemoTasksSentToDrivers => 'Задания отправлены водителям';

  @override
  String get mapDemoActiveDriver => 'Активный водитель';

  @override
  String get mapDemoDirectionToWarehouse => 'На склад';

  @override
  String get mapDemoDirectionUnknown => 'Неизвестно';

  @override
  String mapDemoDirectionLabel(String direction) {
    return 'Направление: $direction';
  }

  @override
  String mapDemoEtaMinutes(int minutes) {
    return 'ETA: ~$minutes мин';
  }

  @override
  String get mapDemoStage1Title => 'Заказ получен';

  @override
  String get mapDemoStage1Desc =>
      'Клиент отправляет заявку на доставку диспетчеру.';

  @override
  String get mapDemoStage2Title => 'Отправка на склад';

  @override
  String get mapDemoStage2Desc =>
      'Диспетчер передаёт заказ на склад для комплектации.';

  @override
  String get mapDemoStage3Title => 'Подготовка на складе';

  @override
  String get mapDemoStage3Desc =>
      'Сотрудники собирают товар и формируют паллеты.';

  @override
  String get mapDemoStage4Title => 'Маршрут создан';

  @override
  String get mapDemoStage4Desc =>
      'Диспетчер строит оптимальный маршрут со всеми точками.';

  @override
  String get mapDemoStage5Title => 'Погрузка в машину';

  @override
  String get mapDemoStage5Desc => 'Паллеты загружаются на машину водителя.';

  @override
  String get mapDemoStage6Title => 'Водитель в пути';

  @override
  String get mapDemoStage6Desc =>
      'Водитель едет по маршруту — на карте видны улицы.';

  @override
  String get mapDemoStage7Title => 'Разгрузка и доставка';

  @override
  String get mapDemoStage7Desc =>
      'На каждой точке разгрузка; точка автоматически отмечается выполненной.';

  @override
  String get mapDemoStage8Title => 'Возврат на склад';

  @override
  String get mapDemoStage8Desc =>
      'Водитель завершает маршрут и возвращается на базу.';

  @override
  String get mapDemoStageCompleteTitle => 'Симуляция завершена';

  @override
  String get mapDemoStageCompleteDesc =>
      'Полный цикл доставки успешно выполнен.';

  @override
  String mapDemoStopLabel(int number) {
    return 'Точка $number';
  }

  @override
  String mapDemoDeliveringAt(String stop) {
    return 'Разгрузка: $stop';
  }

  @override
  String get mapDemoReplay => 'Повторить симуляцию';

  @override
  String get mapDemoLiveBadge => 'LIVE';

  @override
  String get mapDemoKpiMileage => 'пробег';

  @override
  String get mapDemoKpiEtaAccuracy => 'точность ETA';

  @override
  String get mapDemoKpiCalls => 'звонков';

  @override
  String get mapDemoKpiDelivered => 'доставлено';

  @override
  String get mapDemoKpiEnroute => 'в пути';

  @override
  String get mapDemoKpiDistance => 'маршрут';

  @override
  String get mapDemoKpiLate => 'опозданий';

  @override
  String get mapDemoEtaAccuracyValue => '±3 мин';

  @override
  String get mapDemoFinishSubtitle => 'Диспетчер видел всё в реальном времени';

  @override
  String get mapDemoFinishNote =>
      'Ни одного звонка водителю «ты где?» за весь маршрут';

  @override
  String mapDemoMinutesShort(int minutes) {
    return '~$minutes мин';
  }

  @override
  String mapDemoKmShort(String km) {
    return '$km км';
  }

  @override
  String get mapDemoStepShort1 => 'Заказ';

  @override
  String get mapDemoStepShort2 => 'Склад';

  @override
  String get mapDemoStepShort3 => 'Сборка';

  @override
  String get mapDemoStepShort4 => 'Маршрут';

  @override
  String get mapDemoStepShort5 => 'Погрузка';

  @override
  String get mapDemoStepShort6 => 'В пути';

  @override
  String get mapDemoStepShort7 => 'Доставка';

  @override
  String get mapDemoStepShort8 => 'Возврат';

  @override
  String get billingGuardAccessSuspendedTitle => 'Доступ приостановлен';

  @override
  String get billingGuardAccessSuspendedBody =>
      'Аккаунт приостановлен из-за неоплаты. Оплатите, чтобы восстановить доступ.';

  @override
  String get billingGuardAccountCancelledTitle => 'Аккаунт отменён';

  @override
  String get billingGuardAccountCancelledBody =>
      'Аккаунт отменён. Свяжитесь с поддержкой для возобновления.';

  @override
  String get billingGuardTrialEndedTitle => 'Пробный период окончен';

  @override
  String get billingGuardTrialEndedBody =>
      'Пробный период закончился. Перейдите на платный тариф.';

  @override
  String get billingGuardNoAccessTitle => 'Нет доступа';

  @override
  String get billingGuardNoAccessBody => 'Свяжитесь с поддержкой.';

  @override
  String get billingGuardContactSupport => 'Связаться с поддержкой';

  @override
  String get billingGuardPayNow => 'Оплатить сейчас';

  @override
  String get billingGuardUpgrade => 'Улучшить тариф';

  @override
  String billingGuardTrialBanner(int days, String date) {
    return 'Пробный период — осталось $days дн. (до $date)';
  }

  @override
  String billingGuardGraceBanner(int days) {
    return 'Отсрочка — осталось $days дн. для оплаты. Затем аккаунт будет заблокирован.';
  }

  @override
  String get billingGuardCheckoutOpened =>
      'Страница оплаты открыта в браузере. После оплаты аккаунт обновится автоматически.';

  @override
  String billingGuardCheckoutError(String error) {
    return 'Ошибка открытия оплаты: $error';
  }

  @override
  String get companySettingsNotSelected => 'Компания не выбрана';

  @override
  String companySettingsInitError(String error) {
    return 'Ошибка инициализации: $error';
  }

  @override
  String get companySettingsEmptyWarning =>
      'Настройки не найдены. Заполните форму.';

  @override
  String companySettingsLoadError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get billingDashboardTitle => 'Панель биллинга';

  @override
  String get billingDashboardFilterAll => 'Все';

  @override
  String get billingDashboardFilterTrial => '🧪 Пробный';

  @override
  String get billingDashboardFilterActive => '✅ Активен';

  @override
  String get billingDashboardFilterGrace => '⏳ Отсрочка';

  @override
  String get billingDashboardFilterSuspended => '🚫 Приостановлен';

  @override
  String get billingDashboardFilterCancelled => '❌ Отменён';

  @override
  String get billingDashboardSearchHint => 'Поиск…';

  @override
  String get billingDashboardNoCompanies => 'Компании не найдены';

  @override
  String billingDashboardExtendTitle(String companyName) {
    return 'Продлить $companyName';
  }

  @override
  String billingDashboardExtendPaidUntil(String date) {
    return 'Установить оплату до: $date';
  }

  @override
  String get billingDashboardNoteLabel => 'Примечание (обязательно)';

  @override
  String get billingDashboardNoteDefault => 'Продлено через панель';

  @override
  String get billingDashboardExtendButton => 'Продлить';

  @override
  String billingDashboardChangeStatusTitle(String companyName, String status) {
    return 'Изменить $companyName → $status?';
  }

  @override
  String get billingDashboardChangeStatusBody =>
      'Статус биллинга изменится сразу.';

  @override
  String billingDashboardStatusUpdated(String companyName, String status) {
    return '$companyName → $status';
  }

  @override
  String get billingDashboardIntegrityRunning => 'Запуск проверки целостности…';

  @override
  String get billingDashboardIntegrityDone => 'Проверка целостности завершена';

  @override
  String get billingDashboardRunIntegrityTooltip => 'Проверка целостности';

  @override
  String get billingDashboardSeedPricingTooltip =>
      'Загрузить тарифы в Firestore';

  @override
  String get billingDashboardSeedPricingTitle =>
      'Обновить config/billing_pricing?';

  @override
  String get billingDashboardSeedPricingBody =>
      'Записывает текущую сетку тарифов (logistics, warehouse, ops, full) в Firestore config/billing_pricing. Checkout сразу начнёт использовать эти цены.';

  @override
  String get billingDashboardSeedPricingButton => 'Загрузить';

  @override
  String get billingDashboardSeedPricingRunning => 'Загрузка тарифов…';

  @override
  String billingDashboardSeedPricingDone(String plans) {
    return 'Тарифы обновлены: $plans';
  }

  @override
  String billingDashboardExtendSuccess(String companyName, String date) {
    return '$companyName: продлено до $date';
  }

  @override
  String billingDashboardError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get billingLabelProvider => 'Провайдер';

  @override
  String get billingLabelPaidUntil => 'Оплачено до';

  @override
  String get billingLabelTrialUntil => 'Пробный до';

  @override
  String get billingLabelGraceUntil => 'Отсрочка до';

  @override
  String get billingLabelGraceDays => 'Дней отсрочки';

  @override
  String get billingActionExtend => 'Продлить';

  @override
  String get billingActionActive => 'Активен';

  @override
  String get billingActionGrace => 'Отсрочка';

  @override
  String get billingActionSuspend => 'Блокировать';

  @override
  String dispatcherInvalidCoordinates(String error) {
    return 'Неверные координаты: $error';
  }

  @override
  String dispatcherPrintError(String error) {
    return 'Ошибка печати: $error';
  }

  @override
  String dispatcherGenericError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String dispatcherWarehouseSaved(String coords) {
    return 'Координаты склада сохранены: $coords';
  }

  @override
  String get dispatcherTourStopTooltip => 'Закрыть презентацию';

  @override
  String get dispatcherTourStartTooltip => 'Презентация LogiRoute';

  @override
  String dispatcherTourProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get salesDemoSkip => 'Пропустить';

  @override
  String get salesDemoNext => 'Далее';

  @override
  String get salesDemoBack => 'Назад';

  @override
  String get salesDemoGetStarted => 'Начать';

  @override
  String get salesDemoSeeLiveDemo => 'Живое демо';

  @override
  String get salesDemoBrandTagline => 'Платформа логистики под ключ';

  @override
  String get salesDemoSlide1Title => 'Логистика не должна быть хаосом';

  @override
  String get salesDemoSlide1Subtitle =>
      'Ручные маршруты, срывы доставок и разрозненные команды отнимают время и деньги каждый день.';

  @override
  String get salesDemoSlide1Benefit1 => 'Часы уходят на таблицы и звонки';

  @override
  String get salesDemoSlide1Benefit2 =>
      'Нет видимости автопарка в реальном времени';

  @override
  String get salesDemoSlide1Benefit3 => 'Счета и доставки не совпадают';

  @override
  String get salesDemoSlide2Title => 'Знакомьтесь — LogiRoute';

  @override
  String get salesDemoSlide2Subtitle =>
      'Одна платформа для склада, диспетчеризации, водителей и биллинга — готова к росту.';

  @override
  String get salesDemoSlide2Benefit1 => 'От заказа до счёта в одном потоке';

  @override
  String get salesDemoSlide2Benefit2 =>
      'Веб и мобильные — команда всегда на связи';

  @override
  String get salesDemoSlide2Benefit3 => 'Создано для реальной диспетчеризации';

  @override
  String get salesDemoPersonaAdmin => 'Админ';

  @override
  String get salesDemoPersonaDispatcher => 'Диспетчер';

  @override
  String get salesDemoPersonaDriver => 'Водитель';

  @override
  String get salesDemoPersonaAdminDesc =>
      'Полный контроль: компании, пользователи, биллинг и аналитика в одной панели.';

  @override
  String get salesDemoPersonaDispatcherDesc =>
      'Стройте маршруты, назначайте водителей и отслеживайте каждую доставку на карте.';

  @override
  String get salesDemoPersonaDriverDesc =>
      'Чёткие задания, порядок остановок и мгновенные статусы с дороги.';

  @override
  String get salesDemoSlide3Title => 'Умная маршрутизация';

  @override
  String get salesDemoSlide3Subtitle =>
      'Оптимальные маршруты за минуты — не за часы.';

  @override
  String get salesDemoSlide3Benefit1 => 'Автоматическая оптимизация маршрутов';

  @override
  String get salesDemoSlide3Benefit2 => 'Назначение водителей перетаскиванием';

  @override
  String get salesDemoSlide3Benefit3 => 'Живая карта всех активных доставок';

  @override
  String get salesDemoSlide4Title => 'Приложение водителя и трекинг';

  @override
  String get salesDemoSlide4Subtitle =>
      'Каждый водитель знает маршрут — вы видите прогресс в реальном времени.';

  @override
  String get salesDemoSlide4Benefit1 => 'Задания мгновенно на телефон водителя';

  @override
  String get salesDemoSlide4Benefit2 => 'GPS-трекинг на интерактивной карте';

  @override
  String get salesDemoSlide4Benefit3 => 'Меньше звонков, быстрее доставки';

  @override
  String get salesDemoSlide5Title => 'От склада до счёта';

  @override
  String get salesDemoSlide5Subtitle =>
      'Полный жизненный цикл заказа — ничего не теряется.';

  @override
  String get salesDemoSlide5Benefit1 => 'Складские процессы сборки и погрузки';

  @override
  String get salesDemoSlide5Benefit2 => 'Счета привязаны к каждой доставке';

  @override
  String get salesDemoSlide5Benefit3 => 'Полный аудит по каждому заказу';

  @override
  String get salesDemoLifecycleOrder => 'Заказ';

  @override
  String get salesDemoLifecycleDispatch => 'Диспетчер';

  @override
  String get salesDemoLifecycleDelivery => 'Доставка';

  @override
  String get salesDemoLifecycleInvoice => 'Счёт';

  @override
  String get salesDemoSlide6Title => 'Корпоративный уровень';

  @override
  String get salesDemoSlide6Subtitle =>
      'Профессионально, безопасно и готово к росту вашей доставки.';

  @override
  String get salesDemoSlide6Benefit1 => 'Ролевой доступ для каждого сотрудника';

  @override
  String get salesDemoSlide6Benefit2 =>
      'Английский, русский и иврит из коробки';

  @override
  String get salesDemoSlide6Benefit3 =>
      'Доверие диспетчерских команд каждый день';

  @override
  String dispatcherSkippedInvoicesMakor(int count) {
    return 'Пропущено $count счетов — оригинал уже напечатан. Для повторной печати используйте управление счетами.';
  }

  @override
  String get dispatcherCopiesOnlyPendingTax =>
      'Напечатаны только копии — ожидается номер присвоения. Оригинал после одобрения налоговой.';

  @override
  String pointUpdatedSuccess(String name) {
    return 'Точка обновлена: $name';
  }

  @override
  String dispatcherPointReturnedToRoute(String name) {
    return '$name возвращён на маршрут';
  }

  @override
  String get dispatcherManualCompleteTitle => 'Отметить доставлено';

  @override
  String dispatcherManualCompleteMessage(String name) {
    return 'Отметить «$name» доставленным вручную? Если авто-закрытие не сработало.';
  }

  @override
  String get dispatcherManualCompleteTooltip => 'Закрыть точку вручную';

  @override
  String dispatcherPointCompletedManually(String name) {
    return '$name отмечена доставленной';
  }

  @override
  String dispatcherPointAssignedToDriver(String client, String driver) {
    return 'Точка назначена: $client → $driver';
  }

  @override
  String dispatcherAssignDriverTitle(String clientName) {
    return 'Назначить водителя — $clientName';
  }

  @override
  String dispatcherDragAssignSuccess(String driverName) {
    return 'Точка назначена → $driverName';
  }

  @override
  String autoDistributeFailed(String error) {
    return 'Ошибка автораспределения: $error';
  }

  @override
  String companySettingsSaveFailed(String error) {
    return 'Ошибка сохранения настроек: $error';
  }

  @override
  String get makorOriginalPrintedTitle => 'Оригинал уже напечатан';

  @override
  String get makorDocTypeDeliveryNote => 'Накладная';

  @override
  String get makorDocTypeTaxInvoiceReceipt => 'Счёт-фактура / квитанция';

  @override
  String get makorDocTypeTaxInvoice => 'Счёт-фактура';

  @override
  String makorInvoiceLineNumbered(String docType, String seq) {
    return '$docType № $seq';
  }

  @override
  String makorClientLine(String name) {
    return 'Клиент: $name';
  }

  @override
  String get makorBooksLawWarning =>
      'По закону о бухучёте — нельзя напечатать ещё один оригинал.\nМожно только копию или заверенную копию.';

  @override
  String get makorChoosePrintType => 'Выберите тип печати:';

  @override
  String get makorCopy => 'Копия';

  @override
  String makorCopySubtitle(int n) {
    return 'Копия номер $n';
  }

  @override
  String get makorTrueToOriginal => 'Верно к оригиналу';

  @override
  String get makorTrueToOriginalSubtitle => 'Заменяет оригинал';

  @override
  String get makorCopyQuantity => 'Количество копий:';

  @override
  String get makorPrintButton => 'Печать';

  @override
  String get vatId => 'ИНН / Номер плательщика';

  @override
  String get deliveryZones => 'Зоны доставки';

  @override
  String get zonesRequired => 'Необходимо выбрать хотя бы одну зону';

  @override
  String get manualCoordinates => 'Ввести координаты вручную';

  @override
  String get manualCoordinatesSubtitle =>
      'Используйте если геокодирование не работает';

  @override
  String get latitude => 'Широта (Latitude)';

  @override
  String get longitude => 'Долгота (Longitude)';

  @override
  String get latitudeExample => 'Например: 31.9539907';

  @override
  String get longitudeExample => 'Например: 34.8062546';

  @override
  String get enterManualCoordinates => 'Ввести координаты вручную';

  @override
  String get balanceRoutes => 'Балансировать маршруты';

  @override
  String get balanceRoutesConfirm =>
      'Сбалансировать маршруты? Система перенесёт точки с перегруженных маршрутов на лёгкие.';

  @override
  String get routesBalanced => 'Маршруты сбалансированы';

  @override
  String get routesAlreadyBalanced => 'Маршруты уже сбалансированы';

  @override
  String get balancingRoutes => 'Балансировка маршрутов...';

  @override
  String movedPoints(Object count) {
    return '$count точек перенесено между маршрутами';
  }

  @override
  String get navigationOpenError => 'Ошибка открытия навигации';

  @override
  String get driverFallbackName => 'Водитель';

  @override
  String get driverActive => 'Активен';

  @override
  String get printAllInvoicesTooltip => 'Печать всех счетов';

  @override
  String get pickingListTooltip => 'Лист комплектации';

  @override
  String get createInvoiceTooltip => 'Создать счёт';

  @override
  String get createDeliveryNoteTooltip => 'Создать накладную';

  @override
  String autoCompletedPointsTitle(Object count) {
    return 'Автоматически закрытые точки ($count)';
  }

  @override
  String get skipClientTitle => 'Пропустить клиента?';

  @override
  String skipClientContent(Object clientName) {
    return 'Пропустить $clientName и продолжить?';
  }

  @override
  String get stopAllButton => 'Остановить всё';

  @override
  String get skipAndContinueButton => 'Пропустить и продолжить';

  @override
  String invoicesPrintedSuccess(Object count) {
    return '✅ $count счетов напечатано';
  }

  @override
  String printingErrorMessage(Object error) {
    return '❌ Ошибка печати: $error';
  }

  @override
  String get finishCountButton => 'Завершить подсчёт';

  @override
  String uncheckedItemsWarning(Object count) {
    return 'Ещё $count позиций не подсчитано.\nЗавершить всё равно?';
  }

  @override
  String get searchByCodeTypeNumberHint => 'Поиск по коду / типу / номеру';

  @override
  String get noResultsFoundLabel => 'Результаты не найдены';

  @override
  String get noDifferencesLabel => 'Нет расхождений';

  @override
  String get noItemsLabel => 'Нет товаров';

  @override
  String get totalItemsLabel => 'Всего товаров';

  @override
  String get countedLabel => 'Подсчитано';

  @override
  String get differencesLabel => 'Расхождения';

  @override
  String get shortageLabel => 'Недостача';

  @override
  String get surplusLabel => 'Излишек';

  @override
  String get countStartedLabel => 'Начато';

  @override
  String get countFinishedLabel => 'Завершено';

  @override
  String errorLoadingCountMessage(Object error) {
    return 'Ошибка загрузки подсчёта: $error';
  }

  @override
  String errorStartingCountMessage(Object error) {
    return 'Ошибка начала подсчёта: $error';
  }

  @override
  String errorCompletingCountMessage(Object error) {
    return 'Ошибка завершения подсчёта: $error';
  }

  @override
  String get reopenPoint => 'Вернуть';

  @override
  String get deductionForOrderReason => 'Списание при создании заказа';

  @override
  String get inventoryActionAdd => 'Добавлено';

  @override
  String get inventoryActionDeduct => 'Списано';

  @override
  String get inventoryActionUpdate => 'Обновлено';

  @override
  String get priceManagement => 'Управление ценами';

  @override
  String updatePriceTitle(String type, String number) {
    return 'Обновить цену - $type $number';
  }

  @override
  String get priceBeforeVatLabel => 'Цена без НДС (₪)';

  @override
  String get priceBeforeVatHint => 'Цена указана без НДС (18%)';

  @override
  String get enterValidPrice => 'Введите корректную цену';

  @override
  String get priceUpdatedSuccess => 'Цена успешно обновлена';

  @override
  String priceUpdateError(String error) {
    return 'Ошибка обновления цены: $error';
  }

  @override
  String get searchBySkuTypeNumber => 'Поиск по артикулу, типу или номеру';

  @override
  String get noResultsFound => 'Результаты не найдены';

  @override
  String skuLabel(String code) {
    return 'Артикул: $code';
  }

  @override
  String priceDisplay(String price) {
    return 'Цена: ₪$price (без НДС)';
  }

  @override
  String get noPriceSet => 'Цена не установлена';

  @override
  String volumeMlDisplay(int volume) {
    return '$volume мл';
  }

  @override
  String get integrityCheckTitle => 'Проверка целостности данных';

  @override
  String get documentTypeLabel => 'Тип документа:';

  @override
  String get checkRangeLabel => 'Диапазон проверки:';

  @override
  String lastNItems(int count) {
    return 'Последние $count';
  }

  @override
  String get checking => 'Проверка...';

  @override
  String get checkIntegrity => 'Проверить целостность';

  @override
  String get noDocumentsOfType => 'Нет документов этого типа';

  @override
  String rangeLabel(int from, int to) {
    return 'Диапазон: $from..$to';
  }

  @override
  String checkedCount(int count) {
    return 'Проверено: $count';
  }

  @override
  String lastHashLabel(String hash) {
    return 'Последний Hash: $hash...';
  }

  @override
  String breakAtDocument(int number) {
    return 'Разрыв в документе: #$number';
  }

  @override
  String reasonLabel(String reason) {
    return 'Причина: $reason';
  }

  @override
  String get integrityCheckExplain =>
      'Проверяет криптоцепочку нумерации документов. Документы, созданные до внедрения цепочки, автоматически пропускаются — это не ошибка.';

  @override
  String get integrityLegacyOnly =>
      'Записей цепочки нет: все документы этого типа созданы до внедрения проверки. Новые документы будут проверяться нормально.';

  @override
  String integrityLegacySkipped(int from, int to) {
    return 'Пропущены старые номера #$from–#$to (до первой записи в цепочке)';
  }

  @override
  String integrityCheckedFrom(int from, int to) {
    return 'Фактическая проверка: с #$from по #$to';
  }

  @override
  String get integrityReasonMissingEntry => 'Запись в цепочке отсутствует';

  @override
  String get integrityReasonMissingPrevForRange =>
      'Нет предыдущего документа перед диапазоном';

  @override
  String get integrityReasonSchemaInvalid => 'Повреждённая запись цепочки';

  @override
  String get integrityReasonPrevHashMismatch =>
      'Разрыв хеша (цепочка изменена)';

  @override
  String get integrityReasonHashMismatch => 'Хеш не совпадает';

  @override
  String integrityOkSummary(int count) {
    return '✅ Целостность в порядке — проверено: $count';
  }

  @override
  String integrityFailedSummary(int number) {
    return '❌ Ошибка на документе #$number';
  }

  @override
  String get createCompany => 'Создать компанию';

  @override
  String get createCompanyTitle => 'Новая компания';

  @override
  String get createCompanyDesc =>
      'Создаёт компанию, настройки по умолчанию и счётчики документов. Trial — 14 дней.';

  @override
  String get companyIdSlug => 'ID компании (латиница)';

  @override
  String get companyIdSlugHint => 'acme-logistics';

  @override
  String companyCreatedSuccess(String name) {
    return 'Компания «$name» создана';
  }

  @override
  String get companyAlreadyExists => 'Компания с таким ID уже существует';

  @override
  String get invalidCompanyId => 'ID: лatinица, цифры, дефис, 3–40 символов';

  @override
  String get counterInvoices => 'Налоговые накладные';

  @override
  String get counterReceipts => 'Квитанции';

  @override
  String get counterCreditNotes => 'Кредит-ноты';

  @override
  String get counterDeliveryNotes => 'Накладные';

  @override
  String get counterTaxInvoiceReceipts => 'Налоговые накладные/Квитанции';

  @override
  String get creditNoteReasonRequired =>
      'Необходимо указать причину кредит-ноты';

  @override
  String get creditNoteOnlyForIssued =>
      'Кредит-ноту можно создать только для выпущенного документа';

  @override
  String get creditNoteNotForCreditNote =>
      'Нельзя создать кредит-ноту для кредит-ноты';

  @override
  String get reasonRequired => 'Необходимо указать причину';

  @override
  String get creditNoteCreateTitle => 'Создание кредит-ноты';

  @override
  String originalInvoiceLabel(int number) {
    return 'Исходный счёт #$number';
  }

  @override
  String clientLabel(String name) {
    return 'Клиент: $name';
  }

  @override
  String amountLabel(String amount) {
    return 'Сумма: ₪$amount';
  }

  @override
  String get creditNoteDescription =>
      'Кредит-нота создаст новый документ с отрицательными суммами.\nИсходный документ не изменится.';

  @override
  String get creditNoteReasonLabel => 'Причина кредит-ноты *';

  @override
  String get creditNoteReasonHint => 'Например: ошибка в количестве';

  @override
  String get createCreditNoteButton => 'Создать кредит-ноту';

  @override
  String creditNoteCreateError(String error) {
    return 'Ошибка создания кредит-ноты: $error';
  }

  @override
  String get creditNoteIssuanceError => 'Ошибка выпуска кредит-ноты с сервера';

  @override
  String periodLockedError(String docDate, String lockDate) {
    return 'Нельзя создать кредит-ноту — дата документа ($docDate) в закрытом учётном периоде (до $lockDate)';
  }

  @override
  String get allNotificationsMarkedRead =>
      'Все уведомления отмечены как прочитанные';

  @override
  String get timeAgoNow => 'Сейчас';

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours ч назад';
  }

  @override
  String timeAgoDays(int days) {
    return '$days дн назад';
  }

  @override
  String get resourceUsage => 'Использование ресурсов';

  @override
  String get noUsageData => 'Нет данных об использовании';

  @override
  String get usageLoadError => 'Ошибка загрузки данных использования';

  @override
  String get usersUsage => 'Пользователи';

  @override
  String get docsPerMonth => 'Документов/месяц';

  @override
  String get routesPerDay => 'Маршрутов/день';

  @override
  String get paidUntil => 'Оплачено до';

  @override
  String daysRemaining(int days) {
    return 'Осталось $days дней';
  }

  @override
  String get expired => 'Истёк';

  @override
  String get paymentProvider => 'Платёжный провайдер';

  @override
  String get gracePeriodBanner =>
      'Компания в льготном периоде. Необходима оплата для продолжения.';

  @override
  String get paymentPageOpened => 'Страница оплаты открыта';

  @override
  String get cannotOpenPayment => 'Не удалось открыть страницу оплаты';

  @override
  String get selectFormat => 'Выберите формат';

  @override
  String get downloadReceipt => 'Скачать квитанцию';

  @override
  String get receiptCopied => 'Квитанция скопирована';

  @override
  String get receiptExportError => 'Ошибка экспорта квитанции';

  @override
  String get companyLoadError => 'Ошибка загрузки данных компании';

  @override
  String get periodLabel => 'Период:';

  @override
  String get toLabel => 'до';

  @override
  String get deliveriesTab => 'Доставки';

  @override
  String get invoicesTab => 'Счета';

  @override
  String get driversTab => 'Водители';

  @override
  String get totalPointsReport => 'Всего точек';

  @override
  String get completedReport => 'Завершено';

  @override
  String get pendingReport => 'Ожидают';

  @override
  String get onTheWay => 'В пути';

  @override
  String get cancelledReport => 'Отменено';

  @override
  String get totalPalletsReport => 'Всего паллет';

  @override
  String get palletsDelivered => 'Паллет доставлено';

  @override
  String get completionPercent => 'Процент выполнения';

  @override
  String get totalDocumentsReport => 'Всего документов';

  @override
  String get taxInvoicesReport => 'Налоговые счета';

  @override
  String get taxInvoiceReceiptsReport => 'Налоговые счета/квитанции';

  @override
  String get receiptsReport => 'Квитанции';

  @override
  String get deliveryNotesReport => 'Накладные';

  @override
  String get creditNotesReport => 'Кредит-ноты';

  @override
  String get netBeforeVatReport => 'Итого до НДС';

  @override
  String get vatAmountReport => 'НДС';

  @override
  String get grossWithVatReport => 'Итого с НДС';

  @override
  String get noDataForPeriod => 'Нет данных за этот период';

  @override
  String get pointsLabel => 'Точки';

  @override
  String get completedLabel => 'Завершено';

  @override
  String get cancelledLabel => 'Отменено';

  @override
  String get palletsLabel => 'Паллеты';

  @override
  String get completionLabel => 'Выполнение';

  @override
  String get noDriverAssigned => 'Без водителя';

  @override
  String get select => 'Выбрать';

  @override
  String get overviewSection => 'Обзор';

  @override
  String get usersAndRoles => 'Пользователи и роли';

  @override
  String get billingSection => 'Оплата';

  @override
  String get auditAndCompliance => 'Аудит и соответствие';

  @override
  String get operationsSection => 'Операции';

  @override
  String get accountingSection => 'Бухгалтерия';

  @override
  String get userMenu => 'Меню пользователя';

  @override
  String get menuLabel => 'Меню';

  @override
  String get companyDataNotFound => 'Данные компании не найдены';

  @override
  String get noSectionsAvailable => 'Нет доступных разделов';

  @override
  String unknownRoleError(String role) {
    return 'Неизвестная роль: $role';
  }

  @override
  String get pleaseSelectCompany =>
      'Пожалуйста, выберите компанию для продолжения.';

  @override
  String get moduleFilter => 'Модуль';

  @override
  String get eventTypeFilter => 'Тип события';

  @override
  String get userFilter => 'Пользователь';

  @override
  String get dateRange => 'Диапазон дат';

  @override
  String get clearDateRange => 'Очистить диапазон дат';

  @override
  String get exporting => 'Экспорт...';

  @override
  String auditExportError(String error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String get auditLogLoadError => 'Ошибка загрузки журнала аудита';

  @override
  String get noAuditRecords => 'Нет записей в журнале аудита';

  @override
  String auditHistory(String title) {
    return 'История: $title';
  }

  @override
  String get historyLoadError => 'Ошибка загрузки истории';

  @override
  String get noEventsYet => 'Нет событий';

  @override
  String get moduleLogistics => 'Логистика';

  @override
  String get moduleWarehouse => 'Склад';

  @override
  String get moduleAccounting => 'Бухгалтерия';

  @override
  String get moduleDispatcher => 'Диспетчер';

  @override
  String get eventReceiptCreated => 'Квитанция выдана';

  @override
  String get eventCreditNoteCreated => 'Кредит-нота выдана';

  @override
  String get eventDocumentVoided => 'Документ аннулирован до передачи';

  @override
  String get eventInvoiceVoided => 'Счёт аннулирован';

  @override
  String get eventBillingStatusChanged => 'Статус оплаты изменён';

  @override
  String get eventTrialUntilChanged => 'Пробный период обновлён';

  @override
  String get eventAccountingLockedUntilChanged =>
      'Блокировка бухгалтерии обновлена';

  @override
  String get eventInvoiceIssued => 'Счёт выставлен';

  @override
  String get eventInvoicePrinted => 'Счёт распечатан';

  @override
  String get eventInventoryAdjusted => 'Инвентарь скорректирован';

  @override
  String get eventInventoryCountCompleted => 'Инвентаризация завершена';

  @override
  String get eventInventoryCountApproved => 'Инвентаризация утверждена';

  @override
  String get eventRoutePublished => 'Маршрут опубликован';

  @override
  String get eventDeliveryPointStatusChanged => 'Статус точки доставки изменён';

  @override
  String get eventManualAssignment => 'Ручное назначение';

  @override
  String get eventPaymentReceived => 'Платёж получен';

  @override
  String get eventModuleChanged => 'Модуль изменён';

  @override
  String get eventPlanChanged => 'Тарифный план изменён';

  @override
  String get eventBackupRecorded => 'Резервная копия записана';

  @override
  String get eventRetentionChecked => 'Проверка хранения данных';

  @override
  String get deliveriesToday => 'Доставки сегодня';

  @override
  String get invoicesThisMonth => 'Счета за месяц';

  @override
  String get warehouseMovements => 'Движения склада';

  @override
  String get activeDriversKpi => 'Активные водители';

  @override
  String get docsThisMonth => 'Документы за месяц';

  @override
  String printErrorsToday(int count) {
    return 'Ошибки печати сегодня: $count';
  }

  @override
  String get accountSuspendedPayment =>
      'Аккаунт приостановлен — требуется оплата';

  @override
  String get paymentOverdueGrace => 'Просрочка оплаты — льготный период';

  @override
  String get recentEventsTitle => 'Последние события';

  @override
  String get errorLoadingEvents => 'Ошибка загрузки событий';

  @override
  String get noRecentEvents => 'Нет последних событий';

  @override
  String get teamMembers => 'Участники команды';

  @override
  String get errorLoadingUsers => 'Ошибка загрузки пользователей';

  @override
  String get noTeamMembers => 'Нет участников команды';

  @override
  String get roleUpdatedSuccess => 'Роль обновлена';

  @override
  String errorUpdatingRole(Object error) {
    return 'Ошибка обновления роли: $error';
  }

  @override
  String get removeUserTitle => 'Удаление пользователя';

  @override
  String removeUserConfirm(String name) {
    return 'Удалить $name?';
  }

  @override
  String get userRemovedSuccess => 'Пользователь удалён';

  @override
  String errorRemovingUser(Object error) {
    return 'Ошибка удаления пользователя: $error';
  }

  @override
  String get roleSuperAdmin => 'Суперадмин';

  @override
  String get roleDriverLabel => 'Водитель';

  @override
  String get roleViewer => 'Наблюдатель';

  @override
  String get statusInvited => 'Приглашён';

  @override
  String get statusSuspended => 'Приостановлен';

  @override
  String usersLimitReached(int active, int limit) {
    return 'Достигнут лимит пользователей ($active / $limit)';
  }

  @override
  String get usersLimitUpgrade =>
      'Невозможно пригласить больше пользователей. Обновите тариф для увеличения лимита.';

  @override
  String get changeRole => 'Сменить роль';

  @override
  String get removeUser => 'Удалить пользователя';

  @override
  String get retryAttempts => 'Повторные попытки';

  @override
  String get totalEventsKpi => 'Всего событий';

  @override
  String get successRate => 'Процент успеха';

  @override
  String get printEvents => 'События печати';

  @override
  String get systemEvents => 'Системные события';

  @override
  String get filterAll => 'Все';

  @override
  String get filterSuccess => 'Успех';

  @override
  String get filterError => 'Ошибка';

  @override
  String get filterFailed => 'Неудача';

  @override
  String get errorLoadingPrintEvents => 'Ошибка загрузки событий печати';

  @override
  String get noPrintEvents => 'Нет событий печати';

  @override
  String get errorLoadingSystemEvents => 'Ошибка загрузки системных событий';

  @override
  String get noSystemEvents => 'Нет системных событий';

  @override
  String invoiceLabel(String id) {
    return 'Счёт: $id';
  }

  @override
  String printerUserLabel(String printer, String user) {
    return 'Принтер: $printer · Пользователь: $user';
  }

  @override
  String retryCountLabel(int count) {
    return ' · Попытки: $count';
  }

  @override
  String get tryAgain => 'Повторить';

  @override
  String get billingErrorLoading => 'Ошибка загрузки данных биллинга';

  @override
  String get billingAccountSuspended => 'Аккаунт приостановлен';

  @override
  String get billingAccountCancelled => 'Аккаунт отменён';

  @override
  String get billingPaymentRequired =>
      'Требуется оплата для восстановления доступа к аккаунту.';

  @override
  String get billingContactSupport =>
      'Свяжитесь с поддержкой для повторной активации аккаунта.';

  @override
  String billingGraceDefault(int days) {
    return 'Просрочка оплаты — льготный период ($days дней).';
  }

  @override
  String billingGraceRemaining(int remaining) {
    return 'Просрочка оплаты — осталось $remaining дней льготного периода.';
  }

  @override
  String billingTrialRemaining(int remaining) {
    return 'Пробный период — осталось $remaining дней';
  }

  @override
  String get billingPlanDetails => 'Детали плана';

  @override
  String get billingPlan => 'План';

  @override
  String get billingStatusLabel => 'Статус';

  @override
  String get billingTrialEnds => 'Окончание пробного периода';

  @override
  String get billingPaidUntil => 'Оплачено до';

  @override
  String get billingModules => 'Модули';

  @override
  String get billingIncludedInPlan => 'Включены в план';

  @override
  String get billingAddons => 'Дополнения (addon)';

  @override
  String get billingNoModules => 'Нет доступных модулей';

  @override
  String get billingUsage => 'Использование';

  @override
  String get billingDocsPerMonth => 'Документы / месяц';

  @override
  String get billingUsers => 'Пользователи';

  @override
  String get billingRoutesPerDay => 'Маршруты / день';

  @override
  String billingLimit(int limit) {
    return 'Лимит: $limit';
  }

  @override
  String get billingSensitiveFields =>
      'Конфиденциальные поля (только super admin)';

  @override
  String get billingInvoices => 'Счета';

  @override
  String get billingErrorLoadingInvoices => 'Ошибка загрузки счетов';

  @override
  String get billingNoInvoices => 'Нет счетов';

  @override
  String get billingInvoiceDefault => 'Счёт';

  @override
  String get billingPlanWarehouse => 'Только склад';

  @override
  String get billingPlanOps => 'Операции';

  @override
  String get billingPlanFull => 'Полный';

  @override
  String get billingPlanCustom => 'Индивидуальный';

  @override
  String get billingStatusActive => 'Активен';

  @override
  String get billingStatusTrial => 'Пробный';

  @override
  String get billingStatusGrace => 'Льготный период';

  @override
  String get billingStatusSuspended => 'Приостановлен';

  @override
  String get billingStatusCancelled => 'Отменён';

  @override
  String get billingModuleWarehouse => 'Склад';

  @override
  String get billingModuleLogistics => 'Логистика';

  @override
  String get billingModuleDispatcher => 'Доставки';

  @override
  String get billingModuleAccounting => 'Бухгалтерия';

  @override
  String get billingModuleReports => 'Отчёты';

  @override
  String get billingInvoicePaid => 'Оплачен';

  @override
  String get billingInvoicePending => 'Ожидает';

  @override
  String get billingInvoiceOverdue => 'Просрочен';

  @override
  String get billingInvoiceCancelled => 'Отменён';

  @override
  String get settingsCompanyProfile => 'Профиль компании';

  @override
  String get settingsTab => 'Настройки';

  @override
  String get settingsCompanyName => 'Название компании';

  @override
  String get settingsNameHebrew => 'Название на иврите *';

  @override
  String get settingsNameEnglish => 'Название на английском';

  @override
  String get settingsTaxId => 'ИНН *';

  @override
  String get settingsAddress => 'Адрес';

  @override
  String get settingsAddressHebrew => 'Адрес на иврите';

  @override
  String get settingsAddressEnglish => 'Адрес на английском';

  @override
  String get settingsCity => 'Город';

  @override
  String get settingsZipCode => 'Индекс';

  @override
  String get settingsPoBox => 'А/я';

  @override
  String get settingsContactDetails => 'Контактные данные';

  @override
  String get settingsPhone => 'Телефон';

  @override
  String get settingsFax => 'Факс';

  @override
  String get settingsEmail => 'Эл. почта';

  @override
  String get settingsWebsite => 'Веб-сайт';

  @override
  String get settingsReadOnly => 'Только чтение';

  @override
  String get settingsSaving => 'Сохранение...';

  @override
  String get settingsSaveProfile => 'Сохранить профиль';

  @override
  String get settingsSaveSettings => 'Сохранить настройки';

  @override
  String get settingsProfileSaved => 'Профиль сохранён успешно';

  @override
  String settingsProfileError(String error) {
    return 'Ошибка сохранения профиля: $error';
  }

  @override
  String get settingsSettingsSaved => 'Настройки сохранены успешно';

  @override
  String settingsSettingsError(String error) {
    return 'Ошибка сохранения настроек: $error';
  }

  @override
  String get settingsSystemSettings => 'Системные настройки';

  @override
  String get settingsTaxSettings => 'Налоговые настройки';

  @override
  String get settingsTaxIdBn => 'ИНН / ОГРН';

  @override
  String get settingsVatRate => 'Ставка НДС';

  @override
  String get settingsTaxManagedByAdmin =>
      'Налоговые настройки управляются системным администратором';

  @override
  String get settingsInvoiceSettings => 'Настройки счёта';

  @override
  String get settingsInvoiceFooter => 'Текст подвала счёта';

  @override
  String get settingsPaymentTerms => 'Условия оплаты';

  @override
  String get settingsBankDetails => 'Банковские реквизиты';

  @override
  String get settingsDocNumbering => 'Нумерация документов';

  @override
  String get settingsTaxInvoice => 'Налоговый счёт';

  @override
  String get settingsReceipt => 'Квитанция';

  @override
  String get settingsDeliveryNote => 'Накладная';

  @override
  String get settingsCreditNote => 'Кредитная нота';

  @override
  String get settingsAutoNumbering =>
      'Автоматическая последовательная нумерация';

  @override
  String get settingsNumberingManagedBySystem =>
      'Нумерация документов управляется автоматически системой';

  @override
  String get settingsPrintTemplates => 'Шаблоны печати';

  @override
  String get settingsDefaultTemplate => 'Шаблон по умолчанию';

  @override
  String get settingsTemplatesAdminOnly =>
      'Управление шаблонами печати доступно только администраторам';

  @override
  String get settingsIntegrations => 'Интеграции';

  @override
  String get settingsPrinting => 'Печать';

  @override
  String get settingsEmailIntegration => 'Эл. почта';

  @override
  String get settingsApiKeys => 'API ключи';

  @override
  String get settingsConfigured => 'Настроено';

  @override
  String get settingsNotConfigured => 'Не настроено';

  @override
  String get settingsIntegrationsAdminOnly =>
      'Управление интеграциями доступно только администраторам';

  @override
  String get settingsEditTooltip => 'Редактировать';

  @override
  String get integrationPrinterIp => 'IP-адрес принтера';

  @override
  String get integrationPrinterPort => 'Порт';

  @override
  String get integrationPrinterModel => 'Модель принтера';

  @override
  String get integrationPrinterPaperSize => 'Размер бумаги';

  @override
  String get integrationSmtpHost => 'SMTP сервер';

  @override
  String get integrationSmtpPort => 'Порт';

  @override
  String get integrationSmtpUser => 'Имя пользователя';

  @override
  String get integrationSmtpPassword => 'Пароль';

  @override
  String get integrationSmtpFrom => 'Email отправителя';

  @override
  String get integrationSmtpSsl => 'Использовать SSL';

  @override
  String get integrationWhatsappApiUrl => 'URL API';

  @override
  String get integrationWhatsappApiKey => 'API ключ';

  @override
  String get integrationWhatsappPhoneId => 'ID номера телефона';

  @override
  String get integrationApiKeyGenerate => 'Сгенерировать новый ключ';

  @override
  String get integrationApiKeyValue => 'API ключ';

  @override
  String get integrationApiKeyCopied => 'API ключ скопирован в буфер обмена';

  @override
  String get integrationSaved => 'Настройки интеграции сохранены';

  @override
  String integrationSaveError(Object error) {
    return 'Ошибка сохранения настроек: $error';
  }

  @override
  String get integrationTestConnection => 'Проверить подключение';

  @override
  String get integrationTestSuccess => 'Подключение успешно';

  @override
  String integrationTestFailed(Object error) {
    return 'Подключение не удалось: $error';
  }

  @override
  String integrationDialogTitle(Object name) {
    return 'Настройка $name';
  }

  @override
  String get integrationEnabled => 'Включено';

  @override
  String get subscriptionTitle => 'Подписка';

  @override
  String get noCompanySelectedSub => 'Компания не выбрана';

  @override
  String get subscriptionManagementTitle => 'Управление подпиской';

  @override
  String get changePlanTitle => 'Сменить тариф';

  @override
  String get paymentHistoryTitle => 'История платежей';

  @override
  String get currentPlanLabel => 'Текущий тариф';

  @override
  String get planWarehouseOnly => 'Только склад';

  @override
  String get planLogistics => 'Логистика';

  @override
  String get planOps => 'Операции';

  @override
  String get planFull => 'Полный';

  @override
  String get planCustom => 'Индивидуальный';

  @override
  String get planDescWarehouse => 'Только управление складом';

  @override
  String get planDescLogistics => 'Логистика + диспетчер + отчёты (без склада)';

  @override
  String get planDescOps =>
      'Склад + логистика + диспетчер + отчёты (без бухгалтерии)';

  @override
  String get planDescFull =>
      'Все модули, включая бухгалтерию и интеграцию с Greeninvoice';

  @override
  String get planDescCustom => 'Индивидуальный тариф';

  @override
  String get planAccountingNote =>
      'Бухгалтерия (счета, НДС, Greeninvoice) — только в тарифе «Полный». Отдельной доплаты за модуль нет.';

  @override
  String get planBackupNote =>
      'Облачный DR (Firestore Backup Google): включён в «Полный»; на других тарифах — журнал аудита бесплатно, выделенный export +₪149/мес. Счёт Google платит LogiRoute (~₪30–120/мес на весь проект).';

  @override
  String billingDedicatedExportMonthly(int price) {
    return '+₪$price/мес — выделенный квартальный export данных компании (опционально)';
  }

  @override
  String get planModulesLabel => 'Модули:';

  @override
  String get planCurrentBadge => 'Текущий тариф';

  @override
  String get accountingProviderSection => 'Интеграция с налоговой API';

  @override
  String get accountingProviderLabel => 'Провайдер';

  @override
  String get accountingProviderNone => 'Встроенная (LogiRoute)';

  @override
  String get accountingProviderExport => 'Файловый экспорт (единый CSV)';

  @override
  String get accountingProviderGreeninvoice => 'Greeninvoice / Morning';

  @override
  String get accountingProviderIcount => 'iCount';

  @override
  String get accountingProviderHint =>
      'Внешний провайдер ведёт налоговое соответствие и нумерацию документов.';

  @override
  String get accountingProviderConfigure => 'Настроить API-ключи';

  @override
  String get accountingProviderConfigured => 'Ключи сохранены';

  @override
  String get accountingProviderSaved => 'Настройки интеграции сохранены';

  @override
  String get accountingProviderApiKey => 'API key';

  @override
  String get accountingProviderSecret => 'Secret key';

  @override
  String get accountingProviderToken => 'API token';

  @override
  String get accountingProviderSandbox => 'Тестовый режим (sandbox)';

  @override
  String get accountingProviderSandboxHint =>
      'API Greeninvoice sandbox (sandbox.d.greeninvoice.co.il)';

  @override
  String get accountingProviderTest => 'Проверить подключение';

  @override
  String get accountingProviderTestOk => 'Подключение к провайдеру успешно';

  @override
  String accountingProviderTestFailed(String detail) {
    return 'Проверка не удалась: $detail';
  }

  @override
  String get accountingSyncTitle => 'Синхронизация с внешней бухгалтерией';

  @override
  String get accountingSyncStatusSynced => 'Синхронизировано';

  @override
  String get accountingSyncStatusFailed => 'Ошибка';

  @override
  String get accountingSyncStatusProcessing => 'Обработка';

  @override
  String get accountingSyncRetry => 'Повторить';

  @override
  String get accountingSyncNoEntries =>
      'Записей синхронизации пока нет — здесь появятся выписанные счета.';

  @override
  String get accountingSyncRetried => 'Повтор синхронизации запущен';

  @override
  String accountingSyncDistribution(String number) {
    return 'Номер распределения: $number';
  }

  @override
  String accountingExternalDocNumber(String number) {
    return 'Внешний №: $number';
  }

  @override
  String get accountingSyncStatusPending => 'Ожидает';

  @override
  String get accountingDocSyncColumn => 'Синхронизация';

  @override
  String accountingExternalSyncFailedWith(String error) {
    return 'Документ выпущен, синхронизация не удалась: $error';
  }

  @override
  String get billingAddonsTitle => 'Доплаты за использование';

  @override
  String billingExtraDriverMonthly(int price, int included) {
    return '+₪$price/мес за каждого водителя сверх $included включённых';
  }

  @override
  String billingExtraWarehouseMonthly(int price, int included) {
    return '+₪$price/мес за каждый склад/точку сверх $included включённой';
  }

  @override
  String promoMonthlyPrice(int price, int months) {
    return '₪$price/мес (первые $months мес)';
  }

  @override
  String thenMonthlyPrice(int price) {
    return 'Далее ₪$price/мес';
  }

  @override
  String setupAndIntegration(int fee) {
    return 'Установка и интеграция: ₪$fee';
  }

  @override
  String setupAndIntegrationStr(String fee) {
    return 'Установка и интеграция: $fee';
  }

  @override
  String minimumMonths(int months) {
    return 'Минимум $months месяцев';
  }

  @override
  String paidUntilDate(String date) {
    return 'Оплачено до: $date';
  }

  @override
  String paymentProviderLabel(String provider) {
    return 'Платёжный провайдер: $provider';
  }

  @override
  String errorPrefix(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get payNowButton => 'Оплатить сейчас';

  @override
  String get currentChip => 'Текущий';

  @override
  String monthlyPriceShort(int price) {
    return '₪$price/мес';
  }

  @override
  String afterPromoPrice(int months, int price) {
    return 'После $months мес: ₪$price';
  }

  @override
  String changePlanConfirmTitle(String name) {
    return 'Сменить на $name?';
  }

  @override
  String changePlanConfirmBody(String name, int promoPrice, int promoMonths,
      int price, int setupFee, int minMonths) {
    return 'Тариф изменится на $name.\n₪$promoPrice/мес (первые $promoMonths мес), далее ₪$price/мес.\nУстановка: ₪$setupFee. Минимум $minMonths месяцев.\nИзменение вступит в силу немедленно.';
  }

  @override
  String get cancelButton => 'Отмена';

  @override
  String get changePlanButton => 'Сменить тариф';

  @override
  String planChangedSuccess(String name) {
    return 'Тариф изменён на $name';
  }

  @override
  String get noPaymentHistorySub => 'Нет истории платежей';

  @override
  String get paymentReceived => 'Платёж получен';

  @override
  String get subscriptionCancelled => 'Подписка отменена';

  @override
  String providerPrefix(String provider) {
    return 'Провайдер: $provider';
  }

  @override
  String get moduleNotAvailable =>
      'Этот модуль недоступен в вашем текущем тарифе';

  @override
  String get upgradePlanButton => 'Обновить тариф';

  @override
  String get moduleWarehouseTitle => 'Склад';

  @override
  String get moduleLogisticsTitle => 'Логистика';

  @override
  String get moduleDispatcherTitle => 'Диспетчер';

  @override
  String get moduleAccountingTitle => 'Бухгалтерия';

  @override
  String get moduleReportsTitle => 'Отчёты';

  @override
  String priceArrow(String promoPrice, int promoMonths, String price) {
    return '$promoPrice/мес (первые $promoMonths мес) → $price/мес';
  }

  @override
  String get importInventoryTitle => 'Импорт склада';

  @override
  String get importClientsTitle => 'Импорт клиентов';

  @override
  String importPreviewTotal(int total, int valid, int errors) {
    return 'Всего: $total | Корректных: $valid | Ошибок: $errors';
  }

  @override
  String get importPreviewStatus => 'Статус';

  @override
  String importRowsButton(int count) {
    return 'Импортировать $count строк';
  }

  @override
  String importResultMessage(int added, int errors) {
    return 'Добавлено $added | Ошибок $errors';
  }

  @override
  String importClientResultMessage(int added, int skipped, int errors) {
    return 'Добавлено $added | Пропущено $skipped | Ошибок $errors';
  }

  @override
  String importRowError(int row, String error) {
    return 'Строка $row: $error';
  }

  @override
  String get colProductCode => 'Артикул';

  @override
  String get colType => 'Тип';

  @override
  String get colNumber => 'Номер';

  @override
  String get colQuantity => 'Кол-во';

  @override
  String get colQuantityPerPallet => 'Кол-во/паллет';

  @override
  String get colClientNumber => 'Номер';

  @override
  String get colName => 'Имя';

  @override
  String get colAddress => 'Адрес';

  @override
  String get colPhone => 'Телефон';

  @override
  String get colZones => 'Зоны';

  @override
  String get importFromExcelMenu => 'Импорт из Excel';

  @override
  String get exportToExcelMenu => 'Экспорт в Excel';

  @override
  String get downloadTemplateMenu => 'Скачать шаблон';

  @override
  String get fileExportedSuccess => 'Файл экспортирован';

  @override
  String get templateDownloadedSuccess => 'Шаблон скачан';

  @override
  String get loadProductTemplate => 'Загрузить шаблон товаров';

  @override
  String get syncFromWarehouse => 'Синхронизировать со склада';

  @override
  String get permanentDelete => 'Удалить навсегда';

  @override
  String permanentDeleteConfirm(String name) {
    return 'Удалить \"$name\" навсегда? Это действие необратимо.';
  }

  @override
  String duplicateProductCode(String code) {
    return 'Артикул $code уже существует. Выберите другой.';
  }

  @override
  String get syncFromWarehouseTitle => 'Синхронизация со склада';

  @override
  String get syncFromWarehouseConfirm =>
      'Создать новые товары в каталоге для всех позиций, которые есть на складе, но отсутствуют в каталоге?';

  @override
  String get colDiameter => 'Диаметр';

  @override
  String get colVolume => 'Объём';

  @override
  String get colPiecesPerBox => 'Шт. в коробке';

  @override
  String get colAdditionalInfo => 'Доп. информация';

  @override
  String get colContactPerson => 'Контактное лицо';

  @override
  String get colVatId => 'ИНН';

  @override
  String get colLatitude => 'Широта';

  @override
  String get colLongitude => 'Долгота';

  @override
  String get columnMappingHint =>
      'Сопоставьте столбцы файла с полями системы. Поля со * обязательны.';

  @override
  String get targetField => 'Поле назначения';

  @override
  String get sourceColumn => 'Столбец источника';

  @override
  String get sampleValue => 'Пример';

  @override
  String get duplicateHandling => 'Обработка дубликатов';

  @override
  String get duplicateSkip => 'Пропустить';

  @override
  String get duplicateUpdate => 'Обновить существующие';

  @override
  String get duplicateAdd => 'Добавить в любом случае';

  @override
  String get continueImport => 'Продолжить импорт';

  @override
  String get mapColumnsInventory => 'Сопоставление столбцов — Склад';

  @override
  String get mapColumnsClients => 'Сопоставление столбцов — Клиенты';

  @override
  String get mapColumnsDeliveryPoints =>
      'Сопоставление столбцов — Точки доставки';

  @override
  String get importDeliveryPointsMenu => 'Импорт точек доставки';

  @override
  String get importDeliveryPointsTitle => 'Импорт точек доставки';

  @override
  String get loadDemoDataMenu => 'Демо-данные для видео';

  @override
  String get loadDemoDataConfirm =>
      'Загрузить демо-сценарий доставки для 2-минутного видео?';

  @override
  String get loadDemoDataReplaceWarning =>
      'Существующие демо-точки будут заменены.';

  @override
  String loadDemoDataSuccess(int count) {
    return 'Демо-данные загружены ($count точек)';
  }

  @override
  String importResultUpdated(int updated, int errors) {
    return 'Обновлено $updated | Ошибки $errors';
  }

  @override
  String importClientResultUpdated(
      int added, int updated, int skipped, int errors) {
    return 'Добавлено $added | Обновлено $updated | Пропущено $skipped | Ошибки $errors';
  }

  @override
  String get importFromFile => 'Импорт из файла';

  @override
  String get supportConsoleTitle => 'Консоль поддержки';

  @override
  String get verifyIntegrity => 'Проверить целостность';

  @override
  String get exportDiagnosticJson => 'Экспорт диагностики JSON';

  @override
  String get refreshData => 'Обновить';

  @override
  String get tabOverview => 'Обзор';

  @override
  String get tabBillingAudit => 'Аудит биллинга';

  @override
  String tabPayments(int count) {
    return 'Платежи ($count)';
  }

  @override
  String tabNotifications(int count, int unread) {
    return 'Уведомления ($count/$unread)';
  }

  @override
  String tabPushErrors(int count) {
    return 'Ошибки Push ($count)';
  }

  @override
  String tabEmailErrors(int count) {
    return 'Ошибки Email ($count)';
  }

  @override
  String get searchCompany => 'Поиск компании...';

  @override
  String get backToList => 'Назад к списку';

  @override
  String get chipStatus => 'Статус';

  @override
  String get chipPlan => 'Тариф';

  @override
  String get chipUsers => 'Пользователи';

  @override
  String get chipDocsMonth => 'Документы/мес.';

  @override
  String get chipUnread => 'Непрочитанные';

  @override
  String get sectionBilling => 'Биллинг';

  @override
  String get sectionLimitsUsage => 'Лимиты и использование';

  @override
  String get sectionModules => 'Модули';

  @override
  String get labelPaidUntil => 'Оплачено до';

  @override
  String get labelTrialUntil => 'Пробный до';

  @override
  String get labelGracePeriodDays => 'Льготный период (дни)';

  @override
  String get labelPaymentProvider => 'Платёжный провайдер';

  @override
  String get labelPaymentCustomerId => 'ID клиента в платёжной системе';

  @override
  String get labelSubscriptionId => 'ID подписки';

  @override
  String get labelMaxUsers => 'Макс. пользователей';

  @override
  String get labelActualUsers => 'Фактических пользователей';

  @override
  String get labelMaxDocsPerMonth => 'Макс. документов/мес.';

  @override
  String get labelDocsThisMonth => 'Документов в этом месяце';

  @override
  String get userLimitReached => '⚠️ Достигнут лимит пользователей';

  @override
  String get moduleEnabled => '✅ Включён';

  @override
  String get moduleDisabled => '❌ Отключён';

  @override
  String get noAuditEvents => 'Нет событий аудита';

  @override
  String get noPaymentEvents => 'Нет платёжных событий';

  @override
  String get noPushErrors => '✅ Нет ошибок Push-доставки';

  @override
  String get noEmailErrors => '✅ Нет ошибок Email-доставки';

  @override
  String get integrityOk => '✅ Целостность в порядке';

  @override
  String integrityFailed(String error) {
    return '❌ Целостность нарушена: $error';
  }

  @override
  String get diagnosticCopied => '📋 Диагностика JSON скопирована в буфер';

  @override
  String get readStatus => '✓ прочитано';

  @override
  String get unreadStatus => '● не прочитано';

  @override
  String get moduleManagementTitle => 'Управление модулями';

  @override
  String get planLabel => 'Тариф';

  @override
  String get modulesInPlan => 'Модули в тарифе';

  @override
  String get planUpdatedSuccess => 'Тариф успешно обновлён';

  @override
  String get moduleToggleInfo =>
      'Изменения вступят в силу немедленно. Пользователи, пытающиеся получить доступ к отключённому модулю, увидят экран «Модуль недоступен».';

  @override
  String get moduleWarehouseDesc =>
      'Управление запасами, инвентаризация, типы упаковки';

  @override
  String get moduleLogisticsDesc => 'Точки доставки, маршруты, карта';

  @override
  String get moduleDispatcherDesc => 'Управление водителями, автораспределение';

  @override
  String get moduleAccountingDesc => 'Счета, квитанции, кредиты, экспорт';

  @override
  String get moduleReports => 'Отчёты';

  @override
  String get moduleReportsDesc => 'Статистика доставок, счетов, водителей';

  @override
  String get backupManagementTitle => 'Управление резервными копиями';

  @override
  String get tabBackups => 'Резервные копии';

  @override
  String get tabRestoreTests => 'Тесты восстановления';

  @override
  String get tabComplianceReport => 'Отчёт соответствия';

  @override
  String get registerBackup => 'Зарегистрировать копию';

  @override
  String get registerBackupTitle => 'Регистрация резервной копии';

  @override
  String get registerLogiRouteCloudBackup =>
      'Зарегистрировать облачный бэкап LogiRoute';

  @override
  String get registerBackupOther => 'Другое хранилище…';

  @override
  String get backupCloudInfoTitle => 'Облачное резервирование';

  @override
  String get backupCloudInfoBody =>
      'Данные LogiRoute хранятся в облаке Firebase (проект logiroute-app). Кнопка выше — запись в журнал аудита для бухгалтерии, не отдельная услуга Google.';

  @override
  String get backupCloudPricingNote =>
      'Тариф «Полный»: облачное DR включено (бэкап проекта платит LogiRoute). Остальные тарифы: только журнал; выделенный экспорт данных — доп. ₪149/мес.';

  @override
  String get backupFirebaseLocationLabel => 'Имя проекта Firebase';

  @override
  String get backupFirebaseHelper =>
      'Для клиентов LogiRoute обычно достаточно logiroute-app.';

  @override
  String get storageRecommended => '(рекомендуется)';

  @override
  String get storageType => 'Тип хранилища';

  @override
  String get exactLocation => 'Точное расположение *';

  @override
  String get backupRecorded => 'Резервная копия зарегистрирована';

  @override
  String get registerRestoreTest => 'Зарегистрировать тест';

  @override
  String get registerRestoreTestTitle => 'Регистрация теста восстановления';

  @override
  String get restoreFromBackup => 'Восстановить из копии *';

  @override
  String get restoreSuccess => 'Восстановление успешно?';

  @override
  String get restoreTestRecorded => 'Тест восстановления зарегистрирован';

  @override
  String get noBackupsRecorded => 'Нет зарегистрированных копий';

  @override
  String get noBackupsYetRegisterFirst =>
      'Нет копий — сначала зарегистрируйте резервную копию';

  @override
  String get quarterlyBackupRequired => 'Требуется ежеквартальная копия!';

  @override
  String get noRestoreTests => 'Нет тестов восстановления';

  @override
  String get restoreSucceeded => 'Восстановление успешно';

  @override
  String get restoreFailed => 'Восстановление не удалось';

  @override
  String get complianceOk => 'Соответствие — в порядке';

  @override
  String get complianceIssues => 'Обнаружены проблемы соответствия';

  @override
  String get labelQuarter => 'Квартал';

  @override
  String get labelQuarterlyBackup => 'Ежеквартальная копия';

  @override
  String get labelBackupDue => 'Требуется копия';

  @override
  String get labelBackupsRecorded => 'Зарегистрировано копий';

  @override
  String get labelLastRestoreTest => 'Последний тест восстановления';

  @override
  String get labelRestoreTests => 'Тесты восстановления';

  @override
  String get statusDone => '✅ Выполнено';

  @override
  String get statusNotDone => '❌ Не выполнено';

  @override
  String get yes => 'Да';

  @override
  String get statusSucceeded => '✅ Успешно';

  @override
  String get statusNotDoneOrFailed => '❌ Не выполнено/Ошибка';

  @override
  String get storageGoogleDrive => 'Google Drive';

  @override
  String get storageOneDrive => 'OneDrive';

  @override
  String get storageDropbox => 'Dropbox';

  @override
  String get storageAwsS3 => 'AWS S3';

  @override
  String get storageExternalHdd => 'Внешний диск';

  @override
  String get storageNas => 'NAS';

  @override
  String get storageUsb => 'USB / Flash';

  @override
  String get storageFirebase => 'Firebase Backup';

  @override
  String get storageLocalServer => 'Локальный сервер';

  @override
  String get storageFtp => 'FTP / SFTP';

  @override
  String get storageOther => 'Другое';

  @override
  String get hintGoogleDrive =>
      'Ссылка на папку (https://drive.google.com/...)';

  @override
  String get hintOneDrive => 'Ссылка на папку (https://onedrive.live.com/...)';

  @override
  String get hintDropbox => 'Ссылка на папку (https://dropbox.com/...)';

  @override
  String get hintAwsS3 => 'Имя бакета и путь (s3://bucket/path/)';

  @override
  String get hintExternalHdd => 'Имя диска и путь (D:\\Backups\\LogiRoute)';

  @override
  String get hintNas => 'Адрес и путь (\\\\192.168.1.10\\backups)';

  @override
  String get hintUsb => 'Имя устройства и путь (E:\\LogiRoute_Backup)';

  @override
  String get hintFirebase => 'Имя проекта (logiroute-app)';

  @override
  String get hintLocalServer => 'Имя сервера и путь (/srv/backups/logiroute)';

  @override
  String get hintFtp => 'Адрес сервера (ftp://server.com/backups/)';

  @override
  String get hintOther => 'Опишите точное расположение';

  @override
  String get paymentMethodLabel => 'Способ оплаты';

  @override
  String get cash => 'Наличные';

  @override
  String get cheque => 'Чек';

  @override
  String get bankTransfer => 'Банковский перевод';

  @override
  String get creditCard => 'Кредитная карта';

  @override
  String get paymentBankNumber => '№ банка';

  @override
  String get paymentBranchNumber => '№ филиала';

  @override
  String get paymentAccountNumber => '№ счёта';

  @override
  String get paymentChequeNumber => '№ чека';

  @override
  String get paymentDueDateLabel => 'Дата погашения';

  @override
  String get paymentClearingHouse => 'Солик';

  @override
  String get paymentClearingIsracard => 'Isracard';

  @override
  String get paymentClearingCal => 'Cal';

  @override
  String get paymentClearingDiners => 'Diners';

  @override
  String get paymentClearingAmex => 'American Express';

  @override
  String get paymentClearingLeumi => 'Leumi Card';

  @override
  String get paymentCardName => 'Название карты';

  @override
  String get paymentDealType => 'Тип операции';

  @override
  String get paymentDealRegular => 'Обычная';

  @override
  String get paymentDealInstallments => 'Рассрочка';

  @override
  String get paymentDealCredit => 'Кредит';

  @override
  String get paymentInstallmentCount => 'Платежей';

  @override
  String get paymentBankRequired => 'Укажите номер банка';

  @override
  String get paymentBranchRequired => 'Укажите номер филиала';

  @override
  String get paymentAccountRequired => 'Укажите номер счёта';

  @override
  String get paymentChequeRequired => 'Укажите номер чека';

  @override
  String get paymentDueDateRequired => 'Укажите дату погашения';

  @override
  String get paymentInstallmentRange => 'Рассрочка: от 2 до 36';

  @override
  String get dispatcherTaxInvoiceReceiptTitle =>
      'חשבונית מס/קבלה для диспетчера';

  @override
  String get dispatcherTaxInvoiceReceiptHint =>
      'Разрешить диспетчеру выписывать חשבונית מס/קבלה при оплате при доставке';

  @override
  String get createTaxInvoiceReceiptTitle => 'Создать счёт-фактуру/квитанцию';

  @override
  String get createTaxInvoiceReceiptTooltip => 'חשבונית מס/קבלה (оплачено)';

  @override
  String get notSelected => 'Не выбрано';

  @override
  String get paidStatus => 'Оплачено';

  @override
  String get totalToPay => 'Итого к оплате';

  @override
  String get paymentReceivedCheckbox =>
      'Оплата получена (Счёт-фактура/Квитанция)';

  @override
  String get paymentReceivedHint =>
      'Отметьте если клиент оплатил — документ станет счёт-фактурой';

  @override
  String get createDeliveryNoteTitle => 'Создание накладной';

  @override
  String get createInvoiceTitle => 'Создание счёта';

  @override
  String get creatingDoc => 'Создаётся...';

  @override
  String get createAndPrint => 'Создать и распечатать';

  @override
  String get createDeliveryNoteBtn => 'Создать накладную';

  @override
  String get deliveryDateLabel => 'Дата доставки:';

  @override
  String get paymentTermsLabel => 'Условия оплаты:';

  @override
  String get days30 => '30 дней';

  @override
  String get days60 => '60 дней';

  @override
  String get days90 => '90 дней';

  @override
  String get manualEntry => 'Вручную';

  @override
  String get payUntilLabel => 'Оплата до:';

  @override
  String get itemLabel => 'Товар';

  @override
  String get cartonsLabel => 'Картоны';

  @override
  String get pricePerUnitLabel => 'Цена/ед.';

  @override
  String get totalLabel => 'Итого';

  @override
  String get discountLabel => 'Скидка:';

  @override
  String get clientLabelColon => 'Клиент:';

  @override
  String get addressLabelColon => 'Адрес:';

  @override
  String get driverLabelColon => 'Водитель:';

  @override
  String get truckLabelColon => 'Грузовик:';

  @override
  String get clientKvLabel => 'Клиент';

  @override
  String get addressKvLabel => 'Адрес';

  @override
  String get driverKvLabel => 'Водитель';

  @override
  String get truckKvLabel => 'Грузовик';

  @override
  String get deliveryDateKvLabel => 'Дата доставки';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get departureTimeValue => 'Время выезда: 07:00';

  @override
  String get userNotLoggedIn =>
      'Пользователь не авторизован — невозможно создать документ';

  @override
  String get serverIssuanceError => 'Ошибка выпуска документа с сервера';

  @override
  String deliveryNoteAlreadyExists(int docNum) {
    return 'Накладная уже существует (#$docNum)';
  }

  @override
  String deliveryNoteCreatedSuccess(int docNum) {
    return '✅ Накладная создана (#$docNum)';
  }

  @override
  String taxInvoiceReceiptCreatedSuccess(int docNum) {
    return '✅ Счёт-фактура/квитанция создана (#$docNum)';
  }

  @override
  String invoiceCreatedSuccess(int docNum) {
    return '✅ Счёт создан (#$docNum)';
  }

  @override
  String invoicePeriodLockedError(String date, String lockedUntil) {
    return 'Дата $date в закрытом бухгалтерском периоде (до $lockedUntil). Выберите более позднюю дату.';
  }

  @override
  String get possibleDuplicateOrder => 'Возможный дубликат заказа';

  @override
  String exactDuplicateFound(String name) {
    return 'Найден точный дубликат для $name!';
  }

  @override
  String existingOrdersFound(String name) {
    return 'Найдены существующие заказы для $name:';
  }

  @override
  String get checkNotDuplicate => 'Убедитесь, что это не дубликат!';

  @override
  String get deleteDuplicates => 'Удалить дубликаты';

  @override
  String get driverRouteTitle => 'Маршрут водителя';

  @override
  String driverAnotherRoutePoints(int count) {
    return 'Ещё маршрут: $count точек';
  }

  @override
  String wazeOpenError(String error) {
    return 'Ошибка открытия Waze: $error';
  }

  @override
  String get remainingLabel => 'Осталось';

  @override
  String percentCompleted(Object percent) {
    return '$percent% выполнено';
  }

  @override
  String nPoints(Object count) {
    return '$count точек';
  }

  @override
  String get shiftScheduleTitle => 'График смен';

  @override
  String get shiftWorkingDays => 'Рабочие дни';

  @override
  String get shiftDayMon => 'Пн';

  @override
  String get shiftDayTue => 'Вт';

  @override
  String get shiftDayWed => 'Ср';

  @override
  String get shiftDayThu => 'Чт';

  @override
  String get shiftDayFri => 'Пт';

  @override
  String get shiftDaySat => 'Сб';

  @override
  String get shiftDaySun => 'Вс';

  @override
  String get shiftStart => 'Начало смены';

  @override
  String get shiftEnd => 'Конец смены';

  @override
  String get shiftSaved => 'Сохранено';

  @override
  String get shiftRoutingSection => 'Параметры маршрутизации';

  @override
  String get routingAvgSpeedKmh => 'Средняя скорость (км/ч)';

  @override
  String get routingServiceMinutes => 'Время на точке (мин)';

  @override
  String get routingDeliveryDayMode => 'Дата доставки в счёте';

  @override
  String get deliveryDaySame => 'Сегодня';

  @override
  String get deliveryDayNext => 'Завтра';

  @override
  String get deliveryDayNextWorking => 'Ближайший рабочий день';

  @override
  String shiftLoadError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String shiftSaveError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get shiftNoCompanyId => 'Компания не выбрана';

  @override
  String get shiftHolidaysTitle => 'Праздники (GPS выкл.)';

  @override
  String get shiftLoadHolidays => 'Загрузить праздники';

  @override
  String get shiftNoHolidays => 'Праздники не заданы';

  @override
  String shiftHolidaysLoaded(int count) {
    return 'Загружено $count праздников';
  }

  @override
  String shiftHolidaysLoadError(String error) {
    return 'Ошибка загрузки праздников: $error';
  }

  @override
  String get taskNoteLabel => 'Задание (без товара)';

  @override
  String get taskNoteHint => 'Забрать чек, возврат, и т.д.';

  @override
  String get adminActivityLog => 'Журнал событий';

  @override
  String get appBarGroupReports => 'Отчёты';

  @override
  String get appBarGroupWarehouse => 'Склад';

  @override
  String get appBarGroupCompany => 'Компания';

  @override
  String get appBarGroupBilling => 'Биллинг';

  @override
  String get appBarGroupPlatform => 'Платформа';

  @override
  String get appBarGroupLogistics => 'Логистика';

  @override
  String get appBarGroupArchive => 'Архив и данные';

  @override
  String get appBarGroupOperations => 'Операции';

  @override
  String get appBarGroupImportExport => 'Импорт и экспорт';

  @override
  String get appBarGroupHelp => 'Справка';

  @override
  String get ownerNavOverview => 'Обзор';

  @override
  String get ownerNavManagement => 'Управление';

  @override
  String get ownerNavOperations => 'Операции';

  @override
  String get ownerNavCompliance => 'Контроль';

  @override
  String get period24h => '24 часа';

  @override
  String get period48h => '48 часов';

  @override
  String get periodWeek => 'Неделя';

  @override
  String get searchActivityHint => 'Поиск по пользователю или действию...';

  @override
  String get noActivityEvents => 'Нет событий за выбранный период';

  @override
  String get auditSourceLabel => 'Бизнес-аудит';

  @override
  String get accessSourceLabel => 'Журнал доступа';

  @override
  String get accessEventLogin => 'Вход';

  @override
  String get accessEventLogout => 'Выход';

  @override
  String get accessEventViewDocument => 'Просмотр документа';

  @override
  String get accessEventPrintDocument => 'Печать документа';

  @override
  String get accessEventExportData => 'Экспорт данных';

  @override
  String get accessEventCreateDocument => 'Создание документа';

  @override
  String get accessEventCancelDocument => 'Отмена документа';

  @override
  String get accessEventViewAuditLog => 'Просмотр аудита';

  @override
  String get accessEventViewReport => 'Просмотр отчёта';

  @override
  String get accessEventAdminAction => 'Действие админа';

  @override
  String get activityCsvUser => 'Пользователь';

  @override
  String get activityCsvAction => 'Действие';

  @override
  String get activityCsvWhen => 'Когда';

  @override
  String get activityCsvSource => 'Источник';

  @override
  String errorLoadingWithDetail(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String errorWithDetail(String error) {
    return '❌ Ошибка: $error';
  }

  @override
  String get savedSuccessCheck => '✅ Сохранено';

  @override
  String get pickDate => 'Выбрать';

  @override
  String get billingStatusSection => 'Статус биллинга';

  @override
  String get trialPeriodSection => 'Пробный период';

  @override
  String get trialPeriodDesc =>
      'При billingStatus = trial доступ истекает после этой даты.';

  @override
  String get notSet => 'Не задано';

  @override
  String get paymentPaidUntilSection => 'Оплата — оплачено до';

  @override
  String get paymentPaidUntilDesc =>
      'Источник истины для автоматизации биллинга. После этой даты → grace → suspended.';

  @override
  String get accountingPeriodLockSection => 'Блокировка учётного периода';

  @override
  String get accountingPeriodLockDesc =>
      'Документы с deliveryDate ≤ этой даты нельзя создавать или изменять.';

  @override
  String get notSetAllPeriodsOpen => 'Не задано (все периоды открыты)';

  @override
  String get unlockAllPeriods => 'Разблокировать все периоды';

  @override
  String get usersLoseAccessWarning =>
      '⚠️ Пользователи потеряют весь доступ (чтение и запись заблокированы)';

  @override
  String get trialExpiredBlocked =>
      '⚠️ Пробный период истёк — доступ заблокирован';

  @override
  String get paymentExpiredWarning =>
      '⚠️ Оплата истекла — billingEnforcer переведёт в grace/suspended';

  @override
  String get gracePeriodLabel => 'Льготный период:';

  @override
  String companyIdLabel(String id) {
    return 'Компания: $id';
  }

  @override
  String get locationNotReady => 'Геолокация не готова';

  @override
  String get locationPermissionRequired =>
      'Для продолжения требуется разрешение на геолокацию.';

  @override
  String get enableDeviceLocation =>
      'Включите геолокацию на устройстве для продолжения.';

  @override
  String get openSettings => 'Открыть настройки';

  @override
  String get checkAgain => 'Проверить снова';

  @override
  String get locationDeniedForever =>
      'Разрешение отклонено навсегда. Откройте настройки приложения.';

  @override
  String get pendingApprovalTitle => 'Ожидание одобрения';

  @override
  String get pendingApprovalBody =>
      'Регистрация успешно принята.\nАдминистратор назначит вас в компанию и выдаст роль.';

  @override
  String get registerTitle => 'Регистрация в LogiRoute';

  @override
  String get registerSubtitle =>
      'После регистрации администратор назначит вас в компанию';

  @override
  String get phoneOptional => 'Телефон (необязательно)';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get alreadyHaveAccountLogin => 'Уже есть аккаунт — Войти';

  @override
  String get minSixCharacters => 'Минимум 6 символов';

  @override
  String get invalidEmailShort => 'Некорректный email';

  @override
  String get creditNoteCreatedSuccess => 'Кредит-нота успешно создана';

  @override
  String get originalDocumentLabel => 'Исходный документ';

  @override
  String get correctionTypeLabel => 'Тип коррекции';

  @override
  String get fullCorrectionTitle => 'Полная коррекция';

  @override
  String get fullCorrectionSubtitle => 'Все строки из исходного документа';

  @override
  String get partialCorrectionTitle => 'Частичная коррекция';

  @override
  String get partialCorrectionSubtitle => 'Редактирование/удаление строк';

  @override
  String get correctionLinesTitle => 'Строки кредита';

  @override
  String get correctionSummaryTitle => 'Итого кредита';

  @override
  String get correctionReasonLabel => 'Причина коррекции *';

  @override
  String descriptionIndex(int index) {
    return 'Описание $index';
  }

  @override
  String get importNoCompanySelected => 'Ошибка: компания не выбрана';

  @override
  String get importBack => 'Назад';

  @override
  String get importClose => 'Закрыть';

  @override
  String importCount(int count) {
    return 'Импорт ($count)';
  }

  @override
  String get noBusinessTypesAvailable => 'Нет доступных типов бизнеса';

  @override
  String get noTemplatesForBusinessType =>
      'Нет шаблонов для этого типа бизнеса';

  @override
  String get importingProductsWait => 'Импорт товаров, подождите...';

  @override
  String get loadingDocument => 'Загрузка документа...';

  @override
  String get documentNotFound => 'Документ не найден';

  @override
  String get goBack => 'Назад';

  @override
  String get itemsTitle => 'Позиции';

  @override
  String get skuColumn => 'Артикул';

  @override
  String get typeColumn => 'Тип';

  @override
  String get numberColumn => 'Номер';

  @override
  String get quantityColumn => 'Количество';

  @override
  String get priceColumn => 'Цена';

  @override
  String get totalColumn => 'Итого';

  @override
  String get cancellationDetailsTitle => 'Детали отмены';

  @override
  String docIdLabel(String id) {
    return 'ID док.: $id';
  }

  @override
  String documentTypeUnsupported(String collection) {
    return 'Открытие документа типа $collection пока не поддерживается';
  }

  @override
  String get linkCopiedToClipboard => 'Ссылка скопирована в буфер';

  @override
  String get saveProfileTitle => 'Сохранить профиль';

  @override
  String get profileNameLabel => 'Имя профиля';

  @override
  String profileSaved(String name) {
    return 'Профиль \"$name\" сохранён';
  }

  @override
  String get accountingExportTitle => 'Экспорт в бухгалтерию';

  @override
  String get downloadBkmv => 'Скачать BKMV';

  @override
  String get bkmvExportSubtitle =>
      'ZIP OPENFRMT (INI.TXT + BKMVDATA.TXT) для רשות המסים';

  @override
  String get bkmvTaxIdRequired => 'Для BKMV нужен ח.פ компании';

  @override
  String get bkmvExportEmpty => 'Нет документов за выбранный период';

  @override
  String get bkmvSimulatorFailedTitle => 'Проверка OPENFRMT не пройдена';

  @override
  String get bkmvSimulatorFailedBody =>
      'Файл не скачан. Исправьте ошибки и повторите.';

  @override
  String get bkmvSimulatorPassed =>
      'Локальная проверка формата רשות המסים пройдена';

  @override
  String get bkmvSimulatorWarnings => 'Предупреждения';

  @override
  String get bkmvSoftwareRegistrationLabel => 'Рег. номер ПО (BKMV)';

  @override
  String get bkmvSoftwareRegistrationHint => '8 цифр от רשות המסים — поле A100';

  @override
  String get targetSoftwareLabel => 'Целевое ПО';

  @override
  String get periodSection => 'Период';

  @override
  String get untilLabel => 'До';

  @override
  String get documentTypeSection => 'Тип документа';

  @override
  String get fileSettingsSection => 'Настройки файла';

  @override
  String get separatorLabel => 'Разделитель';

  @override
  String get encodingSection => 'Кодировка';

  @override
  String exportErrorWithDetail(String error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String get lastCheckResult => 'Результат последней проверки';

  @override
  String get noPreviousChecks =>
      'Нет предыдущих проверок. Нажмите ▶ для запуска.';

  @override
  String get gapsLabel => 'Пропуски';

  @override
  String get quantityCannotBeNegative =>
      'Количество не может быть отрицательным';

  @override
  String get excelExportWebOnly =>
      'Экспорт в Excel доступен только в веб-версии';

  @override
  String exportErrorDetail(String error) {
    return '❌ Ошибка экспорта: $error';
  }

  @override
  String get productCodeRequired => 'Артикул *';

  @override
  String get typeRequired => 'Тип *';

  @override
  String get numberRequired => 'Номер *';

  @override
  String get volumeMlOptional => 'Объём в мл (необязательно)';

  @override
  String get quantityOnPalletRequired => 'Количество на паллете *';

  @override
  String get diameterOptional => 'Диаметр (необязательно)';

  @override
  String get packedCartonOptional =>
      'Упаковка — кол-во в коробке (необязательно)';

  @override
  String get additionalInfoOptional => 'Доп. информация (необязательно)';

  @override
  String get hashbonitUnderConstruction => 'Hashbonit в разработке';

  @override
  String errorSavingWithDetail(String error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String get testEmailSent => '✅ Тестовый email отправлен';

  @override
  String get testWhatsAppSent => '✅ Тестовый WhatsApp отправлен';

  @override
  String testFailedWithDetail(String error) {
    return '❌ Тест не пройден: $error';
  }

  @override
  String get paperSize80mmReceipt => '80мм (чек)';

  @override
  String get noDocumentId => 'Нет ID документа';

  @override
  String get urgencyVeryUrgent => 'Очень срочно';

  @override
  String get priorityLabel => 'Приоритет';

  @override
  String get orderInRouteLabel => 'Порядок в маршруте';

  @override
  String get newCategoryRequired => 'Новая категория *';

  @override
  String get cancellationReasonRequired => 'Причина отмены (обязательно)';

  @override
  String get searchBoxTypesHint => 'Поиск по артикулу / типу / номеру';

  @override
  String get loginTimeout => 'Таймаут входа (20с)';

  @override
  String errorWithMessage(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get retentionPolicyInfo =>
      'По закону о ведении учёта документы хранятся не менее 7 лет.\nПроверка подтверждает, что документы не удалены и нет пропусков в нумерации.';

  @override
  String get podRetentionInfo =>
      'Фото подтверждения доставки (PoD) хранятся 90 дней, затем удаляются автоматически. Координаты и время доставки сохраняются.';

  @override
  String oldestDocumentDate(String date) {
    return 'Старейший документ: $date';
  }

  @override
  String retentionCutoffDate(String date) {
    return 'Дата отсечения: $date';
  }

  @override
  String retentionGapsCount(int actual, int expected) {
    return 'Пропуски: $actual из $expected ожидаемых';
  }

  @override
  String retentionHistoryEntry(String user, int count) {
    return '$user • $count документов';
  }

  @override
  String retentionDocumentsCount(int count) {
    return 'Документы: $count';
  }

  @override
  String get issuesFound => 'Обнаружены проблемы';

  @override
  String get exportFormatHashavshevet => 'Hashavshevet';

  @override
  String get exportFormatHashavshevetDesc =>
      'Текстовый файл с табуляцией — совместим с импортом Hashavshevet';

  @override
  String get exportFormatPriority => 'Priority ERP';

  @override
  String get exportFormatPriorityDesc =>
      'CSV-файл, совместимый с импортом Priority';

  @override
  String get exportFormatCsv => 'Универсальный CSV';

  @override
  String get exportFormatCsvDesc =>
      'Универсальный CSV — подходит для любого ПО';

  @override
  String get encodingUtf8Bom => 'UTF-8 + BOM (рекомендуется для Excel)';

  @override
  String get encodingUtf8 => 'UTF-8 (без BOM)';

  @override
  String get encodingWindows1255 => 'Windows-1255 (старый Hashavshevet)';

  @override
  String get separatorComma => 'Запятая (,)';

  @override
  String get separatorSemicolon => 'Точка с запятой (;)';

  @override
  String get separatorTab => 'Табуляция';

  @override
  String get hashavshevetEncodingHint =>
      'Для старых версий Hashavshevet — выберите Windows-1255';

  @override
  String get exportCompleteTitle => 'Экспорт завершён';

  @override
  String exportRecordsCount(int count, String fileName) {
    return 'Экспорт завершён — $count записей ($fileName)';
  }

  @override
  String fileLabel(String name) {
    return 'Файл: $name';
  }

  @override
  String recordsLabel(int count) {
    return 'Записи: $count';
  }

  @override
  String formatLabel(String name) {
    return 'Формат: $name';
  }

  @override
  String get downloadFileBtn => 'Скачать файл';

  @override
  String get exportAction => 'Экспорт';

  @override
  String get loginRequiredFirst => 'Сначала войдите в систему';

  @override
  String documentNotFoundAtPath(String path) {
    return 'Документ не найден по пути: $path';
  }

  @override
  String get documentNotFoundOrNoAccess => 'Документ не найден или нет доступа';

  @override
  String companyLabelColon(String name) {
    return 'Компания: $name';
  }

  @override
  String get documentNumberLabel => 'Номер документа';

  @override
  String get createdAtLabel => 'Создан';

  @override
  String get createdByLabel => 'Создал';

  @override
  String get assignmentNumberLabel => 'Номер назначения';

  @override
  String get cancelledByLabel => 'Отменил';

  @override
  String get cancellationDateLabel => 'Дата отмены';

  @override
  String get totalBeforeDiscountLabel => 'Итого до скидки';

  @override
  String discountPercentLabel(int percent) {
    return 'Скидка ($percent%)';
  }

  @override
  String get vat18Label => 'НДС (18%)';

  @override
  String get invoiceManagementTitle => 'Управление счетами';

  @override
  String errorLoadingInvoices(String error) {
    return '❌ Ошибка загрузки счетов: $error';
  }

  @override
  String assignmentNumberReceived(String number) {
    return '✅ Номер назначения получен: $number';
  }

  @override
  String assignmentRequestError(String error) {
    return '❌ Ошибка запроса назначения: $error';
  }

  @override
  String get standaloneInvoiceInDev =>
      '⚠️ Создание отдельного счёта в разработке';

  @override
  String receiptPeriodLockedError(String docDate, String lockDate) {
    return '🔒 Нельзя создать квитанцию — дата документа ($docDate) в закрытом периоде (до $lockDate)';
  }

  @override
  String get receiptCreatedAndPrinted => '✅ Квитанция создана и напечатана';

  @override
  String receiptCreateError(String error) {
    return '❌ Ошибка создания квитанции: $error';
  }

  @override
  String get receiptIssuanceError => 'Ошибка выпуска квитанции с сервера';

  @override
  String get invoicePrintedSuccess => '✅ Счёт напечатан';

  @override
  String get cancelInvoiceTitle => 'Отмена счёта';

  @override
  String cancelInvoiceConfirm(String clientName) {
    return 'Отменить счёт для $clientName?';
  }

  @override
  String get cancelInvoiceLawNote =>
      'По закону о ведении учёта счета нельзя удалять, только отменять.';

  @override
  String get enterCancellationReason => 'Введите причину отмены';

  @override
  String get cancelInvoiceButton => 'Отменить счёт';

  @override
  String get invoiceCancelledSuccess => '✅ Счёт отменён';

  @override
  String cancelInvoiceError(String error) {
    return '❌ Ошибка отмены: $error';
  }

  @override
  String get deliveryNoteShort => 'Накл. доставки';

  @override
  String get taxInvoiceReceiptShort => 'Счёт/квитанция';

  @override
  String get originalPrintedLabel => 'Оригинал напечатан';

  @override
  String copiesCountLabel(int count) {
    return 'Копии: $count';
  }

  @override
  String assignmentApprovedLabel(String number) {
    return 'Назначение: $number';
  }

  @override
  String get assignmentPendingLabel => 'Ожидание назначения';

  @override
  String get assignmentRejectedLabel => 'Назначение отклонено';

  @override
  String get assignmentErrorLabel => 'Ошибка назначения';

  @override
  String get assignmentRequiredLabel => 'Требуется назначение';

  @override
  String get historyTooltip => 'История';

  @override
  String get reprintTooltip => 'Повторная печать';

  @override
  String get createReceiptTooltip => 'Создать квитанцию';

  @override
  String get cancelInvoiceTooltip => 'Отменить счёт';

  @override
  String get retryAssignmentTooltip => 'Повторить назначение';

  @override
  String invoiceNumberTitle(int number) {
    return 'Счёт #$number';
  }

  @override
  String driverWithName(String name) {
    return 'Водитель: $name';
  }

  @override
  String deliveryDateWithValue(String date) {
    return 'Дата доставки: $date';
  }

  @override
  String totalWithAmount(String amount) {
    return 'Итого: ₪$amount';
  }

  @override
  String get newInvoiceButton => 'Новый счёт';

  @override
  String get reprintDialogTitle => 'Повторная печать';

  @override
  String get copyTypeLabel => 'Копия';

  @override
  String copyNumberLabel(int number) {
    return 'Копия номер $number';
  }

  @override
  String get trueToOriginalLabel => 'Верно оригиналу';

  @override
  String get replacesOriginalLabel => 'Заменяет оригинал';

  @override
  String printCopiesButton(int count) {
    return 'Печать $count копий';
  }

  @override
  String get createReceiptTitle => 'Создание квитанции';

  @override
  String receiptForInvoice(int number) {
    return 'Квитанция по счёту #$number';
  }

  @override
  String clientWithName(String name) {
    return 'Клиент: $name';
  }

  @override
  String amountWithValue(String amount) {
    return 'Сумма: ₪$amount';
  }

  @override
  String get createReceiptButton => 'Создать квитанцию';

  @override
  String get addBoxTypeButton => 'Добавить тип коробки';

  @override
  String inStockCount(int count) {
    return 'На складе: $count ед.';
  }

  @override
  String onPalletCount(String count) {
    return 'На паллете: $count';
  }

  @override
  String volumeWithUnit(String value) {
    return 'Объём: $value мл';
  }
}
