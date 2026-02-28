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
  String get roleAdmin => 'מנהל מערכת';

  @override
  String get roleDispatcher => 'משגר';

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
  String get cancelAction2 => 'ביטול';
}
