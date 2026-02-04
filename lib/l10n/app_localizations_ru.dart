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
  String get email => 'Электронная почта';

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
  String get urgency => 'Срочность';

  @override
  String get pallets => 'Паллеты';

  @override
  String get boxes => 'Коробки';

  @override
  String get boxesPerPallet => 'Коробок на паллету (16–48)';

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
  String get required => 'Обязательно';

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
  String get phone => 'Телефон';

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
  String get addressNotFound => 'Адрес не найден';

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
}
