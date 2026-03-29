// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get autoDistributePallets => 'פצל אוטומטית משטחים';

  @override
  String get autoDistributeSuccess => 'המשטחים חולקו אוטומטית לנהגים!';

  @override
  String get autoDistributeError => 'שגיאת פיצול אוטומטי';

  @override
  String get appTitle => 'לוגי-ראוט';

  @override
  String get login => 'התחבר';

  @override
  String get email => 'אימייל';

  @override
  String get password => 'סיסמה';

  @override
  String get logout => 'התנתק';

  @override
  String get admin => 'מנהל מערכת';

  @override
  String get dispatcher => 'משגר';

  @override
  String get driver => 'נהג';

  @override
  String get viewAs => 'הצג כ';

  @override
  String get dashboard => 'לוח בקרה';

  @override
  String get users => 'משתמשים';

  @override
  String get routes => 'מסלולים';

  @override
  String get deliveryPoints => 'נקודות משלוח';

  @override
  String get addPoint => 'הוסף נקודה';

  @override
  String get createRoute => 'צור מסלול';

  @override
  String createRouteFromSelected(int count) {
    return 'מהנבחרים ($count)';
  }

  @override
  String get createRouteByZone => 'מסלול לפי אזור';

  @override
  String get clearSelection => 'נקה בחירה';

  @override
  String selectedCount(int count) {
    return 'נבחרו: $count';
  }

  @override
  String get noZoneLabel => 'ללא אזור';

  @override
  String selectedClientsDifferentZonesWarning(String zones) {
    return 'נבחרו לקוחות מאזורים שונים: $zones. ליצור את המסלול בכל זאת?';
  }

  @override
  String get address => 'כתובת';

  @override
  String get clientName => 'שם לקוח';

  @override
  String get clientNumber => 'מספר לקוח';

  @override
  String get clientManagement => 'ניהול לקוחות';

  @override
  String get editClient => 'ערוך לקוח';

  @override
  String get createClient => 'צור לקוח חדש';

  @override
  String get clientCreated => 'הלקוח נוצר בהצלחה';

  @override
  String get clientUpdated => 'הלקוח עודכן בהצלחה';

  @override
  String get noClientsFound => 'לא נמצאו לקוחות';

  @override
  String get searchClientHint => 'חפש לפי שם, מספר או כתובת';

  @override
  String get addressWillBeGeocoded => 'הכתובת תמופה לקואורדינטות';

  @override
  String get addressNotFound => 'כתובת לא נמצאה';

  @override
  String get geocodingError => 'שגיאת מיפוי כתובת';

  @override
  String get contactPerson => 'איש קשר';

  @override
  String get phone => 'טלפון';

  @override
  String get required => 'שדה חובה';

  @override
  String get search => 'חיפוש';

  @override
  String get urgency => 'דחיפות';

  @override
  String get pallets => 'משטחים';

  @override
  String get boxes => 'קרטונים';

  @override
  String get boxesPerPallet => 'קופסאות במשטח';

  @override
  String get openingTime => 'שעת פתיחה';

  @override
  String get status => 'סטטוס';

  @override
  String get pending => 'ממתין';

  @override
  String get assigned => 'הוקצה';

  @override
  String get inProgress => 'בתהליך';

  @override
  String get completed => 'הושלם';

  @override
  String get cancelled => 'בוטל';

  @override
  String get navigate => 'ניווט';

  @override
  String get openInMaps => 'פתח במפות';

  @override
  String get selectDriver => 'בחר נהג';

  @override
  String get addUser => 'הוסף משתמש';

  @override
  String get addNewUser => 'הוסף משתמש חדש';

  @override
  String get fullName => 'שם מלא';

  @override
  String get role => 'תפקיד';

  @override
  String get palletCapacity => 'קיבולת משטחים';

  @override
  String get truckWeight => 'טונאז\' (טון)';

  @override
  String get cancel => 'ביטול';

  @override
  String get add => 'הוסף';

  @override
  String get error => 'שגיאה';

  @override
  String get fillAllFields => 'יש למלא את כל השדות הנדרשים';

  @override
  String get userAddedSuccessfully => 'המשתמש נוסף בהצלחה';

  @override
  String get errorCreatingUser => 'שגיאה ביצירת המשתמש';

  @override
  String get emailAlreadyInUse => 'כתובת האימייל כבר בשימוש';

  @override
  String get weakPassword => 'הסיסמה חלשה מדי';

  @override
  String get warehouse => 'מחסן';

  @override
  String get invalidEmail => 'כתובת אימייל לא תקינה';

  @override
  String get invalidLoginCredentials => 'אימייל או סיסמה שגויים';

  @override
  String get tooManyRequests => 'יותר מדי ניסיונות. נסה שוב מאוחר יותר';

  @override
  String get systemManager => 'מנהל מערכת';

  @override
  String get ok => 'אישור';

  @override
  String get noDriversAvailable => 'אין נהגים זמינים';

  @override
  String get filterByDriver => 'סנן לפי נהג';

  @override
  String get allDrivers => 'כל הנהגים';

  @override
  String get viewingAs => 'אתה צופה במצב של';

  @override
  String get backToAdmin => 'חזור למנהל';

  @override
  String get cancelPoint => 'בטל נקודה';

  @override
  String get currentLocation => 'מיקום נוכחי';

  @override
  String get distance => 'מרחק';

  @override
  String get km => 'ק״מ';

  @override
  String get language => 'שפה';

  @override
  String get hebrew => 'עברית';

  @override
  String get russian => 'רוסית';

  @override
  String get english => 'אנגלית';

  @override
  String get capacity => 'קיבולת';

  @override
  String get totalPallets => 'סה\"כ משטחים';

  @override
  String get confirm => 'אשר';

  @override
  String get save => 'שמור';

  @override
  String get pointDone => 'נקודה הושלמה';

  @override
  String get noActivePoints => 'אין נקודות פעילות';

  @override
  String get pointCompleted => 'נקודה סומנה כהושלמה';

  @override
  String get next => 'הבא';

  @override
  String get pointAdded => 'נקודה נוספה';

  @override
  String get noPointsForRoute => 'אין נקודות זמינות ליצירת מסלול';

  @override
  String get routeCreated => 'המסלול נוצר';

  @override
  String get noDeliveryPoints => 'אין נקודות משלוח';

  @override
  String get markComplete => 'סמן כהושלם';

  @override
  String get mapViewRequiresApi => 'תצוגת מפה דורשת מפתח Google Maps API';

  @override
  String get unknownDriver => 'נהג לא ידוע';

  @override
  String get fixExistingRoutes => 'תקן מסלולים קיימים';

  @override
  String get printRoute => 'הדפס מסלול';

  @override
  String get routesFixed => 'המסלולים תוקנו!';

  @override
  String get statusPending => 'ממתין';

  @override
  String get statusAssigned => 'הוקצה';

  @override
  String get statusInProgress => 'בביצוע';

  @override
  String get statusCompleted => 'הושלם';

  @override
  String get statusCancelled => 'בוטל';

  @override
  String get statusActive => 'פעיל';

  @override
  String get roleDriver => 'נהג';

  @override
  String get cancelAction => 'בטל';

  @override
  String get completeAction => 'השלם';

  @override
  String get boxesHint => '1-672 קרטונים';

  @override
  String get urgencyNormal => 'רגיל';

  @override
  String get urgencyUrgent => 'דחוף';

  @override
  String get changeDriver => 'החלף נהג';

  @override
  String get cancelRoute => 'בטל מסלול';

  @override
  String get cancelRouteTitle => 'לבטל את המסלול?';

  @override
  String get cancelRouteDescription =>
      'כל הנקודות יחזרו למצב \'ממתין\'. להמשיך?';

  @override
  String get routeCancelled => 'המסלול בוטל, הנקודות הוחזרו לממתין';

  @override
  String get routePointsReordered => 'סדר הנקודות וה-ETA עודכנו';

  @override
  String get optimizeTime => 'אופטימיזציית זמן';

  @override
  String get routeAlreadyOptimal => 'המסלול כבר אופטימלי';

  @override
  String get routeOptimized => 'המסלול עודכן';

  @override
  String get routeOptimizationFailed => 'האופטימיזציה נכשלה';

  @override
  String get routeTimeNotOptimal => 'זמן המסלול לא אופטימלי';

  @override
  String get selectNewDriver => 'בחר נהג חדש';

  @override
  String get noAvailableDrivers => 'אין נהגים זמינים';

  @override
  String driverChangedTo(Object name) {
    return 'הנהג שונה ל $name';
  }

  @override
  String get noUsersFound => 'לא נמצאו משתמשים';

  @override
  String get palletStatistics => 'סטטיסטיקת משטחים';

  @override
  String get total => 'סה\"כ';

  @override
  String get delivered => 'נמסר';

  @override
  String get completionRate => 'שיעור השלמה';

  @override
  String get activeRoutes => 'מסלולים פעילים';

  @override
  String get order => 'סדר';

  @override
  String get roleAdmin => 'מנהל';

  @override
  String get roleDispatcher => 'מוקדן';

  @override
  String get roleWarehouseKeeper => 'מחסנאי';

  @override
  String get roleAccountant => 'חשב';

  @override
  String get roleOwner => 'בעלים';

  @override
  String get refresh => 'רענן';

  @override
  String get analytics => 'ניתוחים';

  @override
  String get settings => 'הגדרות';

  @override
  String get lastUpdated => 'עודכן לאחרונה';

  @override
  String get routeCopiedToClipboard => 'המסלול הועתק ללוח';

  @override
  String get printError => 'שגיאה בהדפסה';

  @override
  String get no => 'לא';

  @override
  String get routeNotFound => 'המסלול לא נמצא';

  @override
  String get map => 'מפה';

  @override
  String get noRoutesYet => 'אין עדיין מסלולים';

  @override
  String get points => 'נקודות';

  @override
  String get refreshMap => 'רענן מפה';

  @override
  String get clientNumberLabel => 'מספר לקוח (6 ספרות)';

  @override
  String get delete => 'מחק';

  @override
  String get deletePoint => 'מחק נקודה';

  @override
  String get pointDeleted => 'נקודה נמחקה';

  @override
  String get assignDriver => 'הקצה נהג';

  @override
  String get pointAssigned => 'נקודה הוקצתה';

  @override
  String addressNotFoundDescription(String address) {
    return 'לא ניתן למצוא קואורדינטות עבור הכתובת:\n\"$address\"\n\nהמערכת ניסתה הרבה אפשרויות אבל הגיאוקודינג נכשל.\n\nנסה:\n בדוק את איות הכתובת\n השתמש בכתובת מלאה עם עיר\n ודא שהכתובת קיימת במפות\n פנה למנהל לעזרה';
  }

  @override
  String get fixAddress => 'תקן כתובת';

  @override
  String get fixOldCoordinates => 'תקן קואורדינטות ישנות';

  @override
  String get fixOldCoordinatesDescription =>
      'זה ימחק נקודות עם קואורדינטות ירושלים ישנות. להמשיך?';

  @override
  String get oldCoordinatesFixed => 'קואורדינטות ישנות תוקנו';

  @override
  String get fixHebrewSearch => 'תקן חיפוש בעברית';

  @override
  String get fixHebrewSearchDescription =>
      'זה יתקן את אינדקס החיפוש לשמות לקוחות בעברית. להמשיך?';

  @override
  String get hebrewSearchFixed => 'אינדקס החיפוש בעברית תוקן';

  @override
  String get clientNumberRequired => 'הכנס מספר לקוח';

  @override
  String get clientNumberLength => 'המספר חייב להכיל 6 ספרות';

  @override
  String get bridgeHeightError => 'שגיאת גובה גשר';

  @override
  String get bridgeHeightErrorDescription =>
      'המסלול חסום על ידי גשר נמוך (גובה < 4מ\'). פנה למנהל לשליחות לבחירת מסלול חלופי.';

  @override
  String get routeBlockedByBridge => 'המסלול חסום על ידי גשר';

  @override
  String get alternativeRouteFound => 'נמצא מסלול חלופי';

  @override
  String get navigation => 'ניווט';

  @override
  String get loadingNavigation => 'טוען מסלול...';

  @override
  String get navigationError => 'שגיאת ניווט';

  @override
  String get noNavigationRoute => 'מסלול לא נמצא';

  @override
  String get retry => 'נסה שוב';

  @override
  String get previous => 'הקודם';

  @override
  String get showMap => 'הצג מפה';

  @override
  String get pointCancelled => 'נקודה בוטלה';

  @override
  String get removeFromRoute => 'הסר ממסלול';

  @override
  String get pointRemovedFromRoute => 'נקודה הוסרה מהמסלול';

  @override
  String removeFromRouteConfirm(String name) {
    return 'להסיר את \"$name\" מהמסלול ולהחזיר להמתנה?';
  }

  @override
  String get temporaryAddress => 'כתובת זמנית';

  @override
  String get temporaryAddressHint => 'כתובת למשלוח זה בלבד...';

  @override
  String get temporaryAddressHelper => 'לא משנה את הכתובת הראשית של הלקוח';

  @override
  String get temporaryAddressTooltip =>
      'כתובת זו תשמש רק למשלוח הנוכחי. הכתובת הראשית של הלקוח תישאר ללא שינוי.';

  @override
  String get originalAddress => 'כתובת מקורית';

  @override
  String get active => 'פעיל';

  @override
  String get forgotPassword => 'שכחת סיסמה?';

  @override
  String get passwordResetEmailSent => 'נשלח מייל לאיפוס סיסמה';

  @override
  String get companyId => 'שם חברה';

  @override
  String get gpsTrackingActive => 'מעקב GPS פעיל';

  @override
  String get gpsTrackingStopped => 'מעקב GPS הופסק';

  @override
  String get weekendDay => 'יום מנוחה';

  @override
  String get workDayEnded => 'יום העבודה הסתיים';

  @override
  String workStartsIn(int minutes) {
    return 'העבודה תתחיל בעוד $minutes דקות';
  }

  @override
  String workEndsIn(int minutes) {
    return 'העבודה תסתיים בעוד $minutes דקות';
  }

  @override
  String get edit => 'ערוך';

  @override
  String editUser(String name) {
    return 'ערוך $name';
  }

  @override
  String deleteUser(String name) {
    return 'למחוק $name?';
  }

  @override
  String get leaveEmptyToKeep => 'השאר ריק כדי לשמור את הנוכחי';

  @override
  String get userUpdated => 'המשתמש עודכן';

  @override
  String get userDeleted => 'המשתמש נמחק';

  @override
  String get updateError => 'שגיאת עדכון';

  @override
  String get deleteError => 'שגיאת מחיקה';

  @override
  String get noPermissionToEdit => 'אין לך הרשאה לערוך משתמש זה';

  @override
  String get warehouseStartPoint => 'נקודת התחלה לכל המסלולים';

  @override
  String get vehicleNumber => 'מספר רכב';

  @override
  String get biometricLoginTitle => 'להפעיל כניסה עם טביעת אצבע?';

  @override
  String get biometricLoginMessage =>
      'תוכל להיכנס לאפליקציה באמצעות טביעת אצבע במקום סיסמה.';

  @override
  String get biometricLoginYes => 'כן, הפעל';

  @override
  String get biometricLoginNo => 'לא';

  @override
  String get biometricLoginEnabled => '✅ כניסה עם טביעת אצבע הופעלה';

  @override
  String get biometricLoginCancelled => 'האימות בוטל';

  @override
  String get biometricLoginError => 'שגיאת ביומטריה';

  @override
  String get biometricLoginButton => 'היכנס עם טביעת אצבע';

  @override
  String get biometricLoginButtonFace => 'היכנס עם Face ID';

  @override
  String get biometricLoginOr => 'או';

  @override
  String get biometricAuthReason => 'היכנס באמצעות טביעת אצבע';

  @override
  String get viewModeWarehouse => 'מצב תצוגה: מחסנאי';

  @override
  String get returnToAdmin => 'חזור';

  @override
  String get manageBoxTypes => 'ניהול מאגר סוגים';

  @override
  String get boxTypesManager => 'ניהול מאגר סוגים';

  @override
  String get noBoxTypesInCatalog => 'אין סוגים במאגר';

  @override
  String get editBoxType => 'ערוך סוג';

  @override
  String get deleteBoxType => 'מחק סוג';

  @override
  String deleteBoxTypeConfirm(Object number, Object type) {
    return 'האם למחוק $type $number מהמאגר?';
  }

  @override
  String get boxTypeUpdated => 'סוג עודכן בהצלחה!';

  @override
  String get boxTypeDeleted => 'סוג נמחק בהצלחה!';

  @override
  String get addNewBoxType => 'הוסף סוג חדש למאגר';

  @override
  String get newBoxTypeAdded => 'סוג חדש נוסף למלאי בהצלחה!';

  @override
  String get typeLabel => 'סוג (בביע, מכסה, כוס)';

  @override
  String get numberLabel => 'מספר (100, 200, וכו\')';

  @override
  String get volumeMlLabel => 'נפח במ\"ל (אופציונלי)';

  @override
  String get quantityLabel => 'כמות (יחידות)';

  @override
  String get quantityPerPalletLabel => 'כמות במשטח';

  @override
  String get diameterLabel => 'קוטר (אופציונלי)';

  @override
  String get piecesPerBoxLabel => 'ארוז - כמות בקרטון (אופציונלי)';

  @override
  String get additionalInfoLabel => 'מידע נוסף (אופציונלי)';

  @override
  String get requiredField => 'שדה חובה';

  @override
  String get close => 'סגור';

  @override
  String formatHours(int hours) {
    return '$hours ש';
  }

  @override
  String formatMinutes(int minutes) {
    return '$minutes ד';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '$hours ש $minutes ד';
  }

  @override
  String get setWarehouseLocation => 'הגדר מיקום מחסן';

  @override
  String get latitudeWarehouse => 'קו רוחב (מחסן במשמרות)';

  @override
  String get longitudeWarehouse => 'קו אורך (מחסן במשמרות)';

  @override
  String get clearPendingPoints => 'נקה נקודות ממתינות';

  @override
  String get clearPendingPointsConfirm =>
      'זה ימחק רק נקודות משלוח ממתינות (לא מסלולים פעילים). להמשיך?';

  @override
  String get clearPending => 'נקה ממתינות';

  @override
  String get clearAllData => 'נקה את כל הנתונים';

  @override
  String get clearAllDataConfirm =>
      'זה ימחק את כל נקודות המשלוח. האם אתה בטוח?';

  @override
  String get deleteAll => 'מחק הכל';

  @override
  String get fixRouteNumbers => 'תקן מספרי מסלול';

  @override
  String get fixRouteNumbersConfirm =>
      'זה יחשב מחדש את מספרי המסלול לכל הנהגים (1, 2, 3...). להמשיך?';

  @override
  String get fixNumbers => 'תקן מספרים';

  @override
  String get dataMigration => 'העברת נתונים';

  @override
  String get daysToMigrate => 'ימים להעברה';

  @override
  String get oneTimeSetup => 'הגדרה חד-פעמית';

  @override
  String get migrationDescription =>
      'זה יבנה מסמכי סיכום עבור חשבוניות ומשלוחים קיימים.';

  @override
  String get migrationInstructions =>
      '• הפעל זאת פעם אחת לאחר פריסת העדכון\n• לוקח ~1 דקה עבור 30 ימים של נתונים\n• בטוח להפעיל מספר פעמים (יבנה מחדש)';

  @override
  String get days => 'ימים';

  @override
  String get warehouseInventoryManagement => 'מחסן - ניהול מלאי';

  @override
  String get addNewBoxTypeToCatalog => 'הוסף סוג חדש למאגר';

  @override
  String get showLowStockOnly => 'הצג רק מלאי נמוך';

  @override
  String get changeHistory => 'היסטוריית שינויים';

  @override
  String get exportReport => 'ייצוא דוח';

  @override
  String get searchByTypeOrNumber => 'חיפוש לפי סוג או מספר...';

  @override
  String get noItemsToExport => 'אין פריטים לייצוא';

  @override
  String get reportExportedSuccessfully => 'הדוח יוצא בהצלחה';

  @override
  String get exportError => 'שגיאה בייצוא';

  @override
  String get noItemsInInventory => 'אין פריטים במלאי';

  @override
  String get noItemsFound => 'לא נמצאו פריטים';

  @override
  String get productCode => 'מק\"ט';

  @override
  String get productCodeLabel => 'מק\"ט *';

  @override
  String get productCodeHelper => 'קוד ייחודי לכל מוצר';

  @override
  String get productCodeSearchHelper => 'הקלד מק\"ט לחיפוש במאגר';

  @override
  String get productCodeFoundInCatalog => 'מק\"ט נמצא במאגר';

  @override
  String get productCodeNotFoundInCatalog => 'מק\"ט לא נמצא במאגר';

  @override
  String get productCodeNotFoundAddFirst =>
      'מק\"ט לא נמצא במאגר. הוסף סוג חדש למאגר תחילה.';

  @override
  String get orSelectFromList => 'או בחר מק\"ט מהרשימה';

  @override
  String get selectFromFullList => 'בחירה מהרשימה המלאה';

  @override
  String get lowStock => 'מלאי נמוך!';

  @override
  String get limitedStock => 'מלאי מועט';

  @override
  String get volume => 'נפח (ליטר)';

  @override
  String get ml => 'מל';

  @override
  String get diameter => 'קוטר';

  @override
  String get packed => 'ארוז';

  @override
  String get piecesInBox => 'יח\' בקרטון';

  @override
  String get quantityPerPallet => 'כמות במשטח';

  @override
  String get additionalInfo => 'מידע נוסף';

  @override
  String get quantity => 'כמות';

  @override
  String get units => 'יח\'';

  @override
  String remainingUnitsOnly(int count) {
    return 'נותרו $count יחידות בלבד';
  }

  @override
  String get urgentOrderStock => 'דחוף! יש להזמין מלאי';

  @override
  String get updated => 'עודכן';

  @override
  String get by => 'ע\"י';

  @override
  String get addInventory => 'הוסף מלאי';

  @override
  String get inventoryUpdatedSuccessfully => 'מלאי עודכן בהצלחה!';

  @override
  String get catalogEmpty => 'המאגר ריק. הוסף סוג חדש למאגר תחילה.';

  @override
  String get editItem => 'ערוך פריט';

  @override
  String get itemUpdatedSuccessfully => 'פריט עודכן בהצלחה!';

  @override
  String get fillAllRequiredFields => 'נא למלא את כל השדות החובה';

  @override
  String get fillAllRequiredFieldsIncludingProductCode =>
      'נא למלא את כל השדות החובה (כולל מק\"ט)';

  @override
  String get typeUpdatedSuccessfully => 'סוג עודכן בהצלחה!';

  @override
  String get deletedSuccessfully => 'נמחק בהצלחה!';

  @override
  String get deleteConfirmation => 'מחק';

  @override
  String get searchByProductCode => 'חיפוש לפי מק\"ט או סוג או מספר...';

  @override
  String get warehouseInventory => 'מלאי';

  @override
  String get inventoryChangesReport => 'דוח שינויים במלאי';

  @override
  String get inventoryCountReportsTooltip => 'דוחות ספירת מלאי';

  @override
  String get archiveManagement => 'ניהול ארכיונים';

  @override
  String get inventoryCount => 'ספירת מלאי';

  @override
  String get inventoryCountReports => 'דוחות ספירת מלאי';

  @override
  String get startNewCount => 'התחל ספירת מלאי חדשה';

  @override
  String get startNewCountConfirm =>
      'האם להתחיל ספירת מלאי חדשה?\nזה ייצור רשימה של כל הפריטים במלאי.';

  @override
  String get start => 'התחל';

  @override
  String get noActiveCount => 'אין ספירת מלאי פעילה';

  @override
  String get countStarted => 'ספירת מלאי חדשה התחילה';

  @override
  String get errorStartingCount => 'שגיאה בהתחלת ספירה';

  @override
  String get errorLoadingCount => 'שגיאה בטעינת ספירה';

  @override
  String get errorUpdatingItem => 'שגיאה בעדכון פריט';

  @override
  String get completeCount => 'סיים ספירה';

  @override
  String completeCountConfirm(int count) {
    return 'יש עדיין $count פריטים שלא נספרו.\nהאם לסיים בכל זאת?';
  }

  @override
  String get finish => 'סיים';

  @override
  String get countCompleted => 'ספירת מלאי הושלמה בהצלחה';

  @override
  String get errorCompletingCount => 'שגיאה בסיום ספירה';

  @override
  String get showOnlyDifferences => 'הצג רק הפרשים';

  @override
  String get counted => 'נספרו';

  @override
  String get differences => 'הפרשים';

  @override
  String get shortage => 'חסר';

  @override
  String get surplus => 'עודף';

  @override
  String get searchByProductCodeTypeNumber => 'חיפוש לפי מק\"ט / סוג / מספר';

  @override
  String get noResults => 'לא נמצאו תוצאות';

  @override
  String get noDifferences => 'אין הפרשים';

  @override
  String get noItems => 'אין פריטים';

  @override
  String get expected => 'צפוי';

  @override
  String get actualCounted => 'נספר';

  @override
  String get difference => 'הפרש';

  @override
  String get suspiciousOrders => 'הזמנות חשודות';

  @override
  String get notes => 'הערות';

  @override
  String get notesOptional => 'הערות (אופציונלי)';

  @override
  String get enterValidNumber => 'נא להזין מספר תקין';

  @override
  String get noCountReports => 'אין דוחות ספירת מלאי';

  @override
  String get countReport => 'דוח ספירת מלאי';

  @override
  String get performedBy => 'ביצע';

  @override
  String get started => 'התחיל';

  @override
  String get finished => 'הסתיים';

  @override
  String get totalItems => 'סה\"כ פריטים';

  @override
  String get viewDetails => 'צפה בפרטים';

  @override
  String get approved => 'אושר';

  @override
  String get approveCount => 'אשר ספירה';

  @override
  String get approveCountConfirm =>
      'האם לאשר את הספירה ולעדכן את המלאי?\nפעולה זו תעדכן את כמויות המלאי בהתאם לספירה.';

  @override
  String get approveAndUpdate => 'אשר ועדכן';

  @override
  String get countApproved => 'הספירה אושרה והמלאי עודכן בהצלחה';

  @override
  String get errorApprovingCount => 'שגיאה באישור ספירה';

  @override
  String get countNotFound => 'דוח לא נמצא';

  @override
  String get exportToExcel => 'ייצוא ל-Excel';

  @override
  String get exportToExcelSoon => 'ייצוא לאקסל - בקרוב';

  @override
  String get countNotCompleted => 'הספירה לא הושלמה';

  @override
  String get errorLoadingReport => 'שגיאה בטעינת דוח';

  @override
  String get items => 'פריטים';

  @override
  String get selectDates => 'בחר תאריכים';

  @override
  String get allPeriod => 'כל התקופה';

  @override
  String get today => 'היום';

  @override
  String get yesterday => 'אתמול';

  @override
  String get thisWeek => 'השבוע';

  @override
  String get thisMonth => 'החודש';

  @override
  String get all => 'הכל';

  @override
  String get searchByProductCodeTypeNumberHint =>
      'חיפוש לפי מק\"ט, סוג או מספר...';

  @override
  String foundChanges(int count) {
    return 'נמצאו: $count שינויים';
  }

  @override
  String get added => 'הוספה';

  @override
  String get deducted => 'הוצאה';

  @override
  String noResultsFor(String query) {
    return 'לא נמצאו תוצאות עבור \"$query\"';
  }

  @override
  String get noChangesInPeriod => 'אין שינויים בתקופה זו';

  @override
  String get before => 'לפני';

  @override
  String get after => 'אחרי';

  @override
  String get reason => 'סיבה';

  @override
  String get statistics => 'סטטיסטיקה';

  @override
  String get totalArchives => 'סה\"כ ארכיונים';

  @override
  String get totalSize => 'גודל כולל';

  @override
  String get records => 'רשומות';

  @override
  String get archiveActions => 'פעולות ארכוב';

  @override
  String get archiveInventoryHistory => 'ארכב היסטוריית מלאי';

  @override
  String get archiveOrders => 'ארכב הזמנות';

  @override
  String get existingArchives => 'ארכיונים קיימים';

  @override
  String get noArchives => 'אין ארכיונים';

  @override
  String get archiveInventoryHistoryTitle => 'ארכוב היסטוריית מלאי';

  @override
  String get archiveInventoryHistoryConfirm =>
      'האם לארכב רשומות ישנות מ-3 חודשים אחרונים?\n\nהרשומות יסומנו כמאורכבות ולא יימחקו.';

  @override
  String get archiveCompletedOrdersTitle => 'ארכוב הזמנות שהושלמו';

  @override
  String get archiveCompletedOrdersConfirm =>
      'האם לארכב הזמנות שהושלמו לפני חודש?\n\nההזמנות יסומנו כמאורכבות ולא יימחקו.';

  @override
  String get archive => 'ארכב';

  @override
  String get errorLoadingArchives => 'שגיאה בטעינת ארכיונים';

  @override
  String get size => 'גודל';

  @override
  String get created => 'נוצר';

  @override
  String get download => 'הורד';

  @override
  String get mb => 'MB';

  @override
  String get insufficientStock => 'אין מספיק מלאי';

  @override
  String get cannotCreateOrderInsufficientStock =>
      'לא ניתן ליצור הזמנה - אין מספיק מלאי:';

  @override
  String get pleaseContactWarehouseKeeper => 'אנא פנה למחסנאי לעדכון המלאי.';

  @override
  String get understood => 'הבנתי';

  @override
  String get available => 'זמין';

  @override
  String get requested => 'מבוקש';

  @override
  String get itemNotFoundInInventory => 'פריט לא נמצא במלאי';

  @override
  String get productCodeNotFound => 'מק\"ט לא נמצא';

  @override
  String get companySettings => 'הגדרות חברה';

  @override
  String get companyDetails => 'פרטי חברה';

  @override
  String get companyNameHebrew => 'שם חברה (עברית)';

  @override
  String get companyNameEnglish => 'שם חברה (אנגלית)';

  @override
  String get taxId => 'ח.פ';

  @override
  String get addressHebrew => 'כתובת (עברית)';

  @override
  String get addressEnglish => 'כתובת (אנגלית)';

  @override
  String get poBox => 'ת.ד';

  @override
  String get city => 'עיר';

  @override
  String get zipCode => 'מיקוד';

  @override
  String get contact => 'יצירת קשר';

  @override
  String get fax => 'פקס';

  @override
  String get website => 'אתר';

  @override
  String get defaultDriver => 'נהג ברירת מחדל';

  @override
  String get driverName => 'שם נהג';

  @override
  String get driverPhone => 'טלפון נהג';

  @override
  String get departureTime => 'שעת יציאה';

  @override
  String get invoice => 'חשבונית';

  @override
  String get invoiceFooterText => 'טקסט תחתון בחשבונית';

  @override
  String get paymentTerms => 'תנאי תשלום';

  @override
  String get bankDetails => 'פרטי בנק';

  @override
  String get saveSettings => 'שמור הגדרות';

  @override
  String get settingsSaved => 'הגדרות נשמרו';

  @override
  String get errorSavingSettings => 'שגיאה בשמירת הגדרות';

  @override
  String get errorLoadingSettings => 'שגיאה בטעינת הגדרות';

  @override
  String get warning => 'אזהרה';

  @override
  String get migrationWarning =>
      'פעולה זו תוסיף את מזהה החברה לכל הרשומות הקיימות במסד הנתונים. ודא שאתה מבצע גיבוי לפני המשך.';

  @override
  String get currentCompanyId => 'מזהה חברה נוכחי';

  @override
  String get startMigration => 'התחל העברה';

  @override
  String get migrating => 'מעביר נתונים...';

  @override
  String get migrationStatistics => 'סטטיסטיקת העברה';

  @override
  String get migrationLog => 'יומן העברה';

  @override
  String get noMigrationYet => 'טרם בוצעה העברת נתונים';

  @override
  String get overloadWarning => 'אזהרת עומס יתר';

  @override
  String overloadWarningMessage(String driverName, int currentLoad, int newLoad,
      int totalLoad, int capacity) {
    return 'הנהג $driverName כבר נושא $currentLoad משטחים, והוספת $newLoad משטחים תעלה את הסה\"כ ל-$totalLoad משטחים (קיבולת: $capacity משטחים). האם להמשיך?';
  }

  @override
  String get continueAnyway => 'המשך בכל זאת';

  @override
  String get productManagement => 'ניהול מוצרים';

  @override
  String get addProduct => 'הוסף מוצר';

  @override
  String get editProduct => 'ערוך מוצר';

  @override
  String get deleteProduct => 'מחק מוצר';

  @override
  String get productName => 'שם המוצר';

  @override
  String get category => 'קטגוריה';

  @override
  String get unitsPerBox => 'יחידות בקופסה';

  @override
  String get weight => 'משקל (ק\"ג)';

  @override
  String get inactive => 'לא פעיל';

  @override
  String get showInactive => 'הצג לא פעילים';

  @override
  String get hideInactive => 'הסתר לא פעילים';

  @override
  String get importFromExcel => 'ייבוא מ-Excel';

  @override
  String get noProducts => 'אין מוצרים';

  @override
  String get addFirstProduct => 'הוסף מוצר ראשון';

  @override
  String get productAdded => 'המוצר נוסף בהצלחה';

  @override
  String get productUpdated => 'המוצר עודכן בהצלחה';

  @override
  String get productDeleted => 'המוצר נמחק';

  @override
  String deleteProductConfirm(Object productName) {
    return 'האם למחוק את $productName?';
  }

  @override
  String get allCategories => 'הכל';

  @override
  String get categoryGeneral => 'כללי';

  @override
  String get categoryCups => 'גביעים';

  @override
  String get categoryLids => 'מכסים';

  @override
  String get categoryContainers => 'מיכלים';

  @override
  String get categoryBread => 'לחם';

  @override
  String get categoryDairy => 'חלב';

  @override
  String get categoryShirts => 'חולצות';

  @override
  String get categoryTrays => 'מגשים';

  @override
  String get categoryBottles => 'בקבוקים';

  @override
  String get categoryBags => 'שקיות';

  @override
  String get categoryBoxes => 'קופסאות';

  @override
  String get terminology => 'טרמינולוגיה';

  @override
  String get businessType => 'סוג עסק';

  @override
  String get selectBusinessType => 'בחר סוג עסק';

  @override
  String get businessTypePackaging => 'אריזות ופלסטיק';

  @override
  String get businessTypeFood => 'מוצרי מזון';

  @override
  String get businessTypeClothing => 'ביגוד וטקסטיל';

  @override
  String get businessTypeConstruction => 'חומרי בניין';

  @override
  String get businessTypeCustom => 'מותאם אישית';

  @override
  String get unitName => 'שם יחידה (יחיד)';

  @override
  String get unitNamePlural => 'שם יחידה (רבים)';

  @override
  String get palletName => 'שם משטח (יחיד)';

  @override
  String get palletNamePlural => 'שם משטח (רבים)';

  @override
  String get usesPallets => 'משתמש במשטחים';

  @override
  String get capacityCalculation => 'חישוב תפוסה';

  @override
  String get capacityByUnits => 'לפי יחידות';

  @override
  String get capacityByWeight => 'לפי משקל';

  @override
  String get capacityByVolume => 'לפי נפח';

  @override
  String get terminologyUpdated => 'הטרמינולוגיה עודכנה';

  @override
  String get applyTemplate => 'החל תבנית';

  @override
  String get customTerminology => 'טרמינולוגיה מותאמת';

  @override
  String get invalidNumber => 'מספר לא תקין';

  @override
  String get noCompanySelected => 'לא נבחרה חברה';

  @override
  String get addNewProduct => 'הוסף מוצר חדש';

  @override
  String get terminologySettings => 'הגדרות טרמינולוגיה';

  @override
  String get selectTemplate => 'בחר תבנית';

  @override
  String get or => 'או';

  @override
  String get customSettings => 'הגדרות מותאמות';

  @override
  String get downloadTemplate => 'הורד תבנית';

  @override
  String importSuccess(Object count) {
    return 'יובאו $count מוצרים בהצלחה';
  }

  @override
  String get importError => 'שגיאה בייבוא';

  @override
  String get exportSuccess => 'הקובץ הורד בהצלחה';

  @override
  String get templateDownloaded => 'תבנית הורדה בהצלחה';

  @override
  String get billingAndLocks => 'חיוב ונעילות';

  @override
  String get billingPortal => 'פורטל חיוב';

  @override
  String get moduleManagement => 'ניהול מודולים';

  @override
  String get subscriptionManagement => 'ניהול מנוי';

  @override
  String get subscription => 'מנוי';

  @override
  String get currentPlan => 'תוכנית נוכחית';

  @override
  String get changePlan => 'שנה תוכנית';

  @override
  String get changePlanConfirm => 'לשנות תוכנית?';

  @override
  String get payNow => 'שלם עכשיו';

  @override
  String get contactSupport => 'צור קשר עם התמיכה';

  @override
  String get paymentHistory => 'היסטוריית תשלומים';

  @override
  String get noPaymentHistory => 'אין היסטוריית תשלומים';

  @override
  String get reports => 'דוחות';

  @override
  String get integrityCheck => 'בדיקת שלמות';

  @override
  String get documentType => 'סוג מסמך';

  @override
  String get checkRange => 'טווח בדיקה';

  @override
  String get backupManagement => 'ניהול גיבויים';

  @override
  String get backupHistory => 'היסטוריית גיבויים';

  @override
  String get noBackups => 'אין גיבויים';

  @override
  String get createBackup => 'צור גיבוי';

  @override
  String get backupLocation => 'מיקום גיבוי';

  @override
  String get backupCreated => 'גיבוי נוצר בהצלחה';

  @override
  String get restoreTest => 'בדיקת שחזור';

  @override
  String get restoreTestHistory => 'היסטוריית בדיקות שחזור';

  @override
  String get complianceReport => 'דוח עמידה';

  @override
  String get dataRetention => 'מדיניות שמירת נתונים';

  @override
  String get retentionCheck => 'בדיקת שמירה';

  @override
  String get retentionHistory => 'היסטוריית בדיקות';

  @override
  String get runCheck => 'הפעל בדיקה';

  @override
  String get compliant => 'תקין';

  @override
  String get notCompliant => 'לא תקין';

  @override
  String get totalDocuments => 'סה\"כ מסמכים';

  @override
  String get oldestDocument => 'מסמך ישן ביותר';

  @override
  String get sequentialGaps => 'פערים במספור';

  @override
  String get notifications => 'התראות';

  @override
  String get markAllRead => 'סמן הכל כנקרא';

  @override
  String get noNotifications => 'אין התראות';

  @override
  String get upgradePlan => 'שדרג תוכנית';

  @override
  String get accountSuspended => 'החשבון הושעה';

  @override
  String get accountGrace => 'תקופת חסד';

  @override
  String get trialEnding => 'תקופת ניסיון מסתיימת';

  @override
  String get savePlan => 'שמור';

  @override
  String get noAccount => 'אין לך חשבון? הירשם';

  @override
  String get cancelAction2 => 'ביטול';

  @override
  String get reportsTitle => 'דוחות';

  @override
  String get monthlyReport => 'דוח חודשי';

  @override
  String get vatReport => 'דוח מע״מ';

  @override
  String get clientReport => 'דוח לקוחות';

  @override
  String get errorLoadingData => 'שגיאה בטעינת נתונים';

  @override
  String get noDataToDisplay => 'אין נתונים להצגה';

  @override
  String get exportCsv => 'ייצוא CSV';

  @override
  String get monthColumn => 'חודש';

  @override
  String get documentsColumn => 'מסמכים';

  @override
  String get netAmount => 'נטו (₪)';

  @override
  String get vatAmount => 'מע״מ (₪)';

  @override
  String get grossAmount => 'ברוטו (₪)';

  @override
  String get csvCopiedToClipboard => 'CSV הועתק ללוח';

  @override
  String get totalVatForPeriod => 'סה״כ מע״מ לתקופה';

  @override
  String get taxBase => 'בסיס מס';

  @override
  String get taxBaseAmount => 'בסיס מס (₪)';

  @override
  String get vatRateColumn => 'שיעור מע״מ';

  @override
  String get customerColumn => 'לקוח';

  @override
  String get taxIdShort => 'ח.פ.';

  @override
  String get unknownCustomer => 'לא ידוע';

  @override
  String customersCount(int count) {
    return '$count לקוחות';
  }

  @override
  String get issuedDocuments => 'מסמכים שהונפקו';

  @override
  String draftsCount(int count) {
    return 'טיוטות: $count';
  }

  @override
  String get totalRevenueGross => 'סה״כ הכנסות (Gross)';

  @override
  String netLabel(String amount) {
    return 'נטו: ₪$amount';
  }

  @override
  String get vatPercent => 'מע״מ (18%)';

  @override
  String get forTaxAuthorities => 'לדיווח לרשויות';

  @override
  String get creditNotes => 'תעודות זיכוי';

  @override
  String get accountingDocuments => 'מסמכים חשבונאיים';

  @override
  String get createDocument => 'צור מסמך';

  @override
  String get allFilter => 'הכל';

  @override
  String get errorLoadingDocuments => 'שגיאה בטעינת מסמכים';

  @override
  String get noDocuments => 'אין מסמכים';

  @override
  String get columnType => 'סוג';

  @override
  String get columnNumber => 'מספר';

  @override
  String get columnCustomer => 'לקוח';

  @override
  String get columnAmount => 'סכום';

  @override
  String get columnStatus => 'סטטוס';

  @override
  String get columnDate => 'תאריך';

  @override
  String get columnActions => 'פעולות';

  @override
  String get draftStatus => 'טיוטה';

  @override
  String get issuedStatus => 'הונפק';

  @override
  String get lockedStatus => 'נעול';

  @override
  String get creditedStatus => 'זוכה';

  @override
  String get voidedStatus => 'בוטל';

  @override
  String get taxInvoice => 'חשבונית מס';

  @override
  String get receipt => 'קבלה';

  @override
  String get taxInvoiceReceipt => 'חשבונית מס/קבלה';

  @override
  String get creditNote => 'תעודת זיכוי';

  @override
  String get editTooltip => 'ערוך';

  @override
  String get issueTooltip => 'הנפק';

  @override
  String get cancelTooltip => 'בטל';

  @override
  String get createCreditNote => 'צור תעודת זיכוי';

  @override
  String get issueDocumentTitle => 'הנפקת מסמך';

  @override
  String issueDocumentConfirm(String name) {
    return 'האם להנפיק את המסמך \"$name\"?\n\nלאחר ההנפקה, שדות מפתח (מספר, תאריך, לקוח, שורות, סכומים) ייהפכו לבלתי ניתנים לעריכה.';
  }

  @override
  String get issueButton => 'הנפק';

  @override
  String get documentIssuedSuccess => 'המסמך הונפק בהצלחה';

  @override
  String errorIssuingDocument(String error) {
    return 'שגיאה בהנפקת מסמך: $error';
  }

  @override
  String get voidDocumentTitle => 'ביטול מסמך';

  @override
  String voidDocumentConfirm(String name) {
    return 'האם לבטל את המסמך \"$name\"?';
  }

  @override
  String get voidReasonLabel => 'סיבת ביטול *';

  @override
  String get voidReasonRequired => 'יש להזין סיבת ביטול';

  @override
  String get backButton => 'חזור';

  @override
  String get voidDocumentButton => 'בטל מסמך';

  @override
  String get documentVoidedSuccess => 'המסמך בוטל בהצלחה';

  @override
  String errorVoidingDocument(String error) {
    return 'שגיאה בביטול מסמך: $error';
  }

  @override
  String get immutableFieldsTooltip => 'שדות מפתח נעולים לעריכה';

  @override
  String get selectDocType => 'בחר סוג מסמך';

  @override
  String newDocumentTitle(String type) {
    return 'מסמך חדש — $type';
  }

  @override
  String get customerDetails => 'פרטי לקוח';

  @override
  String get customerNameRequired => 'שם לקוח *';

  @override
  String get taxIdLabel => 'ח.פ. / ע.מ.';

  @override
  String get documentLines => 'שורות מסמך';

  @override
  String get addLine => 'הוסף שורה';

  @override
  String descriptionN(int n) {
    return 'תיאור $n';
  }

  @override
  String get quantityShort => 'כמות';

  @override
  String get unitPriceLabel => 'מחיר יח׳';

  @override
  String get vatRateLabel => 'מע״מ';

  @override
  String get removeLine => 'הסר שורה';

  @override
  String get summaryTitle => 'סיכום';

  @override
  String get netBeforeVat => 'סה״כ לפני מע״מ (Net)';

  @override
  String get vatLabelCalc => 'מע״מ (VAT)';

  @override
  String get grossWithVat => 'סה״כ כולל מע״מ (Gross)';

  @override
  String get saveDraft => 'שמור טיוטה';

  @override
  String get notesLabel => 'הערות';

  @override
  String get invalidValue => 'לא תקין';

  @override
  String get documentCreatedSuccess => 'המסמך נוצר בהצלחה';

  @override
  String errorCreatingDoc(String error) {
    return 'שגיאה ביצירת מסמך: $error';
  }

  @override
  String get documentChainTitle => 'שרשרת מסמכים';

  @override
  String get errorLoadingChain => 'שגיאה בטעינת שרשרת מסמכים';

  @override
  String get noRelatedDocs => 'לא נמצאו מסמכים קשורים';

  @override
  String get originalDocBadge => 'מסמך מקורי';

  @override
  String get currentDocBadge => 'נוכחי';

  @override
  String get totalSummary => 'סה״כ';

  @override
  String get loadingAdvice => 'המלצת העמסה';

  @override
  String capacityLabel(Object count) {
    return 'קיבולת: $count משטחים';
  }

  @override
  String overCapacity(Object current, Object max) {
    return 'חריגה: $current/$max משטחים';
  }

  @override
  String canCombineAdjacent(Object names) {
    return '$names → 1 משטח משותף';
  }

  @override
  String canCombineDistant(Object names) {
    return '$names → ניתן לאחד, אבל הנהג יצטרך לסדר מחדש';
  }

  @override
  String savingPallets(Object count) {
    return 'חיסכון: $count';
  }

  @override
  String get hideGpsTracks => 'הסתר מסלולי GPS';

  @override
  String get showGpsTracks => 'הצג מסלולי GPS (24 שעות)';

  @override
  String get mapTooltipCurrentRoute => 'מסלול נוכחי';

  @override
  String get mapTooltipPreviousRoute => 'מסלול קודם';

  @override
  String get mapTooltipClearMap => 'נקה מפה';

  @override
  String get mapTooltipExitDemo => 'יציאה ממצב הדגמה';

  @override
  String get mapTooltipDemoMode => 'מצב הדגמה';

  @override
  String get mapBannerPreviousRouteShown => 'מוצג מסלול קודם';

  @override
  String get billingGuardAccessSuspendedTitle => 'הגישה הושעתה';

  @override
  String get billingGuardAccessSuspendedBody =>
      'החשבון שלך הושעה עקב אי תשלום. שלם כדי לחדש את הגישה.';

  @override
  String get billingGuardAccountCancelledTitle => 'החשבון בוטל';

  @override
  String get billingGuardAccountCancelledBody =>
      'החשבון שלך בוטל. אנא צור קשר עם התמיכה לחידוש.';

  @override
  String get billingGuardTrialEndedTitle => 'תקופת הניסיון הסתיימה';

  @override
  String get billingGuardTrialEndedBody =>
      'תקופת הניסיון שלך הסתיימה. שדרג לתוכנית בתשלום.';

  @override
  String get billingGuardNoAccessTitle => 'אין גישה';

  @override
  String get billingGuardNoAccessBody => 'אנא צור קשר עם התמיכה.';

  @override
  String get billingGuardContactSupport => 'צור קשר עם התמיכה';

  @override
  String get billingGuardPayNow => 'שלם עכשיו';

  @override
  String get billingGuardUpgrade => 'שדרג';

  @override
  String billingGuardTrialBanner(int days, String date) {
    return 'תקופת ניסיון — נותרו $days ימים (עד $date)';
  }

  @override
  String billingGuardGraceBanner(int days) {
    return 'תקופת חסד — נותרו $days ימים לתשלום. לאחר מכן החשבון יושעה.';
  }

  @override
  String get billingGuardCheckoutOpened =>
      'דף התשלום נפתח בדפדפן. לאחר התשלום החשבון יתעדכן אוטומטית.';

  @override
  String billingGuardCheckoutError(String error) {
    return 'שגיאה בפתיחת דף תשלום: $error';
  }

  @override
  String get companySettingsNotSelected => 'לא נבחרה חברה';

  @override
  String companySettingsInitError(String error) {
    return 'שגיאת אתחול: $error';
  }

  @override
  String get companySettingsEmptyWarning => 'לא נמצאו הגדרות. מלאו את הטופס.';

  @override
  String companySettingsLoadError(String error) {
    return 'שגיאת טעינה: $error';
  }

  @override
  String get billingDashboardTitle => 'לוח חיוב';

  @override
  String get billingDashboardFilterAll => 'הכל';

  @override
  String get billingDashboardFilterTrial => '🧪 ניסיון';

  @override
  String get billingDashboardFilterActive => '✅ פעיל';

  @override
  String get billingDashboardFilterGrace => '⏳ חסד';

  @override
  String get billingDashboardFilterSuspended => '🚫 מושעה';

  @override
  String get billingDashboardFilterCancelled => '❌ בוטל';

  @override
  String get billingDashboardSearchHint => 'חיפוש…';

  @override
  String get billingDashboardNoCompanies => 'לא נמצאו חברות';

  @override
  String billingDashboardExtendTitle(String companyName) {
    return 'הארכה — $companyName';
  }

  @override
  String billingDashboardExtendPaidUntil(String date) {
    return 'קבע תשלום עד: $date';
  }

  @override
  String get billingDashboardNoteLabel => 'הערה (חובה)';

  @override
  String get billingDashboardNoteDefault => 'הוארך דרך לוח הבקרה';

  @override
  String get billingDashboardExtendButton => 'הארך';

  @override
  String billingDashboardChangeStatusTitle(String companyName, String status) {
    return 'לשנות $companyName → $status?';
  }

  @override
  String get billingDashboardChangeStatusBody =>
      'השינוי יחול על סטטוס החיוב מיד.';

  @override
  String billingDashboardStatusUpdated(String companyName, String status) {
    return '$companyName → $status';
  }

  @override
  String get billingDashboardIntegrityRunning => 'מריץ בדיקת שלמות…';

  @override
  String get billingDashboardIntegrityDone => 'בדיקת שלמות הושלמה';

  @override
  String get billingDashboardRunIntegrityTooltip => 'הרץ בדיקת שלמות';

  @override
  String billingDashboardExtendSuccess(String companyName, String date) {
    return '$companyName הוארך עד $date';
  }

  @override
  String billingDashboardError(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get billingLabelProvider => 'ספק';

  @override
  String get billingLabelPaidUntil => 'שולם עד';

  @override
  String get billingLabelTrialUntil => 'ניסיון עד';

  @override
  String get billingLabelGraceUntil => 'חסד עד';

  @override
  String get billingLabelGraceDays => 'ימי חסד';

  @override
  String get billingActionExtend => 'הארך';

  @override
  String get billingActionActive => 'פעיל';

  @override
  String get billingActionGrace => 'חסד';

  @override
  String get billingActionSuspend => 'השעה';

  @override
  String dispatcherInvalidCoordinates(String error) {
    return 'קואורדינטות לא תקינות: $error';
  }

  @override
  String dispatcherPrintError(String error) {
    return 'שגיאת הדפסה: $error';
  }

  @override
  String dispatcherGenericError(String error) {
    return 'שגיאה: $error';
  }

  @override
  String dispatcherWarehouseSaved(String coords) {
    return 'מיקום המחסן נשמר: $coords';
  }

  @override
  String get dispatcherTourStep1 =>
      'נקודות משלוח: מוסיפים לקוח ומוצרים להזמנה — כאן נבנית ההזמנה לפני המסלול';

  @override
  String get dispatcherTourStep2 =>
      'בכל נקודה: מוצרים וכמויות; אפשר לערוך לפני בניית מסלול';

  @override
  String get dispatcherTourStep3 =>
      'כשהמוצרים מוכנים — עוברים ללשונית «מסלולים פעילים» ושיוך לנהג';

  @override
  String get dispatcherTourStep4 =>
      'מסלולים פעילים: השיוך לנהג, סדר עצירות ומסלול על המפה';

  @override
  String get dispatcherTourStep5 =>
      'אחרי בניית המסלול — המשימות מגיעות לנהג באפליקציה; עוברים למפה';

  @override
  String get dispatcherTourStopTooltip => 'עצור סיור הדגמה';

  @override
  String get dispatcherTourStartTooltip => 'סיור הדגמה: מוצר → מסלול → נהג';

  @override
  String dispatcherTourProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String dispatcherSkippedInvoicesMakor(int count) {
    return 'דולגו $count חשבוניות — מקור כבר הודפס. להדפסה חוזרת השתמשו בניהול חשבוניות.';
  }

  @override
  String get dispatcherCopiesOnlyPendingTax =>
      'הודפסו עותקים בלבד — ממתין למספר הקצאה. המקור יודפס לאחר אישור רשות המסים.';

  @override
  String pointUpdatedSuccess(String name) {
    return 'הנקודה עודכנה: $name';
  }

  @override
  String dispatcherPointReturnedToRoute(String name) {
    return '$name הוחזר למסלול';
  }

  @override
  String get dispatcherManualCompleteTitle => 'סמן כמסופק';

  @override
  String dispatcherManualCompleteMessage(String name) {
    return 'לסמן את \"$name\" כמסופק ידנית? אם הסגירה האוטומטית לא רצה.';
  }

  @override
  String get dispatcherManualCompleteTooltip => 'סגירה ידנית של נקודה';

  @override
  String dispatcherPointCompletedManually(String name) {
    return '$name סומן כמסופק';
  }

  @override
  String dispatcherPointAssignedToDriver(String client, String driver) {
    return 'הוקצה לנהג: $client → $driver';
  }

  @override
  String dispatcherAssignDriverTitle(String clientName) {
    return 'שיוך לנהג — $clientName';
  }

  @override
  String dispatcherDragAssignSuccess(String driverName) {
    return 'הוקצה לנהג → $driverName';
  }

  @override
  String autoDistributeFailed(String error) {
    return 'שגיאה בחלוקה אוטומטית: $error';
  }

  @override
  String companySettingsSaveFailed(String error) {
    return 'שגיאה בשמירת הגדרות: $error';
  }

  @override
  String get makorOriginalPrintedTitle => 'מקור כבר הודפס';

  @override
  String get makorDocTypeDeliveryNote => 'תעודת משלוח';

  @override
  String get makorDocTypeTaxInvoiceReceipt => 'חשבונית מס / קבלה';

  @override
  String get makorDocTypeTaxInvoice => 'חשבונית מס';

  @override
  String makorInvoiceLineNumbered(String docType, String seq) {
    return '$docType מס\' $seq';
  }

  @override
  String makorClientLine(String name) {
    return 'לקוח: $name';
  }

  @override
  String get makorBooksLawWarning =>
      'לפי חוק ניהול ספרים — לא ניתן להדפיס מקור נוסף.\nניתן להדפיס העתק או נאמן למקור בלבד.';

  @override
  String get makorChoosePrintType => 'בחר סוג הדפסה:';

  @override
  String get makorCopy => 'העתק';

  @override
  String makorCopySubtitle(int n) {
    return 'עותק מספר $n';
  }

  @override
  String get makorTrueToOriginal => 'נאמן למקור';

  @override
  String get makorTrueToOriginalSubtitle => 'מחליף את המקור';

  @override
  String get makorCopyQuantity => 'כמות עותקים:';

  @override
  String get makorPrintButton => 'הדפס';

  @override
  String get vatId => 'ח.פ / ע.מ (מספר עוסק)';

  @override
  String get deliveryZones => 'אזורי חלוקה';

  @override
  String get zonesRequired => 'חובה לבחור לפחות אזור אחד';

  @override
  String get manualCoordinates => 'הכנס קואורדינטות ידנית';

  @override
  String get manualCoordinatesSubtitle => 'השתמש אם הגיאוקודינג לא עובד';

  @override
  String get latitude => 'קו רוחב (Latitude)';

  @override
  String get longitude => 'קו אורך (Longitude)';

  @override
  String get latitudeExample => 'לדוגמה: 31.9539907';

  @override
  String get longitudeExample => 'לדוגמה: 34.8062546';

  @override
  String get enterManualCoordinates => 'הכנס קואורדינטות ידנית';

  @override
  String get balanceRoutes => 'איזון מסלולים';

  @override
  String get balanceRoutesConfirm =>
      'לאזן את המסלולים? המערכת תעביר נקודות ממסלולים עמוסים למסלולים קלים.';

  @override
  String get routesBalanced => 'המסלולים אוזנו בהצלחה';

  @override
  String get routesAlreadyBalanced => 'המסלולים כבר מאוזנים';

  @override
  String get balancingRoutes => 'מאזן מסלולים...';

  @override
  String movedPoints(Object count) {
    return '$count נקודות הועברו בין מסלולים';
  }

  @override
  String get navigationOpenError => 'שגיאה בפתיחת ניווט';

  @override
  String get driverFallbackName => 'נהג';

  @override
  String get driverActive => 'פעיל';

  @override
  String get printAllInvoicesTooltip => 'הדפס כל החשבוניות';

  @override
  String get pickingListTooltip => 'תעודת ליקוט';

  @override
  String get createInvoiceTooltip => 'צור חשבונית';

  @override
  String get createDeliveryNoteTooltip => 'צור תעודת משלוח';

  @override
  String autoCompletedPointsTitle(Object count) {
    return 'נקודות שנסגרו אוטומטית ($count)';
  }

  @override
  String get skipClientTitle => 'דלג על לקוח?';

  @override
  String skipClientContent(Object clientName) {
    return 'דלג על $clientName והמשך?';
  }

  @override
  String get stopAllButton => 'עצור הכל';

  @override
  String get skipAndContinueButton => 'דלג והמשך';

  @override
  String invoicesPrintedSuccess(Object count) {
    return '✅ $count חשבוניות הודפסו';
  }

  @override
  String printingErrorMessage(Object error) {
    return '❌ שגיאה בהדפסה: $error';
  }

  @override
  String get finishCountButton => 'סיים ספירה';

  @override
  String uncheckedItemsWarning(Object count) {
    return 'יש עדיין $count פריטים שלא נספרו.\nהאם לסיים בכל זאת?';
  }

  @override
  String get searchByCodeTypeNumberHint => 'חיפוש לפי מק\"ט / סוג / מספר';

  @override
  String get noResultsFoundLabel => 'לא נמצאו תוצאות';

  @override
  String get noDifferencesLabel => 'אין הפרשים';

  @override
  String get noItemsLabel => 'אין פריטים';

  @override
  String get totalItemsLabel => 'סה\"כ פריטים';

  @override
  String get countedLabel => 'נספרו';

  @override
  String get differencesLabel => 'הפרשים';

  @override
  String get shortageLabel => 'חסר';

  @override
  String get surplusLabel => 'עודף';

  @override
  String get countStartedLabel => 'התחיל';

  @override
  String get countFinishedLabel => 'הסתיים';

  @override
  String errorLoadingCountMessage(Object error) {
    return 'שגיאה בטעינת ספירה: $error';
  }

  @override
  String errorStartingCountMessage(Object error) {
    return 'שגיאה בהתחלת ספירה: $error';
  }

  @override
  String errorCompletingCountMessage(Object error) {
    return 'שגיאה בסיום ספירה: $error';
  }

  @override
  String get reopenPoint => 'החזר';

  @override
  String get deductionForOrderReason => 'ניכוי מלאי ליצירת הזמנה';

  @override
  String get inventoryActionAdd => 'הוספה';

  @override
  String get inventoryActionDeduct => 'הוצאה';

  @override
  String get inventoryActionUpdate => 'עדכון';

  @override
  String get priceManagement => 'ניהול מחירים';

  @override
  String updatePriceTitle(String type, String number) {
    return 'עדכן מחיר - $type $number';
  }

  @override
  String get priceBeforeVatLabel => 'מחיר לפני מע\"מ (₪)';

  @override
  String get priceBeforeVatHint => 'המחיר הוא לפני מע\"מ (18%)';

  @override
  String get enterValidPrice => 'נא להזין מחיר תקין';

  @override
  String get priceUpdatedSuccess => 'המחיר עודכן בהצלחה';

  @override
  String priceUpdateError(String error) {
    return 'שגיאה בעדכון מחיר: $error';
  }

  @override
  String get searchBySkuTypeNumber => 'חיפוש לפי מק\"ט, סוג או מספר';

  @override
  String get noResultsFound => 'לא נמצאו תוצאות';

  @override
  String skuLabel(String code) {
    return 'מק\"ט: $code';
  }

  @override
  String priceDisplay(String price) {
    return 'מחיר: ₪$price (לפני מע\"מ)';
  }

  @override
  String get noPriceSet => 'לא הוגדר מחיר';

  @override
  String volumeMlDisplay(int volume) {
    return '$volume מל';
  }

  @override
  String get integrityCheckTitle => 'בדיקת שלמות שרשרת';

  @override
  String get documentTypeLabel => 'סוג מסמך:';

  @override
  String get checkRangeLabel => 'טווח בדיקה:';

  @override
  String lastNItems(int count) {
    return 'אחרונים $count';
  }

  @override
  String get checking => 'בודק...';

  @override
  String get checkIntegrity => 'בדוק שלמות';

  @override
  String get noDocumentsOfType => 'אין מסמכים מסוג זה';

  @override
  String rangeLabel(int from, int to) {
    return 'טווח: $from..$to';
  }

  @override
  String checkedCount(int count) {
    return 'נבדקו: $count';
  }

  @override
  String lastHashLabel(String hash) {
    return 'Hash אחרון: $hash...';
  }

  @override
  String breakAtDocument(int number) {
    return 'שבירה במסמך: #$number';
  }

  @override
  String reasonLabel(String reason) {
    return 'סיבה: $reason';
  }

  @override
  String get counterInvoices => 'חשבוניות מס';

  @override
  String get counterReceipts => 'קבלות';

  @override
  String get counterCreditNotes => 'זיכויים';

  @override
  String get counterDeliveryNotes => 'תעודות משלוח';

  @override
  String get counterTaxInvoiceReceipts => 'חשבוניות מס/קבלה';

  @override
  String get creditNoteReasonRequired => 'חובה לציין סיבה לזיכוי';

  @override
  String get creditNoteOnlyForIssued => 'ניתן ליצור זיכוי רק למסמך שהונפק';

  @override
  String get creditNoteNotForCreditNote => 'לא ניתן ליצור זיכוי לזיכוי';

  @override
  String get reasonRequired => 'חובה לציין סיבה';

  @override
  String get creditNoteCreateTitle => 'יצירת זיכוי';

  @override
  String originalInvoiceLabel(int number) {
    return 'חשבונית מקור #$number';
  }

  @override
  String clientLabel(String name) {
    return 'לקוח: $name';
  }

  @override
  String amountLabel(String amount) {
    return 'סכום: ₪$amount';
  }

  @override
  String get creditNoteDescription =>
      'הזיכוי ייצור מסמך חדש עם סכומים שליליים.\nהמסמך המקורי לא ישתנה.';

  @override
  String get creditNoteReasonLabel => 'סיבת הזיכוי *';

  @override
  String get creditNoteReasonHint => 'לדוגמה: טעות בכמות';

  @override
  String get createCreditNoteButton => 'צור זיכוי';

  @override
  String creditNoteCreateError(String error) {
    return 'שגיאה ביצירת זיכוי: $error';
  }

  @override
  String get creditNoteIssuanceError => 'שגיאה בהנפקת זיכוי מהשרת';

  @override
  String periodLockedError(String docDate, String lockDate) {
    return 'לא ניתן ליצור זיכוי — תאריך המסמך ($docDate) נמצא בתקופה חשבונאית סגורה (עד $lockDate)';
  }

  @override
  String get allNotificationsMarkedRead => 'כל ההתראות סומנו כנקראו';

  @override
  String get timeAgoNow => 'עכשיו';

  @override
  String timeAgoMinutes(int minutes) {
    return 'לפני $minutes דק׳';
  }

  @override
  String timeAgoHours(int hours) {
    return 'לפני $hours שע׳';
  }

  @override
  String timeAgoDays(int days) {
    return 'לפני $days ימים';
  }

  @override
  String get resourceUsage => 'שימוש במשאבים';

  @override
  String get noUsageData => 'אין נתוני שימוש';

  @override
  String get usageLoadError => 'שגיאה בטעינת נתוני שימוש';

  @override
  String get usersUsage => 'משתמשים';

  @override
  String get docsPerMonth => 'מסמכים/חודש';

  @override
  String get routesPerDay => 'מסלולים/יום';

  @override
  String get paidUntil => 'שולם עד';

  @override
  String daysRemaining(int days) {
    return 'נותרו $days ימים';
  }

  @override
  String get expired => 'פג תוקף';

  @override
  String get paymentProvider => 'ספק תשלום';

  @override
  String get gracePeriodBanner =>
      'החברה בתקופת חסד. יש לשלם כדי להמשיך את השירות.';

  @override
  String get paymentPageOpened => 'דף התשלום נפתח';

  @override
  String get cannotOpenPayment => 'לא ניתן לפתוח את דף התשלום';

  @override
  String get selectFormat => 'בחר פורמט';

  @override
  String get downloadReceipt => 'הורד קבלה';

  @override
  String get receiptCopied => 'הקבלה הועתקה';

  @override
  String get receiptExportError => 'שגיאה בייצוא הקבלה';

  @override
  String get companyLoadError => 'שגיאה בטעינת נתוני חברה';

  @override
  String get periodLabel => 'תקופה:';

  @override
  String get toLabel => 'עד';

  @override
  String get deliveriesTab => 'משלוחים';

  @override
  String get invoicesTab => 'חשבוניות';

  @override
  String get driversTab => 'נהגים';

  @override
  String get totalPointsReport => 'סה\"כ נקודות';

  @override
  String get completedReport => 'הושלמו';

  @override
  String get pendingReport => 'ממתינות';

  @override
  String get onTheWay => 'בדרך';

  @override
  String get cancelledReport => 'בוטלו';

  @override
  String get totalPalletsReport => 'סה\"כ משטחים';

  @override
  String get palletsDelivered => 'משטחים שנמסרו';

  @override
  String get completionPercent => 'אחוז השלמה';

  @override
  String get totalDocumentsReport => 'סה\"כ מסמכים';

  @override
  String get taxInvoicesReport => 'חשבוניות מס';

  @override
  String get taxInvoiceReceiptsReport => 'חשבוניות מס/קבלה';

  @override
  String get receiptsReport => 'קבלות';

  @override
  String get deliveryNotesReport => 'תעודות משלוח';

  @override
  String get creditNotesReport => 'זיכויים';

  @override
  String get netBeforeVatReport => 'סה\"כ לפני מע\"מ';

  @override
  String get vatAmountReport => 'מע\"מ';

  @override
  String get grossWithVatReport => 'סה\"כ כולל מע\"מ';

  @override
  String get noDataForPeriod => 'אין נתונים לתקופה';

  @override
  String get pointsLabel => 'נקודות';

  @override
  String get completedLabel => 'הושלמו';

  @override
  String get cancelledLabel => 'בוטלו';

  @override
  String get palletsLabel => 'משטחים';

  @override
  String get completionLabel => 'השלמה';

  @override
  String get noDriverAssigned => 'ללא נהג';

  @override
  String get select => 'בחר';

  @override
  String get overviewSection => 'סקירה כללית';

  @override
  String get usersAndRoles => 'משתמשים ותפקידים';

  @override
  String get billingSection => 'חיוב';

  @override
  String get auditAndCompliance => 'ביקורת ותאימות';

  @override
  String get operationsSection => 'תפעול';

  @override
  String get accountingSection => 'הנהלת חשבונות';

  @override
  String get userMenu => 'תפריט משתמש';

  @override
  String get menuLabel => 'תפריט';

  @override
  String get companyDataNotFound => 'לא נמצאו נתוני חברה';

  @override
  String get noSectionsAvailable => 'אין חלקים זמינים';

  @override
  String unknownRoleError(String role) {
    return 'תפקיד לא ידוע: $role';
  }

  @override
  String get pleaseSelectCompany => 'אנא בחר חברה כדי להמשיך.';

  @override
  String get moduleFilter => 'מודול';

  @override
  String get eventTypeFilter => 'סוג אירוע';

  @override
  String get userFilter => 'משתמש';

  @override
  String get dateRange => 'טווח תאריכים';

  @override
  String get clearDateRange => 'נקה טווח תאריכים';

  @override
  String get exporting => 'מייצא...';

  @override
  String auditExportError(String error) {
    return 'שגיאה בייצוא: $error';
  }

  @override
  String get auditLogLoadError => 'שגיאה בטעינת יומן ביקורת';

  @override
  String get noAuditRecords => 'אין רשומות ביומן הביקורת';

  @override
  String auditHistory(String title) {
    return 'היסטוריה: $title';
  }

  @override
  String get historyLoadError => 'שגיאה בטעינת היסטוריה';

  @override
  String get noEventsYet => 'אין אירועים עדיין';

  @override
  String get moduleLogistics => 'לוגיסטיקה';

  @override
  String get moduleWarehouse => 'מחסן';

  @override
  String get moduleAccounting => 'הנהלת חשבונות';

  @override
  String get moduleDispatcher => 'דיספצ\'ר';

  @override
  String get eventReceiptCreated => 'קבלה הופקה';

  @override
  String get eventCreditNoteCreated => 'הודעת זיכוי הופקה';

  @override
  String get eventDocumentVoided => 'מסמך בוטל לפני מסירה';

  @override
  String get eventInvoiceVoided => 'חשבונית בוטלה';

  @override
  String get eventBillingStatusChanged => 'סטטוס חיוב שונה';

  @override
  String get eventTrialUntilChanged => 'תקופת ניסיון עודכנה';

  @override
  String get eventAccountingLockedUntilChanged => 'נעילת הנהלת חשבונות עודכנה';

  @override
  String get eventInvoiceIssued => 'חשבונית הופקה';

  @override
  String get eventInvoicePrinted => 'חשבונית הודפסה';

  @override
  String get eventInventoryAdjusted => 'מלאי עודכן';

  @override
  String get eventInventoryCountCompleted => 'ספירת מלאי הושלמה';

  @override
  String get eventInventoryCountApproved => 'ספירת מלאי אושרה';

  @override
  String get eventRoutePublished => 'מסלול פורסם';

  @override
  String get eventDeliveryPointStatusChanged => 'סטטוס נקודת מסירה שונה';

  @override
  String get eventManualAssignment => 'שיוך ידני';

  @override
  String get eventPaymentReceived => 'תשלום התקבל';

  @override
  String get eventModuleChanged => 'מודול שונה';

  @override
  String get eventPlanChanged => 'תוכנית שונה';

  @override
  String get eventBackupRecorded => 'גיבוי נרשם';

  @override
  String get eventRetentionChecked => 'שמירת נתונים נבדקה';

  @override
  String get deliveriesToday => 'משלוחים היום';

  @override
  String get invoicesThisMonth => 'חשבוניות החודש';

  @override
  String get warehouseMovements => 'תנועות מחסן';

  @override
  String get activeDriversKpi => 'נהגים פעילים';

  @override
  String get docsThisMonth => 'מסמכים החודש';

  @override
  String printErrorsToday(int count) {
    return 'שגיאות הדפסה היום: $count';
  }

  @override
  String get accountSuspendedPayment => 'החשבון מושעה — נדרש תשלום';

  @override
  String get paymentOverdueGrace => 'תשלום באיחור — תקופת חסד';

  @override
  String get recentEventsTitle => 'אירועים אחרונים';

  @override
  String get errorLoadingEvents => 'שגיאה בטעינת אירועים';

  @override
  String get noRecentEvents => 'אין אירועים אחרונים';

  @override
  String get teamMembers => 'חברי צוות';

  @override
  String get errorLoadingUsers => 'שגיאה בטעינת משתמשים';

  @override
  String get noTeamMembers => 'אין חברי צוות';

  @override
  String get roleUpdatedSuccess => 'התפקיד עודכן בהצלחה';

  @override
  String errorUpdatingRole(Object error) {
    return 'שגיאה בעדכון תפקיד: $error';
  }

  @override
  String get removeUserTitle => 'הסרת משתמש';

  @override
  String removeUserConfirm(String name) {
    return 'האם להסיר את $name?';
  }

  @override
  String get userRemovedSuccess => 'המשתמש הוסר בהצלחה';

  @override
  String errorRemovingUser(Object error) {
    return 'שגיאה בהסרת משתמש: $error';
  }

  @override
  String get roleSuperAdmin => 'סופר אדמין';

  @override
  String get roleDriverLabel => 'נהג';

  @override
  String get roleViewer => 'צופה';

  @override
  String get statusInvited => 'הוזמן';

  @override
  String get statusSuspended => 'מושעה';

  @override
  String usersLimitReached(int active, int limit) {
    return 'הגעת למגבלת המשתמשים ($active / $limit)';
  }

  @override
  String get usersLimitUpgrade =>
      'לא ניתן להזמין משתמשים נוספים. שדרג את התוכנית להגדלת המגבלה.';

  @override
  String get changeRole => 'שנה תפקיד';

  @override
  String get removeUser => 'הסר משתמש';

  @override
  String get retryAttempts => 'ניסיונות חוזרים';

  @override
  String get totalEventsKpi => 'סה\"כ אירועים';

  @override
  String get successRate => 'אחוז הצלחה';

  @override
  String get printEvents => 'אירועי הדפסה';

  @override
  String get systemEvents => 'אירועי מערכת';

  @override
  String get filterAll => 'הכל';

  @override
  String get filterSuccess => 'הצלחה';

  @override
  String get filterError => 'שגיאה';

  @override
  String get filterFailed => 'נכשל';

  @override
  String get errorLoadingPrintEvents => 'שגיאה בטעינת אירועי הדפסה';

  @override
  String get noPrintEvents => 'אין אירועי הדפסה';

  @override
  String get errorLoadingSystemEvents => 'שגיאה בטעינת אירועי מערכת';

  @override
  String get noSystemEvents => 'אין אירועי מערכת';

  @override
  String invoiceLabel(String id) {
    return 'חשבונית: $id';
  }

  @override
  String printerUserLabel(String printer, String user) {
    return 'מדפסת: $printer · משתמש: $user';
  }

  @override
  String retryCountLabel(int count) {
    return ' · ניסיונות: $count';
  }

  @override
  String get tryAgain => 'נסה שוב';

  @override
  String get billingErrorLoading => 'שגיאה בטעינת נתוני חיוב';

  @override
  String get billingAccountSuspended => 'החשבון מושעה';

  @override
  String get billingAccountCancelled => 'החשבון בוטל';

  @override
  String get billingPaymentRequired => 'נדרש תשלום כדי לשחזר את הגישה לחשבון.';

  @override
  String get billingContactSupport =>
      'צור קשר עם התמיכה כדי להפעיל מחדש את החשבון.';

  @override
  String billingGraceDefault(int days) {
    return 'תשלום באיחור — תקופת חסד ($days ימים).';
  }

  @override
  String billingGraceRemaining(int remaining) {
    return 'תשלום באיחור — נותרו $remaining ימים בתקופת חסד.';
  }

  @override
  String billingTrialRemaining(int remaining) {
    return 'תקופת ניסיון — נותרו $remaining ימים';
  }

  @override
  String get billingPlanDetails => 'פרטי תוכנית';

  @override
  String get billingPlan => 'תוכנית';

  @override
  String get billingStatusLabel => 'סטטוס';

  @override
  String get billingTrialEnds => 'סיום ניסיון';

  @override
  String get billingPaidUntil => 'שולם עד';

  @override
  String get billingModules => 'מודולים';

  @override
  String get billingIncludedInPlan => 'כלולים בתוכנית';

  @override
  String get billingAddons => 'תוספות (addon)';

  @override
  String get billingNoModules => 'אין מודולים זמינים';

  @override
  String get billingUsage => 'שימוש';

  @override
  String get billingDocsPerMonth => 'מסמכים / חודש';

  @override
  String get billingUsers => 'משתמשים';

  @override
  String get billingRoutesPerDay => 'מסלולים / יום';

  @override
  String billingLimit(int limit) {
    return 'לימיט: $limit';
  }

  @override
  String get billingSensitiveFields => 'שדות רגישים (super admin בלבד)';

  @override
  String get billingInvoices => 'חשבוניות';

  @override
  String get billingErrorLoadingInvoices => 'שגיאה בטעינת חשבוניות';

  @override
  String get billingNoInvoices => 'אין חשבוניות';

  @override
  String get billingInvoiceDefault => 'חשבונית';

  @override
  String get billingPlanWarehouse => 'מחסן בלבד';

  @override
  String get billingPlanOps => 'תפעול';

  @override
  String get billingPlanFull => 'מלא';

  @override
  String get billingPlanCustom => 'מותאם אישית';

  @override
  String get billingStatusActive => 'פעיל';

  @override
  String get billingStatusTrial => 'ניסיון';

  @override
  String get billingStatusGrace => 'תקופת חסד';

  @override
  String get billingStatusSuspended => 'מושעה';

  @override
  String get billingStatusCancelled => 'בוטל';

  @override
  String get billingModuleWarehouse => 'מחסן';

  @override
  String get billingModuleLogistics => 'לוגיסטיקה';

  @override
  String get billingModuleDispatcher => 'שליחויות';

  @override
  String get billingModuleAccounting => 'הנהלת חשבונות';

  @override
  String get billingModuleReports => 'דוחות';

  @override
  String get billingInvoicePaid => 'שולם';

  @override
  String get billingInvoicePending => 'ממתין';

  @override
  String get billingInvoiceOverdue => 'באיחור';

  @override
  String get billingInvoiceCancelled => 'בוטל';

  @override
  String get settingsCompanyProfile => 'פרופיל חברה';

  @override
  String get settingsTab => 'הגדרות';

  @override
  String get settingsCompanyName => 'שם החברה';

  @override
  String get settingsNameHebrew => 'שם בעברית *';

  @override
  String get settingsNameEnglish => 'שם באנגלית';

  @override
  String get settingsTaxId => 'ח.פ. *';

  @override
  String get settingsAddress => 'כתובת';

  @override
  String get settingsAddressHebrew => 'כתובת בעברית';

  @override
  String get settingsAddressEnglish => 'כתובת באנגלית';

  @override
  String get settingsCity => 'עיר';

  @override
  String get settingsZipCode => 'מיקוד';

  @override
  String get settingsPoBox => 'ת.ד.';

  @override
  String get settingsContactDetails => 'פרטי קשר';

  @override
  String get settingsPhone => 'טלפון';

  @override
  String get settingsFax => 'פקס';

  @override
  String get settingsEmail => 'דוא\"ל';

  @override
  String get settingsWebsite => 'אתר אינטרנט';

  @override
  String get settingsReadOnly => 'קריאה בלבד';

  @override
  String get settingsSaving => 'שומר...';

  @override
  String get settingsSaveProfile => 'שמור פרופיל';

  @override
  String get settingsSaveSettings => 'שמור הגדרות';

  @override
  String get settingsProfileSaved => 'הפרופיל נשמר בהצלחה';

  @override
  String settingsProfileError(String error) {
    return 'שגיאה בשמירת הפרופיל: $error';
  }

  @override
  String get settingsSettingsSaved => 'ההגדרות נשמרו בהצלחה';

  @override
  String settingsSettingsError(String error) {
    return 'שגיאה בשמירת ההגדרות: $error';
  }

  @override
  String get settingsSystemSettings => 'הגדרות מערכת';

  @override
  String get settingsTaxSettings => 'הגדרות מס';

  @override
  String get settingsTaxIdBn => 'ח.פ / ע.מ';

  @override
  String get settingsVatRate => 'שיעור מע\"מ';

  @override
  String get settingsTaxManagedByAdmin => 'הגדרות מס מנוהלות ע\"י מנהל המערכת';

  @override
  String get settingsInvoiceSettings => 'הגדרות חשבונית';

  @override
  String get settingsInvoiceFooter => 'טקסט תחתית חשבונית';

  @override
  String get settingsPaymentTerms => 'תנאי תשלום';

  @override
  String get settingsBankDetails => 'פרטי בנק';

  @override
  String get settingsDocNumbering => 'מספור מסמכים';

  @override
  String get settingsTaxInvoice => 'חשבונית מס';

  @override
  String get settingsReceipt => 'קבלה';

  @override
  String get settingsDeliveryNote => 'תעודת משלוח';

  @override
  String get settingsCreditNote => 'חשבונית זיכוי';

  @override
  String get settingsAutoNumbering => 'מספור רציף אוטומטי';

  @override
  String get settingsNumberingManagedBySystem =>
      'מספור מסמכים מנוהל אוטומטית ע\"י המערכת';

  @override
  String get settingsPrintTemplates => 'תבניות הדפסה';

  @override
  String get settingsDefaultTemplate => 'תבנית ברירת מחדל';

  @override
  String get settingsTemplatesAdminOnly =>
      'ניהול תבניות הדפסה זמין למנהלים בלבד';

  @override
  String get settingsIntegrations => 'אינטגרציות';

  @override
  String get settingsPrinting => 'הדפסה';

  @override
  String get settingsEmailIntegration => 'דוא\"ל';

  @override
  String get settingsApiKeys => 'מפתחות API';

  @override
  String get settingsConfigured => 'מוגדר';

  @override
  String get settingsNotConfigured => 'לא מוגדר';

  @override
  String get settingsIntegrationsAdminOnly =>
      'ניהול אינטגרציות זמין למנהלים בלבד';

  @override
  String get settingsEditTooltip => 'ערוך';

  @override
  String get integrationPrinterIp => 'כתובת IP של מדפסת';

  @override
  String get integrationPrinterPort => 'פורט';

  @override
  String get integrationPrinterModel => 'דגם מדפסת';

  @override
  String get integrationPrinterPaperSize => 'גודל נייר';

  @override
  String get integrationSmtpHost => 'שרת SMTP';

  @override
  String get integrationSmtpPort => 'פורט';

  @override
  String get integrationSmtpUser => 'שם משתמש';

  @override
  String get integrationSmtpPassword => 'סיסמה';

  @override
  String get integrationSmtpFrom => 'כתובת שולח';

  @override
  String get integrationSmtpSsl => 'שימוש ב-SSL';

  @override
  String get integrationWhatsappApiUrl => 'כתובת API';

  @override
  String get integrationWhatsappApiKey => 'מפתח API';

  @override
  String get integrationWhatsappPhoneId => 'מזהה מספר טלפון';

  @override
  String get integrationApiKeyGenerate => 'צור מפתח חדש';

  @override
  String get integrationApiKeyValue => 'מפתח API';

  @override
  String get integrationApiKeyCopied => 'מפתח API הועתק ללוח';

  @override
  String get integrationSaved => 'הגדרות אינטגרציה נשמרו';

  @override
  String integrationSaveError(Object error) {
    return 'שגיאה בשמירת הגדרות: $error';
  }

  @override
  String get integrationTestConnection => 'בדוק חיבור';

  @override
  String get integrationTestSuccess => 'החיבור הצליח';

  @override
  String integrationTestFailed(Object error) {
    return 'החיבור נכשל: $error';
  }

  @override
  String integrationDialogTitle(Object name) {
    return 'הגדרת $name';
  }

  @override
  String get integrationEnabled => 'מופעל';

  @override
  String get subscriptionTitle => 'מנוי';

  @override
  String get noCompanySelectedSub => 'לא נבחרה חברה';

  @override
  String get subscriptionManagementTitle => 'ניהול מנוי';

  @override
  String get changePlanTitle => 'שנה תוכנית';

  @override
  String get paymentHistoryTitle => 'היסטוריית תשלומים';

  @override
  String get currentPlanLabel => 'התוכנית הנוכחית';

  @override
  String get planWarehouseOnly => 'מחסן בלבד';

  @override
  String get planOps => 'תפעול';

  @override
  String get planFull => 'מלא';

  @override
  String get planCustom => 'מותאם אישית';

  @override
  String get planDescWarehouse => 'ניהול מלאי בלבד';

  @override
  String get planDescOps => 'מחסן + לוגיסטיקה + דוחות';

  @override
  String get planDescFull => 'כל המודולים כולל הנהלת חשבונות';

  @override
  String get planDescCustom => 'תוכנית מותאמת';

  @override
  String promoMonthlyPrice(int price, int months) {
    return '₪$price/חודש ($months חודשים ראשונים)';
  }

  @override
  String thenMonthlyPrice(int price) {
    return 'לאחר מכן ₪$price/חודש';
  }

  @override
  String setupAndIntegration(int fee) {
    return 'התקנה ואינטגרציה: ₪$fee';
  }

  @override
  String setupAndIntegrationStr(String fee) {
    return 'התקנה ואינטגרציה: $fee';
  }

  @override
  String minimumMonths(int months) {
    return 'מינימום $months חודשים';
  }

  @override
  String paidUntilDate(String date) {
    return 'שולם עד: $date';
  }

  @override
  String paymentProviderLabel(String provider) {
    return 'ספק תשלום: $provider';
  }

  @override
  String errorPrefix(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get payNowButton => 'שלם עכשיו';

  @override
  String get currentChip => 'נוכחי';

  @override
  String monthlyPriceShort(int price) {
    return '₪$price/חודש';
  }

  @override
  String afterPromoPrice(int months, int price) {
    return 'לאחר $months חודשים: ₪$price';
  }

  @override
  String changePlanConfirmTitle(String name) {
    return 'שנה ל$name?';
  }

  @override
  String changePlanConfirmBody(String name, int promoPrice, int promoMonths,
      int price, int setupFee, int minMonths) {
    return 'התוכנית תשתנה ל$name.\n₪$promoPrice/חודש ($promoMonths חודשים ראשונים), לאחר מכן ₪$price/חודש.\nהתקנה: ₪$setupFee. מינימום $minMonths חודשים.\nהשינוי ייכנס לתוקף מיד.';
  }

  @override
  String get cancelButton => 'ביטול';

  @override
  String get changePlanButton => 'שנה תוכנית';

  @override
  String planChangedSuccess(String name) {
    return 'התוכנית שונתה ל$name';
  }

  @override
  String get noPaymentHistorySub => 'אין היסטוריית תשלומים';

  @override
  String get paymentReceived => 'תשלום התקבל';

  @override
  String get subscriptionCancelled => 'מנוי בוטל';

  @override
  String providerPrefix(String provider) {
    return 'ספק: $provider';
  }

  @override
  String get moduleNotAvailable => 'מודול זה אינו זמין בתוכנית הנוכחית שלך';

  @override
  String get upgradePlanButton => 'שדרג תוכנית';

  @override
  String get moduleWarehouseTitle => 'מחסן — Warehouse';

  @override
  String get moduleLogisticsTitle => 'לוגיסטיקה — Logistics';

  @override
  String get moduleDispatcherTitle => 'דיספצ\'ר — Dispatcher';

  @override
  String get moduleAccountingTitle => 'הנהלת חשבונות — Accounting';

  @override
  String get moduleReportsTitle => 'דוחות — Reports';

  @override
  String priceArrow(String promoPrice, int promoMonths, String price) {
    return '$promoPrice/חודש ($promoMonths חודשים ראשונים) → $price/חודש';
  }

  @override
  String get importInventoryTitle => 'ייבוא מלאי';

  @override
  String get importClientsTitle => 'ייבוא לקוחות';

  @override
  String importPreviewTotal(int total, int valid, int errors) {
    return 'סה\"כ: $total | תקינות: $valid | שגיאות: $errors';
  }

  @override
  String get importPreviewStatus => 'סטטוס';

  @override
  String importRowsButton(int count) {
    return 'ייבא $count שורות';
  }

  @override
  String importResultMessage(int added, int errors) {
    return 'נוספו $added | שגיאות $errors';
  }

  @override
  String importClientResultMessage(int added, int skipped, int errors) {
    return 'נוספו $added | דולגו $skipped | שגיאות $errors';
  }

  @override
  String importRowError(int row, String error) {
    return 'שורה $row: $error';
  }

  @override
  String get colProductCode => 'מק\"ט';

  @override
  String get colType => 'סוג';

  @override
  String get colNumber => 'מספר';

  @override
  String get colQuantity => 'כמות';

  @override
  String get colQuantityPerPallet => 'כמות במשטח';

  @override
  String get colClientNumber => 'מספר';

  @override
  String get colName => 'שם';

  @override
  String get colAddress => 'כתובת';

  @override
  String get colPhone => 'טלפון';

  @override
  String get colZones => 'אזורים';

  @override
  String get importFromExcelMenu => 'ייבוא מ-Excel';

  @override
  String get exportToExcelMenu => 'ייצוא ל-Excel';

  @override
  String get downloadTemplateMenu => 'הורד תבנית';

  @override
  String get fileExportedSuccess => 'הקובץ הורד בהצלחה';

  @override
  String get templateDownloadedSuccess => 'תבנית הורדה בהצלחה';

  @override
  String get loadProductTemplate => 'טען תבנית מוצרים';

  @override
  String get syncFromWarehouse => 'סנכרן מהמחסן';

  @override
  String get permanentDelete => 'מחיקה סופית';

  @override
  String permanentDeleteConfirm(String name) {
    return 'למחוק לצמיתות את \"$name\"? פעולה זו אינה הפיכה.';
  }

  @override
  String duplicateProductCode(String code) {
    return 'מק\"ט $code כבר קיים. יש לבחור מק\"ט אחר.';
  }

  @override
  String get syncFromWarehouseTitle => 'סנכרון מהמחסן';

  @override
  String get syncFromWarehouseConfirm =>
      'ליצור מוצרים חדשים בקטלוג עבור כל הפריטים שקיימים במחסן אך חסרים בקטלוג?';

  @override
  String get colDiameter => 'קוטר';

  @override
  String get colVolume => 'נפח';

  @override
  String get colPiecesPerBox => 'ארוז (יח\' בקרטון)';

  @override
  String get colAdditionalInfo => 'מידע נוסף';

  @override
  String get colContactPerson => 'איש קשר';

  @override
  String get colVatId => 'ח.פ';

  @override
  String get colLatitude => 'קו רוחב';

  @override
  String get colLongitude => 'קו אורך';

  @override
  String get columnMappingHint =>
      'התאם את העמודות מהקובץ לשדות במערכת. שדות עם * הם חובה.';

  @override
  String get targetField => 'שדה יעד';

  @override
  String get sourceColumn => 'עמודה מקורית';

  @override
  String get sampleValue => 'דוגמה';

  @override
  String get duplicateHandling => 'טיפול בכפילויות';

  @override
  String get duplicateSkip => 'דלג';

  @override
  String get duplicateUpdate => 'עדכן קיים';

  @override
  String get duplicateAdd => 'הוסף בכל מקרה';

  @override
  String get continueImport => 'המשך ייבוא';

  @override
  String get mapColumnsInventory => 'מיפוי עמודות — מלאי';

  @override
  String get mapColumnsClients => 'מיפוי עמודות — לקוחות';

  @override
  String importResultUpdated(int updated, int errors) {
    return 'עודכנו $updated | שגיאות $errors';
  }

  @override
  String importClientResultUpdated(
      int added, int updated, int skipped, int errors) {
    return 'נוספו $added | עודכנו $updated | דולגו $skipped | שגיאות $errors';
  }

  @override
  String get importFromFile => 'ייבוא מקובץ';

  @override
  String get supportConsoleTitle => 'מסוף תמיכה';

  @override
  String get verifyIntegrity => 'בדיקת שלמות';

  @override
  String get exportDiagnosticJson => 'ייצוא JSON אבחון';

  @override
  String get refreshData => 'רענון';

  @override
  String get tabOverview => 'סקירה';

  @override
  String get tabBillingAudit => 'אירועי חיוב';

  @override
  String tabPayments(int count) {
    return 'תשלומים ($count)';
  }

  @override
  String tabNotifications(int count, int unread) {
    return 'התראות ($count/$unread)';
  }

  @override
  String tabPushErrors(int count) {
    return 'שגיאות Push ($count)';
  }

  @override
  String tabEmailErrors(int count) {
    return 'שגיאות Email ($count)';
  }

  @override
  String get searchCompany => 'חפש חברה...';

  @override
  String get backToList => 'חזרה לרשימה';

  @override
  String get chipStatus => 'סטטוס';

  @override
  String get chipPlan => 'תוכנית';

  @override
  String get chipUsers => 'משתמשים';

  @override
  String get chipDocsMonth => 'מסמכים/חודש';

  @override
  String get chipUnread => 'לא נקראו';

  @override
  String get sectionBilling => 'חיוב';

  @override
  String get sectionLimitsUsage => 'מגבלות ושימוש';

  @override
  String get sectionModules => 'מודולים';

  @override
  String get labelPaidUntil => 'שולם עד';

  @override
  String get labelTrialUntil => 'ניסיון עד';

  @override
  String get labelGracePeriodDays => 'ימי חסד';

  @override
  String get labelPaymentProvider => 'ספק תשלום';

  @override
  String get labelPaymentCustomerId => 'מזהה לקוח תשלום';

  @override
  String get labelSubscriptionId => 'מזהה מנוי';

  @override
  String get labelMaxUsers => 'מקסימום משתמשים';

  @override
  String get labelActualUsers => 'משתמשים בפועל';

  @override
  String get labelMaxDocsPerMonth => 'מקסימום מסמכים/חודש';

  @override
  String get labelDocsThisMonth => 'מסמכים החודש';

  @override
  String get userLimitReached => '⚠️ הגעת למגבלת משתמשים';

  @override
  String get moduleEnabled => '✅ פעיל';

  @override
  String get moduleDisabled => '❌ מושבת';

  @override
  String get noAuditEvents => 'אין אירועי ביקורת';

  @override
  String get noPaymentEvents => 'אין אירועי תשלום';

  @override
  String get noPushErrors => '✅ אין שגיאות Push';

  @override
  String get noEmailErrors => '✅ אין שגיאות Email';

  @override
  String get integrityOk => '✅ שלמות תקינה';

  @override
  String integrityFailed(String error) {
    return '❌ שלמות נכשלה: $error';
  }

  @override
  String get diagnosticCopied => '📋 JSON אבחון הועתק ללוח';

  @override
  String get readStatus => '✓ נקרא';

  @override
  String get unreadStatus => '● לא נקרא';

  @override
  String get moduleManagementTitle => 'ניהול מודולים';

  @override
  String get planLabel => 'תוכנית';

  @override
  String get modulesInPlan => 'מודולים בתוכנית';

  @override
  String get planUpdatedSuccess => 'התוכנית עודכנה בהצלחה';

  @override
  String get moduleToggleInfo =>
      'שינויים ייכנסו לתוקף מיד. משתמשים שמנסים לגשת למודול מושבת יראו מסך \"מודול לא זמין\".';

  @override
  String get moduleWarehouseDesc => 'ניהול מלאי, ספירות, סוגי אריזות';

  @override
  String get moduleLogisticsDesc => 'נקודות משלוח, מסלולים, מפה';

  @override
  String get moduleDispatcherDesc => 'ניהול נהגים, חלוקה אוטומטית';

  @override
  String get moduleAccountingDesc => 'חשבוניות, קבלות, זיכויים, ייצוא';

  @override
  String get moduleReports => 'דוחות';

  @override
  String get moduleReportsDesc => 'סטטיסטיקות משלוחים, חשבוניות, נהגים';

  @override
  String get backupManagementTitle => 'ניהול גיבויים';

  @override
  String get tabBackups => 'גיבויים';

  @override
  String get tabRestoreTests => 'בדיקות שחזור';

  @override
  String get tabComplianceReport => 'דוח עמידה';

  @override
  String get registerBackup => 'רשום גיבוי';

  @override
  String get registerBackupTitle => 'רישום גיבוי';

  @override
  String get storageType => 'סוג אחסון';

  @override
  String get exactLocation => 'מיקום מדויק *';

  @override
  String get backupRecorded => 'גיבוי נרשם בהצלחה';

  @override
  String get registerRestoreTest => 'רשום בדיקת שחזור';

  @override
  String get registerRestoreTestTitle => 'רישום בדיקת שחזור';

  @override
  String get restoreFromBackup => 'שחזור מגיבוי *';

  @override
  String get restoreSuccess => 'השחזור הצליח?';

  @override
  String get restoreTestRecorded => 'בדיקת שחזור נרשמה';

  @override
  String get noBackupsRecorded => 'אין גיבויים רשומים';

  @override
  String get noBackupsYetRegisterFirst =>
      'אין גיבויים רשומים — יש לרשום גיבוי קודם';

  @override
  String get quarterlyBackupRequired => 'נדרש גיבוי רבעוני!';

  @override
  String get noRestoreTests => 'אין בדיקות שחזור';

  @override
  String get restoreSucceeded => 'שחזור הצליח';

  @override
  String get restoreFailed => 'שחזור נכשל';

  @override
  String get complianceOk => 'עמידה בדרישות — תקין';

  @override
  String get complianceIssues => 'בעיות בעמידה בדרישות';

  @override
  String get labelQuarter => 'רבעון';

  @override
  String get labelQuarterlyBackup => 'גיבוי רבעוני';

  @override
  String get labelBackupDue => 'נדרש גיבוי';

  @override
  String get labelBackupsRecorded => 'גיבויים רשומים';

  @override
  String get labelLastRestoreTest => 'בדיקת שחזור אחרונה';

  @override
  String get labelRestoreTests => 'בדיקות שחזור';

  @override
  String get statusDone => '✅ בוצע';

  @override
  String get statusNotDone => '❌ לא בוצע';

  @override
  String get yes => 'כן';

  @override
  String get statusSucceeded => '✅ הצליח';

  @override
  String get statusNotDoneOrFailed => '❌ לא בוצע/נכשל';

  @override
  String get storageGoogleDrive => 'Google Drive';

  @override
  String get storageOneDrive => 'OneDrive';

  @override
  String get storageDropbox => 'Dropbox';

  @override
  String get storageAwsS3 => 'AWS S3';

  @override
  String get storageExternalHdd => 'דיסק חיצוני';

  @override
  String get storageNas => 'NAS';

  @override
  String get storageUsb => 'USB / Flash';

  @override
  String get storageFirebase => 'Firebase Backup';

  @override
  String get storageLocalServer => 'שרת מקומי';

  @override
  String get storageFtp => 'FTP / SFTP';

  @override
  String get storageOther => 'אחר';

  @override
  String get hintGoogleDrive => 'קישור לתיקייה (https://drive.google.com/...)';

  @override
  String get hintOneDrive => 'קישור לתיקייה (https://onedrive.live.com/...)';

  @override
  String get hintDropbox => 'קישור לתיקייה (https://dropbox.com/...)';

  @override
  String get hintAwsS3 => 'שם הדלי והנתיב (s3://bucket/path/)';

  @override
  String get hintExternalHdd => 'שם הדיסק ונתיב (D:\\Backups\\LogiRoute)';

  @override
  String get hintNas => 'כתובת ונתיב (\\\\192.168.1.10\\backups)';

  @override
  String get hintUsb => 'שם ההתקן ונתיב (E:\\LogiRoute_Backup)';

  @override
  String get hintFirebase => 'שם הפרויקט (logiroute-app)';

  @override
  String get hintLocalServer => 'שם השרת ונתיב (/srv/backups/logiroute)';

  @override
  String get hintFtp => 'כתובת השרת (ftp://server.com/backups/)';

  @override
  String get hintOther => 'תאר את המיקום המדויק';

  @override
  String get paymentMethodLabel => 'אופן תשלום';

  @override
  String get cash => 'מזומן';

  @override
  String get cheque => 'צ\'ק';

  @override
  String get bankTransfer => 'העברה בנקאית';

  @override
  String get creditCard => 'כרטיס אשראי';

  @override
  String get notSelected => 'לא נבחר';

  @override
  String get paidStatus => 'שולם';

  @override
  String get totalToPay => 'סה״כ לתשלום';

  @override
  String get paymentReceivedCheckbox => 'תשלום התקבל (חשבונית מס / קבלה)';

  @override
  String get paymentReceivedHint =>
      'סמן אם הלקוח שילם — המסמך יהפוך לחשבונית מס-קבלה';

  @override
  String get createDeliveryNoteTitle => 'יצירת תעודת משלוח';

  @override
  String get createInvoiceTitle => 'יצירת חשבונית';

  @override
  String get creatingDoc => 'יוצר...';

  @override
  String get createAndPrint => 'צור והדפס';

  @override
  String get createDeliveryNoteBtn => 'צור תעודת משלוח';

  @override
  String get deliveryDateLabel => 'תאריך אספקה:';

  @override
  String get paymentTermsLabel => 'תנאי תשלום:';

  @override
  String get days30 => '30 ימים';

  @override
  String get days60 => '60 ימים';

  @override
  String get days90 => '90 ימים';

  @override
  String get manualEntry => 'ידני';

  @override
  String get payUntilLabel => 'תשלום עד:';

  @override
  String get itemLabel => 'פריט';

  @override
  String get cartonsLabel => 'קרטונים';

  @override
  String get pricePerUnitLabel => 'מחיר ליח\'';

  @override
  String get totalLabel => 'סה״כ';

  @override
  String get discountLabel => 'הנחה:';

  @override
  String get clientLabelColon => 'לקוח:';

  @override
  String get addressLabelColon => 'כתובת:';

  @override
  String get driverLabelColon => 'נהג:';

  @override
  String get truckLabelColon => 'משאית:';

  @override
  String get notSpecified => 'לא צוין';

  @override
  String get departureTimeValue => 'שעת יציאה: 07:00';

  @override
  String get userNotLoggedIn => 'משתמש לא מחובר — לא ניתן ליצור מסמך';

  @override
  String get serverIssuanceError => 'שגיאה בהנפקת מסמך מהשרת';

  @override
  String deliveryNoteAlreadyExists(int docNum) {
    return 'תעודת משלוח כבר קיימת (#$docNum)';
  }

  @override
  String deliveryNoteCreatedSuccess(int docNum) {
    return '✅ תעודת משלוח נוצרה בהצלחה (#$docNum)';
  }

  @override
  String taxInvoiceReceiptCreatedSuccess(int docNum) {
    return '✅ חשבונית מס / קבלה נוצרה בהצלחה (#$docNum)';
  }

  @override
  String invoiceCreatedSuccess(int docNum) {
    return '✅ חשבונית נוצרה בהצלחה (#$docNum)';
  }

  @override
  String invoicePeriodLockedError(String date, String lockedUntil) {
    return 'תאריך $date נמצא בתקופה חשבונאית סגורה (עד $lockedUntil). בחר תאריך מאוחר יותר.';
  }

  @override
  String get possibleDuplicateOrder => 'הזמנה כפולה אפשרית';

  @override
  String exactDuplicateFound(String name) {
    return 'נמצאה הזמנה זהה לחלוטין עבור $name!';
  }

  @override
  String existingOrdersFound(String name) {
    return 'נמצאו הזמנות קיימות עבור $name:';
  }

  @override
  String get checkNotDuplicate => 'בדוק שזו לא הזמנה כפולה!';

  @override
  String get deleteDuplicates => 'מחק כפילויות';

  @override
  String get driverRouteTitle => 'מסלול נהג';

  @override
  String wazeOpenError(String error) {
    return 'שגיאה בפתיחת Waze: $error';
  }

  @override
  String get remainingLabel => 'נותרו';

  @override
  String percentCompleted(Object percent) {
    return '$percent% הושלם';
  }

  @override
  String nPoints(Object count) {
    return '$count נקודות';
  }

  @override
  String get shiftScheduleTitle => 'לוח משמרות';

  @override
  String get shiftWorkingDays => 'ימי עבודה';

  @override
  String get shiftDayMon => 'ב׳';

  @override
  String get shiftDayTue => 'ג׳';

  @override
  String get shiftDayWed => 'ד׳';

  @override
  String get shiftDayThu => 'ה׳';

  @override
  String get shiftDayFri => 'ו׳';

  @override
  String get shiftDaySat => 'ש׳';

  @override
  String get shiftDaySun => 'א׳';

  @override
  String get shiftStart => 'תחילת משמרת';

  @override
  String get shiftEnd => 'סיום משמרת';

  @override
  String get shiftSaved => 'נשמר';

  @override
  String shiftLoadError(String error) {
    return 'שגיאת טעינה: $error';
  }

  @override
  String shiftSaveError(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get shiftNoCompanyId => 'לא נבחרה חברה';
}
