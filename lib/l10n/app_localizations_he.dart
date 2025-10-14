// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

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
  String get viewAs => 'הצג כ־';

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
  String get urgency => 'דחיפות';

  @override
  String get pallets => 'משטחים';

  @override
  String get boxes => 'קרטונים';

  @override
  String get boxesPerPallet => 'קרטונים למשטח (16–48)';

  @override
  String get openingTime => 'שעת פתיחה';

  @override
  String get status => 'סטטוס';

  @override
  String get pending => 'ממתין';

  @override
  String get assigned => 'הוקצה';

  @override
  String get inProgress => 'בביצוע';

  @override
  String get completed => 'הושלם';

  @override
  String get cancelled => 'בוטל';

  @override
  String get selectDriver => 'בחר נהג';

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
  String get cancel => 'בטל';

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
  String get error => 'שגיאה';

  @override
  String get required => 'שדה חובה';

  @override
  String get noPointsForRoute => 'אין נקודות זמינות ליצירת מסלול';

  @override
  String get routeCreated => 'המסלול נוצר';

  @override
  String get noDeliveryPoints => 'אין נקודות משלוח';

  @override
  String get markComplete => 'סמן כהושלם';

  @override
  String get mapViewRequiresApi => 'תצוגת מפה – דורשת מפתח Google Maps API';

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
  String get selectNewDriver => 'בחר נהג חדש';

  @override
  String get noAvailableDrivers => 'אין נהגים זמינים';

  @override
  String driverChangedTo(Object name) {
    return 'הנהג שונה ל־$name';
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
  String get noDriversAvailable => 'אין נהגים זמינים';

  @override
  String get map => 'מפה';

  @override
  String get noRoutesYet => 'אין עדיין מסלולים';

  @override
  String get points => 'נקודות';

  @override
  String get refreshMap => 'רענן מפה';

  @override
  String get phone => 'טלפון';

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
  String get addressNotFound => 'כתובת לא נמצאה';

  @override
  String addressNotFoundDescription(String address) {
    return 'לא ניתן למצוא קואורדינטות עבור הכתובת:\n\"$address\"\n\nהמערכת ניסתה הרבה אפשרויות אבל הגיאוקודינג נכשל.\n\nנסה:\n• בדוק את איות הכתובת\n• השתמש בכתובת מלאה עם עיר\n• ודא שהכתובת קיימת במפות\n• פנה למנהל לעזרה';
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
}
