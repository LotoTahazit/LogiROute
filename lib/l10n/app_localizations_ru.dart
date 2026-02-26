// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

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
  String get language => 'Язык';

  @override
  String get hebrew => 'Иврит';

  @override
  String get russian => 'Русский';

  @override
  String get english => 'Английский';

  @override
  String get capacity => 'Вместимость';

  @override
  String get totalPallets => 'Всего паллет';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get save => 'Сохранить';

  @override
  String get pointDone => 'Точка выполнена';

  @override
  String get noActivePoints => 'Нет активных точек';

  @override
  String get pointCompleted => 'Точка завершена';

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
  String get statusActive => 'активен';

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
  String get printError => 'Ошибка печати';

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
  String get passwordResetEmailSent => 'Письмо для сброса пароля отправлено';

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
  String get companyNameHebrew => 'Название компании (иврит)';

  @override
  String get companyNameEnglish => 'Название компании (английский)';

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
}
