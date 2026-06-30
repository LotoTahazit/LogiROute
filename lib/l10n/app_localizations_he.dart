// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get routeHistoryTitle => 'היסטוריית מסלולים';

  @override
  String get routeHistoryEmpty => 'אין עדיין מסלולים שהושלמו';

  @override
  String get vatRegimeLabel => 'סוג עוסק (הדפסה)';

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
      'הפלטפורמה לא מוגדרת — נדרש ISRAEL_INVOICE_* ב-functions/.env';

  @override
  String get israelInvoiceCompanyConnected => 'מחובר לרשות המסים';

  @override
  String get israelInvoiceCompanyNotConnected => 'לא מחובר — לחץ לחיבור OAuth';

  @override
  String get israelInvoiceConnect => 'חבר למערכת חשבוניות ישראל';

  @override
  String get israelInvoiceConnectHint =>
      'התחברות חד-פעמית של העסק לרשות המסים לקבלת מספרי הקצאה. ייפתח דף ההתחברות.';

  @override
  String get israelInvoiceAssignmentReady => 'מספר הקצאה — מוכן';

  @override
  String get israelInvoiceAssignmentMissingOAuth =>
      'מספר הקצאה — חסר חיבור OAuth';

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
  String get regeocodeAllClientsMenu => 'גיאוקוד מחדש לכל הלקוחות';

  @override
  String get regeocodeAllClientsConfirm =>
      'לבצע גיאוקוד מחדש לכל הלקוחות עם כתובת? הקואורדינטות יתעדכנו לפי עיר מהכתובת. זה עלול לקחת כמה דקות.';

  @override
  String regeocodeAllClientsProgress(int done, int total) {
    return 'גיאוקוד $done / $total…';
  }

  @override
  String regeocodeAllClientsResult(
      int updated, int unchanged, int failed, int skipped, int points) {
    return 'הושלם: עודכנו $updated, ללא שינוי $unchanged, שגיאות $failed, ללא כתובת $skipped. נקודות פעילות: $points.';
  }

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
  String get authUserNotFound => 'לא נמצא משתמש עם אימייל זה';

  @override
  String get authUserDisabled => 'החשבון מושבת. פנה למנהל המערכת';

  @override
  String get authNetworkError => 'אין חיבור לשרת. בדוק את האינטרנט';

  @override
  String get authOperationNotAllowed => 'כניסה באימייל מושבתת בהגדרות הפרויקט';

  @override
  String get authInvalidApiKey => 'שגיאת תצורת אפליקציה (API key). פנה למנהל';

  @override
  String get authAppNotAuthorized =>
      'Android לא מאושר ב-Firebase. הוסף SHA-1 release ב-Firebase Console → Project settings → Android app';

  @override
  String get authInternalError => 'שגיאת שרת אימות. נסה שוב מאוחר יותר';

  @override
  String get authProfileNotFound => 'פרופיל לא נמצא או לא מוגדר. פנה למנהל';

  @override
  String get authUnknownError => 'ההתחברות נכשלה. בדוק את הפרטים או נסה שוב';

  @override
  String get authPasswordResetFailed =>
      'לא ניתן לשלוח מייל לאיפוס סיסמה. בדוק אימייל או פנה למנהל';

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
  String get themeLight => 'ערכת נושא בהירה';

  @override
  String get themeDark => 'ערכת נושא כהה';

  @override
  String get themeSystem => 'לפי המערכת';

  @override
  String get capacity => 'קיבולת';

  @override
  String get totalPallets => 'סה\"כ משטחים';

  @override
  String get confirm => 'אשר';

  @override
  String get save => 'שמור';

  @override
  String get deliveryWindowTitle => 'חלון מסירה';

  @override
  String get deliveryWindowFrom => 'מ-';

  @override
  String get deliveryWindowTo => 'עד';

  @override
  String get deliveryWindowNotSet => 'לא הוגדר';

  @override
  String get deliveryWindowClear => 'נקה חלון';

  @override
  String routeLateBy(int minutes) {
    return 'באיחור של $minutes דק׳';
  }

  @override
  String get routeOnTime => 'בזמן';

  @override
  String avgMinutesPerPoint(int minutes) {
    return '~$minutes דק׳/נק׳';
  }

  @override
  String get requirePodPhoto => 'לחייב צילום מסירה (POD)';

  @override
  String get requirePodPhotoHint =>
      'מסתיר סגירה בנגיעה ומכבה סגירה אוטומטית — כל מסירה דורשת צילום.';

  @override
  String get autoCloseEnabledTitle => 'סגירת נקודות אוטומטית לפי GPS';

  @override
  String get autoCloseEnabledHint =>
      'הנקודה נסגרת אוטומטית כשהנהג עומד אצל הלקוח. כבה אם ברצונך שהנהג יסגור נקודות רק ידנית.';

  @override
  String get deliverySection => 'מסירה';

  @override
  String get settingsDeliveryAndOps => 'מסירה ותפעול';

  @override
  String get settingsDriverDefaults => 'ברירת מחדל לנהג';

  @override
  String get settingsOpsManagedByAdmin =>
      'הגדרות מסירה ונהג מנוהלות על ידי מנהל המערכת';

  @override
  String get pointDone => 'נקודה הושלמה';

  @override
  String get noActivePoints => 'אין נקודות פעילות';

  @override
  String get pointCompleted => 'נקודה סומנה כהושלמה';

  @override
  String get autoCloseToggle => 'אוטו';

  @override
  String get bgLocationTitle => 'מיקום ברקע';

  @override
  String get bgLocationBody =>
      'כדי שמסלול הנהג יירשם במלואו (גם כשהמסך נעול), אפשר גישה למיקום \"תמיד\" בהגדרות האפליקציה.';

  @override
  String get bgLocationOpenSettings => 'פתח הגדרות';

  @override
  String get androidSetupTitle => 'הגדרת אנדרואיד למשמרת';

  @override
  String get androidSetupIntro =>
      'כדי שהמשמרת וה-GPS יעבדו ברקע (גם כשהמסך נעול), הפעל 3 הגדרות:';

  @override
  String get androidSetupLocationTitle => 'מיקום: \"אפשר תמיד\"';

  @override
  String get androidSetupLocationDesc => 'בלי זה ה-GPS נעלם כשהמסך נעול.';

  @override
  String get androidSetupBatteryTitle => 'סוללה: ללא הגבלות';

  @override
  String get androidSetupBatteryDesc =>
      'כדי שהמערכת לא תסגור את שירות הרקע של המשמרת.';

  @override
  String get androidSetupAutostartTitle =>
      'הפעלה אוטומטית (Xiaomi/MIUI, Huawei, Oppo…)';

  @override
  String get androidSetupAutostartDesc =>
      'אפשר הפעלה אוטומטית של האפליקציה — אחרת השירות לא יתחיל אחרי הפעלה מחדש. בדוק ידנית בהגדרות האפליקציה.';

  @override
  String get androidSetupEnable => 'הפעל';

  @override
  String get androidSetupDone => 'סיום';

  @override
  String get androidSetupGranted => 'מופעל';

  @override
  String get androidSetupMenu => 'הגדרת אנדרואיד (רקע)';

  @override
  String get closeWithPhoto => 'סגור עם תמונה';

  @override
  String get fixLocationButton => 'מיקום שגוי';

  @override
  String get fixLocationTitle => 'לעדכן את מיקום הלקוח?';

  @override
  String fixLocationBody(String clientName) {
    return 'לשמור את מיקומך הנוכחי כקואורדינטות של הלקוח \"$clientName\"? זה יתקן את הנקודה למשלוחים הבאים.';
  }

  @override
  String get fixLocationSuccess => 'מיקום הלקוח עודכן';

  @override
  String get fixLocationGpsError => 'אין GPS מדויק, או מיקום מחוץ לישראל';

  @override
  String get fixLocationClientMissing => 'הלקוח לא נמצא';

  @override
  String get autoCloseUndoMessage => 'הנקודה נסגרה אוטומטית';

  @override
  String pointCloseUndoMessage(String name) {
    return 'משלוח \"$name\" נסגר';
  }

  @override
  String autoClosePendingBanner(String name, int distance, int seconds) {
    return 'סגירה אוטומטית: $name · $distance מ׳ · ~$seconds שנ׳';
  }

  @override
  String get undo => 'ביטול';

  @override
  String get podTitle => 'אישור מסירה';

  @override
  String get podTakePhoto => 'צלם תמונה';

  @override
  String get podRetake => 'צלם שוב';

  @override
  String get podConfirm => 'אשר מסירה';

  @override
  String get podGps => 'מיקום GPS';

  @override
  String get podTime => 'שעה';

  @override
  String get podDistance => 'מרחק ללקוח';

  @override
  String get podPhotoRequired => 'נדרשת תמונת מסירה';

  @override
  String get podGpsUnavailable => 'GPS לא זמין — הפעל מיקום';

  @override
  String get podUploadFailed => 'העלאת התמונה נכשלה — בדוק את החיבור ונסה שוב';

  @override
  String get podViewerTooltip => 'תמונת מסירה';

  @override
  String get podViewerNoPhoto => 'לא צורפה תמונה — הנקודה נסגרה ללא צילום';

  @override
  String get podViewerPhotoError => 'טעינת התמונה נכשלה';

  @override
  String get podViewerAutoClosed => 'נסגר אוטומטית לפי GPS';

  @override
  String get podSharePhoto => 'שתף';

  @override
  String get routeArchiveTitle => 'ארכיון מסלולים';

  @override
  String get routeArchiveHint =>
      'משלוחים מ-90 הימים האחרונים. תמונות זמינות במהלך התקופה; GPS ושעה נשמרים לאחר מכן.';

  @override
  String get routeArchiveEmpty => 'אין משלוחים בארכיון לתקופה זו';

  @override
  String get routeArchiveSearchHint => 'חיפוש לקוח, נהג או כתובת';

  @override
  String routeArchivePointsCount(Object count) {
    return '$count נקודות';
  }

  @override
  String get routeArchiveGpsOnly => 'GPS בלבד';

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
  String get analyticsPeriodHint => 'הניתוח מחושב לתקופה שנבחרה בלבד.';

  @override
  String get analyticsPeriodToday => 'היום';

  @override
  String get settings => 'הגדרות';

  @override
  String get lastUpdated => 'עודכן לאחרונה';

  @override
  String get routeCopiedToClipboard => 'המסלול הועתק ללוח';

  @override
  String printError(String error) {
    return '❌ שגיאה בהדפסה: $error';
  }

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
  String get deliveryAddressOverrideToggle => 'כתובת המשלוח שונה מכתובת הלקוח';

  @override
  String get deliveryAddressOverrideLabel => 'כתובת למשלוח זה';

  @override
  String get deliveryAddressOverrideHint => 'סניף, פריקה חד-פעמית, מקום זמני…';

  @override
  String get deliveryAddressOverrideBadge => 'כתובת משלוח חד-פעמית';

  @override
  String get deliveryAddressOverrideNoCoords =>
      'קואורדינטות כתובת המשלוח לא נמצאו';

  @override
  String get deliveryAddressLabel => 'כתובת משלוח';

  @override
  String get findCoordinates => 'מצא קואורדינטות';

  @override
  String get clientAddressLabel => 'כתובת לקוח';

  @override
  String get originalAddress => 'כתובת מקורית';

  @override
  String get active => 'פעיל';

  @override
  String get forgotPassword => 'שכחת סיסמה?';

  @override
  String get passwordResetEmailSent =>
      'אם האימייל רשום במערכת, בדוק/י את תיבת הדואר והספאם לקישור איפוס';

  @override
  String get resetPasswordTitle => 'סיסמה חדשה';

  @override
  String get resetPasswordHint => 'הזן/י סיסמה חדשה לחשבון שלך';

  @override
  String get newPasswordLabel => 'סיסמה חדשה';

  @override
  String get confirmPasswordLabel => 'אימות סיסמה';

  @override
  String get saveNewPassword => 'שמור סיסמה';

  @override
  String get passwordResetSuccess => 'הסיסמה עודכנה. התחבר/י עם הסיסמה החדשה';

  @override
  String get passwordsDoNotMatch => 'הסיסמאות אינן תואמות';

  @override
  String get invalidResetLink =>
      'קישור האיפוס לא תקין. בקש/י קישור חדש במסך ההתחברות';

  @override
  String get emailTypoGmail =>
      'התכוונת ל-@gmail.com? @google.com אינו ספק דוא\"ל תקין';

  @override
  String get emailTypoCon => 'שגיאת הקלדה בדומיין: .con במקום .com?';

  @override
  String get companyId => 'שם חברה';

  @override
  String get gpsTrackingActive => 'מעקב GPS פעיל';

  @override
  String get gpsTrackingStopped => 'מעקב GPS הופסק';

  @override
  String get gpsStatusActive => 'פעיל';

  @override
  String get gpsStatusWaiting => 'ממתין';

  @override
  String get gpsStatusError => 'שגיאה';

  @override
  String get gpsStatusDisabled => 'מושבת';

  @override
  String get gpsStatusPermissionRequired => 'נדרשת הרשאה';

  @override
  String get gpsStatusUploadError => 'שגיאת שליחה';

  @override
  String get gpsUnavailableHint => 'GPS לא זמין. הפעל מיקום ואפשר גישה.';

  @override
  String get gpsBackgroundHintShort => 'למעקב ברקע, אפשר גישה למיקום \"תמיד\".';

  @override
  String get bgModeActive => 'מצב רקע פעיל';

  @override
  String get bgModeInactive => 'מצב רקע לא פעיל';

  @override
  String get bgSystemStoppedWarning =>
      'מעקב ברקע הופסק על ידי המערכת. בדקו הגדרות סוללה.';

  @override
  String get bgOpenSetup => 'הגדרות Android';

  @override
  String get gpsFirestoreWriteFailed =>
      'לא ניתן לשלוח קואורדינטות לשרת. בדוק את האינטרנט.';

  @override
  String get gpsStaleHint => 'GPS לא התעדכן זמן רב. בדוק הגדרות מיקום.';

  @override
  String get gpsRecheck => 'בדוק שוב';

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
  String get typeLabelFood => 'קטגוריה (חלב, לחם, משקאות)';

  @override
  String get typeLabelClothing => 'סוג (חולצה, מכנס, נעל)';

  @override
  String get typeLabelConstruction => 'סוג (מלט, בלוקים)';

  @override
  String get typeLabelGeneric => 'סוג / קטגוריה';

  @override
  String get numberLabelFood => 'גרסה / גודל (0.5ל, 1ק\"ג)';

  @override
  String get numberLabelClothing => 'מידה / מק\"ט';

  @override
  String get numberLabelConstruction => 'דרגה / גודל';

  @override
  String get numberLabelGeneric => 'מספר או קוד גרסה';

  @override
  String get volumeLabelFood => 'נפח או משקל (אופציונלי)';

  @override
  String get volumeLabelOptionalGeneric => 'גודל / הערה (אופציונלי)';

  @override
  String get weightLabelOptional => 'משקל ק\"ג (אופציונלי)';

  @override
  String quantityOnPalletName(String palletName) {
    return 'כמות על $palletName';
  }

  @override
  String piecesPerUnitInBox(String unitName) {
    return 'אריזה — $unitName בקרטון (אופציונלי)';
  }

  @override
  String get quantityPerBoxLabel => 'כמות בקרטון';

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
  String get companyNameHebrew => 'שם (עברית)';

  @override
  String get companyNameEnglish => 'שם (אנגלית, אופציונלי)';

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
  String get categoryBeverages => 'משקאות';

  @override
  String get categoryFrozen => 'קפואים';

  @override
  String get categorySnacks => 'חטיפים';

  @override
  String get categoryPants => 'מכנסיים';

  @override
  String get categoryShoes => 'נעליים';

  @override
  String get categoryAccessories => 'אביזרים';

  @override
  String get categoryBlocks => 'בלוקים';

  @override
  String get categoryMix => 'תערובות';

  @override
  String get categoryTools => 'כלים';

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
  String get reportsPeriodHint => 'הדוח מחושב לתקופה שנבחרה בלבד.';

  @override
  String get reportsPeriodThisMonth => 'חודש נוכחי';

  @override
  String get reportsPeriodLast3Months => '3 חודשים';

  @override
  String get reportsPeriodLast12Months => '12 חודשים';

  @override
  String get reportsPeriodCustom => 'טווח מותאם';

  @override
  String get reportsLoadMore => 'טען עוד';

  @override
  String reportsTruncatedHint(int count) {
    return 'מוצגים עד $count מסמכים. לחץ «טען עוד» או צמצם את התקופה.';
  }

  @override
  String get monthlyReport => 'דוח חודשי';

  @override
  String get vatReport => 'דוח מע״מ';

  @override
  String get clientReport => 'דוח לקוחות';

  @override
  String get reportStockTab => 'מלאי';

  @override
  String get reportStockSku => 'מק\"ט';

  @override
  String get reportStockProduct => 'מוצר';

  @override
  String get reportStockQty => 'כמות (יח\')';

  @override
  String get reportStockPallets => 'משטחים';

  @override
  String get reportStockTotalSkus => 'פריטים';

  @override
  String get reportStockTotalUnits => 'סה\"כ יחידות';

  @override
  String get reportStockTotalPallets => 'סה\"כ משטחים';

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
  String get mapDemoRoutesBuilt => 'נבנו 3 מסלולים אופטימליים';

  @override
  String get mapDemoWarehouseCreatedDeliveries => 'המחסן יצר 12 משלוחים';

  @override
  String get mapDemoTruckLoading => 'טעינה למשאית: 12 משלוחים הועמסו מהמחסן';

  @override
  String get mapDemoTasksSentToDrivers => 'המשימות נשלחו לנהגים';

  @override
  String get mapDemoActiveDriver => 'נהג פעיל';

  @override
  String get mapDemoDirectionToWarehouse => 'למחסן';

  @override
  String get mapDemoDirectionUnknown => 'לא ידוע';

  @override
  String mapDemoDirectionLabel(String direction) {
    return 'כיוון: $direction';
  }

  @override
  String mapDemoEtaMinutes(int minutes) {
    return 'ETA: ~$minutes דק\'';
  }

  @override
  String get mapDemoStage1Title => 'הזמנה התקבלה';

  @override
  String get mapDemoStage1Desc => 'הלקוח שולח בקשת משלוח למפקח.';

  @override
  String get mapDemoStage2Title => 'נשלח למחסן';

  @override
  String get mapDemoStage2Desc => 'המפקח מעביר את ההזמנה למחסן לביצוע.';

  @override
  String get mapDemoStage3Title => 'הכנה במחסן';

  @override
  String get mapDemoStage3Desc => 'הצוות אורז סחורה ובונה משטחים.';

  @override
  String get mapDemoStage4Title => 'מסלול נוצר';

  @override
  String get mapDemoStage4Desc => 'המפקח מתכנן מסלול אופטימלי עם כל התחנות.';

  @override
  String get mapDemoStage5Title => 'טעינה למשאית';

  @override
  String get mapDemoStage5Desc => 'המשטחים נטענים למשאית הנהג.';

  @override
  String get mapDemoStage6Title => 'הנהג בדרך';

  @override
  String get mapDemoStage6Desc => 'הנהג נוסע במסלול — הרחובות נראים על המפה.';

  @override
  String get mapDemoStage7Title => 'פריקה ומסירה';

  @override
  String get mapDemoStage7Desc =>
      'בכל תחנה פריקה; התחנה מסומנת אוטומטית כהושלמה.';

  @override
  String get mapDemoStage8Title => 'חזרה למחסן';

  @override
  String get mapDemoStage8Desc => 'הנהג מסיים את המסלול וחוזר לבסיס.';

  @override
  String get mapDemoStageCompleteTitle => 'הסימולציה הושלמה';

  @override
  String get mapDemoStageCompleteDesc => 'מחזור המשלוח המלא הושלם בהצלחה.';

  @override
  String mapDemoStopLabel(int number) {
    return 'תחנה $number';
  }

  @override
  String mapDemoDeliveringAt(String stop) {
    return 'פריקה ב$stop';
  }

  @override
  String get mapDemoReplay => 'הפעל שוב';

  @override
  String get mapDemoLiveBadge => 'LIVE';

  @override
  String get mapDemoKpiMileage => 'נסועה';

  @override
  String get mapDemoKpiEtaAccuracy => 'דיוק ETA';

  @override
  String get mapDemoKpiCalls => 'שיחות';

  @override
  String get mapDemoKpiDelivered => 'נמסרו';

  @override
  String get mapDemoKpiEnroute => 'בדרך';

  @override
  String get mapDemoKpiDistance => 'מסלול';

  @override
  String get mapDemoKpiLate => 'איחורים';

  @override
  String get mapDemoEtaAccuracyValue => '±3 דק׳';

  @override
  String get mapDemoFinishSubtitle => 'המוקדן ראה הכול בזמן אמת';

  @override
  String get mapDemoFinishNote => 'אף שיחת \"איפה אתה?\" לנהג לאורך כל המסלול';

  @override
  String mapDemoMinutesShort(int minutes) {
    return '~$minutes דק׳';
  }

  @override
  String mapDemoKmShort(String km) {
    return '$km ק״מ';
  }

  @override
  String get mapDemoStepShort1 => 'הזמנה';

  @override
  String get mapDemoStepShort2 => 'מחסן';

  @override
  String get mapDemoStepShort3 => 'הכנה';

  @override
  String get mapDemoStepShort4 => 'מסלול';

  @override
  String get mapDemoStepShort5 => 'טעינה';

  @override
  String get mapDemoStepShort6 => 'נסיעה';

  @override
  String get mapDemoStepShort7 => 'מסירה';

  @override
  String get mapDemoStepShort8 => 'חזרה';

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
  String get billingGuardVerifyFailedTitle => 'לא ניתן לאמת את סטטוס המנוי';

  @override
  String get billingGuardVerifyFailedBody =>
      'בדוק את חיבור האינטרנט או נסה שוב מאוחר יותר.';

  @override
  String get billingGuardRetry => 'נסה שוב';

  @override
  String get billingSupportDialogTitle => 'צור קשר עם התמיכה';

  @override
  String get billingSupportDialogBody =>
      'שלח לנו אימייל — נעזור לשחזר גישה או לשנות תוכנית.';

  @override
  String get billingSupportCopyEmail => 'העתק אימייל';

  @override
  String get billingSupportEmailCopied => 'האימייל הועתק';

  @override
  String get billingSupportOpenEmail => 'שלח אימייל';

  @override
  String get billingSupportCall => 'התקשר';

  @override
  String get billingSupportPayUnavailable =>
      'לא ניתן לאמת את המנוי. התשלום אינו זמין כרגע.';

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
  String get billingDashboardSeedPricingTooltip => 'העלה תמחור ל-Firestore';

  @override
  String get billingDashboardSeedPricingTitle =>
      'לעדכן config/billing_pricing?';

  @override
  String get billingDashboardSeedPricingBody =>
      'כותב את רשת התמחור הנוכחית (לוגיסטיקה, מחסן, תפעול, מלא) ל-config/billing_pricing. Checkout ישתמש במחירים מיד.';

  @override
  String get billingDashboardSeedPricingButton => 'העלה';

  @override
  String get billingDashboardSeedPricingRunning => 'מעלה תמחור…';

  @override
  String billingDashboardSeedPricingDone(String plans) {
    return 'תמחור עודכן: $plans';
  }

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
  String get dispatcherTourStopTooltip => 'סגור מצגת';

  @override
  String get dispatcherTourStartTooltip => 'מצגת LogiRoute';

  @override
  String dispatcherTourProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get salesDemoSkip => 'דלג';

  @override
  String get salesDemoNext => 'הבא';

  @override
  String get salesDemoBack => 'חזור';

  @override
  String get salesDemoGetStarted => 'התחל';

  @override
  String get salesDemoSeeLiveDemo => 'דמו חי';

  @override
  String get salesDemoBrandTagline => 'פלטפורמת לוגיסטיקה מקצה לקצה';

  @override
  String get salesDemoSlide1Title => 'לוגיסטיקה לא צריכה להרגיש כאוס';

  @override
  String get salesDemoSlide1Subtitle =>
      'מסלולים ידניים, משלוחים שמתפספסים וצוותים מנותקים עולים בזמן ובכסף כל יום.';

  @override
  String get salesDemoSlide1Benefit1 => 'שעות אבודות על גיליונות ושיחות';

  @override
  String get salesDemoSlide1Benefit2 => 'אין ראות בזמן אמת על הצי';

  @override
  String get salesDemoSlide1Benefit3 => 'חשבוניות ומשלוחים לא מסונכרנים';

  @override
  String get salesDemoSlide2Title => 'הכירו את LogiRoute';

  @override
  String get salesDemoSlide2Subtitle =>
      'פלטפורמה אחת למחסן, דיספוצ\'ר, נהגים וחיוב — מוכנה לצמיחה.';

  @override
  String get salesDemoSlide2Benefit1 => 'מהזמנה לחשבונית בזרימה אחת';

  @override
  String get salesDemoSlide2Benefit2 => 'ווב ומובייל — הצוות תמיד מחובר';

  @override
  String get salesDemoSlide2Benefit3 => 'נבנה לפעילות דיספוצ\'ר אמיתית';

  @override
  String get salesDemoPersonaAdmin => 'מנהל';

  @override
  String get salesDemoPersonaDispatcher => 'דיספוצ\'ר';

  @override
  String get salesDemoPersonaDriver => 'נהג';

  @override
  String get salesDemoPersonaAdminDesc =>
      'שליטה מלאה: חברות, משתמשים, חיוב ואנליטיקה בלוח אחד.';

  @override
  String get salesDemoPersonaDispatcherDesc =>
      'בנו מסלולים, שייכו נהגים ועקבו אחרי כל משלוח חי על המפה.';

  @override
  String get salesDemoPersonaDriverDesc =>
      'משימות ברורות, סדר עצירות ועדכוני סטטוס מיידיים מהכביש.';

  @override
  String get salesDemoSlide3Title => 'ניתוב חכם ודיספוצ\'ר';

  @override
  String get salesDemoSlide3Subtitle =>
      'תכננו מסלולים אופטימליים בדקות — לא בשעות.';

  @override
  String get salesDemoSlide3Benefit1 => 'אופטימיזציית מסלולים אוטומטית';

  @override
  String get salesDemoSlide3Benefit2 => 'שיוך נהגים בגרירה';

  @override
  String get salesDemoSlide3Benefit3 => 'מפה חיה עם כל המשלוחים הפעילים';

  @override
  String get salesDemoSlide4Title => 'אפליקציית נהג ומעקב חי';

  @override
  String get salesDemoSlide4Subtitle =>
      'כל נהג יודע לאן ללכת — אתם רואים התקדמות בזמן אמת.';

  @override
  String get salesDemoSlide4Benefit1 => 'משימות מגיעות מיידית לטלפון הנהג';

  @override
  String get salesDemoSlide4Benefit2 => 'מעקב GPS על מפה אינטראקטיבית';

  @override
  String get salesDemoSlide4Benefit3 => 'פחות שיחות, משלוחים מהירים יותר';

  @override
  String get salesDemoSlide5Title => 'מהמחסן לחשבונית';

  @override
  String get salesDemoSlide5Subtitle =>
      'מחזור חיי הזמנה מלא — שום דבר לא נופל בין הכיסאות.';

  @override
  String get salesDemoSlide5Benefit1 => 'תהליכי ליקוט וטעינה במחסן';

  @override
  String get salesDemoSlide5Benefit2 => 'חיוב מסונכרן עם כל משלוח';

  @override
  String get salesDemoSlide5Benefit3 => 'מעקב מלא אחרי כל הזמנה';

  @override
  String get salesDemoLifecycleOrder => 'הזמנה';

  @override
  String get salesDemoLifecycleDispatch => 'שיבוץ';

  @override
  String get salesDemoLifecycleDelivery => 'משלוח';

  @override
  String get salesDemoLifecycleInvoice => 'חשבונית';

  @override
  String get salesDemoSlide6Title => 'לוגיסטיקה ברמת ארגון';

  @override
  String get salesDemoSlide6Subtitle =>
      'מקצועי, מאובטח ומוכן לפעילות משלוחים בצמיחה.';

  @override
  String get salesDemoSlide6Benefit1 => 'גישה מבוססת תפקיד לכל חבר צוות';

  @override
  String get salesDemoSlide6Benefit2 => 'אנגלית, רוסית ועברית מובנות';

  @override
  String get salesDemoSlide6Benefit3 => 'בשימוש צוותי דיספוצ\'ר כל יום';

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
  String get mergeRoutes => 'מיזוג מסלולים';

  @override
  String get mergeRoutesHint =>
      'נקודות פעילות יעברו למסלול היעד. נקודות שהושלמו יישארו במסלול המקורי.';

  @override
  String get mergeRoutesTarget => 'מסלול יעד';

  @override
  String get mergeRoutesSources => 'הוסף נקודות פעילות מ';

  @override
  String get mergeRoutesNoEligible =>
      'אין מסלולים למיזוג (נדרשים 2+ לאותו נהג)';

  @override
  String get mergeRoutesPickTarget => 'בחר מסלול יעד';

  @override
  String get mergeRoutesPickSource => 'בחר לפחות מסלול מקור אחד';

  @override
  String get mergeRoutesNothingMoved => 'אין נקודות פעילות להעברה';

  @override
  String mergeRoutesSuccess(Object count) {
    return 'הועברו נקודות פעילות: $count';
  }

  @override
  String mergeRoutesRouteLabel(
      Object driver, Object active, Object done, Object total) {
    return '$driver · $active פעיל / $done הושלם · $total נקודות';
  }

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
  String get navigationNoDestination => 'אין קואורדינטות או כתובת לניווט';

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
  String get inventoryActionBarcodeIn => 'כניסה (ברקוד)';

  @override
  String get inventoryActionBarcodeOut => 'יציאה (ברקוד)';

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
  String get integrityCheckExplain =>
      'בודק את שרשרת המספור הקריפטוגרפית. מסמכים שהונפקו לפני הפעלת השרשרת מדולגים אוטומטית — זו לא שגיאה.';

  @override
  String get integrityLegacyOnly =>
      'אין רשומות בשרשרת: כל המסמכים מסוג זה הונפקו לפני בדיקת השלמות. מסמכים חדשים ייבדקו כרגיל.';

  @override
  String integrityLegacySkipped(int from, int to) {
    return 'מספרים ישנים #$from–#$to דולגו (לפני הרשומה הראשונה בשרשרת)';
  }

  @override
  String integrityCheckedFrom(int from, int to) {
    return 'נבדק בפועל: #$from עד #$to';
  }

  @override
  String get integrityReasonMissingEntry => 'רשומה חסרה בשרשרת';

  @override
  String get integrityReasonMissingPrevForRange => 'מסמך קודם לפני הטווח חסר';

  @override
  String get integrityReasonSchemaInvalid => 'רשומת שרשרת פגומה';

  @override
  String get integrityReasonPrevHashMismatch => 'שרשרת ההאש נשברה';

  @override
  String get integrityReasonHashMismatch => 'האש לא תואם';

  @override
  String integrityOkSummary(int count) {
    return '✅ שלמות תקינה — נבדקו: $count';
  }

  @override
  String integrityFailedSummary(int number) {
    return '❌ שגיאה במסמך #$number';
  }

  @override
  String get createCompany => 'צור חברה';

  @override
  String get createCompanyTitle => 'חברה חדשה';

  @override
  String get createCompanyDesc =>
      'יוצר חברה, הגדרות ברירת מחדל ומוני מסמכים. ניסיון 14 יום.';

  @override
  String get companyIdSlug => 'מזהה מערכת (a-z, מספרים)';

  @override
  String get companyIdSlugHint => 'acme-logistics';

  @override
  String companyCreatedSuccess(String name) {
    return 'החברה \"$name\" נוצרה';
  }

  @override
  String get companyAlreadyExists => 'חברה עם מזהה זה כבר קיימת';

  @override
  String get invalidCompanyId => 'מזהה: a-z, ספרות, מקף, 3–40 תווים';

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
  String get cannotOpenPayment => 'לא ניתן לפתוח את דף התשלום.';

  @override
  String get checkoutCopyLink => 'העתק קישור';

  @override
  String get checkoutLinkCopied => 'הקישור הועתק';

  @override
  String get checkoutSessionFailed =>
      'לא ניתן ליצור סשן תשלום. נסה שוב מאוחר יותר.';

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
  String get docNumberShort => 'מס׳';

  @override
  String get auditEventBy => 'ע\"י';

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
  String get eventDeliveryAddressChanged => 'כתובת משלוח שונתה';

  @override
  String get auditOldDeliveryAddress => 'קודם';

  @override
  String get auditNewDeliveryAddress => 'חדש';

  @override
  String get auditChangedByRole => 'שונה על ידי';

  @override
  String get auditCorrelationId => 'CorrelationId';

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
  String get metricsNotCalculatedYet =>
      'המדדים עדיין לא חושבו. לחץ «חשב מחדש» או המתן לעדכון הלילי.';

  @override
  String get recalculateMetrics => 'חשב מחדש מדדים';

  @override
  String get metricsRecalculateDone => 'המדדים עודכנו';

  @override
  String get metricsRecalculateFailed => 'לא ניתן לחשב מחדש את המדדים';

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
      'הגעת למגבלת התוכנית — אזהרה בלבד (הזמנות לא נחסמות בפיילוט). מומלץ לשדרג.';

  @override
  String get limitEnforcementSoft => 'מגבלה רכה (אזהרה)';

  @override
  String get limitEnforcementHard => 'מגבלה קשה';

  @override
  String get limitEnforcementNotEnforced => 'לא במעקב עדיין';

  @override
  String get limitSoftExceededNote => 'חריגה מהמגבלה לא חוסמת פעולות בפיילוט.';

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
  String get settingsOwnerSetupHint =>
      'שם החברה וח.פ. — בלשונית «פרופיל חברה». כאן: מע\"מ, חשבוניות ואינטגרציות.';

  @override
  String get settingsInvoiceSettings => 'הגדרות חשבונית';

  @override
  String get settingsInvoiceFooter => 'טקסט תחתית חשבונית';

  @override
  String get settingsInvoiceFooterHint =>
      'מודפס בתחתית חשבונית PDF: תודה, תנאים, פרטי בנק';

  @override
  String get settingsTaxIdFillInProfile => 'מלא ח.פ. בלשונית פרופיל החברה';

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
  String get planLogistics => 'לוגיסטיקה';

  @override
  String get planOps => 'תפעול';

  @override
  String get planFull => 'מלא';

  @override
  String get planCustom => 'מותאם אישית';

  @override
  String get planDescWarehouse => 'ניהול מלאי בלבד';

  @override
  String get planDescLogistics => 'לוגיסטיקה + דיספצ׳ר + דוחות (ללא מחסן)';

  @override
  String get planDescOps =>
      'מחסן + לוגיסטיקה + דיספצ׳ר + דוחות (ללא הנהלת חשבונות)';

  @override
  String get planDescFull => 'כל המודולים כולל הנהלת חשבונות ו-Greeninvoice';

  @override
  String get planDescCustom => 'תוכנית מותאמת';

  @override
  String get planAccountingNote =>
      'הנהלת חשבונות (חשבוניות, מע״מ, Greeninvoice) — רק בתוכנית «מלא». ללא תשלום נפרד למודול.';

  @override
  String get planBackupNote =>
      'DR ענן (Firestore Backup של Google): כלול ב«מלא»; בתוכניות אחרות — יומן ביקורת חינם, export ייעודי +₪149/חודש. חשבון Google משולם על ידי LogiRoute (~₪30–120/חודש לכל הפרויקט).';

  @override
  String billingDedicatedExportMonthly(int price) {
    return '+₪$price/חודש — export רבעוני ייעודי לחברה (אופציונלי)';
  }

  @override
  String get planModulesLabel => 'מודולים:';

  @override
  String get planCurrentBadge => 'תוכנית נוכחית';

  @override
  String get accountingProviderSection => 'אינטגרציית API מס';

  @override
  String get accountingProviderLabel => 'ספק';

  @override
  String get accountingProviderNone => 'מובנה (LogiRoute)';

  @override
  String get accountingProviderExport => 'ייצוא קובץ (CSV אחיד)';

  @override
  String get accountingProviderGreeninvoice => 'Greeninvoice / Morning';

  @override
  String get accountingProviderIcount => 'iCount';

  @override
  String get accountingProviderHint =>
      'ספק חיצוני מטפל בציות מס ובמספור מסמכים.';

  @override
  String get accountingProviderConfigure => 'הגדר אישורי API';

  @override
  String get accountingProviderConfigured => 'אישורים נשמרו';

  @override
  String get accountingProviderSaved => 'הגדרות אינטגרציה חשבונאית נשמרו';

  @override
  String get accountingProviderApiKey => 'מפתח API';

  @override
  String get accountingProviderSecret => 'מפתח סודי';

  @override
  String get accountingProviderToken => 'טוקן API';

  @override
  String get accountingProviderSandbox => 'מצב Sandbox';

  @override
  String get accountingProviderSandboxHint =>
      'שימוש ב-API בדיקות של Greeninvoice (sandbox.d.greeninvoice.co.il)';

  @override
  String get accountingProviderTest => 'בדיקת חיבור';

  @override
  String get accountingProviderTestOk => 'החיבור לספק הצליח';

  @override
  String accountingProviderTestFailed(String detail) {
    return 'בדיקת החיבור נכשלה: $detail';
  }

  @override
  String get accountingSyncTitle => 'סנכרון חשבונאות חיצוני';

  @override
  String get accountingSyncStatusSynced => 'סונכרן';

  @override
  String get accountingSyncStatusFailed => 'נכשל';

  @override
  String get accountingSyncStatusProcessing => 'מעבד';

  @override
  String get accountingSyncRetry => 'נסה שוב';

  @override
  String get accountingSyncRetryAllFailed => 'נסה שוב את כל השגויים';

  @override
  String get accountingSyncBackfillUnsynced => 'סנכרן מסמכים שלא הועלו';

  @override
  String accountingSyncBatchResult(
      int processed, int succeeded, int failed, int skipped) {
    return 'עובדו $processed: הצליחו $succeeded, נכשלו $failed, דולגו $skipped';
  }

  @override
  String get accountingSyncNoEntries =>
      'אין רשומות סנכרון — חשבוניות שהונפקו יופיעו כאן.';

  @override
  String get accountingSyncRetried => 'ניסיון סנכרון החל';

  @override
  String accountingSyncDistribution(String number) {
    return 'מספר הקצאה: $number';
  }

  @override
  String accountingExternalDocNumber(String number) {
    return 'מס׳ חיצוני: $number';
  }

  @override
  String get accountingSyncStatusPending => 'ממתין';

  @override
  String get accountingDocSyncColumn => 'סנכרון';

  @override
  String accountingExternalSyncFailedWith(String error) {
    return 'המסמך הונפק, הסנכרון נכשל: $error';
  }

  @override
  String get billingAddonsTitle => 'תוספות לפי שימוש';

  @override
  String billingExtraDriverMonthly(int price, int included) {
    return '+₪$price/חודש לכל נהג מעבר ל-$included הכלולים';
  }

  @override
  String billingExtraWarehouseMonthly(int price, int included) {
    return '+₪$price/חודש לכל מחסן/נקודה מעבר ל-$included הכלול';
  }

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
  String get importFileReadFailed =>
      'לא ניתן לקרוא את הקובץ בדפדפן. נסה שוב או דפדפן אחר.';

  @override
  String get importFileParseFailed =>
      'לא ניתן לנתח את קובץ האקסל. הורד תבנית מחדש ומלא את גיליון Clients.';

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
  String get exportLargeDatasetWarning =>
      'תיטען כל הקолקציה (עלול לקחת זמן ו-reads רבים). להמשיך?';

  @override
  String exportLargeDatasetNotice(int count) {
    return 'יוצאו $count רשומות — נפח גדול.';
  }

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
  String get mapColumnsDeliveryPoints => 'מיפוי עמודות — נקודות משלוח';

  @override
  String get importDeliveryPointsMenu => 'ייבוא נקודות משלוח';

  @override
  String get importDeliveryPointsTitle => 'ייבוא נקודות משלוח';

  @override
  String get loadDemoDataMenu => 'נתוני דמו לסרטון';

  @override
  String get loadDemoDataConfirm =>
      'לטעון תרחיש משלוח לדמו של סרטון מוצר (2 דקות)?';

  @override
  String get loadDemoDataReplaceWarning => 'נקודות דמו קיימות יוחלפו.';

  @override
  String loadDemoDataSuccess(int count) {
    return 'נתוני דמו נטענו ($count נקודות)';
  }

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
  String get registerLogiRouteCloudBackup => 'רשום גיבוי ענן LogiRoute';

  @override
  String get registerBackupOther => 'אחסון אחר…';

  @override
  String get backupCloudInfoTitle => 'גיבוי ענן';

  @override
  String get backupCloudInfoBody =>
      'נתוני LogiRoute נשמרים בענן Firebase (פרויקט logiroute-app). הכפתור למעלה — רישום ביומן ביקורת, לא שירות Google נפרד.';

  @override
  String get backupCloudPricingNote =>
      'תוכנית «מלא»: DR ענן כלול (LogiRoute משלם על גיבוי הפרויקט). תוכניות אחרות: יומן בלבד; export ייעודי — +₪149/חודש.';

  @override
  String get backupFirebaseLocationLabel => 'שם פרויקט Firebase';

  @override
  String get backupFirebaseHelper =>
      'ללקוחות LogiRoute בדרך כלל מספיק logiroute-app.';

  @override
  String get storageRecommended => '(מומלץ)';

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
  String get restoreDrillHint =>
      'Restore drill — בדיקת שחזור עם evidence. אסור success בלי הוכחה.';

  @override
  String get backupRecordHint => 'רשומת יומן = גיבוי בוצע. לא restore drill.';

  @override
  String get restoreDrillTargetEnvironment => 'פרויקט / סביבת יעד *';

  @override
  String get restoreDrillRestoredCollections => 'Collections ששוחזרו *';

  @override
  String get restoreDrillRestoredCollectionsHint =>
      'מופרד בפסיקים: invoices, clients, delivery_points';

  @override
  String get restoreDrillEvidenceNotes => 'Evidence (מה נבדק) *';

  @override
  String get restoreDrillDurationMinutes => 'משך (דקות) *';

  @override
  String get restoreDrillTestDate => 'תאריך drill *';

  @override
  String get restoreDrillResult => 'תוצאה *';

  @override
  String get restoreDrillResultSuccess => 'Success';

  @override
  String get restoreDrillResultFailed => 'Failed';

  @override
  String get restoreDrillIncomplete => 'מלא את כל שדות ה-evidence';

  @override
  String get restoreDrillEvidenceSuccessHint =>
      'ל-success — לפחות 40 תווים: מה שוחזר ואיך אומת.';

  @override
  String get registerRestoreDrill => 'רשום restore drill';

  @override
  String get registerRestoreDrillTitle => 'Restore drill (עם evidence)';

  @override
  String get labelVerifiedRestoreDrills => 'Drills מאומתים';

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
  String get paymentBankNumber => 'מספר בנק';

  @override
  String get paymentBranchNumber => 'מספר סניף';

  @override
  String get paymentAccountNumber => 'מספר חשבון';

  @override
  String get paymentChequeNumber => 'מספר המחאה';

  @override
  String get paymentDueDateLabel => 'תאריך פירעון';

  @override
  String get paymentClearingHouse => 'חברת סליקה';

  @override
  String get paymentClearingIsracard => 'ישראכרט';

  @override
  String get paymentClearingCal => 'כאל';

  @override
  String get paymentClearingDiners => 'דיינרס';

  @override
  String get paymentClearingAmex => 'אמריקן אקספרס';

  @override
  String get paymentClearingLeumi => 'לאומי כארד';

  @override
  String get paymentCardName => 'שם כרטיס';

  @override
  String get paymentDealType => 'סוג עסקה';

  @override
  String get paymentDealRegular => 'רגיל';

  @override
  String get paymentDealInstallments => 'תשלומים';

  @override
  String get paymentDealCredit => 'קרדיט';

  @override
  String get paymentInstallmentCount => 'מספר תשלומים';

  @override
  String get paymentBankRequired => 'נדרש מספר בנק';

  @override
  String get paymentBranchRequired => 'נדרש מספר סניף';

  @override
  String get paymentAccountRequired => 'נדרש מספר חשבון';

  @override
  String get paymentChequeRequired => 'נדרש מספר המחאה';

  @override
  String get paymentDueDateRequired => 'נדרש תאריך פירעון';

  @override
  String get paymentInstallmentRange => 'תשלומים: 2–36';

  @override
  String get dispatcherTaxInvoiceReceiptTitle => 'חשבונית מס/קבלה למפיץ';

  @override
  String get dispatcherTaxInvoiceReceiptHint =>
      'לאפשר למפיץ להוציא חשבונית מס/קבלה כשהתשלום מתקבל במסירה';

  @override
  String get createTaxInvoiceReceiptTitle => 'יצירת חשבונית מס/קבלה';

  @override
  String get createTaxInvoiceReceiptTooltip => 'חשבונית מס/קבלה (שולם)';

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
  String get clientKvLabel => 'לקוח';

  @override
  String get addressKvLabel => 'כתובת';

  @override
  String get driverKvLabel => 'נהג';

  @override
  String get truckKvLabel => 'משאית';

  @override
  String get deliveryDateKvLabel => 'תאריך אספקה';

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
  String driverAnotherRoutePoints(int count) {
    return 'מסלול נוסף: $count נקודות';
  }

  @override
  String wazeOpenError(String error) {
    return 'שגיאה בפתיחת Waze: $error';
  }

  @override
  String get wazeLaunchFailed => 'לא ניתן לפתוח את Waze';

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
  String get shiftRoutingSection => 'פרמטרי ניתוב';

  @override
  String get routingAvgSpeedKmh => 'מהירות ממוצעת (קמ\"ש)';

  @override
  String get routingServiceMinutes => 'זמן בנקודה (דק\')';

  @override
  String get routingDeliveryDayMode => 'תאריך אספקה בחשבונית';

  @override
  String get deliveryDaySame => 'היום';

  @override
  String get deliveryDayNext => 'מחר';

  @override
  String get deliveryDayNextWorking => 'יום עבודה הקרוב';

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

  @override
  String get shiftHolidaysTitle => 'ימי חג (GPS כבוי)';

  @override
  String get shiftLoadHolidays => 'טען חגים';

  @override
  String get shiftNoHolidays => 'אין ימי חג מוגדרים';

  @override
  String shiftHolidaysLoaded(int count) {
    return 'נטענו $count חגים';
  }

  @override
  String shiftHolidaysLoadError(String error) {
    return 'שגיאה בטעינת חגים: $error';
  }

  @override
  String get taskNoteLabel => 'משימה (ללא סחורה)';

  @override
  String get taskNoteHint => 'לאסוף צ׳ק, החזרה, וכו׳';

  @override
  String get adminActivityLog => 'יומן פעילות';

  @override
  String get appBarGroupReports => 'דוחות';

  @override
  String get appBarGroupWarehouse => 'מחסן';

  @override
  String get appBarGroupCompany => 'חברה';

  @override
  String get appBarGroupBilling => 'חיוב';

  @override
  String get appBarGroupPlatform => 'פלטפורמה';

  @override
  String get appBarGroupLogistics => 'לוגיסטיקה';

  @override
  String get appBarGroupArchive => 'ארכיון ונתונים';

  @override
  String get appBarGroupOperations => 'תפעול';

  @override
  String get appBarGroupImportExport => 'ייבוא וייצוא';

  @override
  String get appBarGroupHelp => 'עזרה';

  @override
  String get ownerNavOverview => 'סקירה';

  @override
  String get ownerNavManagement => 'ניהול';

  @override
  String get ownerNavOperations => 'תפעול';

  @override
  String get ownerNavCompliance => 'בקרה';

  @override
  String get period24h => '24 שעות';

  @override
  String get period48h => '48 שעות';

  @override
  String get periodWeek => 'שבוע';

  @override
  String get searchActivityHint => 'חיפוש משתמש או פעולה...';

  @override
  String get noActivityEvents => 'אין אירועים לתקופה שנבחרה';

  @override
  String get auditSourceLabel => 'ביקורת עסקית';

  @override
  String get accessSourceLabel => 'יומן גישה';

  @override
  String get accessEventLogin => 'כניסה';

  @override
  String get accessEventLogout => 'יציאה';

  @override
  String get accessEventViewDocument => 'צפייה במסמך';

  @override
  String get accessEventPrintDocument => 'הדפסת מסמך';

  @override
  String get accessEventExportData => 'ייצוא נתונים';

  @override
  String get accessEventCreateDocument => 'יצירת מסמך';

  @override
  String get accessEventCancelDocument => 'ביטול מסמך';

  @override
  String get accessEventViewAuditLog => 'צפייה ביומן ביקורת';

  @override
  String get accessEventViewReport => 'צפייה בדוח';

  @override
  String get accessEventAdminAction => 'פעולת מנהל';

  @override
  String get activityCsvUser => 'משתמש';

  @override
  String get activityCsvAction => 'פעולה';

  @override
  String get activityCsvWhen => 'מתי';

  @override
  String get activityCsvSource => 'מקור';

  @override
  String errorLoadingWithDetail(String error) {
    return 'שגיאה בטעינה: $error';
  }

  @override
  String errorWithDetail(String error) {
    return '❌ שגיאה: $error';
  }

  @override
  String get savedSuccessCheck => '✅ נשמר';

  @override
  String get pickDate => 'בחר';

  @override
  String get billingStatusSection => 'סטטוס חיוב';

  @override
  String get trialPeriodSection => 'תקופת ניסיון';

  @override
  String get trialPeriodDesc =>
      'כאשר billingStatus = trial, הגישה פגה לאחר תאריך זה.';

  @override
  String get notSet => 'לא הוגדר';

  @override
  String get paymentPaidUntilSection => 'תשלום — שולם עד';

  @override
  String get paymentPaidUntilDesc =>
      'מקור האמת לאוטומציית חיוב. לאחר תאריך זה → grace → suspended.';

  @override
  String get accountingPeriodLockSection => 'נעילת תקופה חשבונאית';

  @override
  String get accountingPeriodLockDesc =>
      'לא ניתן ליצור או לשנות מסמכים עם deliveryDate ≤ תאריך זה.';

  @override
  String get notSetAllPeriodsOpen => 'לא הוגדר (כל התקופות פתוחות)';

  @override
  String get unlockAllPeriods => 'פתח את כל התקופות';

  @override
  String get lockPreviousMonthEnd => 'סוף חודש קודם';

  @override
  String get computerizedWarehouseTitle => 'מחסן ממוחשב (ברקודים)';

  @override
  String get computerizedWarehouseEnabled => 'הפעל סריקת ברקוד';

  @override
  String get computerizedWarehouseHint =>
      'מוסיף סריקת ברקוד בתפריט המחסן. חיפוש לפי מק\"ט או ברקוד EAN על הפריט.';

  @override
  String get barcodeScanTitle => 'סריקת ברקוד';

  @override
  String get barcodeScanHint =>
      'סורק USB: מקד את השדה וסרוק. נייד: הקלד או הדבק.';

  @override
  String get barcodeScanFieldLabel => 'ברקוד / מק\"ט';

  @override
  String get barcodeScanIn => 'כניסה למלאי';

  @override
  String get barcodeScanOut => 'יציאה מהמלאי';

  @override
  String get barcodeScanApply => 'בצע';

  @override
  String get barcodeNotFound => 'פריט לא נמצא לברקוד זה';

  @override
  String get barcodeInsufficientStock => 'אין מספיק במלאי';

  @override
  String barcodeScanSuccess(String code, int qty) {
    return '$code: יתרה $qty יח\'';
  }

  @override
  String get barcodeEditTitle => 'עדכון ברקוד';

  @override
  String get barcodeDuplicateError => 'ברקוד זה כבר משויך לפריט אחר';

  @override
  String get barcodeUpdatedSuccess => 'ברקוד עודכן';

  @override
  String barcodeWithValue(String code) {
    return 'ברקוד: $code';
  }

  @override
  String get barcodeOptionalHelper =>
      'אופציונלי: EAN לסריקה (אפשר גם לפי מק\"ט)';

  @override
  String inventoryUpdatedLine(String date, String user) {
    return 'עודכן: $date ע\"י $user';
  }

  @override
  String get usersLoseAccessWarning =>
      '⚠️ משתמשים יאבדו את כל הגישה (קריאה וכתיבה חסומות)';

  @override
  String get trialExpiredBlocked => '⚠️ תקופת הניסיון פגה — הגישה חסומה';

  @override
  String get paymentExpiredWarning =>
      '⚠️ התשלום פג — billingEnforcer יעבור ל-grace/suspended';

  @override
  String get gracePeriodLabel => 'תקופת חסד:';

  @override
  String companyIdLabel(String id) {
    return 'חברה: $id';
  }

  @override
  String get locationNotReady => 'המיקום אינו מוכן';

  @override
  String get locationPermissionRequired => 'נדרשת הרשאת מיקום כדי להמשיך.';

  @override
  String get enableDeviceLocation => 'אנא הפעל מיקום במכשיר כדי להמשיך.';

  @override
  String get openSettings => 'פתח הגדרות';

  @override
  String get checkAgain => 'בדוק שוב';

  @override
  String get locationDeniedForever =>
      'ההרשאה נדחתה לצמיתות. פתח הגדרות אפליקציה.';

  @override
  String get pendingApprovalTitle => 'ממתין לאישור';

  @override
  String get pendingApprovalBody =>
      'ההרשמה התקבלה בהצלחה.\nמנהל המערכת ישייך אותך לחברה ויקצה לך תפקיד.';

  @override
  String get noWorkspaceTitle => 'אין מסך עבודה זמין';

  @override
  String get noWorkspaceBody => 'לתפקיד שלך אין מסך עבודה. פנה למנהל המערכת.';

  @override
  String get registerTitle => 'הרשמה ל-LogiRoute';

  @override
  String get registerSubtitle => 'צור חשבון וחברה — ניסיון 14 יום בחינם';

  @override
  String get registerOwnerSubtitle =>
      'תוך 2 דקות: חשבון בעלים + חברה + ניסיון 14 יום. אחר כך ייבוא לקוחות והשלמת הגדרה.';

  @override
  String get registerAlreadyProvisioned =>
      'לחשבון זה כבר יש חברה. התחבר או פנה לתמיכה.';

  @override
  String get registerResumeTitle => 'המשך הרשמה';

  @override
  String get registerResumeSubtitle =>
      'החשבון נוצר — הזן פרטי חברה כדי לסיים את ההרשמה.';

  @override
  String get registerContinueButton => 'צור חברה';

  @override
  String get phoneOptional => 'טלפון (אופציונלי)';

  @override
  String get registerButton => 'הרשמה';

  @override
  String get alreadyHaveAccountLogin => 'כבר יש לי חשבון — התחברות';

  @override
  String get minSixCharacters => 'מינימום 6 תווים';

  @override
  String get invalidEmailShort => 'אימייל לא תקין';

  @override
  String get creditNoteCreatedSuccess => 'תעודת זיכוי נוצרה בהצלחה';

  @override
  String get originalDocumentLabel => 'מסמך מקורי';

  @override
  String get correctionTypeLabel => 'סוג תיקון';

  @override
  String get fullCorrectionTitle => 'תיקון מלא';

  @override
  String get fullCorrectionSubtitle => 'כל השורות מהמסמך המקורי';

  @override
  String get partialCorrectionTitle => 'תיקון חלקי';

  @override
  String get partialCorrectionSubtitle => 'עריכה/הסרה של שורות';

  @override
  String get correctionLinesTitle => 'שורות זיכוי';

  @override
  String get correctionSummaryTitle => 'סיכום זיכוי';

  @override
  String get correctionReasonLabel => 'סיבת תיקון *';

  @override
  String descriptionIndex(int index) {
    return 'תיאור $index';
  }

  @override
  String get importNoCompanySelected => 'שגיאה: לא נבחרה חברה';

  @override
  String get importBack => 'חזרה';

  @override
  String get importClose => 'סגור';

  @override
  String importCount(int count) {
    return 'ייבוא ($count)';
  }

  @override
  String get noBusinessTypesAvailable => 'אין סוגי עסק זמינים';

  @override
  String get noTemplatesForBusinessType => 'אין תבניות זמינות לסוג עסק זה';

  @override
  String get importingProductsWait => 'מייבא מוצרים, אנא המתן...';

  @override
  String get loadingDocument => 'טוען מסמך...';

  @override
  String get documentNotFound => 'מסמך לא נמצא';

  @override
  String get goBack => 'חזרה';

  @override
  String get itemsTitle => 'פריטים';

  @override
  String get skuColumn => 'מק\"ט';

  @override
  String get typeColumn => 'סוג';

  @override
  String get numberColumn => 'מספר';

  @override
  String get quantityColumn => 'כמות';

  @override
  String get priceColumn => 'מחיר';

  @override
  String get totalColumn => 'סה\"כ';

  @override
  String get cancellationDetailsTitle => 'פרטי ביטול';

  @override
  String docIdLabel(String id) {
    return 'מזהה מסמך: $id';
  }

  @override
  String documentTypeUnsupported(String collection) {
    return 'פתיחת מסמך מסוג $collection עדיין לא נתמכת';
  }

  @override
  String get linkCopiedToClipboard => 'קישור הועתק ללוח';

  @override
  String get saveProfileTitle => 'שמור פרופיל';

  @override
  String get profileNameLabel => 'שם הפרופיל';

  @override
  String profileSaved(String name) {
    return 'פרופיל \"$name\" נשמר';
  }

  @override
  String get accountingExportTitle => 'ייצוא להנהלת חשבונות';

  @override
  String get downloadBkmv => 'הורד BKMV';

  @override
  String get bkmvExportSubtitle =>
      'קובץ ZIP OPENFRMT (INI.TXT + BKMVDATA.TXT) לרשות המסים';

  @override
  String get bkmvTaxIdRequired => 'נדרש מספר עוסק (ח.פ) לייצוא BKMV';

  @override
  String get bkmvExportEmpty => 'אין מסמכים בתקופה שנבחרה';

  @override
  String get bkmvSimulatorFailedTitle => 'בדיקת OPENFRMT נכשלה';

  @override
  String get bkmvSimulatorFailedBody =>
      'הקובץ לא הורד. תקן את השגיאות ונסה שוב.';

  @override
  String get bkmvSimulatorPassed => 'עבר בדיקה מקומית לרשות המסים';

  @override
  String get bkmvSimulatorWarnings => 'אזהרות';

  @override
  String get bkmvSoftwareRegistrationLabel => 'מספר רישום תוכנה (BKMV)';

  @override
  String get bkmvSoftwareRegistrationHint => '8 ספרות מרשות המסים — שדה A100';

  @override
  String get targetSoftwareLabel => 'תוכנת יעד';

  @override
  String get periodSection => 'תקופה';

  @override
  String get untilLabel => 'עד';

  @override
  String get documentTypeSection => 'סוג מסמך';

  @override
  String get fileSettingsSection => 'הגדרות קובץ';

  @override
  String get separatorLabel => 'מפריד';

  @override
  String get encodingSection => 'קידוד';

  @override
  String exportErrorWithDetail(String error) {
    return 'שגיאה בייצוא: $error';
  }

  @override
  String get lastCheckResult => 'תוצאת בדיקה אחרונה';

  @override
  String get noPreviousChecks => 'אין בדיקות קודמות. לחץ ▶ להפעלת בדיקה.';

  @override
  String get gapsLabel => 'פערים';

  @override
  String get quantityCannotBeNegative => 'כמות לא יכולה להיות שלילית';

  @override
  String get quantityMustBePositive => 'יש להזין כמות גדולה מ-0';

  @override
  String get excelExportWebOnly => 'ייצוא Excel זמין רק בגרסת האינטרנט';

  @override
  String exportErrorDetail(String error) {
    return '❌ שגיאת ייצוא: $error';
  }

  @override
  String get productCodeRequired => 'מק\"ט *';

  @override
  String get typeRequired => 'סוג *';

  @override
  String get numberRequired => 'מספר *';

  @override
  String get volumeMlOptional => 'נפח במ\"ל (אופציונלי)';

  @override
  String get quantityOnPalletRequired => 'כמות במשטח *';

  @override
  String get diameterOptional => 'קוטר (אופציונלי)';

  @override
  String get packedCartonOptional => 'ארוז - כמות בקרטון (אופציונלי)';

  @override
  String get additionalInfoOptional => 'מידע נוסף (אופציונלי)';

  @override
  String get hashbonitUnderConstruction => 'חשבונית בבנייה';

  @override
  String errorSavingWithDetail(String error) {
    return 'שגיאה בשמירה: $error';
  }

  @override
  String get testEmailSent => '✅ אימייל בדיקה נשלח';

  @override
  String get testWhatsAppSent => '✅ WhatsApp בדיקה נשלח';

  @override
  String testFailedWithDetail(String error) {
    return '❌ הבדיקה נכשלה: $error';
  }

  @override
  String get paperSize80mmReceipt => '80מ\"מ (קבלה)';

  @override
  String get noDocumentId => 'אין מזהה מסמך';

  @override
  String get urgencyVeryUrgent => 'דחוף מאוד';

  @override
  String get priorityLabel => 'עדיפות';

  @override
  String get orderInRouteLabel => 'סדר במסלול';

  @override
  String get newCategoryRequired => 'קטגוריה חדשה *';

  @override
  String get cancellationReasonRequired => 'סיבת ביטול (חובה)';

  @override
  String get searchBoxTypesHint => 'חיפוש לפי מק\"ט / סוג / מספר';

  @override
  String get loginTimeout => 'פג זמן התחברות (20 שניות)';

  @override
  String errorWithMessage(String error) {
    return 'שגיאה: $error';
  }

  @override
  String get retentionPolicyInfo =>
      'לפי חוק ניהול ספרים, יש לשמור מסמכים לפחות 7 שנים.\nהבדיקה מוודאת שלא נמחקו מסמכים ושאין פערים במספור.';

  @override
  String get podRetentionInfo =>
      'תמונות אישור מסירה (PoD) נשמרות 90 יום ולאחר מכן נמחקות אוטומטית. קואורדינטות GPS ושעת המסירה נשמרות.';

  @override
  String oldestDocumentDate(String date) {
    return 'מסמך ישן ביותר: $date';
  }

  @override
  String retentionCutoffDate(String date) {
    return 'תאריך חיתוך: $date';
  }

  @override
  String retentionGapsCount(int actual, int expected) {
    return 'פערים: $actual מתוך $expected צפויים';
  }

  @override
  String retentionHistoryEntry(String user, int count) {
    return '$user • $count מסמכים';
  }

  @override
  String retentionDocumentsCount(int count) {
    return 'מסמכים: $count';
  }

  @override
  String get issuesFound => 'בעיות נמצאו';

  @override
  String get exportFormatHashavshevet => 'חשבשבת';

  @override
  String get exportFormatHashavshevetDesc =>
      'קובץ טקסט עם טאבים — תואם לייבוא חשבשבת';

  @override
  String get exportFormatPriority => 'Priority ERP';

  @override
  String get exportFormatPriorityDesc => 'קובץ CSV תואם לייבוא Priority';

  @override
  String get exportFormatCsv => 'CSV אוניברסלי';

  @override
  String get exportFormatCsvDesc => 'קובץ CSV אוניברסלי — מתאים לכל תוכנה';

  @override
  String get encodingUtf8Bom => 'UTF-8 + BOM (מומלץ לאקסל)';

  @override
  String get encodingUtf8 => 'UTF-8 (ללא BOM)';

  @override
  String get encodingWindows1255 => 'Windows-1255 (חשבשבת ישן)';

  @override
  String get separatorComma => 'פסיק (,)';

  @override
  String get separatorSemicolon => 'נקודה-פסיק (;)';

  @override
  String get separatorTab => 'טאב';

  @override
  String get hashavshevetEncodingHint =>
      'לגרסאות ישנות של חשבשבת — בחר Windows-1255';

  @override
  String get exportCompleteTitle => 'ייצוא הושלם';

  @override
  String exportRecordsCount(int count, String fileName) {
    return 'ייצוא הושלם — $count רשומות ($fileName)';
  }

  @override
  String fileLabel(String name) {
    return 'קובץ: $name';
  }

  @override
  String recordsLabel(int count) {
    return 'רשומות: $count';
  }

  @override
  String formatLabel(String name) {
    return 'פורמט: $name';
  }

  @override
  String get downloadFileBtn => 'הורד קובץ';

  @override
  String get exportAction => 'ייצוא';

  @override
  String get loginRequiredFirst => 'יש להתחבר למערכת תחילה';

  @override
  String documentNotFoundAtPath(String path) {
    return 'מסמך לא נמצא בנתיב: $path';
  }

  @override
  String get documentNotFoundOrNoAccess => 'המסמך לא נמצא או שאין גישה';

  @override
  String companyLabelColon(String name) {
    return 'חברה: $name';
  }

  @override
  String get documentNumberLabel => 'מספר מסמך';

  @override
  String get createdAtLabel => 'נוצר';

  @override
  String get createdByLabel => 'נוצר על ידי';

  @override
  String get assignmentNumberLabel => 'מספר הקצאה';

  @override
  String get cancelledByLabel => 'בוטל על ידי';

  @override
  String get cancellationDateLabel => 'תאריך ביטול';

  @override
  String get totalBeforeDiscountLabel => 'סה\"כ לפני הנחה';

  @override
  String discountPercentLabel(int percent) {
    return 'הנחה ($percent%)';
  }

  @override
  String get vat18Label => 'מע\"מ (18%)';

  @override
  String get invoiceManagementTitle => 'ניהול חשבוניות';

  @override
  String errorLoadingInvoices(String error) {
    return '❌ שגיאה בטעינת חשבוניות: $error';
  }

  @override
  String assignmentNumberReceived(String number) {
    return '✅ מספר הקצאה התקבל: $number';
  }

  @override
  String assignmentRequestError(String error) {
    return '❌ שגיאה בבקשת הקצאה: $error';
  }

  @override
  String get standaloneInvoiceInDev => '⚠️ יצירת חשבונית עצמאית בפיתוח';

  @override
  String receiptPeriodLockedError(String docDate, String lockDate) {
    return '🔒 לא ניתן ליצור קבלה — תאריך המסמך ($docDate) נמצא בתקופה חשבונאית סגורה (עד $lockDate)';
  }

  @override
  String get receiptCreatedAndPrinted => '✅ קבלה נוצרה והודפסה';

  @override
  String receiptCreateError(String error) {
    return '❌ שגיאה ביצירת קבלה: $error';
  }

  @override
  String get receiptIssuanceError => 'שגיאה בהנפקת קבלה מהשרת';

  @override
  String get invoicePrintedSuccess => '✅ חשבונית הודפסה';

  @override
  String get cancelInvoiceTitle => 'ביטול חשבונית';

  @override
  String cancelInvoiceConfirm(String clientName) {
    return 'האם לבטל חשבונית עבור $clientName?';
  }

  @override
  String get cancelInvoiceLawNote =>
      'לפי חוק ניהול ספרים, חשבונית לא ניתן למחוק, רק לבטל.';

  @override
  String get enterCancellationReason => 'נא להזין סיבת ביטול';

  @override
  String get cancelInvoiceButton => 'בטל חשבונית';

  @override
  String get invoiceCancelledSuccess => '✅ חשבונית בוטלה';

  @override
  String cancelInvoiceError(String error) {
    return '❌ שגיאה בביטול: $error';
  }

  @override
  String get deliveryNoteShort => 'ת. משלוח';

  @override
  String get taxInvoiceReceiptShort => 'חשבונית מס/קבלה';

  @override
  String get originalPrintedLabel => 'מקור הודפס';

  @override
  String copiesCountLabel(int count) {
    return 'עותקים: $count';
  }

  @override
  String assignmentApprovedLabel(String number) {
    return 'הקצאה: $number';
  }

  @override
  String get assignmentPendingLabel => 'ממתין להקצאה';

  @override
  String get assignmentRejectedLabel => 'הקצאה נדחתה';

  @override
  String get assignmentErrorLabel => 'שגיאת הקצאה';

  @override
  String get assignmentRequiredLabel => 'נדרש הקצאה';

  @override
  String get historyTooltip => 'היסטוריה';

  @override
  String get reprintTooltip => 'הדפס מחדש';

  @override
  String get createReceiptTooltip => 'צור קבלה';

  @override
  String get cancelInvoiceTooltip => 'בטל חשבונית';

  @override
  String get retryAssignmentTooltip => 'ניסיון חוזר להקצאה';

  @override
  String invoiceNumberTitle(int number) {
    return 'חשבונית #$number';
  }

  @override
  String driverWithName(String name) {
    return 'נהג: $name';
  }

  @override
  String deliveryDateWithValue(String date) {
    return 'תאריך אספקה: $date';
  }

  @override
  String totalWithAmount(String amount) {
    return 'סה\"כ: ₪$amount';
  }

  @override
  String get newInvoiceButton => 'חשבונית חדשה';

  @override
  String get reprintDialogTitle => 'הדפסה חוזרת';

  @override
  String get copyTypeLabel => 'העתק';

  @override
  String copyNumberLabel(int number) {
    return 'עותק מספר $number';
  }

  @override
  String get trueToOriginalLabel => 'נאמן למקור';

  @override
  String get replacesOriginalLabel => 'מחליף את המקור';

  @override
  String printCopiesButton(int count) {
    return 'הדפס $count עותקים';
  }

  @override
  String get createReceiptTitle => 'יצירת קבלה';

  @override
  String receiptForInvoice(int number) {
    return 'קבלה עבור חשבונית #$number';
  }

  @override
  String clientWithName(String name) {
    return 'לקוח: $name';
  }

  @override
  String amountWithValue(String amount) {
    return 'סכום: ₪$amount';
  }

  @override
  String get createReceiptButton => 'צור קבלה';

  @override
  String get addBoxTypeButton => 'הוסף סוג קופסה';

  @override
  String inStockCount(int count) {
    return 'במלאי: $count יח\'';
  }

  @override
  String onPalletCount(String count) {
    return 'במשטח: $count';
  }

  @override
  String volumeWithUnit(String value) {
    return 'נפח: $value מ\"ל';
  }

  @override
  String get setupWizardTitle => 'הגדרת חברה';

  @override
  String get setupWizardContinueLater => 'המשך מאוחר יותר';

  @override
  String get setupWizardBannerTitle => 'השלימו הגדרת חברה ראשונית';

  @override
  String get setupWizardBannerAction => 'פתח אשף הגדרה';

  @override
  String setupWizardProgress(int current, int total) {
    return 'שלב $current מתוך $total';
  }

  @override
  String get setupWizardOpenStep => 'פתח';

  @override
  String get setupWizardMarkComplete => 'סמן כהושלם';

  @override
  String get setupWizardSkip => 'דלג';

  @override
  String get setupWizardReadyTitle => 'החברה מוכנה לעבודה.';

  @override
  String get setupWizardReadyBody =>
      'כל השלבים הנדרשים הושלמו. אפשר להתחיל עבודה יומית.';

  @override
  String get setupWizardStatusNotStarted => 'לא התחיל';

  @override
  String get setupWizardStatusInProgress => 'בתהליך';

  @override
  String get setupWizardStatusCompleted => 'הושלם';

  @override
  String get setupWizardStatusSkipped => 'דולג';

  @override
  String get setupWizardStepCompanyInfo => 'פרטי חברה';

  @override
  String get setupWizardStepImportClients => 'ייבוא לקוחות';

  @override
  String get setupWizardStepImportProducts => 'ייבוא מוצרים';

  @override
  String get setupWizardStepAddDrivers => 'הוספת נהגים';

  @override
  String get setupWizardStepWarehouse => 'הגדרת מחסן';

  @override
  String get setupWizardStepAccounting => 'הגדרת חשבונאות';

  @override
  String get setupWizardStepGps => 'בדיקת GPS נהג';

  @override
  String get setupWizardStepFirstRoute => 'מסלול ראשון';

  @override
  String get setupWizardStepTestDelivery => 'משלוח בדיקה';

  @override
  String get setupWizardStepReady => 'המערכת מוכנה';

  @override
  String get setupWizardHintCompanyInfo => 'מלאו שם, ח.פ, כתובת ופרטי קשר.';

  @override
  String get setupWizardHintImportClients => 'ייבוא Excel או הוספה ידנית.';

  @override
  String get setupWizardHintImportProducts =>
      'ייבוא מק\"ט (ניתן לדלג בלי מחסן).';

  @override
  String get setupWizardHintAddDrivers => 'צרו לפחות נהג אחד עם קיבולת משאית.';

  @override
  String get setupWizardHintWarehouse =>
      'שאלון: יחידות, קרטונים, משטחים — לפי המחסן שלכם.';

  @override
  String get warehouseQuestionnaireTitle => 'הגדרת מחסן';

  @override
  String get warehouseQuestionnaireSubtitle =>
      'יחידות, קרטונים, משטחים — שאלון למחסן שלכם';

  @override
  String get warehouseQuestionnaireSaved => 'פרופיל המחסן נשמר';

  @override
  String get warehouseQuestionUnitTitle => 'איך אתם שולחים סחורה?';

  @override
  String get warehouseQuestionUnitHint =>
      'מעורב — אם חלק מהמק\"ט בקרטון וחלק ביחידות.';

  @override
  String get warehouseUnitLoose => 'יחידות בלבד';

  @override
  String get warehouseUnitLooseHint => 'בלי קרטונים — משקל, ליטר, יחידות';

  @override
  String get warehouseUnitBoxed => 'רק בקרטונים';

  @override
  String get warehouseUnitBoxedHint => 'תמיד אריזה / קרטון';

  @override
  String get warehouseUnitBoth => 'גם וגם';

  @override
  String get warehouseUnitBothHint => 'מוצרים שונים — אריזה שונה';

  @override
  String get warehouseQuestionPalletTitle => 'קרטונים על משטחים?';

  @override
  String get warehouseQuestionPalletHint =>
      'מעורב — אם רק חלק מהמק\"ט על משטחים.';

  @override
  String get warehousePalletNone => 'בלי משטחים';

  @override
  String get warehousePalletNoneHint => 'רק קרטונים או יחידות';

  @override
  String get warehousePalletAlways => 'תמיד על משטחים';

  @override
  String get warehousePalletAlwaysHint => 'לוגיסטיקת משטחים סטандартית';

  @override
  String get warehousePalletBoth => 'מעורב';

  @override
  String get warehousePalletBothHint => 'חלק על משטחים, חלק לא';

  @override
  String get warehouseLooseNoPallets =>
      'לשילוח יחידות בדרך כלל לא צריך משטחים.';

  @override
  String get warehouseQuestionDefaultsTitle => 'ערכי ברירת מחדל (אופציונלי)';

  @override
  String get warehouseQuestionDefaultsHint =>
      'לא לכל 100 המק\"טים. רק ממלא טופס «הוסף מוצר». לכל מק\"ט — יחידות/קרטון וקרטונים/משטח משלו (ידני או Excel).';

  @override
  String get warehouseDefaultUnitsPerBox => 'יחידות בקרטון — רמז למק\"ט חדש';

  @override
  String get warehouseDefaultBoxesPerPallet =>
      'קרטונים על משטח — רמז למק\"ט חדש';

  @override
  String get setupWizardHintAccounting => 'בחרו ספק חשבונאות או export.';

  @override
  String get setupWizardHintGps => 'הנהג מפעיל GPS; הדיספצ\'ר רואה על המפה.';

  @override
  String get setupWizardHintFirstRoute => 'צרו מסלול והקצו נהג בממשק דיספצ\'ר.';

  @override
  String get setupWizardHintTestDelivery => 'סגרו נקודה אחת באפליקציית נהג.';

  @override
  String get setupWizardHintReady => 'ההגדרה הושלמה — אפשר לעבוד.';

  @override
  String get onboardingSection => 'מרכז השקה';

  @override
  String get onboardingCenterTitle => 'מרכז השקה';

  @override
  String get onboardingCenterSubtitle =>
      'השלימו משימות בכל סדר. ההתקדמות מסתנכרנת מהנתונים אוטומטית.';

  @override
  String get onboardingCenterOpenWizard => 'אשף שלב-אחר-שלב';

  @override
  String get onboardingCenterRefresh => 'רענון סטטוס';

  @override
  String get onboardingCenterAutoDetected => 'זוהה אוטומטית';

  @override
  String get onboardingCenterNextStep => 'המשימה המומלצת';

  @override
  String onboardingCenterCompletedSteps(int done, int total) {
    return '$done מתוך $total משימות';
  }

  @override
  String onboardingCenterEstimatedTime(int minutes) {
    return 'נותרו ~$minutes דק\'';
  }

  @override
  String get onboardingCenterAlmostReadyTitle => 'החברה כמעט מוכנה';

  @override
  String get onboardingCenterAlmostReadyBody =>
      'משימות החובה הושלמו. סיימו אופציונליות והשלימו Go Live.';

  @override
  String get onboardingCenterCanStartTitle => 'אפשר להתחיל לעבוד';

  @override
  String get onboardingCenterCanStartBody =>
      'השקה הושלמה — עברו לעבודה יומיומית מלוח הבעלים.';

  @override
  String get launchCenterCardCompanyDetails => 'פרטי חברה';

  @override
  String get launchCenterCardFirstOwnerAdmin => 'בעלים/מנהל ראשון';

  @override
  String get launchCenterCardClients => 'לקוחות';

  @override
  String get launchCenterCardProducts => 'מוצרים / מק\"ט';

  @override
  String get launchCenterCardDrivers => 'נהגים';

  @override
  String get launchCenterCardWarehouse => 'מחסן';

  @override
  String get launchCenterCardAccounting => 'הנהלת חשבונות';

  @override
  String get launchCenterCardGps => 'GPS';

  @override
  String get launchCenterCardFirstRoute => 'מסלול ראשון';

  @override
  String get launchCenterCardTestDelivery => 'משלוח בדיקה';

  @override
  String get launchCenterCardGoLive => 'Go Live';

  @override
  String get launchCenterHintCompanyDetails => 'שם, ח.פ. ופרופיל חברה.';

  @override
  String get launchCenterHintFirstOwnerAdmin => 'לפחות בעלים או מנהל אחד.';

  @override
  String get launchCenterHintClients => 'ייבוא או הוספת לקוחות.';

  @override
  String get launchCenterHintProducts => 'ייבוא או הגדרת סוגי מוצר / מק\"ט.';

  @override
  String get launchCenterHintDrivers => 'הוסיפו נהגים למסלולים.';

  @override
  String get launchCenterHintWarehouse => 'מבנה מחסן ומלאי.';

  @override
  String get launchCenterHintAccounting => 'ספק חשבונאות או חשבונית ראשונה.';

  @override
  String get launchCenterHintGps => 'נהג שולח GPS — דיספצ\'ר רואה במפה.';

  @override
  String get launchCenterHintFirstRoute => 'צרו מסלול והקצו נהג.';

  @override
  String get launchCenterHintTestDelivery => 'סגרו משלוח אחד באפליקציית נהג.';

  @override
  String get launchCenterHintGoLive => 'אשרו מוכנות לעבודה יומיומית.';

  @override
  String get launchCenterRequired => 'חובה';

  @override
  String get launchCenterOptional => 'אופציונלי';

  @override
  String get launchCenterAssign => 'הקצאה';

  @override
  String get launchCenterAssignCard => 'הקצאת משימה';

  @override
  String get launchCenterAssignee => 'ממונה';

  @override
  String get launchCenterUnassigned => 'לא מוקצה';

  @override
  String get launchCenterNotes => 'הערות';

  @override
  String launchCenterEstimatedMin(int minutes) {
    return '~$minutes דק\'';
  }

  @override
  String get launchCenterCompanyReady => 'החברה מוכנה';

  @override
  String get launchCenterCompanyReadyTitle => 'החברה מוכנה';

  @override
  String get launchCenterCompanyReadyBody =>
      'כל משימות החובה הושלמו. השלימו Go Live כשמוכנים.';

  @override
  String get launchCenterModeSelfSetup => 'Self Setup';

  @override
  String get launchCenterModeDoneForYou => 'Done for you';

  @override
  String get onboardingSectionCompanySetup => 'הגדרת חברה';

  @override
  String get onboardingSectionImportStatus => 'סטטוס ייבוא';

  @override
  String get onboardingSectionDrivers => 'נהגים';

  @override
  String get onboardingSectionWarehouse => 'מחסן';

  @override
  String get onboardingSectionAccounting => 'הנהלת חשבונות';

  @override
  String get onboardingSectionGps => 'GPS';

  @override
  String get onboardingSectionFirstRoute => 'מסלול ראשון';

  @override
  String get onboardingSectionTestDelivery => 'משלוח בדיקה';

  @override
  String get onboardingSectionGoLive => 'Go Live';

  @override
  String get healthStripCompany => 'חברה';

  @override
  String get healthStripBilling => 'חיוב';

  @override
  String get healthStripFirestore => 'Firestore';

  @override
  String get healthStripRoutes => 'מסלולים';

  @override
  String healthStripRoutesActive(int count) {
    return '$count פעילים';
  }

  @override
  String get healthStripFcm => 'FCM';

  @override
  String get healthStripAccounting => 'הנהלת חשבונות';

  @override
  String get healthStripAccountingSyncFailed => 'סנכרון נכשל';

  @override
  String get healthStripLastError => 'שגיאה אחרונה';

  @override
  String get healthStripSetup => 'Setup';

  @override
  String get healthStripGps => 'GPS';

  @override
  String get healthStripInvoices => 'חשבוניות';

  @override
  String get healthStripWarehouse => 'מחסן';

  @override
  String get healthStripDrivers => 'נהגים';

  @override
  String get healthStripLastSync => 'סנכרון';

  @override
  String get healthStripProblems => 'בעיות';

  @override
  String get healthStripOk => 'OK';

  @override
  String get healthStripWarn => 'WARN';

  @override
  String get healthStripFail => 'FAIL';

  @override
  String get healthStripJustNow => 'עכשיו';

  @override
  String healthStripMinutesAgo(int minutes) {
    return 'לפני $minutes דק\'';
  }

  @override
  String healthStripHoursAgo(int hours) {
    return 'לפני $hours ש\'';
  }

  @override
  String get customerHealthCompanyId => 'מזהה חברה';

  @override
  String get customerHealthLoadMore => 'טען עוד';

  @override
  String get customerHealthDashboardTitle => 'בריאות לקוחות';

  @override
  String get customerHealthStatus => 'Health';

  @override
  String get customerHealthHealthy => 'Healthy';

  @override
  String get customerHealthWarning => 'Warning';

  @override
  String get customerHealthCritical => 'Critical';

  @override
  String get customerHealthUnknown => 'Unknown';

  @override
  String get customerHealthFilterAll => 'הכל';

  @override
  String get customerHealthFilterDemo => 'Demo';

  @override
  String get customerHealthFailedSync => 'Sync נכשל';

  @override
  String get customerHealthStaleGps => 'GPS ישן';

  @override
  String get customerHealthLastActivity => 'פעילות אחרונה';

  @override
  String get customerHealthDemoBadge => 'Demo';

  @override
  String get customerHealthNoRows => 'אין חברות לפי הסינון';

  @override
  String get customerHealthOpenSupport => 'Support Console';

  @override
  String get customerHealthSwitchCompany => 'החלף חברה';

  @override
  String get demoCompanyTitle => 'חברת דמו';

  @override
  String get demoCompanySuperAdminOnly => 'super_admin בלבד';

  @override
  String get demoCompanyDesc =>
      'Demo Foods Israel — נתוני דמו למכירות. כל הרשומות עם isDemo. מזהה: demo-foods-israel.';

  @override
  String get demoCompanyCreate => 'צור חברת דמו';

  @override
  String get demoCompanyResetAction => 'איפוס ויצירה מחדש';

  @override
  String get demoCompanyResetTitle => 'איפוס נתוני דמו';

  @override
  String get demoCompanyResetConfirm =>
      'למחוק demo-foods-israel וליצור מחדש? חברות אמיתיות לא יושפעו.';

  @override
  String get demoCompanySuccess => 'חברת הדמו מוכנה';

  @override
  String get demoCompanyCredentialsTitle => 'התחברות (בדויים)';

  @override
  String get demoCompanyCredOwner => 'Owner';

  @override
  String get demoCompanyCredDispatcher => 'Dispatcher';

  @override
  String get demoCompanyCredDriver => 'נהג 1';

  @override
  String demoCompanyLastSeed(int clients, int products) {
    return 'נטענו: $clients לקוחות, $products מק\"ט';
  }

  @override
  String get demoCompanyPasswordHint =>
      'סיסמת דמו מוגדרת ב-env / הגדרה מקומית בלבד.';

  @override
  String get demoCompanyResetPreviewTitle => 'תצוגה מקדימה לאיפוס';

  @override
  String demoCompanyResetPreviewBody(int deletable, int blocked) {
    return 'יימחקו $deletable מסמכים. חסומים (ללא isDemo): $blocked. להמשיך?';
  }

  @override
  String demoCompanyResetBlocked(int blocked) {
    return 'איפוס חסום: $blocked מסמכים ללא isDemo.';
  }

  @override
  String get supportDiagQuickActions => 'פעולות מהירות';

  @override
  String get supportDiagOpenAsOwner => 'פתח כ-owner';

  @override
  String get supportDiagOpenAsDispatcher => 'פתח כ-dispatcher';

  @override
  String get supportDiagSetupNext => 'שלב חובה הבא';

  @override
  String get supportDiagUsersDrivers => 'משתמשים / נהגים';

  @override
  String get supportDiagTotalUsers => 'סה״כ משתמשים';

  @override
  String get supportDiagActiveDrivers => 'נהגים פעילים (היום)';

  @override
  String get supportDiagActiveRoutes => 'מסלולים פעילים';

  @override
  String get supportDiagPendingPoints => 'נקודות ממתינות';

  @override
  String get supportDiagCompletedToday => 'הושלמו היום';

  @override
  String get supportDiagCancelledPoints => 'בוטלו / חסומות';

  @override
  String get supportDiagSyncStatus => 'סטטוס sync אחרון';

  @override
  String get supportDiagNotifications => 'התראות';

  @override
  String get supportDiagLastPush => 'לוג push אחרון';

  @override
  String get supportDiagLastEmail => 'לוג email אחרון';

  @override
  String get supportDiagRecentErrors => 'שגיאות אחרונות';

  @override
  String get supportDiagFilterCorrelation => 'סינון לפי correlationId';

  @override
  String get supportDiagLastPayment => 'תשלום מוצלח אחרון';

  @override
  String get supportDiagFailedPayment => 'תשלום כושל אחרון';

  @override
  String get supportDiagLoadedAt => 'נטען';

  @override
  String get usageSummaryTitle => 'Usage (פיילוט)';

  @override
  String get usageSummaryDays7 => '7 ימים';

  @override
  String get usageSummaryDays30 => '30 ימים';

  @override
  String get usageSummaryActiveUsers => 'משתמשים פעילים';

  @override
  String get usageSummaryTotalEvents => 'סה״כ אירועים';

  @override
  String get usageSummaryLastEvent => 'אירוע אחרון';

  @override
  String get usageSummaryNoEvents => 'אין אירועים בתקופה';

  @override
  String get usageSummaryOwnerOnly => 'owner / admin / super_admin בלבד';

  @override
  String usageSummarySampleNote(int sampleSize) {
    return 'משתמשים פעילים — לפי $sampleSize אירועים אחרונים (limit)';
  }

  @override
  String get driverSessionBlockedTitle => 'הנהג כבר פעיל במכשיר אחר';

  @override
  String get driverSessionBlockedSubtitle => 'עבודה במסלול חסומה במכשיר זה.';

  @override
  String driverSessionBlockedDevice(String label) {
    return 'מכשיר פעיל: $label';
  }

  @override
  String get driverSessionTakeoverButton => 'עבור למכשיר זה';

  @override
  String get driverSessionLostTitle => 'הסשן הועבר למכשיר אחר';

  @override
  String get driverSessionLostSubtitle => 'מעקב GPS והמסלול הופסקו במכשיר זה.';

  @override
  String get driverSessionLostAcknowledge => 'הבנתי';

  @override
  String driverSessionActiveDevice(String label) {
    return 'מכשיר פעיל: $label';
  }

  @override
  String get importWizardTitle => 'אשף ייבוא';

  @override
  String get importWizardStepType => 'סוג נתונים';

  @override
  String get importWizardStepFile => 'קובץ';

  @override
  String get importWizardStepHeaders => 'כותרות';

  @override
  String get importWizardStepMapping => 'מיפוי';

  @override
  String get importWizardStepPreview => 'תצוגה מקדימה';

  @override
  String get importWizardStepImport => 'ייבוא';

  @override
  String get importWizardStepResult => 'תוצאה';

  @override
  String get importWizardConfidence => '%';

  @override
  String get importWizardSaveTemplate => 'לשמור תבנית?';

  @override
  String get importWizardSaveTemplateHint =>
      'שמירת מיפוי עמודות לקבצים דומים בעתיד.';

  @override
  String get importWizardUseSavedMapping => 'נמצאה תבנית שמורה';

  @override
  String get importWizardTypeClients => 'לקוחות';

  @override
  String get importWizardTypeProducts => 'מוצרים';

  @override
  String get importWizardTypeDeliveryPoints => 'נקודות משלוח';

  @override
  String get importWizardFileHint => 'בחרו קובץ Excel (.xlsx) או CSV.';

  @override
  String get importWizardPickFile => 'בחירת קובץ';

  @override
  String importWizardFileSummary(int columns, int rows) {
    return '$columns עמודות, $rows שורות';
  }

  @override
  String importWizardHeadersFound(int count) {
    return 'עמודות שנמצאו: $count';
  }

  @override
  String get importWizardPreviewTitle => 'תצוגה מקדימה (עד 20 שורות)';

  @override
  String get importWizardRun => 'ייבוא';

  @override
  String get importWizardImporting => 'מייבא…';

  @override
  String get importWizardResultTitle => 'הייבוא הושלם';

  @override
  String get importWizardImported => 'נוספו';

  @override
  String get importWizardUpdated => 'עודכנו';

  @override
  String get importWizardSkipped => 'דולגו';

  @override
  String get importWizardErrors => 'שגיאות';

  @override
  String get importWizardDownloadErrors => 'הורדת שגיאות (CSV)';

  @override
  String get importWizardTemplateName => 'שם תבנית';

  @override
  String get importWizardTemplateDefaultName => 'התבנית שלי';

  @override
  String get importWizardMenu => 'אשף ייבוא';

  @override
  String get importWizardBack => 'חזרה';

  @override
  String get importWizardApply => 'החל';

  @override
  String get importWizardUnusedColumns => 'עמודות שלא בשימוש';

  @override
  String importWizardDetectedPack(String pack) {
    return 'פורמט שזוהה: $pack';
  }

  @override
  String get createCompanyFlowTitle => 'יצירת חברה';

  @override
  String get createCompanyFlowStepCompany => 'פרטי חברה';

  @override
  String get createCompanyFlowStepOwner => 'משתמש ראשון';

  @override
  String get createCompanyFlowStepMode => 'מצב הטמעה';

  @override
  String get createCompanyFlowStepConfirm => 'אישור';

  @override
  String get createCompanyFlowDefaults =>
      'מדינה: ישראל · שפה: עברית · אזור זמן: Asia/Jerusalem · ניסיון: 14 יום';

  @override
  String get createCompanyFlowModeSelf => 'Self Setup';

  @override
  String get createCompanyFlowModeSelfHint => 'הבעלים משלים Launch Center';

  @override
  String get createCompanyFlowModeDone => 'Done-for-you';

  @override
  String get createCompanyFlowModeDoneHint => 'LogiRoute מגדירה את החברה';

  @override
  String createCompanyFlowModeLabel(String mode) {
    return 'מצב: $mode';
  }

  @override
  String get createCompanyFlowMaxUsers => 'מגבלת משתמשים';

  @override
  String get createCompanyFlowSuccessTitle => 'החברה נוצרה';

  @override
  String get createCompanyFlowSuccessBody =>
      'החברה מוכנה. למשתמש הראשון נשלח מייל כניסה.';

  @override
  String get createCompanyFlowEmailFailed =>
      'שליחת המייל נכשלה. החברה נוצרה — שלחו איפוס סיסמה ידנית.';

  @override
  String get createCompanyFlowOpenAsOwner => 'פתיחה כ-owner';

  @override
  String get createCompanyFlowOpenAsDispatcher => 'פתיחה כ-dispatcher';

  @override
  String get createCompanyFlowCopyInvite => 'העתקת הזמנה';

  @override
  String get createCompanyFlowInviteCopied => 'ההזמנה הועתקה';

  @override
  String get createCompanyFlowOwnerRequired =>
      'נדרשים שם ואימייל ל-owner/admin';

  @override
  String get createCompanyFlowUserInOtherCompany =>
      'אימייל זה כבר משויך לחברה אחרת';

  @override
  String get createCompanyFlowEmailConflict => 'לא ניתן ליצור או לקשר משתמש';

  @override
  String get launchCenterOpen => 'פתיחת Launch Center';

  @override
  String get trialEndsLabel => 'ניסיון עד';

  @override
  String get platformErrorCenterTitle => 'מרכז שגיאות';

  @override
  String get platformErrorDetailTitle => 'פרטי שגיאה';

  @override
  String get platformErrorFilterOpen => 'פתוחות בלבד';

  @override
  String get platformErrorEmpty => 'אין שגיאות';

  @override
  String get platformErrorColSeverity => 'חומרה';

  @override
  String get platformErrorColCount => 'חזרות';

  @override
  String get platformErrorColOperation => 'פעולה';

  @override
  String get platformErrorColFirstSeen => 'הופעה ראשונה';

  @override
  String get platformErrorColLastSeen => 'הופעה אחרונה';

  @override
  String get platformErrorResolved => 'נסגר';

  @override
  String get platformErrorOpen => 'פתוח';

  @override
  String get platformErrorCorrelationIds => 'Correlation ID';

  @override
  String get platformErrorStackTrace => 'Stack trace';

  @override
  String get platformErrorNoStack => 'אין stack trace';

  @override
  String get platformErrorCopy => 'העתק שגיאה';

  @override
  String get platformErrorCopyJson => 'העתק JSON';

  @override
  String get platformErrorCopied => 'הועתק';

  @override
  String get platformErrorMarkResolved => 'סמן כנסגר';

  @override
  String get platformErrorReopen => 'פתח מחדש';

  @override
  String get platformErrorIncidentSuggested =>
      'השגיאה חזרה >20 פעמים בשעה האחרונה';

  @override
  String get remoteConfigTitle => 'הגדרות פיילוט';

  @override
  String get remoteConfigSubtitle =>
      'פרמטרים חיים — שינויים נכנסים לתוקף ללא בנייה מחדש';

  @override
  String get remoteConfigSaved => 'ההגדרות נשמרו';

  @override
  String remoteConfigSaveError(String error) {
    return 'שגיאת שמירה: $error';
  }

  @override
  String get remoteConfigResetField => 'איפוס לברירת מחדל';

  @override
  String get remoteConfigResetAll => 'איפוס הכל לברירת מחדל';

  @override
  String remoteConfigDefault(String value) {
    return 'ברירת מחדל: $value';
  }

  @override
  String get rcAutoCloseRadius => 'רדיוס סגירה אוטומטית (מ\')';

  @override
  String get rcAutoCloseRadiusDesc =>
      'רדיוס GPS שבתוכו נקודת המשלוח נסגרת אוטומטית';

  @override
  String get rcAutoCloseResetRadius => 'רדיוס איפוס (מ\')';

  @override
  String get rcAutoCloseResetRadiusDesc =>
      'חייב להיות ≥ מרדיוס הסגירה. מונע איפוס טיימר בגלל רעד GPS';

  @override
  String get rcAutoCloseWait => 'זמן המתנה לסגירה (שניות)';

  @override
  String get rcAutoCloseWaitDesc =>
      'שניות שהנהג חייב להישאר בתוך הרדיוס לפני הסגירה האוטומטית';

  @override
  String get rcCloseUndo => 'משך ביטול (שניות)';

  @override
  String get rcCloseUndoDesc =>
      'שניות שכפתור \'ביטול\' מוצג לאחר סגירת נקודת משלוח';

  @override
  String get rcGpsStale => 'סף GPS מיושן (דקות)';

  @override
  String get rcGpsStaleDesc =>
      'לאחר מספר דקות זה ללא עדכון GPS הנהג נחשב לא מקוון';

  @override
  String get rcDriverGpsUiStale => 'GPS לא עדכני בממשק הנהג (שניות)';

  @override
  String get rcDriverGpsUiStaleDesc =>
      'שניות ללא פיקס מקומי טרי לפני שהבאנר של הנהג מציג GPS לא עדכני (60–900)';

  @override
  String get rcSessionHeartbeat => 'פעימת לב של סשן (שניות)';

  @override
  String get rcSessionHeartbeatDesc =>
      'כמה פעמים מכשיר הנהג שולח פעימת לב לשמירת בעלות הסשן';

  @override
  String get rcSessionStale => 'פסק זמן סשן מיושן (דקות)';

  @override
  String get rcSessionStaleDesc =>
      'הסשן נחשב מיושן לאחר מספר דקות זה ללא פעימת לב';

  @override
  String get rcBgAutoClose => 'סגירה אוטומטית ברקע';

  @override
  String get rcBgAutoCloseDesc =>
      'אפשר לשירות הרקע לסגור נקודות משלוח אוטומטית';

  @override
  String get rcSessionLock => 'נעילת סשן מכשיר נהג';

  @override
  String get rcSessionLockDesc => 'מניעת כניסה בו-זמנית של נהג משני מכשירים';

  @override
  String get rcPreferWaze => 'העדפת ניווט Waze';

  @override
  String get rcPreferWazeDesc =>
      'השתמש ב-Waze כאפליקציית ניווט ראשית. כשכבוי, Google Maps ישמש במקום';

  @override
  String get rcImportPreviewRows => 'שורות תצוגה מקדימה לייבוא';

  @override
  String get rcImportPreviewRowsDesc =>
      'מספר השורות המוצגות בשלב התצוגה המקדימה של הייבוא';

  @override
  String get rcSectionAutoClose => 'סגירה אוטומטית';

  @override
  String get rcSectionSession => 'סשן';

  @override
  String get rcSectionFeatures => 'תכונות';

  @override
  String get dataIntegrityTitle => 'שלמות נתונים';

  @override
  String get dataIntegritySubtitle =>
      'איתור אי-התאמות בין משתמשים, נקודות, מסלולים, חשבוניות ומלאי';

  @override
  String get dataIntegrityRunCheck => 'הרץ בדיקה';

  @override
  String dataIntegrityCheckDone(int count) {
    return 'הבדיקה הושלמה: $count בעיות';
  }

  @override
  String get dataIntegrityCsvCopied => 'CSV הועתק ללוח';

  @override
  String get dataIntegrityNever => 'בדיקת שלמות מעולם לא רצה';

  @override
  String get dataIntegrityLastCheck => 'בדיקה אחרונה';

  @override
  String get dataIntegrityNoIssues => 'לא נמצאו בעיות';

  @override
  String get dataIntegrityExportCsv => 'ייצוא CSV';

  @override
  String dataIntegrityIssuesCount(int count) {
    return '$count בעיות';
  }

  @override
  String get dataIntegrityFilterAll => 'הכול';

  @override
  String get dataIntegrityStatusOpen => 'פתוחות';

  @override
  String get dataIntegrityStatusIgnored => 'מתעלם';

  @override
  String get dataIntegrityStatusResolved => 'נפתרו';

  @override
  String get dataIntegrityMarkIgnored => 'התעלם';

  @override
  String get dataIntegrityMarkResolved => 'סמן כנפתר';

  @override
  String get dataIntegrityReopen => 'פתח מחדש';

  @override
  String get dataIntegrityOpenEntity => 'פרטים';

  @override
  String get dataIntegrityCopyId => 'העתק מזהה';

  @override
  String get dataIntegrityOpen => 'פתח בדיקת שלמות';

  @override
  String get severityCritical => 'קריטי';

  @override
  String get severityHigh => 'גבוה';

  @override
  String get severityMedium => 'בינוני';

  @override
  String get severityLow => 'נמוך';
}
