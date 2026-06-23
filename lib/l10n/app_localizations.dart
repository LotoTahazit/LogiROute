import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
    Locale('ru')
  ];

  /// No description provided for @routeHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Route history'**
  String get routeHistoryTitle;

  /// No description provided for @routeHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed routes yet'**
  String get routeHistoryEmpty;

  /// No description provided for @vatRegimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Taxpayer type (print)'**
  String get vatRegimeLabel;

  /// No description provided for @vatRegimeAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Authorized dealer'**
  String get vatRegimeAuthorized;

  /// No description provided for @vatRegimeExempt.
  ///
  /// In en, this message translates to:
  /// **'VAT exempt'**
  String get vatRegimeExempt;

  /// No description provided for @vatRegimeCompany.
  ///
  /// In en, this message translates to:
  /// **'Ltd. company'**
  String get vatRegimeCompany;

  /// No description provided for @israelInvoiceStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Israel Invoices system'**
  String get israelInvoiceStatusTitle;

  /// No description provided for @israelInvoicePlatformNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Platform not configured — set ISRAEL_INVOICE_* in functions/.env'**
  String get israelInvoicePlatformNotConfigured;

  /// No description provided for @israelInvoiceCompanyConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Tax Authority'**
  String get israelInvoiceCompanyConnected;

  /// No description provided for @israelInvoiceCompanyNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected — use OAuth'**
  String get israelInvoiceCompanyNotConnected;

  /// No description provided for @israelInvoiceConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Israel Invoices'**
  String get israelInvoiceConnect;

  /// No description provided for @israelInvoiceConnectHint.
  ///
  /// In en, this message translates to:
  /// **'One-time business authorization with the Tax Authority for allocation numbers. A login page will open.'**
  String get israelInvoiceConnectHint;

  /// No description provided for @autoDistributePallets.
  ///
  /// In en, this message translates to:
  /// **'Auto-distribute pallets'**
  String get autoDistributePallets;

  /// No description provided for @autoDistributeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pallets have been automatically assigned to drivers!'**
  String get autoDistributeSuccess;

  /// No description provided for @autoDistributeError.
  ///
  /// In en, this message translates to:
  /// **'Auto-distribution error'**
  String get autoDistributeError;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LogiRoute'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get admin;

  /// No description provided for @dispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get dispatcher;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @viewAs.
  ///
  /// In en, this message translates to:
  /// **'View as'**
  String get viewAs;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @routes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get routes;

  /// No description provided for @deliveryPoints.
  ///
  /// In en, this message translates to:
  /// **'Delivery Points'**
  String get deliveryPoints;

  /// No description provided for @addPoint.
  ///
  /// In en, this message translates to:
  /// **'Add Point'**
  String get addPoint;

  /// No description provided for @createRoute.
  ///
  /// In en, this message translates to:
  /// **'Create Route'**
  String get createRoute;

  /// No description provided for @createRouteFromSelected.
  ///
  /// In en, this message translates to:
  /// **'From Selected ({count})'**
  String createRouteFromSelected(int count);

  /// No description provided for @createRouteByZone.
  ///
  /// In en, this message translates to:
  /// **'Route by Zone'**
  String get createRouteByZone;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String selectedCount(int count);

  /// No description provided for @noZoneLabel.
  ///
  /// In en, this message translates to:
  /// **'No zone'**
  String get noZoneLabel;

  /// No description provided for @selectedClientsDifferentZonesWarning.
  ///
  /// In en, this message translates to:
  /// **'Selected clients are from different zones: {zones}. Create the route anyway?'**
  String selectedClientsDifferentZonesWarning(String zones);

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @clientNumber.
  ///
  /// In en, this message translates to:
  /// **'Client Number'**
  String get clientNumber;

  /// No description provided for @clientManagement.
  ///
  /// In en, this message translates to:
  /// **'Client Management'**
  String get clientManagement;

  /// No description provided for @editClient.
  ///
  /// In en, this message translates to:
  /// **'Edit Client'**
  String get editClient;

  /// No description provided for @createClient.
  ///
  /// In en, this message translates to:
  /// **'Create New Client'**
  String get createClient;

  /// No description provided for @clientCreated.
  ///
  /// In en, this message translates to:
  /// **'Client created successfully'**
  String get clientCreated;

  /// No description provided for @clientUpdated.
  ///
  /// In en, this message translates to:
  /// **'Client updated successfully'**
  String get clientUpdated;

  /// No description provided for @noClientsFound.
  ///
  /// In en, this message translates to:
  /// **'No clients found'**
  String get noClientsFound;

  /// No description provided for @searchClientHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, number or address'**
  String get searchClientHint;

  /// No description provided for @addressWillBeGeocoded.
  ///
  /// In en, this message translates to:
  /// **'Address will be geocoded to coordinates'**
  String get addressWillBeGeocoded;

  /// No description provided for @addressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Address not found'**
  String get addressNotFound;

  /// No description provided for @geocodingError.
  ///
  /// In en, this message translates to:
  /// **'Geocoding error'**
  String get geocodingError;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get contactPerson;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @urgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgency;

  /// No description provided for @pallets.
  ///
  /// In en, this message translates to:
  /// **'Pallets'**
  String get pallets;

  /// No description provided for @boxes.
  ///
  /// In en, this message translates to:
  /// **'Boxes'**
  String get boxes;

  /// No description provided for @boxesPerPallet.
  ///
  /// In en, this message translates to:
  /// **'Boxes per Pallet'**
  String get boxesPerPallet;

  /// No description provided for @openingTime.
  ///
  /// In en, this message translates to:
  /// **'Opening Time'**
  String get openingTime;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @assigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @selectDriver.
  ///
  /// In en, this message translates to:
  /// **'Select Driver'**
  String get selectDriver;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @palletCapacity.
  ///
  /// In en, this message translates to:
  /// **'Pallet Capacity'**
  String get palletCapacity;

  /// No description provided for @truckWeight.
  ///
  /// In en, this message translates to:
  /// **'Truck Weight (tons)'**
  String get truckWeight;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get fillAllFields;

  /// No description provided for @userAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User added successfully'**
  String get userAddedSuccessfully;

  /// No description provided for @errorCreatingUser.
  ///
  /// In en, this message translates to:
  /// **'Error creating user'**
  String get errorCreatingUser;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email address is already in use'**
  String get emailAlreadyInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get weakPassword;

  /// No description provided for @warehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouse;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @invalidLoginCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidLoginCredentials;

  /// No description provided for @authUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email'**
  String get authUserNotFound;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'Account disabled. Contact your administrator'**
  String get authUserDisabled;

  /// No description provided for @authNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server. Check your internet connection'**
  String get authNetworkError;

  /// No description provided for @authOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is disabled in project settings'**
  String get authOperationNotAllowed;

  /// No description provided for @authInvalidApiKey.
  ///
  /// In en, this message translates to:
  /// **'App configuration error (API key). Contact administrator'**
  String get authInvalidApiKey;

  /// No description provided for @authAppNotAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Android app not authorized in Firebase. Add release SHA-1 in Firebase Console → Project settings → Android app'**
  String get authAppNotAuthorized;

  /// No description provided for @authInternalError.
  ///
  /// In en, this message translates to:
  /// **'Authentication server error. Try again later'**
  String get authInternalError;

  /// No description provided for @authProfileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found or not configured. Contact administrator'**
  String get authProfileNotFound;

  /// No description provided for @authUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Check your credentials or try again later'**
  String get authUnknownError;

  /// No description provided for @authPasswordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send password reset email. Check the email or contact administrator'**
  String get authPasswordResetFailed;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later'**
  String get tooManyRequests;

  /// No description provided for @systemManager.
  ///
  /// In en, this message translates to:
  /// **'System Manager'**
  String get systemManager;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @noDriversAvailable.
  ///
  /// In en, this message translates to:
  /// **'No drivers available'**
  String get noDriversAvailable;

  /// No description provided for @filterByDriver.
  ///
  /// In en, this message translates to:
  /// **'Filter by driver'**
  String get filterByDriver;

  /// No description provided for @allDrivers.
  ///
  /// In en, this message translates to:
  /// **'All drivers'**
  String get allDrivers;

  /// No description provided for @viewingAs.
  ///
  /// In en, this message translates to:
  /// **'You are viewing as'**
  String get viewingAs;

  /// No description provided for @backToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Back to Admin'**
  String get backToAdmin;

  /// No description provided for @cancelPoint.
  ///
  /// In en, this message translates to:
  /// **'Cancel Point'**
  String get cancelPoint;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @hebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew'**
  String get hebrew;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @capacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get capacity;

  /// No description provided for @totalPallets.
  ///
  /// In en, this message translates to:
  /// **'Total Pallets'**
  String get totalPallets;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deliveryWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery window'**
  String get deliveryWindowTitle;

  /// No description provided for @deliveryWindowFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get deliveryWindowFrom;

  /// No description provided for @deliveryWindowTo.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get deliveryWindowTo;

  /// No description provided for @deliveryWindowNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get deliveryWindowNotSet;

  /// No description provided for @deliveryWindowClear.
  ///
  /// In en, this message translates to:
  /// **'Clear window'**
  String get deliveryWindowClear;

  /// No description provided for @routeLateBy.
  ///
  /// In en, this message translates to:
  /// **'Late by {minutes} min'**
  String routeLateBy(int minutes);

  /// No description provided for @routeOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get routeOnTime;

  /// No description provided for @avgMinutesPerPoint.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min/pt'**
  String avgMinutesPerPoint(int minutes);

  /// No description provided for @requirePodPhoto.
  ///
  /// In en, this message translates to:
  /// **'Require delivery photo (POD)'**
  String get requirePodPhoto;

  /// No description provided for @requirePodPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Hides one-tap close and disables auto-close — every delivery needs a photo.'**
  String get requirePodPhotoHint;

  /// No description provided for @autoCloseEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-close points by GPS'**
  String get autoCloseEnabledTitle;

  /// No description provided for @autoCloseEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'A point closes automatically when the driver stops at the client. Turn off if you want the driver to close points only manually.'**
  String get autoCloseEnabledHint;

  /// No description provided for @deliverySection.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliverySection;

  /// No description provided for @pointDone.
  ///
  /// In en, this message translates to:
  /// **'Point Done'**
  String get pointDone;

  /// No description provided for @noActivePoints.
  ///
  /// In en, this message translates to:
  /// **'No active points'**
  String get noActivePoints;

  /// No description provided for @pointCompleted.
  ///
  /// In en, this message translates to:
  /// **'Point completed'**
  String get pointCompleted;

  /// No description provided for @autoCloseToggle.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get autoCloseToggle;

  /// No description provided for @bgLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Background location'**
  String get bgLocationTitle;

  /// No description provided for @bgLocationBody.
  ///
  /// In en, this message translates to:
  /// **'So the driver\'s route is recorded in full (even when the screen is locked), allow location access \"All the time\" in the app settings.'**
  String get bgLocationBody;

  /// No description provided for @bgLocationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get bgLocationOpenSettings;

  /// No description provided for @androidSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Android setup for shifts'**
  String get androidSetupTitle;

  /// No description provided for @androidSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'So shifts and GPS work in the background (even when the screen is locked), enable these 3 settings:'**
  String get androidSetupIntro;

  /// No description provided for @androidSetupLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location: \"Allow all the time\"'**
  String get androidSetupLocationTitle;

  /// No description provided for @androidSetupLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Without this, GPS stops when the screen is locked.'**
  String get androidSetupLocationDesc;

  /// No description provided for @androidSetupBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery: no restrictions'**
  String get androidSetupBatteryTitle;

  /// No description provided for @androidSetupBatteryDesc.
  ///
  /// In en, this message translates to:
  /// **'So the system doesn\'t kill the shift\'s background service.'**
  String get androidSetupBatteryDesc;

  /// No description provided for @androidSetupAutostartTitle.
  ///
  /// In en, this message translates to:
  /// **'Autostart (Xiaomi/MIUI, Huawei, Oppo…)'**
  String get androidSetupAutostartTitle;

  /// No description provided for @androidSetupAutostartDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow the app to autostart — otherwise the service won\'t start after a reboot. Check manually in app settings.'**
  String get androidSetupAutostartDesc;

  /// No description provided for @androidSetupEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get androidSetupEnable;

  /// No description provided for @androidSetupDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get androidSetupDone;

  /// No description provided for @androidSetupGranted.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get androidSetupGranted;

  /// No description provided for @androidSetupMenu.
  ///
  /// In en, this message translates to:
  /// **'Android setup (background)'**
  String get androidSetupMenu;

  /// No description provided for @closeWithPhoto.
  ///
  /// In en, this message translates to:
  /// **'Close with photo'**
  String get closeWithPhoto;

  /// No description provided for @fixLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Fix location'**
  String get fixLocationButton;

  /// No description provided for @fixLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Update client location?'**
  String get fixLocationTitle;

  /// No description provided for @fixLocationBody.
  ///
  /// In en, this message translates to:
  /// **'Save your current location as the coordinates for client \"{clientName}\"? This fixes the pin for future deliveries.'**
  String fixLocationBody(String clientName);

  /// No description provided for @fixLocationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Client location updated'**
  String get fixLocationSuccess;

  /// No description provided for @fixLocationGpsError.
  ///
  /// In en, this message translates to:
  /// **'No accurate GPS, or location outside Israel'**
  String get fixLocationGpsError;

  /// No description provided for @fixLocationClientMissing.
  ///
  /// In en, this message translates to:
  /// **'Client not found'**
  String get fixLocationClientMissing;

  /// No description provided for @autoCloseUndoMessage.
  ///
  /// In en, this message translates to:
  /// **'Point closed automatically'**
  String get autoCloseUndoMessage;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @podTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery'**
  String get podTitle;

  /// No description provided for @podTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get podTakePhoto;

  /// No description provided for @podRetake.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get podRetake;

  /// No description provided for @podConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery'**
  String get podConfirm;

  /// No description provided for @podGps.
  ///
  /// In en, this message translates to:
  /// **'Your GPS'**
  String get podGps;

  /// No description provided for @podTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get podTime;

  /// No description provided for @podDistance.
  ///
  /// In en, this message translates to:
  /// **'To client'**
  String get podDistance;

  /// No description provided for @podPhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Delivery photo required'**
  String get podPhotoRequired;

  /// No description provided for @podGpsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'GPS unavailable — enable location'**
  String get podGpsUnavailable;

  /// No description provided for @podUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo upload failed — check your connection and retry'**
  String get podUploadFailed;

  /// No description provided for @podViewerTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delivery photo'**
  String get podViewerTooltip;

  /// No description provided for @podViewerNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'No photo attached — point closed without a photo'**
  String get podViewerNoPhoto;

  /// No description provided for @podViewerPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load photo'**
  String get podViewerPhotoError;

  /// No description provided for @podViewerAutoClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed automatically by GPS'**
  String get podViewerAutoClosed;

  /// No description provided for @podSharePhoto.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get podSharePhoto;

  /// No description provided for @routeArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Route archive'**
  String get routeArchiveTitle;

  /// No description provided for @routeArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Deliveries from the last 90 days. Photos are available during that period; GPS and time remain after.'**
  String get routeArchiveHint;

  /// No description provided for @routeArchiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archived deliveries in this period'**
  String get routeArchiveEmpty;

  /// No description provided for @routeArchiveSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search client, driver or address'**
  String get routeArchiveSearchHint;

  /// No description provided for @routeArchivePointsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String routeArchivePointsCount(Object count);

  /// No description provided for @routeArchiveGpsOnly.
  ///
  /// In en, this message translates to:
  /// **'GPS only'**
  String get routeArchiveGpsOnly;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @pointAdded.
  ///
  /// In en, this message translates to:
  /// **'Point added'**
  String get pointAdded;

  /// No description provided for @noPointsForRoute.
  ///
  /// In en, this message translates to:
  /// **'No points for route creation'**
  String get noPointsForRoute;

  /// No description provided for @routeCreated.
  ///
  /// In en, this message translates to:
  /// **'Route created'**
  String get routeCreated;

  /// No description provided for @noDeliveryPoints.
  ///
  /// In en, this message translates to:
  /// **'No delivery points'**
  String get noDeliveryPoints;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get markComplete;

  /// No description provided for @mapViewRequiresApi.
  ///
  /// In en, this message translates to:
  /// **'Map view - requires Google Maps API'**
  String get mapViewRequiresApi;

  /// No description provided for @unknownDriver.
  ///
  /// In en, this message translates to:
  /// **'Unknown Driver'**
  String get unknownDriver;

  /// No description provided for @fixExistingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Fix Existing Routes'**
  String get fixExistingRoutes;

  /// No description provided for @printRoute.
  ///
  /// In en, this message translates to:
  /// **'Print Route'**
  String get printRoute;

  /// No description provided for @routesFixed.
  ///
  /// In en, this message translates to:
  /// **'Routes fixed!'**
  String get routesFixed;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get statusPending;

  /// No description provided for @statusAssigned.
  ///
  /// In en, this message translates to:
  /// **'assigned'**
  String get statusAssigned;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'in_progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'cancelled'**
  String get statusCancelled;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'driver'**
  String get roleDriver;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get cancelAction;

  /// No description provided for @completeAction.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get completeAction;

  /// No description provided for @boxesHint.
  ///
  /// In en, this message translates to:
  /// **'1-672 boxes'**
  String get boxesHint;

  /// No description provided for @urgencyNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get urgencyNormal;

  /// No description provided for @urgencyUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgencyUrgent;

  /// No description provided for @changeDriver.
  ///
  /// In en, this message translates to:
  /// **'Change driver'**
  String get changeDriver;

  /// No description provided for @cancelRoute.
  ///
  /// In en, this message translates to:
  /// **'Cancel route'**
  String get cancelRoute;

  /// No description provided for @cancelRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel route?'**
  String get cancelRouteTitle;

  /// No description provided for @cancelRouteDescription.
  ///
  /// In en, this message translates to:
  /// **'All points will return to \'pending\'. Continue?'**
  String get cancelRouteDescription;

  /// No description provided for @routeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Route cancelled, points returned to pending'**
  String get routeCancelled;

  /// No description provided for @routePointsReordered.
  ///
  /// In en, this message translates to:
  /// **'Route order and ETA updated'**
  String get routePointsReordered;

  /// No description provided for @optimizeTime.
  ///
  /// In en, this message translates to:
  /// **'Optimize time'**
  String get optimizeTime;

  /// No description provided for @routeAlreadyOptimal.
  ///
  /// In en, this message translates to:
  /// **'Route is already optimal'**
  String get routeAlreadyOptimal;

  /// No description provided for @routeOptimized.
  ///
  /// In en, this message translates to:
  /// **'Route optimized'**
  String get routeOptimized;

  /// No description provided for @routeOptimizationFailed.
  ///
  /// In en, this message translates to:
  /// **'Optimization failed'**
  String get routeOptimizationFailed;

  /// No description provided for @routeTimeNotOptimal.
  ///
  /// In en, this message translates to:
  /// **'Route time is not optimal'**
  String get routeTimeNotOptimal;

  /// No description provided for @selectNewDriver.
  ///
  /// In en, this message translates to:
  /// **'Select a new driver'**
  String get selectNewDriver;

  /// No description provided for @noAvailableDrivers.
  ///
  /// In en, this message translates to:
  /// **'No available drivers'**
  String get noAvailableDrivers;

  /// No description provided for @driverChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Driver changed to {name}'**
  String driverChangedTo(Object name);

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @palletStatistics.
  ///
  /// In en, this message translates to:
  /// **'Pallet Statistics'**
  String get palletStatistics;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @activeRoutes.
  ///
  /// In en, this message translates to:
  /// **'Active Routes'**
  String get activeRoutes;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get roleDispatcher;

  /// No description provided for @roleWarehouseKeeper.
  ///
  /// In en, this message translates to:
  /// **'Warehouse keeper'**
  String get roleWarehouseKeeper;

  /// No description provided for @roleAccountant.
  ///
  /// In en, this message translates to:
  /// **'Accountant'**
  String get roleAccountant;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @routeCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Route copied to clipboard'**
  String get routeCopiedToClipboard;

  /// No description provided for @printError.
  ///
  /// In en, this message translates to:
  /// **'❌ Print error: {error}'**
  String printError(String error);

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @routeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get routeNotFound;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @noRoutesYet.
  ///
  /// In en, this message translates to:
  /// **'No routes yet'**
  String get noRoutesYet;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get points;

  /// No description provided for @refreshMap.
  ///
  /// In en, this message translates to:
  /// **'Refresh map'**
  String get refreshMap;

  /// Label for client number input field (English)
  ///
  /// In en, this message translates to:
  /// **'Client Number (6 digits)'**
  String get clientNumberLabel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deletePoint.
  ///
  /// In en, this message translates to:
  /// **'Delete point'**
  String get deletePoint;

  /// No description provided for @pointDeleted.
  ///
  /// In en, this message translates to:
  /// **'Point deleted'**
  String get pointDeleted;

  /// No description provided for @assignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign driver'**
  String get assignDriver;

  /// No description provided for @pointAssigned.
  ///
  /// In en, this message translates to:
  /// **'Point assigned'**
  String get pointAssigned;

  /// Error message for address not found
  ///
  /// In en, this message translates to:
  /// **'Could not find coordinates for address:\n\"{address}\"\n\nThe system tried many variants but geocoding failed.\n\nTry:\n• Check address spelling\n• Use full address with city\n• Verify address exists in maps\n• Contact administrator for help'**
  String addressNotFoundDescription(String address);

  /// No description provided for @fixAddress.
  ///
  /// In en, this message translates to:
  /// **'Fix address'**
  String get fixAddress;

  /// No description provided for @fixOldCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Fix old coordinates'**
  String get fixOldCoordinates;

  /// No description provided for @fixOldCoordinatesDescription.
  ///
  /// In en, this message translates to:
  /// **'This will delete points with old Jerusalem coordinates. Continue?'**
  String get fixOldCoordinatesDescription;

  /// No description provided for @oldCoordinatesFixed.
  ///
  /// In en, this message translates to:
  /// **'Old coordinates fixed'**
  String get oldCoordinatesFixed;

  /// No description provided for @fixHebrewSearch.
  ///
  /// In en, this message translates to:
  /// **'Fix Hebrew search'**
  String get fixHebrewSearch;

  /// No description provided for @fixHebrewSearchDescription.
  ///
  /// In en, this message translates to:
  /// **'This will fix the search index for Hebrew client names. Continue?'**
  String get fixHebrewSearchDescription;

  /// No description provided for @hebrewSearchFixed.
  ///
  /// In en, this message translates to:
  /// **'Hebrew search index fixed'**
  String get hebrewSearchFixed;

  /// No description provided for @clientNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter client number'**
  String get clientNumberRequired;

  /// No description provided for @clientNumberLength.
  ///
  /// In en, this message translates to:
  /// **'Number must contain 6 digits'**
  String get clientNumberLength;

  /// No description provided for @bridgeHeightError.
  ///
  /// In en, this message translates to:
  /// **'Bridge height error'**
  String get bridgeHeightError;

  /// No description provided for @bridgeHeightErrorDescription.
  ///
  /// In en, this message translates to:
  /// **'Route blocked by low bridge (height < 4m). Contact dispatcher to select alternative route.'**
  String get bridgeHeightErrorDescription;

  /// No description provided for @routeBlockedByBridge.
  ///
  /// In en, this message translates to:
  /// **'Route blocked by bridge'**
  String get routeBlockedByBridge;

  /// No description provided for @alternativeRouteFound.
  ///
  /// In en, this message translates to:
  /// **'Alternative route found'**
  String get alternativeRouteFound;

  /// No description provided for @navigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get navigation;

  /// No description provided for @loadingNavigation.
  ///
  /// In en, this message translates to:
  /// **'Loading route...'**
  String get loadingNavigation;

  /// No description provided for @navigationError.
  ///
  /// In en, this message translates to:
  /// **'Navigation error'**
  String get navigationError;

  /// No description provided for @noNavigationRoute.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get noNavigationRoute;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @showMap.
  ///
  /// In en, this message translates to:
  /// **'Show map'**
  String get showMap;

  /// No description provided for @pointCancelled.
  ///
  /// In en, this message translates to:
  /// **'Point cancelled'**
  String get pointCancelled;

  /// No description provided for @removeFromRoute.
  ///
  /// In en, this message translates to:
  /// **'Remove from route'**
  String get removeFromRoute;

  /// No description provided for @pointRemovedFromRoute.
  ///
  /// In en, this message translates to:
  /// **'Point removed from route'**
  String get pointRemovedFromRoute;

  /// No description provided for @removeFromRouteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from route and return to pending?'**
  String removeFromRouteConfirm(String name);

  /// No description provided for @temporaryAddress.
  ///
  /// In en, this message translates to:
  /// **'Temporary Address'**
  String get temporaryAddress;

  /// No description provided for @temporaryAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Address for this delivery only...'**
  String get temporaryAddressHint;

  /// No description provided for @temporaryAddressHelper.
  ///
  /// In en, this message translates to:
  /// **'Does not change client\'s main address'**
  String get temporaryAddressHelper;

  /// No description provided for @temporaryAddressTooltip.
  ///
  /// In en, this message translates to:
  /// **'This address will be used only for the current delivery. The client\'s main address will remain unchanged.'**
  String get temporaryAddressTooltip;

  /// No description provided for @originalAddress.
  ///
  /// In en, this message translates to:
  /// **'Original Address'**
  String get originalAddress;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'If this email is registered, check your inbox and spam for a reset link'**
  String get passwordResetEmailSent;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password for your account'**
  String get resetPasswordHint;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @saveNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get saveNewPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Sign in with your new password'**
  String get passwordResetSuccess;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @invalidResetLink.
  ///
  /// In en, this message translates to:
  /// **'Reset link is invalid. Request a new one on the login screen'**
  String get invalidResetLink;

  /// No description provided for @emailTypoGmail.
  ///
  /// In en, this message translates to:
  /// **'Did you mean @gmail.com? @google.com is not a valid email provider'**
  String get emailTypoGmail;

  /// No description provided for @emailTypoCon.
  ///
  /// In en, this message translates to:
  /// **'Typo in domain: .con instead of .com?'**
  String get emailTypoCon;

  /// No description provided for @companyId.
  ///
  /// In en, this message translates to:
  /// **'Company ID'**
  String get companyId;

  /// No description provided for @gpsTrackingActive.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking active'**
  String get gpsTrackingActive;

  /// No description provided for @gpsTrackingStopped.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking stopped'**
  String get gpsTrackingStopped;

  /// No description provided for @weekendDay.
  ///
  /// In en, this message translates to:
  /// **'Weekend day'**
  String get weekendDay;

  /// No description provided for @workDayEnded.
  ///
  /// In en, this message translates to:
  /// **'Work day ended'**
  String get workDayEnded;

  /// Message showing minutes until work starts
  ///
  /// In en, this message translates to:
  /// **'Work starts in {minutes} minutes'**
  String workStartsIn(int minutes);

  /// Message showing minutes until work ends
  ///
  /// In en, this message translates to:
  /// **'Work ends in {minutes} minutes'**
  String workEndsIn(int minutes);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Edit user dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editUser(String name);

  /// Delete user confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteUser(String name);

  /// No description provided for @leaveEmptyToKeep.
  ///
  /// In en, this message translates to:
  /// **'leave empty to keep current'**
  String get leaveEmptyToKeep;

  /// No description provided for @userUpdated.
  ///
  /// In en, this message translates to:
  /// **'User updated'**
  String get userUpdated;

  /// No description provided for @userDeleted.
  ///
  /// In en, this message translates to:
  /// **'User deleted'**
  String get userDeleted;

  /// No description provided for @updateError.
  ///
  /// In en, this message translates to:
  /// **'Update error'**
  String get updateError;

  /// No description provided for @deleteError.
  ///
  /// In en, this message translates to:
  /// **'Delete error'**
  String get deleteError;

  /// No description provided for @noPermissionToEdit.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit this user'**
  String get noPermissionToEdit;

  /// No description provided for @warehouseStartPoint.
  ///
  /// In en, this message translates to:
  /// **'Starting point for all routes'**
  String get warehouseStartPoint;

  /// No description provided for @vehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get vehicleNumber;

  /// No description provided for @biometricLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Fingerprint Login?'**
  String get biometricLoginTitle;

  /// No description provided for @biometricLoginMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be able to log in using your fingerprint instead of a password.'**
  String get biometricLoginMessage;

  /// No description provided for @biometricLoginYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, enable'**
  String get biometricLoginYes;

  /// No description provided for @biometricLoginNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get biometricLoginNo;

  /// No description provided for @biometricLoginEnabled.
  ///
  /// In en, this message translates to:
  /// **'✅ Fingerprint login enabled'**
  String get biometricLoginEnabled;

  /// No description provided for @biometricLoginCancelled.
  ///
  /// In en, this message translates to:
  /// **'Authentication cancelled'**
  String get biometricLoginCancelled;

  /// No description provided for @biometricLoginError.
  ///
  /// In en, this message translates to:
  /// **'Biometric error'**
  String get biometricLoginError;

  /// No description provided for @biometricLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Login with fingerprint'**
  String get biometricLoginButton;

  /// No description provided for @biometricLoginButtonFace.
  ///
  /// In en, this message translates to:
  /// **'Login with Face ID'**
  String get biometricLoginButtonFace;

  /// No description provided for @biometricLoginOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get biometricLoginOr;

  /// No description provided for @biometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Log in using your fingerprint'**
  String get biometricAuthReason;

  /// No description provided for @viewModeWarehouse.
  ///
  /// In en, this message translates to:
  /// **'View Mode: Warehouse Keeper'**
  String get viewModeWarehouse;

  /// No description provided for @returnToAdmin.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnToAdmin;

  /// No description provided for @manageBoxTypes.
  ///
  /// In en, this message translates to:
  /// **'Manage Box Types Catalog'**
  String get manageBoxTypes;

  /// No description provided for @boxTypesManager.
  ///
  /// In en, this message translates to:
  /// **'Manage Box Types Catalog'**
  String get boxTypesManager;

  /// No description provided for @noBoxTypesInCatalog.
  ///
  /// In en, this message translates to:
  /// **'No types in catalog'**
  String get noBoxTypesInCatalog;

  /// No description provided for @editBoxType.
  ///
  /// In en, this message translates to:
  /// **'Edit Type'**
  String get editBoxType;

  /// No description provided for @deleteBoxType.
  ///
  /// In en, this message translates to:
  /// **'Delete Type'**
  String get deleteBoxType;

  /// No description provided for @deleteBoxTypeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {type} {number} from catalog?'**
  String deleteBoxTypeConfirm(Object number, Object type);

  /// No description provided for @boxTypeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Type updated successfully!'**
  String get boxTypeUpdated;

  /// No description provided for @boxTypeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Type deleted successfully!'**
  String get boxTypeDeleted;

  /// No description provided for @addNewBoxType.
  ///
  /// In en, this message translates to:
  /// **'Add New Type to Catalog'**
  String get addNewBoxType;

  /// No description provided for @newBoxTypeAdded.
  ///
  /// In en, this message translates to:
  /// **'New type added to inventory successfully!'**
  String get newBoxTypeAdded;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type (bottle, cap, cup)'**
  String get typeLabel;

  /// No description provided for @numberLabel.
  ///
  /// In en, this message translates to:
  /// **'Number (100, 200, etc.)'**
  String get numberLabel;

  /// No description provided for @volumeMlLabel.
  ///
  /// In en, this message translates to:
  /// **'Volume in ml (optional)'**
  String get volumeMlLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity (units)'**
  String get quantityLabel;

  /// No description provided for @quantityPerPalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity per pallet'**
  String get quantityPerPalletLabel;

  /// No description provided for @diameterLabel.
  ///
  /// In en, this message translates to:
  /// **'Diameter (optional)'**
  String get diameterLabel;

  /// No description provided for @piecesPerBoxLabel.
  ///
  /// In en, this message translates to:
  /// **'Packed - quantity per box (optional)'**
  String get piecesPerBoxLabel;

  /// No description provided for @additionalInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Additional information (optional)'**
  String get additionalInfoLabel;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Format hours in English
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String formatHours(int hours);

  /// Format minutes in English
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String formatMinutes(int minutes);

  /// Format hours and minutes in English
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String formatHoursMinutes(int hours, int minutes);

  /// No description provided for @setWarehouseLocation.
  ///
  /// In en, this message translates to:
  /// **'Set warehouse location'**
  String get setWarehouseLocation;

  /// No description provided for @latitudeWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Latitude (Warehouse in Mishmarot)'**
  String get latitudeWarehouse;

  /// No description provided for @longitudeWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Longitude (Warehouse in Mishmarot)'**
  String get longitudeWarehouse;

  /// No description provided for @clearPendingPoints.
  ///
  /// In en, this message translates to:
  /// **'Clear Pending Points'**
  String get clearPendingPoints;

  /// No description provided for @clearPendingPointsConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete ONLY pending delivery points (not active routes). Continue?'**
  String get clearPendingPointsConfirm;

  /// No description provided for @clearPending.
  ///
  /// In en, this message translates to:
  /// **'Clear Pending'**
  String get clearPending;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get clearAllData;

  /// No description provided for @clearAllDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete ALL delivery points. Are you sure?'**
  String get clearAllDataConfirm;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAll;

  /// No description provided for @fixRouteNumbers.
  ///
  /// In en, this message translates to:
  /// **'Fix Route Numbers'**
  String get fixRouteNumbers;

  /// No description provided for @fixRouteNumbersConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will recalculate route numbers for all drivers (1, 2, 3...). Continue?'**
  String get fixRouteNumbersConfirm;

  /// No description provided for @fixNumbers.
  ///
  /// In en, this message translates to:
  /// **'Fix Numbers'**
  String get fixNumbers;

  /// No description provided for @dataMigration.
  ///
  /// In en, this message translates to:
  /// **'Data Migration'**
  String get dataMigration;

  /// No description provided for @daysToMigrate.
  ///
  /// In en, this message translates to:
  /// **'Days to migrate'**
  String get daysToMigrate;

  /// No description provided for @oneTimeSetup.
  ///
  /// In en, this message translates to:
  /// **'One-Time Setup'**
  String get oneTimeSetup;

  /// No description provided for @migrationDescription.
  ///
  /// In en, this message translates to:
  /// **'This will build summary documents for existing invoices and deliveries.'**
  String get migrationDescription;

  /// No description provided for @migrationInstructions.
  ///
  /// In en, this message translates to:
  /// **'• Run this ONCE after deploying the update\n• Takes ~1 minute for 30 days of data\n• Safe to run multiple times (will rebuild)'**
  String get migrationInstructions;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @warehouseInventoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Warehouse - Inventory Management'**
  String get warehouseInventoryManagement;

  /// No description provided for @addNewBoxTypeToCatalog.
  ///
  /// In en, this message translates to:
  /// **'Add New Type to Catalog'**
  String get addNewBoxTypeToCatalog;

  /// No description provided for @showLowStockOnly.
  ///
  /// In en, this message translates to:
  /// **'Show Low Stock Only'**
  String get showLowStockOnly;

  /// No description provided for @changeHistory.
  ///
  /// In en, this message translates to:
  /// **'Change History'**
  String get changeHistory;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @searchByTypeOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Search by type or number...'**
  String get searchByTypeOrNumber;

  /// No description provided for @noItemsToExport.
  ///
  /// In en, this message translates to:
  /// **'No items to export'**
  String get noItemsToExport;

  /// No description provided for @reportExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report exported successfully'**
  String get reportExportedSuccessfully;

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error'**
  String get exportError;

  /// No description provided for @noItemsInInventory.
  ///
  /// In en, this message translates to:
  /// **'No items in inventory'**
  String get noItemsInInventory;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @productCode.
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get productCode;

  /// No description provided for @productCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Product Code *'**
  String get productCodeLabel;

  /// No description provided for @productCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Unique code for each product'**
  String get productCodeHelper;

  /// No description provided for @productCodeSearchHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter product code to search in catalog'**
  String get productCodeSearchHelper;

  /// No description provided for @productCodeFoundInCatalog.
  ///
  /// In en, this message translates to:
  /// **'Product code found in catalog'**
  String get productCodeFoundInCatalog;

  /// No description provided for @productCodeNotFoundInCatalog.
  ///
  /// In en, this message translates to:
  /// **'Product code not found in catalog'**
  String get productCodeNotFoundInCatalog;

  /// No description provided for @productCodeNotFoundAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Product code not found in catalog. Add new type to catalog first.'**
  String get productCodeNotFoundAddFirst;

  /// No description provided for @orSelectFromList.
  ///
  /// In en, this message translates to:
  /// **'or select product code from list'**
  String get orSelectFromList;

  /// No description provided for @selectFromFullList.
  ///
  /// In en, this message translates to:
  /// **'Select from full list'**
  String get selectFromFullList;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock!'**
  String get lowStock;

  /// No description provided for @limitedStock.
  ///
  /// In en, this message translates to:
  /// **'Limited Stock'**
  String get limitedStock;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume (L)'**
  String get volume;

  /// No description provided for @ml.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get ml;

  /// No description provided for @diameter.
  ///
  /// In en, this message translates to:
  /// **'Diameter'**
  String get diameter;

  /// No description provided for @packed.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get packed;

  /// No description provided for @piecesInBox.
  ///
  /// In en, this message translates to:
  /// **'pcs per box'**
  String get piecesInBox;

  /// No description provided for @quantityPerPallet.
  ///
  /// In en, this message translates to:
  /// **'Quantity per pallet'**
  String get quantityPerPallet;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInfo;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get units;

  /// No description provided for @remainingUnitsOnly.
  ///
  /// In en, this message translates to:
  /// **'Only {count} units remaining'**
  String remainingUnitsOnly(int count);

  /// No description provided for @urgentOrderStock.
  ///
  /// In en, this message translates to:
  /// **'Urgent! Need to order stock'**
  String get urgentOrderStock;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get by;

  /// No description provided for @addInventory.
  ///
  /// In en, this message translates to:
  /// **'Add Inventory'**
  String get addInventory;

  /// No description provided for @inventoryUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Inventory updated successfully!'**
  String get inventoryUpdatedSuccessfully;

  /// No description provided for @catalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Catalog is empty. Add new type to catalog first.'**
  String get catalogEmpty;

  /// No description provided for @editItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Item'**
  String get editItem;

  /// No description provided for @itemUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Item updated successfully!'**
  String get itemUpdatedSuccessfully;

  /// No description provided for @fillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get fillAllRequiredFields;

  /// No description provided for @fillAllRequiredFieldsIncludingProductCode.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields (including product code)'**
  String get fillAllRequiredFieldsIncludingProductCode;

  /// No description provided for @typeUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Type updated successfully!'**
  String get typeUpdatedSuccessfully;

  /// No description provided for @deletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully!'**
  String get deletedSuccessfully;

  /// No description provided for @deleteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirmation;

  /// No description provided for @searchByProductCode.
  ///
  /// In en, this message translates to:
  /// **'Search by product code, type or number...'**
  String get searchByProductCode;

  /// No description provided for @warehouseInventory.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Inventory'**
  String get warehouseInventory;

  /// No description provided for @inventoryChangesReport.
  ///
  /// In en, this message translates to:
  /// **'Inventory Changes Report'**
  String get inventoryChangesReport;

  /// No description provided for @inventoryCountReportsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count Reports'**
  String get inventoryCountReportsTooltip;

  /// No description provided for @archiveManagement.
  ///
  /// In en, this message translates to:
  /// **'Archive Management'**
  String get archiveManagement;

  /// No description provided for @inventoryCount.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count'**
  String get inventoryCount;

  /// No description provided for @inventoryCountReports.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count Reports'**
  String get inventoryCountReports;

  /// No description provided for @startNewCount.
  ///
  /// In en, this message translates to:
  /// **'Start New Inventory Count'**
  String get startNewCount;

  /// No description provided for @startNewCountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start a new inventory count?\nThis will create a list of all items in inventory.'**
  String get startNewCountConfirm;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @noActiveCount.
  ///
  /// In en, this message translates to:
  /// **'No active inventory count'**
  String get noActiveCount;

  /// No description provided for @countStarted.
  ///
  /// In en, this message translates to:
  /// **'New inventory count started'**
  String get countStarted;

  /// No description provided for @errorStartingCount.
  ///
  /// In en, this message translates to:
  /// **'Error starting count'**
  String get errorStartingCount;

  /// No description provided for @errorLoadingCount.
  ///
  /// In en, this message translates to:
  /// **'Error loading count'**
  String get errorLoadingCount;

  /// No description provided for @errorUpdatingItem.
  ///
  /// In en, this message translates to:
  /// **'Error updating item'**
  String get errorUpdatingItem;

  /// No description provided for @completeCount.
  ///
  /// In en, this message translates to:
  /// **'Complete Count'**
  String get completeCount;

  /// No description provided for @completeCountConfirm.
  ///
  /// In en, this message translates to:
  /// **'There are still {count} items not counted.\nComplete anyway?'**
  String completeCountConfirm(int count);

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @countCompleted.
  ///
  /// In en, this message translates to:
  /// **'Inventory count completed successfully'**
  String get countCompleted;

  /// No description provided for @errorCompletingCount.
  ///
  /// In en, this message translates to:
  /// **'Error completing count'**
  String get errorCompletingCount;

  /// No description provided for @showOnlyDifferences.
  ///
  /// In en, this message translates to:
  /// **'Show only differences'**
  String get showOnlyDifferences;

  /// No description provided for @counted.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get counted;

  /// No description provided for @differences.
  ///
  /// In en, this message translates to:
  /// **'Differences'**
  String get differences;

  /// No description provided for @shortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortage;

  /// No description provided for @surplus.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get surplus;

  /// No description provided for @searchByProductCodeTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Search by code / type / number'**
  String get searchByProductCodeTypeNumber;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @noDifferences.
  ///
  /// In en, this message translates to:
  /// **'No differences'**
  String get noDifferences;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItems;

  /// No description provided for @expected.
  ///
  /// In en, this message translates to:
  /// **'Expected'**
  String get expected;

  /// No description provided for @actualCounted.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get actualCounted;

  /// No description provided for @difference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get difference;

  /// No description provided for @suspiciousOrders.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Orders'**
  String get suspiciousOrders;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @noCountReports.
  ///
  /// In en, this message translates to:
  /// **'No inventory count reports'**
  String get noCountReports;

  /// No description provided for @countReport.
  ///
  /// In en, this message translates to:
  /// **'Inventory Count Report'**
  String get countReport;

  /// No description provided for @performedBy.
  ///
  /// In en, this message translates to:
  /// **'Performed by'**
  String get performedBy;

  /// No description provided for @started.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get started;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @approveCount.
  ///
  /// In en, this message translates to:
  /// **'Approve Count'**
  String get approveCount;

  /// No description provided for @approveCountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Approve the count and update inventory?\nThis will update inventory quantities according to the count.'**
  String get approveCountConfirm;

  /// No description provided for @approveAndUpdate.
  ///
  /// In en, this message translates to:
  /// **'Approve and Update'**
  String get approveAndUpdate;

  /// No description provided for @countApproved.
  ///
  /// In en, this message translates to:
  /// **'Count approved and inventory updated successfully'**
  String get countApproved;

  /// No description provided for @errorApprovingCount.
  ///
  /// In en, this message translates to:
  /// **'Error approving count'**
  String get errorApprovingCount;

  /// No description provided for @countNotFound.
  ///
  /// In en, this message translates to:
  /// **'Report not found'**
  String get countNotFound;

  /// No description provided for @exportToExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcel;

  /// No description provided for @exportToExcelSoon.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel - coming soon'**
  String get exportToExcelSoon;

  /// No description provided for @countNotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Count not completed'**
  String get countNotCompleted;

  /// No description provided for @errorLoadingReport.
  ///
  /// In en, this message translates to:
  /// **'Error loading report'**
  String get errorLoadingReport;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @selectDates.
  ///
  /// In en, this message translates to:
  /// **'Select Dates'**
  String get selectDates;

  /// No description provided for @allPeriod.
  ///
  /// In en, this message translates to:
  /// **'All Period'**
  String get allPeriod;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @searchByProductCodeTypeNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Search by product code, type or number...'**
  String get searchByProductCodeTypeNumberHint;

  /// No description provided for @foundChanges.
  ///
  /// In en, this message translates to:
  /// **'Found: {count} changes'**
  String foundChanges(int count);

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @deducted.
  ///
  /// In en, this message translates to:
  /// **'Deducted'**
  String get deducted;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results found for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @noChangesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No changes in this period'**
  String get noChangesInPeriod;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @totalArchives.
  ///
  /// In en, this message translates to:
  /// **'Total Archives'**
  String get totalArchives;

  /// No description provided for @totalSize.
  ///
  /// In en, this message translates to:
  /// **'Total Size'**
  String get totalSize;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get records;

  /// No description provided for @archiveActions.
  ///
  /// In en, this message translates to:
  /// **'Archive Actions'**
  String get archiveActions;

  /// No description provided for @archiveInventoryHistory.
  ///
  /// In en, this message translates to:
  /// **'Archive Inventory History'**
  String get archiveInventoryHistory;

  /// No description provided for @archiveOrders.
  ///
  /// In en, this message translates to:
  /// **'Archive Orders'**
  String get archiveOrders;

  /// No description provided for @existingArchives.
  ///
  /// In en, this message translates to:
  /// **'Existing Archives'**
  String get existingArchives;

  /// No description provided for @noArchives.
  ///
  /// In en, this message translates to:
  /// **'No Archives'**
  String get noArchives;

  /// No description provided for @archiveInventoryHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Inventory History'**
  String get archiveInventoryHistoryTitle;

  /// No description provided for @archiveInventoryHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive old records from the last 3 months?\n\nRecords will be marked as archived and will not be deleted.'**
  String get archiveInventoryHistoryConfirm;

  /// No description provided for @archiveCompletedOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Completed Orders'**
  String get archiveCompletedOrdersTitle;

  /// No description provided for @archiveCompletedOrdersConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive orders completed a month ago?\n\nOrders will be marked as archived and will not be deleted.'**
  String get archiveCompletedOrdersConfirm;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @errorLoadingArchives.
  ///
  /// In en, this message translates to:
  /// **'Error loading archives'**
  String get errorLoadingArchives;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @mb.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get mb;

  /// No description provided for @insufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Stock'**
  String get insufficientStock;

  /// No description provided for @cannotCreateOrderInsufficientStock.
  ///
  /// In en, this message translates to:
  /// **'Cannot create order - insufficient stock:'**
  String get cannotCreateOrderInsufficientStock;

  /// No description provided for @pleaseContactWarehouseKeeper.
  ///
  /// In en, this message translates to:
  /// **'Please contact the warehouse keeper to update inventory.'**
  String get pleaseContactWarehouseKeeper;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @requested.
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requested;

  /// No description provided for @itemNotFoundInInventory.
  ///
  /// In en, this message translates to:
  /// **'Item not found in inventory'**
  String get itemNotFoundInInventory;

  /// No description provided for @productCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product code not found'**
  String get productCodeNotFound;

  /// No description provided for @companySettings.
  ///
  /// In en, this message translates to:
  /// **'Company Settings'**
  String get companySettings;

  /// No description provided for @companyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get companyDetails;

  /// No description provided for @companyNameHebrew.
  ///
  /// In en, this message translates to:
  /// **'Name (Hebrew)'**
  String get companyNameHebrew;

  /// No description provided for @companyNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'Name (English, optional)'**
  String get companyNameEnglish;

  /// No description provided for @taxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get taxId;

  /// No description provided for @addressHebrew.
  ///
  /// In en, this message translates to:
  /// **'Address (Hebrew)'**
  String get addressHebrew;

  /// No description provided for @addressEnglish.
  ///
  /// In en, this message translates to:
  /// **'Address (English)'**
  String get addressEnglish;

  /// No description provided for @poBox.
  ///
  /// In en, this message translates to:
  /// **'P.O. Box'**
  String get poBox;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @zipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip Code'**
  String get zipCode;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @fax.
  ///
  /// In en, this message translates to:
  /// **'Fax'**
  String get fax;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @defaultDriver.
  ///
  /// In en, this message translates to:
  /// **'Default Driver'**
  String get defaultDriver;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get driverName;

  /// No description provided for @driverPhone.
  ///
  /// In en, this message translates to:
  /// **'Driver Phone'**
  String get driverPhone;

  /// No description provided for @departureTime.
  ///
  /// In en, this message translates to:
  /// **'Departure Time'**
  String get departureTime;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @invoiceFooterText.
  ///
  /// In en, this message translates to:
  /// **'Invoice Footer Text'**
  String get invoiceFooterText;

  /// No description provided for @paymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment Terms'**
  String get paymentTerms;

  /// No description provided for @bankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Details'**
  String get bankDetails;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings Saved'**
  String get settingsSaved;

  /// No description provided for @errorSavingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error Saving Settings'**
  String get errorSavingSettings;

  /// No description provided for @errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Settings'**
  String get errorLoadingSettings;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @migrationWarning.
  ///
  /// In en, this message translates to:
  /// **'This operation will add company ID to all existing records in the database. Make sure you have a backup before proceeding.'**
  String get migrationWarning;

  /// No description provided for @currentCompanyId.
  ///
  /// In en, this message translates to:
  /// **'Current Company ID'**
  String get currentCompanyId;

  /// No description provided for @startMigration.
  ///
  /// In en, this message translates to:
  /// **'Start Migration'**
  String get startMigration;

  /// No description provided for @migrating.
  ///
  /// In en, this message translates to:
  /// **'Migrating...'**
  String get migrating;

  /// No description provided for @migrationStatistics.
  ///
  /// In en, this message translates to:
  /// **'Migration Statistics'**
  String get migrationStatistics;

  /// No description provided for @migrationLog.
  ///
  /// In en, this message translates to:
  /// **'Migration Log'**
  String get migrationLog;

  /// No description provided for @noMigrationYet.
  ///
  /// In en, this message translates to:
  /// **'No migration performed yet'**
  String get noMigrationYet;

  /// No description provided for @overloadWarning.
  ///
  /// In en, this message translates to:
  /// **'Overload Warning'**
  String get overloadWarning;

  /// No description provided for @overloadWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Driver {driverName} is already carrying {currentLoad} pallets, adding {newLoad} pallets will increase the total to {totalLoad} pallets (capacity: {capacity} pallets). Continue?'**
  String overloadWarningMessage(String driverName, int currentLoad, int newLoad,
      int totalLoad, int capacity);

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continueAnyway;

  /// No description provided for @productManagement.
  ///
  /// In en, this message translates to:
  /// **'Product Management'**
  String get productManagement;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @unitsPerBox.
  ///
  /// In en, this message translates to:
  /// **'Units per Box'**
  String get unitsPerBox;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weight;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @showInactive.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive'**
  String get showInactive;

  /// No description provided for @hideInactive.
  ///
  /// In en, this message translates to:
  /// **'Hide Inactive'**
  String get hideInactive;

  /// No description provided for @importFromExcel.
  ///
  /// In en, this message translates to:
  /// **'Import from Excel'**
  String get importFromExcel;

  /// No description provided for @noProducts.
  ///
  /// In en, this message translates to:
  /// **'No Products'**
  String get noProducts;

  /// No description provided for @addFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Add First Product'**
  String get addFirstProduct;

  /// No description provided for @productAdded.
  ///
  /// In en, this message translates to:
  /// **'Product Added'**
  String get productAdded;

  /// No description provided for @productUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product Updated'**
  String get productUpdated;

  /// No description provided for @productDeleted.
  ///
  /// In en, this message translates to:
  /// **'Product Deleted'**
  String get productDeleted;

  /// No description provided for @deleteProductConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {productName}?'**
  String deleteProductConfirm(Object productName);

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategories;

  /// No description provided for @categoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get categoryGeneral;

  /// No description provided for @categoryCups.
  ///
  /// In en, this message translates to:
  /// **'Cups'**
  String get categoryCups;

  /// No description provided for @categoryLids.
  ///
  /// In en, this message translates to:
  /// **'Lids'**
  String get categoryLids;

  /// No description provided for @categoryContainers.
  ///
  /// In en, this message translates to:
  /// **'Containers'**
  String get categoryContainers;

  /// No description provided for @categoryBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get categoryBread;

  /// No description provided for @categoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get categoryDairy;

  /// No description provided for @categoryShirts.
  ///
  /// In en, this message translates to:
  /// **'Shirts'**
  String get categoryShirts;

  /// No description provided for @categoryTrays.
  ///
  /// In en, this message translates to:
  /// **'Trays'**
  String get categoryTrays;

  /// No description provided for @categoryBottles.
  ///
  /// In en, this message translates to:
  /// **'Bottles'**
  String get categoryBottles;

  /// No description provided for @categoryBags.
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get categoryBags;

  /// No description provided for @categoryBoxes.
  ///
  /// In en, this message translates to:
  /// **'Boxes'**
  String get categoryBoxes;

  /// No description provided for @terminology.
  ///
  /// In en, this message translates to:
  /// **'Terminology'**
  String get terminology;

  /// No description provided for @businessType.
  ///
  /// In en, this message translates to:
  /// **'Business Type'**
  String get businessType;

  /// No description provided for @selectBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Select Business Type'**
  String get selectBusinessType;

  /// No description provided for @businessTypePackaging.
  ///
  /// In en, this message translates to:
  /// **'Packaging & Plastic'**
  String get businessTypePackaging;

  /// No description provided for @businessTypeFood.
  ///
  /// In en, this message translates to:
  /// **'Food Products'**
  String get businessTypeFood;

  /// No description provided for @businessTypeClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing & Textile'**
  String get businessTypeClothing;

  /// No description provided for @businessTypeConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction Materials'**
  String get businessTypeConstruction;

  /// No description provided for @businessTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get businessTypeCustom;

  /// No description provided for @unitName.
  ///
  /// In en, this message translates to:
  /// **'Unit Name (singular)'**
  String get unitName;

  /// No description provided for @unitNamePlural.
  ///
  /// In en, this message translates to:
  /// **'Unit Name (plural)'**
  String get unitNamePlural;

  /// No description provided for @palletName.
  ///
  /// In en, this message translates to:
  /// **'Pallet Name (singular)'**
  String get palletName;

  /// No description provided for @palletNamePlural.
  ///
  /// In en, this message translates to:
  /// **'Pallet Name (plural)'**
  String get palletNamePlural;

  /// No description provided for @usesPallets.
  ///
  /// In en, this message translates to:
  /// **'Uses Pallets'**
  String get usesPallets;

  /// No description provided for @capacityCalculation.
  ///
  /// In en, this message translates to:
  /// **'Capacity Calculation'**
  String get capacityCalculation;

  /// No description provided for @capacityByUnits.
  ///
  /// In en, this message translates to:
  /// **'By Units'**
  String get capacityByUnits;

  /// No description provided for @capacityByWeight.
  ///
  /// In en, this message translates to:
  /// **'By Weight'**
  String get capacityByWeight;

  /// No description provided for @capacityByVolume.
  ///
  /// In en, this message translates to:
  /// **'By Volume'**
  String get capacityByVolume;

  /// No description provided for @terminologyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Terminology Updated'**
  String get terminologyUpdated;

  /// No description provided for @applyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Apply Template'**
  String get applyTemplate;

  /// No description provided for @customTerminology.
  ///
  /// In en, this message translates to:
  /// **'Custom Terminology'**
  String get customTerminology;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @noCompanySelected.
  ///
  /// In en, this message translates to:
  /// **'No company selected'**
  String get noCompanySelected;

  /// No description provided for @addNewProduct.
  ///
  /// In en, this message translates to:
  /// **'Add New Product'**
  String get addNewProduct;

  /// No description provided for @terminologySettings.
  ///
  /// In en, this message translates to:
  /// **'Terminology Settings'**
  String get terminologySettings;

  /// No description provided for @selectTemplate.
  ///
  /// In en, this message translates to:
  /// **'Select Template'**
  String get selectTemplate;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @customSettings.
  ///
  /// In en, this message translates to:
  /// **'Custom Settings'**
  String get customSettings;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download Template'**
  String get downloadTemplate;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} products'**
  String importSuccess(Object count);

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import Error'**
  String get importError;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'File Downloaded'**
  String get exportSuccess;

  /// No description provided for @templateDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Template Downloaded'**
  String get templateDownloaded;

  /// No description provided for @billingAndLocks.
  ///
  /// In en, this message translates to:
  /// **'Billing & Locks'**
  String get billingAndLocks;

  /// No description provided for @billingPortal.
  ///
  /// In en, this message translates to:
  /// **'Billing Portal'**
  String get billingPortal;

  /// No description provided for @moduleManagement.
  ///
  /// In en, this message translates to:
  /// **'Module Management'**
  String get moduleManagement;

  /// No description provided for @subscriptionManagement.
  ///
  /// In en, this message translates to:
  /// **'Subscription Management'**
  String get subscriptionManagement;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @currentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlan;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change Plan'**
  String get changePlan;

  /// No description provided for @changePlanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change plan?'**
  String get changePlanConfirm;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @noPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'No payment history'**
  String get noPaymentHistory;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @integrityCheck.
  ///
  /// In en, this message translates to:
  /// **'Integrity Check'**
  String get integrityCheck;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get documentType;

  /// No description provided for @checkRange.
  ///
  /// In en, this message translates to:
  /// **'Check Range'**
  String get checkRange;

  /// No description provided for @backupManagement.
  ///
  /// In en, this message translates to:
  /// **'Backup Management'**
  String get backupManagement;

  /// No description provided for @backupHistory.
  ///
  /// In en, this message translates to:
  /// **'Backup History'**
  String get backupHistory;

  /// No description provided for @noBackups.
  ///
  /// In en, this message translates to:
  /// **'No backups'**
  String get noBackups;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackup;

  /// No description provided for @backupLocation.
  ///
  /// In en, this message translates to:
  /// **'Backup Location'**
  String get backupLocation;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backupCreated;

  /// No description provided for @restoreTest.
  ///
  /// In en, this message translates to:
  /// **'Restore Test'**
  String get restoreTest;

  /// No description provided for @restoreTestHistory.
  ///
  /// In en, this message translates to:
  /// **'Restore Test History'**
  String get restoreTestHistory;

  /// No description provided for @complianceReport.
  ///
  /// In en, this message translates to:
  /// **'Compliance Report'**
  String get complianceReport;

  /// No description provided for @dataRetention.
  ///
  /// In en, this message translates to:
  /// **'Data Retention Policy'**
  String get dataRetention;

  /// No description provided for @retentionCheck.
  ///
  /// In en, this message translates to:
  /// **'Retention Check'**
  String get retentionCheck;

  /// No description provided for @retentionHistory.
  ///
  /// In en, this message translates to:
  /// **'Check History'**
  String get retentionHistory;

  /// No description provided for @runCheck.
  ///
  /// In en, this message translates to:
  /// **'Run Check'**
  String get runCheck;

  /// No description provided for @compliant.
  ///
  /// In en, this message translates to:
  /// **'Compliant'**
  String get compliant;

  /// No description provided for @notCompliant.
  ///
  /// In en, this message translates to:
  /// **'Not Compliant'**
  String get notCompliant;

  /// No description provided for @totalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Total Documents'**
  String get totalDocuments;

  /// No description provided for @oldestDocument.
  ///
  /// In en, this message translates to:
  /// **'Oldest Document'**
  String get oldestDocument;

  /// No description provided for @sequentialGaps.
  ///
  /// In en, this message translates to:
  /// **'Sequential Gaps'**
  String get sequentialGaps;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspended;

  /// No description provided for @accountGrace.
  ///
  /// In en, this message translates to:
  /// **'Grace Period'**
  String get accountGrace;

  /// No description provided for @trialEnding.
  ///
  /// In en, this message translates to:
  /// **'Trial Ending'**
  String get trialEnding;

  /// No description provided for @savePlan.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savePlan;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccount;

  /// No description provided for @cancelAction2.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction2;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTitle;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @vatReport.
  ///
  /// In en, this message translates to:
  /// **'VAT Report'**
  String get vatReport;

  /// No description provided for @clientReport.
  ///
  /// In en, this message translates to:
  /// **'Client Report'**
  String get clientReport;

  /// No description provided for @reportStockTab.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get reportStockTab;

  /// No description provided for @reportStockSku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get reportStockSku;

  /// No description provided for @reportStockProduct.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get reportStockProduct;

  /// No description provided for @reportStockQty.
  ///
  /// In en, this message translates to:
  /// **'Quantity (units)'**
  String get reportStockQty;

  /// No description provided for @reportStockPallets.
  ///
  /// In en, this message translates to:
  /// **'Pallets'**
  String get reportStockPallets;

  /// No description provided for @reportStockTotalSkus.
  ///
  /// In en, this message translates to:
  /// **'SKUs'**
  String get reportStockTotalSkus;

  /// No description provided for @reportStockTotalUnits.
  ///
  /// In en, this message translates to:
  /// **'Total units'**
  String get reportStockTotalUnits;

  /// No description provided for @reportStockTotalPallets.
  ///
  /// In en, this message translates to:
  /// **'Total pallets'**
  String get reportStockTotalPallets;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @noDataToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No data to display'**
  String get noDataToDisplay;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @monthColumn.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthColumn;

  /// No description provided for @documentsColumn.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsColumn;

  /// No description provided for @netAmount.
  ///
  /// In en, this message translates to:
  /// **'Net (₪)'**
  String get netAmount;

  /// No description provided for @vatAmount.
  ///
  /// In en, this message translates to:
  /// **'VAT (₪)'**
  String get vatAmount;

  /// No description provided for @grossAmount.
  ///
  /// In en, this message translates to:
  /// **'Gross (₪)'**
  String get grossAmount;

  /// No description provided for @csvCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'CSV copied to clipboard'**
  String get csvCopiedToClipboard;

  /// No description provided for @totalVatForPeriod.
  ///
  /// In en, this message translates to:
  /// **'Total VAT for period'**
  String get totalVatForPeriod;

  /// No description provided for @taxBase.
  ///
  /// In en, this message translates to:
  /// **'Tax base'**
  String get taxBase;

  /// No description provided for @taxBaseAmount.
  ///
  /// In en, this message translates to:
  /// **'Tax base (₪)'**
  String get taxBaseAmount;

  /// No description provided for @vatRateColumn.
  ///
  /// In en, this message translates to:
  /// **'VAT rate'**
  String get vatRateColumn;

  /// No description provided for @customerColumn.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerColumn;

  /// No description provided for @taxIdShort.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get taxIdShort;

  /// No description provided for @unknownCustomer.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownCustomer;

  /// No description provided for @customersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} customers'**
  String customersCount(int count);

  /// No description provided for @issuedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Issued documents'**
  String get issuedDocuments;

  /// No description provided for @draftsCount.
  ///
  /// In en, this message translates to:
  /// **'Drafts: {count}'**
  String draftsCount(int count);

  /// No description provided for @totalRevenueGross.
  ///
  /// In en, this message translates to:
  /// **'Total revenue (Gross)'**
  String get totalRevenueGross;

  /// No description provided for @netLabel.
  ///
  /// In en, this message translates to:
  /// **'Net: ₪{amount}'**
  String netLabel(String amount);

  /// No description provided for @vatPercent.
  ///
  /// In en, this message translates to:
  /// **'VAT (18%)'**
  String get vatPercent;

  /// No description provided for @forTaxAuthorities.
  ///
  /// In en, this message translates to:
  /// **'For tax authorities'**
  String get forTaxAuthorities;

  /// No description provided for @creditNotes.
  ///
  /// In en, this message translates to:
  /// **'Credit notes'**
  String get creditNotes;

  /// No description provided for @accountingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Accounting documents'**
  String get accountingDocuments;

  /// No description provided for @createDocument.
  ///
  /// In en, this message translates to:
  /// **'Create document'**
  String get createDocument;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @errorLoadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Error loading documents'**
  String get errorLoadingDocuments;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get noDocuments;

  /// No description provided for @columnType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get columnType;

  /// No description provided for @columnNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get columnNumber;

  /// No description provided for @columnCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get columnCustomer;

  /// No description provided for @columnAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get columnAmount;

  /// No description provided for @columnStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get columnStatus;

  /// No description provided for @columnDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get columnDate;

  /// No description provided for @columnActions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get columnActions;

  /// No description provided for @draftStatus.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draftStatus;

  /// No description provided for @issuedStatus.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get issuedStatus;

  /// No description provided for @lockedStatus.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedStatus;

  /// No description provided for @creditedStatus.
  ///
  /// In en, this message translates to:
  /// **'Credited'**
  String get creditedStatus;

  /// No description provided for @voidedStatus.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get voidedStatus;

  /// No description provided for @taxInvoice.
  ///
  /// In en, this message translates to:
  /// **'Tax Invoice'**
  String get taxInvoice;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @taxInvoiceReceipt.
  ///
  /// In en, this message translates to:
  /// **'Tax Invoice/Receipt'**
  String get taxInvoiceReceipt;

  /// No description provided for @creditNote.
  ///
  /// In en, this message translates to:
  /// **'Credit Note'**
  String get creditNote;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @issueTooltip.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueTooltip;

  /// No description provided for @cancelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTooltip;

  /// No description provided for @createCreditNote.
  ///
  /// In en, this message translates to:
  /// **'Create credit note'**
  String get createCreditNote;

  /// No description provided for @issueDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Issue document'**
  String get issueDocumentTitle;

  /// No description provided for @issueDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Issue document \"{name}\"?\n\nAfter issuance, key fields (number, date, customer, lines, amounts) will become immutable.'**
  String issueDocumentConfirm(String name);

  /// No description provided for @issueButton.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get issueButton;

  /// No description provided for @documentIssuedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Document issued successfully'**
  String get documentIssuedSuccess;

  /// No description provided for @errorIssuingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error issuing document: {error}'**
  String errorIssuingDocument(String error);

  /// No description provided for @voidDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Void document'**
  String get voidDocumentTitle;

  /// No description provided for @voidDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Void document \"{name}\"?'**
  String voidDocumentConfirm(String name);

  /// No description provided for @voidReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Void reason *'**
  String get voidReasonLabel;

  /// No description provided for @voidReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a void reason'**
  String get voidReasonRequired;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @voidDocumentButton.
  ///
  /// In en, this message translates to:
  /// **'Void document'**
  String get voidDocumentButton;

  /// No description provided for @documentVoidedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Document voided successfully'**
  String get documentVoidedSuccess;

  /// No description provided for @errorVoidingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error voiding document: {error}'**
  String errorVoidingDocument(String error);

  /// No description provided for @immutableFieldsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Key fields are locked for editing'**
  String get immutableFieldsTooltip;

  /// No description provided for @selectDocType.
  ///
  /// In en, this message translates to:
  /// **'Select document type'**
  String get selectDocType;

  /// No description provided for @newDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'New document — {type}'**
  String newDocumentTitle(String type);

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer details'**
  String get customerDetails;

  /// No description provided for @customerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer name *'**
  String get customerNameRequired;

  /// No description provided for @taxIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get taxIdLabel;

  /// No description provided for @documentLines.
  ///
  /// In en, this message translates to:
  /// **'Document lines'**
  String get documentLines;

  /// No description provided for @addLine.
  ///
  /// In en, this message translates to:
  /// **'Add line'**
  String get addLine;

  /// No description provided for @descriptionN.
  ///
  /// In en, this message translates to:
  /// **'Description {n}'**
  String descriptionN(int n);

  /// No description provided for @quantityShort.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantityShort;

  /// No description provided for @unitPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit price'**
  String get unitPriceLabel;

  /// No description provided for @vatRateLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatRateLabel;

  /// No description provided for @removeLine.
  ///
  /// In en, this message translates to:
  /// **'Remove line'**
  String get removeLine;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summaryTitle;

  /// No description provided for @netBeforeVat.
  ///
  /// In en, this message translates to:
  /// **'Total before VAT (Net)'**
  String get netBeforeVat;

  /// No description provided for @vatLabelCalc.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatLabelCalc;

  /// No description provided for @grossWithVat.
  ///
  /// In en, this message translates to:
  /// **'Total with VAT (Gross)'**
  String get grossWithVat;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @invalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalidValue;

  /// No description provided for @documentCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Document created successfully'**
  String get documentCreatedSuccess;

  /// No description provided for @errorCreatingDoc.
  ///
  /// In en, this message translates to:
  /// **'Error creating document: {error}'**
  String errorCreatingDoc(String error);

  /// No description provided for @documentChainTitle.
  ///
  /// In en, this message translates to:
  /// **'Document chain'**
  String get documentChainTitle;

  /// No description provided for @errorLoadingChain.
  ///
  /// In en, this message translates to:
  /// **'Error loading document chain'**
  String get errorLoadingChain;

  /// No description provided for @noRelatedDocs.
  ///
  /// In en, this message translates to:
  /// **'No related documents found'**
  String get noRelatedDocs;

  /// No description provided for @originalDocBadge.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalDocBadge;

  /// No description provided for @currentDocBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentDocBadge;

  /// No description provided for @totalSummary.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalSummary;

  /// No description provided for @loadingAdvice.
  ///
  /// In en, this message translates to:
  /// **'Loading advice'**
  String get loadingAdvice;

  /// No description provided for @capacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity: {count} pallets'**
  String capacityLabel(Object count);

  /// No description provided for @overCapacity.
  ///
  /// In en, this message translates to:
  /// **'Over capacity: {current}/{max} pallets'**
  String overCapacity(Object current, Object max);

  /// No description provided for @canCombineAdjacent.
  ///
  /// In en, this message translates to:
  /// **'{names} → 1 shared pallet'**
  String canCombineAdjacent(Object names);

  /// No description provided for @canCombineDistant.
  ///
  /// In en, this message translates to:
  /// **'{names} → can combine, but driver will need to rearrange'**
  String canCombineDistant(Object names);

  /// No description provided for @savingPallets.
  ///
  /// In en, this message translates to:
  /// **'Saving: {count}'**
  String savingPallets(Object count);

  /// No description provided for @hideGpsTracks.
  ///
  /// In en, this message translates to:
  /// **'Hide GPS tracks'**
  String get hideGpsTracks;

  /// No description provided for @showGpsTracks.
  ///
  /// In en, this message translates to:
  /// **'Show GPS tracks (24h)'**
  String get showGpsTracks;

  /// No description provided for @mapTooltipCurrentRoute.
  ///
  /// In en, this message translates to:
  /// **'Current route'**
  String get mapTooltipCurrentRoute;

  /// No description provided for @mapTooltipPreviousRoute.
  ///
  /// In en, this message translates to:
  /// **'Previous route'**
  String get mapTooltipPreviousRoute;

  /// No description provided for @mapTooltipClearMap.
  ///
  /// In en, this message translates to:
  /// **'Clear map'**
  String get mapTooltipClearMap;

  /// No description provided for @mapTooltipExitDemo.
  ///
  /// In en, this message translates to:
  /// **'Exit demo mode'**
  String get mapTooltipExitDemo;

  /// No description provided for @mapTooltipDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get mapTooltipDemoMode;

  /// No description provided for @mapBannerPreviousRouteShown.
  ///
  /// In en, this message translates to:
  /// **'Showing previous route'**
  String get mapBannerPreviousRouteShown;

  /// No description provided for @mapDemoRoutesBuilt.
  ///
  /// In en, this message translates to:
  /// **'3 optimal routes built'**
  String get mapDemoRoutesBuilt;

  /// No description provided for @mapDemoWarehouseCreatedDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Warehouse created 12 deliveries'**
  String get mapDemoWarehouseCreatedDeliveries;

  /// No description provided for @mapDemoTruckLoading.
  ///
  /// In en, this message translates to:
  /// **'Truck loading: 12 deliveries loaded from warehouse'**
  String get mapDemoTruckLoading;

  /// No description provided for @mapDemoTasksSentToDrivers.
  ///
  /// In en, this message translates to:
  /// **'Tasks sent to drivers'**
  String get mapDemoTasksSentToDrivers;

  /// No description provided for @mapDemoActiveDriver.
  ///
  /// In en, this message translates to:
  /// **'Active driver'**
  String get mapDemoActiveDriver;

  /// No description provided for @mapDemoDirectionToWarehouse.
  ///
  /// In en, this message translates to:
  /// **'To warehouse'**
  String get mapDemoDirectionToWarehouse;

  /// No description provided for @mapDemoDirectionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get mapDemoDirectionUnknown;

  /// No description provided for @mapDemoDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Direction: {direction}'**
  String mapDemoDirectionLabel(String direction);

  /// No description provided for @mapDemoEtaMinutes.
  ///
  /// In en, this message translates to:
  /// **'ETA: ~{minutes} min'**
  String mapDemoEtaMinutes(int minutes);

  /// No description provided for @mapDemoStage1Title.
  ///
  /// In en, this message translates to:
  /// **'Order received'**
  String get mapDemoStage1Title;

  /// No description provided for @mapDemoStage1Desc.
  ///
  /// In en, this message translates to:
  /// **'Client submits a delivery request to the dispatcher.'**
  String get mapDemoStage1Desc;

  /// No description provided for @mapDemoStage2Title.
  ///
  /// In en, this message translates to:
  /// **'Sent to warehouse'**
  String get mapDemoStage2Title;

  /// No description provided for @mapDemoStage2Desc.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher forwards the order for fulfillment.'**
  String get mapDemoStage2Desc;

  /// No description provided for @mapDemoStage3Title.
  ///
  /// In en, this message translates to:
  /// **'Warehouse preparation'**
  String get mapDemoStage3Title;

  /// No description provided for @mapDemoStage3Desc.
  ///
  /// In en, this message translates to:
  /// **'Staff pick goods and build pallets for shipment.'**
  String get mapDemoStage3Desc;

  /// No description provided for @mapDemoStage4Title.
  ///
  /// In en, this message translates to:
  /// **'Route created'**
  String get mapDemoStage4Title;

  /// No description provided for @mapDemoStage4Desc.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher plans an optimized route with all stops.'**
  String get mapDemoStage4Desc;

  /// No description provided for @mapDemoStage5Title.
  ///
  /// In en, this message translates to:
  /// **'Truck loading'**
  String get mapDemoStage5Title;

  /// No description provided for @mapDemoStage5Desc.
  ///
  /// In en, this message translates to:
  /// **'Pallets are loaded onto the driver truck.'**
  String get mapDemoStage5Desc;

  /// No description provided for @mapDemoStage6Title.
  ///
  /// In en, this message translates to:
  /// **'Driver on the road'**
  String get mapDemoStage6Title;

  /// No description provided for @mapDemoStage6Desc.
  ///
  /// In en, this message translates to:
  /// **'Driver follows the route — streets visible on the map.'**
  String get mapDemoStage6Desc;

  /// No description provided for @mapDemoStage7Title.
  ///
  /// In en, this message translates to:
  /// **'Delivery and unload'**
  String get mapDemoStage7Title;

  /// No description provided for @mapDemoStage7Desc.
  ///
  /// In en, this message translates to:
  /// **'At each stop goods are unloaded; the stop is marked done.'**
  String get mapDemoStage7Desc;

  /// No description provided for @mapDemoStage8Title.
  ///
  /// In en, this message translates to:
  /// **'Return to warehouse'**
  String get mapDemoStage8Title;

  /// No description provided for @mapDemoStage8Desc.
  ///
  /// In en, this message translates to:
  /// **'Driver completes the route and returns to base.'**
  String get mapDemoStage8Desc;

  /// No description provided for @mapDemoStageCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Simulation complete'**
  String get mapDemoStageCompleteTitle;

  /// No description provided for @mapDemoStageCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Full delivery cycle finished successfully.'**
  String get mapDemoStageCompleteDesc;

  /// No description provided for @mapDemoStopLabel.
  ///
  /// In en, this message translates to:
  /// **'Stop {number}'**
  String mapDemoStopLabel(int number);

  /// No description provided for @mapDemoDeliveringAt.
  ///
  /// In en, this message translates to:
  /// **'Unloading at {stop}'**
  String mapDemoDeliveringAt(String stop);

  /// No description provided for @mapDemoReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay simulation'**
  String get mapDemoReplay;

  /// No description provided for @mapDemoLiveBadge.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get mapDemoLiveBadge;

  /// No description provided for @mapDemoKpiMileage.
  ///
  /// In en, this message translates to:
  /// **'mileage'**
  String get mapDemoKpiMileage;

  /// No description provided for @mapDemoKpiEtaAccuracy.
  ///
  /// In en, this message translates to:
  /// **'ETA accuracy'**
  String get mapDemoKpiEtaAccuracy;

  /// No description provided for @mapDemoKpiCalls.
  ///
  /// In en, this message translates to:
  /// **'calls'**
  String get mapDemoKpiCalls;

  /// No description provided for @mapDemoKpiDelivered.
  ///
  /// In en, this message translates to:
  /// **'delivered'**
  String get mapDemoKpiDelivered;

  /// No description provided for @mapDemoKpiEnroute.
  ///
  /// In en, this message translates to:
  /// **'en route'**
  String get mapDemoKpiEnroute;

  /// No description provided for @mapDemoKpiDistance.
  ///
  /// In en, this message translates to:
  /// **'route'**
  String get mapDemoKpiDistance;

  /// No description provided for @mapDemoKpiLate.
  ///
  /// In en, this message translates to:
  /// **'late'**
  String get mapDemoKpiLate;

  /// No description provided for @mapDemoEtaAccuracyValue.
  ///
  /// In en, this message translates to:
  /// **'±3 min'**
  String get mapDemoEtaAccuracyValue;

  /// No description provided for @mapDemoFinishSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The dispatcher saw everything in real time'**
  String get mapDemoFinishSubtitle;

  /// No description provided for @mapDemoFinishNote.
  ///
  /// In en, this message translates to:
  /// **'Not a single \"where are you?\" call to the driver the whole route'**
  String get mapDemoFinishNote;

  /// No description provided for @mapDemoMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String mapDemoMinutesShort(int minutes);

  /// No description provided for @mapDemoKmShort.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String mapDemoKmShort(String km);

  /// No description provided for @mapDemoStepShort1.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get mapDemoStepShort1;

  /// No description provided for @mapDemoStepShort2.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get mapDemoStepShort2;

  /// No description provided for @mapDemoStepShort3.
  ///
  /// In en, this message translates to:
  /// **'Prep'**
  String get mapDemoStepShort3;

  /// No description provided for @mapDemoStepShort4.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get mapDemoStepShort4;

  /// No description provided for @mapDemoStepShort5.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get mapDemoStepShort5;

  /// No description provided for @mapDemoStepShort6.
  ///
  /// In en, this message translates to:
  /// **'Drive'**
  String get mapDemoStepShort6;

  /// No description provided for @mapDemoStepShort7.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get mapDemoStepShort7;

  /// No description provided for @mapDemoStepShort8.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get mapDemoStepShort8;

  /// No description provided for @billingGuardAccessSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access suspended'**
  String get billingGuardAccessSuspendedTitle;

  /// No description provided for @billingGuardAccessSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended for non-payment. Pay to restore access.'**
  String get billingGuardAccessSuspendedBody;

  /// No description provided for @billingGuardAccountCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Account cancelled'**
  String get billingGuardAccountCancelledTitle;

  /// No description provided for @billingGuardAccountCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been cancelled. Please contact support to renew.'**
  String get billingGuardAccountCancelledBody;

  /// No description provided for @billingGuardTrialEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trial ended'**
  String get billingGuardTrialEndedTitle;

  /// No description provided for @billingGuardTrialEndedBody.
  ///
  /// In en, this message translates to:
  /// **'Your trial has ended. Upgrade to a paid plan.'**
  String get billingGuardTrialEndedBody;

  /// No description provided for @billingGuardNoAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get billingGuardNoAccessTitle;

  /// No description provided for @billingGuardNoAccessBody.
  ///
  /// In en, this message translates to:
  /// **'Please contact support.'**
  String get billingGuardNoAccessBody;

  /// No description provided for @billingGuardContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get billingGuardContactSupport;

  /// No description provided for @billingGuardPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get billingGuardPayNow;

  /// No description provided for @billingGuardUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get billingGuardUpgrade;

  /// No description provided for @billingGuardTrialBanner.
  ///
  /// In en, this message translates to:
  /// **'Trial — {days} days left (until {date})'**
  String billingGuardTrialBanner(int days, String date);

  /// No description provided for @billingGuardGraceBanner.
  ///
  /// In en, this message translates to:
  /// **'Grace period — {days} days left to pay. After that the account will be suspended.'**
  String billingGuardGraceBanner(int days);

  /// No description provided for @billingGuardCheckoutOpened.
  ///
  /// In en, this message translates to:
  /// **'Payment page opened in the browser. After payment, the account will update automatically.'**
  String get billingGuardCheckoutOpened;

  /// No description provided for @billingGuardCheckoutError.
  ///
  /// In en, this message translates to:
  /// **'Error opening payment page: {error}'**
  String billingGuardCheckoutError(String error);

  /// No description provided for @companySettingsNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No company selected'**
  String get companySettingsNotSelected;

  /// No description provided for @companySettingsInitError.
  ///
  /// In en, this message translates to:
  /// **'Initialization error: {error}'**
  String companySettingsInitError(String error);

  /// No description provided for @companySettingsEmptyWarning.
  ///
  /// In en, this message translates to:
  /// **'No settings found. Fill in the form.'**
  String get companySettingsEmptyWarning;

  /// No description provided for @companySettingsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Load error: {error}'**
  String companySettingsLoadError(String error);

  /// No description provided for @billingDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing dashboard'**
  String get billingDashboardTitle;

  /// No description provided for @billingDashboardFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get billingDashboardFilterAll;

  /// No description provided for @billingDashboardFilterTrial.
  ///
  /// In en, this message translates to:
  /// **'🧪 Trial'**
  String get billingDashboardFilterTrial;

  /// No description provided for @billingDashboardFilterActive.
  ///
  /// In en, this message translates to:
  /// **'✅ Active'**
  String get billingDashboardFilterActive;

  /// No description provided for @billingDashboardFilterGrace.
  ///
  /// In en, this message translates to:
  /// **'⏳ Grace'**
  String get billingDashboardFilterGrace;

  /// No description provided for @billingDashboardFilterSuspended.
  ///
  /// In en, this message translates to:
  /// **'🚫 Suspended'**
  String get billingDashboardFilterSuspended;

  /// No description provided for @billingDashboardFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'❌ Cancelled'**
  String get billingDashboardFilterCancelled;

  /// No description provided for @billingDashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get billingDashboardSearchHint;

  /// No description provided for @billingDashboardNoCompanies.
  ///
  /// In en, this message translates to:
  /// **'No companies found'**
  String get billingDashboardNoCompanies;

  /// No description provided for @billingDashboardExtendTitle.
  ///
  /// In en, this message translates to:
  /// **'Extend {companyName}'**
  String billingDashboardExtendTitle(String companyName);

  /// No description provided for @billingDashboardExtendPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Set paid until: {date}'**
  String billingDashboardExtendPaidUntil(String date);

  /// No description provided for @billingDashboardNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (required)'**
  String get billingDashboardNoteLabel;

  /// No description provided for @billingDashboardNoteDefault.
  ///
  /// In en, this message translates to:
  /// **'Extended via dashboard'**
  String get billingDashboardNoteDefault;

  /// No description provided for @billingDashboardExtendButton.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get billingDashboardExtendButton;

  /// No description provided for @billingDashboardChangeStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Change {companyName} → {status}?'**
  String billingDashboardChangeStatusTitle(String companyName, String status);

  /// No description provided for @billingDashboardChangeStatusBody.
  ///
  /// In en, this message translates to:
  /// **'This will immediately change the billing status.'**
  String get billingDashboardChangeStatusBody;

  /// No description provided for @billingDashboardStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'{companyName} → {status}'**
  String billingDashboardStatusUpdated(String companyName, String status);

  /// No description provided for @billingDashboardIntegrityRunning.
  ///
  /// In en, this message translates to:
  /// **'Running integrity check…'**
  String get billingDashboardIntegrityRunning;

  /// No description provided for @billingDashboardIntegrityDone.
  ///
  /// In en, this message translates to:
  /// **'Integrity check complete'**
  String get billingDashboardIntegrityDone;

  /// No description provided for @billingDashboardRunIntegrityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Run integrity check'**
  String get billingDashboardRunIntegrityTooltip;

  /// No description provided for @billingDashboardSeedPricingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Upload billing pricing to Firestore'**
  String get billingDashboardSeedPricingTooltip;

  /// No description provided for @billingDashboardSeedPricingTitle.
  ///
  /// In en, this message translates to:
  /// **'Update config/billing_pricing?'**
  String get billingDashboardSeedPricingTitle;

  /// No description provided for @billingDashboardSeedPricingBody.
  ///
  /// In en, this message translates to:
  /// **'Writes the current tariff grid (logistics, warehouse, ops, full) to Firestore config/billing_pricing. Checkout will use these prices immediately.'**
  String get billingDashboardSeedPricingBody;

  /// No description provided for @billingDashboardSeedPricingButton.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get billingDashboardSeedPricingButton;

  /// No description provided for @billingDashboardSeedPricingRunning.
  ///
  /// In en, this message translates to:
  /// **'Uploading pricing…'**
  String get billingDashboardSeedPricingRunning;

  /// No description provided for @billingDashboardSeedPricingDone.
  ///
  /// In en, this message translates to:
  /// **'Pricing updated: {plans}'**
  String billingDashboardSeedPricingDone(String plans);

  /// No description provided for @billingDashboardExtendSuccess.
  ///
  /// In en, this message translates to:
  /// **'{companyName} extended to {date}'**
  String billingDashboardExtendSuccess(String companyName, String date);

  /// No description provided for @billingDashboardError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String billingDashboardError(String error);

  /// No description provided for @billingLabelProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get billingLabelProvider;

  /// No description provided for @billingLabelPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get billingLabelPaidUntil;

  /// No description provided for @billingLabelTrialUntil.
  ///
  /// In en, this message translates to:
  /// **'Trial until'**
  String get billingLabelTrialUntil;

  /// No description provided for @billingLabelGraceUntil.
  ///
  /// In en, this message translates to:
  /// **'Grace until'**
  String get billingLabelGraceUntil;

  /// No description provided for @billingLabelGraceDays.
  ///
  /// In en, this message translates to:
  /// **'Grace days'**
  String get billingLabelGraceDays;

  /// No description provided for @billingActionExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get billingActionExtend;

  /// No description provided for @billingActionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get billingActionActive;

  /// No description provided for @billingActionGrace.
  ///
  /// In en, this message translates to:
  /// **'Grace'**
  String get billingActionGrace;

  /// No description provided for @billingActionSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get billingActionSuspend;

  /// No description provided for @dispatcherInvalidCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinates: {error}'**
  String dispatcherInvalidCoordinates(String error);

  /// No description provided for @dispatcherPrintError.
  ///
  /// In en, this message translates to:
  /// **'Print error: {error}'**
  String dispatcherPrintError(String error);

  /// No description provided for @dispatcherGenericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String dispatcherGenericError(String error);

  /// No description provided for @dispatcherWarehouseSaved.
  ///
  /// In en, this message translates to:
  /// **'Warehouse location saved: {coords}'**
  String dispatcherWarehouseSaved(String coords);

  /// No description provided for @dispatcherTourStopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close presentation'**
  String get dispatcherTourStopTooltip;

  /// No description provided for @dispatcherTourStartTooltip.
  ///
  /// In en, this message translates to:
  /// **'LogiRoute product presentation'**
  String get dispatcherTourStartTooltip;

  /// No description provided for @dispatcherTourProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String dispatcherTourProgress(int current, int total);

  /// No description provided for @salesDemoSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get salesDemoSkip;

  /// No description provided for @salesDemoNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get salesDemoNext;

  /// No description provided for @salesDemoBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get salesDemoBack;

  /// No description provided for @salesDemoGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get salesDemoGetStarted;

  /// No description provided for @salesDemoSeeLiveDemo.
  ///
  /// In en, this message translates to:
  /// **'See live demo'**
  String get salesDemoSeeLiveDemo;

  /// No description provided for @salesDemoBrandTagline.
  ///
  /// In en, this message translates to:
  /// **'End-to-end logistics platform'**
  String get salesDemoBrandTagline;

  /// No description provided for @salesDemoSlide1Title.
  ///
  /// In en, this message translates to:
  /// **'Logistics shouldn\'t feel chaotic'**
  String get salesDemoSlide1Title;

  /// No description provided for @salesDemoSlide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manual routes, missed deliveries, and disconnected teams cost you time and money every day.'**
  String get salesDemoSlide1Subtitle;

  /// No description provided for @salesDemoSlide1Benefit1.
  ///
  /// In en, this message translates to:
  /// **'Hours lost to spreadsheets and phone calls'**
  String get salesDemoSlide1Benefit1;

  /// No description provided for @salesDemoSlide1Benefit2.
  ///
  /// In en, this message translates to:
  /// **'No real-time visibility into your fleet'**
  String get salesDemoSlide1Benefit2;

  /// No description provided for @salesDemoSlide1Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Invoices and deliveries out of sync'**
  String get salesDemoSlide1Benefit3;

  /// No description provided for @salesDemoSlide2Title.
  ///
  /// In en, this message translates to:
  /// **'Meet LogiRoute'**
  String get salesDemoSlide2Title;

  /// No description provided for @salesDemoSlide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'One platform for warehouse, dispatch, drivers, and billing — built to scale.'**
  String get salesDemoSlide2Subtitle;

  /// No description provided for @salesDemoSlide2Benefit1.
  ///
  /// In en, this message translates to:
  /// **'From order to invoice in one seamless flow'**
  String get salesDemoSlide2Benefit1;

  /// No description provided for @salesDemoSlide2Benefit2.
  ///
  /// In en, this message translates to:
  /// **'Web and mobile — your team, always connected'**
  String get salesDemoSlide2Benefit2;

  /// No description provided for @salesDemoSlide2Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Designed for real dispatch operations'**
  String get salesDemoSlide2Benefit3;

  /// No description provided for @salesDemoPersonaAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get salesDemoPersonaAdmin;

  /// No description provided for @salesDemoPersonaDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get salesDemoPersonaDispatcher;

  /// No description provided for @salesDemoPersonaDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get salesDemoPersonaDriver;

  /// No description provided for @salesDemoPersonaAdminDesc.
  ///
  /// In en, this message translates to:
  /// **'Full control: companies, users, billing, and analytics in one dashboard.'**
  String get salesDemoPersonaAdminDesc;

  /// No description provided for @salesDemoPersonaDispatcherDesc.
  ///
  /// In en, this message translates to:
  /// **'Build routes, assign drivers, and track every delivery live on the map.'**
  String get salesDemoPersonaDispatcherDesc;

  /// No description provided for @salesDemoPersonaDriverDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear tasks, turn-by-turn stops, and instant status updates from the road.'**
  String get salesDemoPersonaDriverDesc;

  /// No description provided for @salesDemoSlide3Title.
  ///
  /// In en, this message translates to:
  /// **'Smart routing & dispatch'**
  String get salesDemoSlide3Title;

  /// No description provided for @salesDemoSlide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan optimal routes in minutes — not hours.'**
  String get salesDemoSlide3Subtitle;

  /// No description provided for @salesDemoSlide3Benefit1.
  ///
  /// In en, this message translates to:
  /// **'Automatic route optimization'**
  String get salesDemoSlide3Benefit1;

  /// No description provided for @salesDemoSlide3Benefit2.
  ///
  /// In en, this message translates to:
  /// **'Drag-and-drop driver assignment'**
  String get salesDemoSlide3Benefit2;

  /// No description provided for @salesDemoSlide3Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Live map with all active deliveries'**
  String get salesDemoSlide3Benefit3;

  /// No description provided for @salesDemoSlide4Title.
  ///
  /// In en, this message translates to:
  /// **'Driver app & live tracking'**
  String get salesDemoSlide4Title;

  /// No description provided for @salesDemoSlide4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Every driver knows where to go — you see progress in real time.'**
  String get salesDemoSlide4Subtitle;

  /// No description provided for @salesDemoSlide4Benefit1.
  ///
  /// In en, this message translates to:
  /// **'Tasks pushed instantly to driver phones'**
  String get salesDemoSlide4Benefit1;

  /// No description provided for @salesDemoSlide4Benefit2.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking on an interactive map'**
  String get salesDemoSlide4Benefit2;

  /// No description provided for @salesDemoSlide4Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Fewer calls, faster deliveries'**
  String get salesDemoSlide4Benefit3;

  /// No description provided for @salesDemoSlide5Title.
  ///
  /// In en, this message translates to:
  /// **'Warehouse to invoice'**
  String get salesDemoSlide5Title;

  /// No description provided for @salesDemoSlide5Subtitle.
  ///
  /// In en, this message translates to:
  /// **'The complete order lifecycle — nothing falls through the cracks.'**
  String get salesDemoSlide5Subtitle;

  /// No description provided for @salesDemoSlide5Benefit1.
  ///
  /// In en, this message translates to:
  /// **'Warehouse picking and loading workflows'**
  String get salesDemoSlide5Benefit1;

  /// No description provided for @salesDemoSlide5Benefit2.
  ///
  /// In en, this message translates to:
  /// **'Invoicing aligned with every delivery'**
  String get salesDemoSlide5Benefit2;

  /// No description provided for @salesDemoSlide5Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Full audit trail for every order'**
  String get salesDemoSlide5Benefit3;

  /// No description provided for @salesDemoLifecycleOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get salesDemoLifecycleOrder;

  /// No description provided for @salesDemoLifecycleDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get salesDemoLifecycleDispatch;

  /// No description provided for @salesDemoLifecycleDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get salesDemoLifecycleDelivery;

  /// No description provided for @salesDemoLifecycleInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get salesDemoLifecycleInvoice;

  /// No description provided for @salesDemoSlide6Title.
  ///
  /// In en, this message translates to:
  /// **'Enterprise-ready logistics'**
  String get salesDemoSlide6Title;

  /// No description provided for @salesDemoSlide6Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Professional, secure, and ready for growing delivery operations.'**
  String get salesDemoSlide6Subtitle;

  /// No description provided for @salesDemoSlide6Benefit1.
  ///
  /// In en, this message translates to:
  /// **'Role-based access for every team member'**
  String get salesDemoSlide6Benefit1;

  /// No description provided for @salesDemoSlide6Benefit2.
  ///
  /// In en, this message translates to:
  /// **'English, Russian, and Hebrew built in'**
  String get salesDemoSlide6Benefit2;

  /// No description provided for @salesDemoSlide6Benefit3.
  ///
  /// In en, this message translates to:
  /// **'Trusted by dispatch teams every day'**
  String get salesDemoSlide6Benefit3;

  /// No description provided for @dispatcherSkippedInvoicesMakor.
  ///
  /// In en, this message translates to:
  /// **'{count} invoices skipped — original already printed. Use invoice management to reprint.'**
  String dispatcherSkippedInvoicesMakor(int count);

  /// No description provided for @dispatcherCopiesOnlyPendingTax.
  ///
  /// In en, this message translates to:
  /// **'Copy prints only — waiting for assignment number. Original prints after tax authority approval.'**
  String get dispatcherCopiesOnlyPendingTax;

  /// No description provided for @pointUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Point updated: {name}'**
  String pointUpdatedSuccess(String name);

  /// No description provided for @dispatcherPointReturnedToRoute.
  ///
  /// In en, this message translates to:
  /// **'{name} returned to route'**
  String dispatcherPointReturnedToRoute(String name);

  /// No description provided for @dispatcherManualCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark as delivered'**
  String get dispatcherManualCompleteTitle;

  /// No description provided for @dispatcherManualCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Mark \"{name}\" as delivered manually? Use if auto-close did not run.'**
  String dispatcherManualCompleteMessage(String name);

  /// No description provided for @dispatcherManualCompleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark as delivered manually'**
  String get dispatcherManualCompleteTooltip;

  /// No description provided for @dispatcherPointCompletedManually.
  ///
  /// In en, this message translates to:
  /// **'{name} marked as delivered'**
  String dispatcherPointCompletedManually(String name);

  /// No description provided for @dispatcherPointAssignedToDriver.
  ///
  /// In en, this message translates to:
  /// **'Point assigned: {client} → {driver}'**
  String dispatcherPointAssignedToDriver(String client, String driver);

  /// No description provided for @dispatcherAssignDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign driver — {clientName}'**
  String dispatcherAssignDriverTitle(String clientName);

  /// No description provided for @dispatcherDragAssignSuccess.
  ///
  /// In en, this message translates to:
  /// **'Point assigned → {driverName}'**
  String dispatcherDragAssignSuccess(String driverName);

  /// No description provided for @autoDistributeFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-distribution failed: {error}'**
  String autoDistributeFailed(String error);

  /// No description provided for @companySettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String companySettingsSaveFailed(String error);

  /// No description provided for @makorOriginalPrintedTitle.
  ///
  /// In en, this message translates to:
  /// **'Original already printed'**
  String get makorOriginalPrintedTitle;

  /// No description provided for @makorDocTypeDeliveryNote.
  ///
  /// In en, this message translates to:
  /// **'Delivery note'**
  String get makorDocTypeDeliveryNote;

  /// No description provided for @makorDocTypeTaxInvoiceReceipt.
  ///
  /// In en, this message translates to:
  /// **'Tax invoice / receipt'**
  String get makorDocTypeTaxInvoiceReceipt;

  /// No description provided for @makorDocTypeTaxInvoice.
  ///
  /// In en, this message translates to:
  /// **'Tax invoice'**
  String get makorDocTypeTaxInvoice;

  /// No description provided for @makorInvoiceLineNumbered.
  ///
  /// In en, this message translates to:
  /// **'{docType} no. {seq}'**
  String makorInvoiceLineNumbered(String docType, String seq);

  /// No description provided for @makorClientLine.
  ///
  /// In en, this message translates to:
  /// **'Client: {name}'**
  String makorClientLine(String name);

  /// No description provided for @makorBooksLawWarning.
  ///
  /// In en, this message translates to:
  /// **'Under bookkeeping law — you cannot print another original.\nYou may print a copy or true-to-original only.'**
  String get makorBooksLawWarning;

  /// No description provided for @makorChoosePrintType.
  ///
  /// In en, this message translates to:
  /// **'Choose print type:'**
  String get makorChoosePrintType;

  /// No description provided for @makorCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get makorCopy;

  /// No description provided for @makorCopySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy number {n}'**
  String makorCopySubtitle(int n);

  /// No description provided for @makorTrueToOriginal.
  ///
  /// In en, this message translates to:
  /// **'True to original'**
  String get makorTrueToOriginal;

  /// No description provided for @makorTrueToOriginalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replaces the original'**
  String get makorTrueToOriginalSubtitle;

  /// No description provided for @makorCopyQuantity.
  ///
  /// In en, this message translates to:
  /// **'Number of copies:'**
  String get makorCopyQuantity;

  /// No description provided for @makorPrintButton.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get makorPrintButton;

  /// No description provided for @vatId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID / Business Number'**
  String get vatId;

  /// No description provided for @deliveryZones.
  ///
  /// In en, this message translates to:
  /// **'Delivery Zones'**
  String get deliveryZones;

  /// No description provided for @zonesRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one zone'**
  String get zonesRequired;

  /// No description provided for @manualCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get manualCoordinates;

  /// No description provided for @manualCoordinatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use if geocoding doesn\'t work'**
  String get manualCoordinatesSubtitle;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @latitudeExample.
  ///
  /// In en, this message translates to:
  /// **'Example: 31.9539907'**
  String get latitudeExample;

  /// No description provided for @longitudeExample.
  ///
  /// In en, this message translates to:
  /// **'Example: 34.8062546'**
  String get longitudeExample;

  /// No description provided for @enterManualCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get enterManualCoordinates;

  /// No description provided for @balanceRoutes.
  ///
  /// In en, this message translates to:
  /// **'Balance Routes'**
  String get balanceRoutes;

  /// No description provided for @balanceRoutesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Balance routes? The system will move points from overloaded routes to lighter ones.'**
  String get balanceRoutesConfirm;

  /// No description provided for @routesBalanced.
  ///
  /// In en, this message translates to:
  /// **'Routes balanced successfully'**
  String get routesBalanced;

  /// No description provided for @routesAlreadyBalanced.
  ///
  /// In en, this message translates to:
  /// **'Routes are already balanced'**
  String get routesAlreadyBalanced;

  /// No description provided for @balancingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Balancing routes...'**
  String get balancingRoutes;

  /// No description provided for @movedPoints.
  ///
  /// In en, this message translates to:
  /// **'{count} points moved between routes'**
  String movedPoints(Object count);

  /// No description provided for @navigationOpenError.
  ///
  /// In en, this message translates to:
  /// **'Error opening navigation'**
  String get navigationOpenError;

  /// No description provided for @driverFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverFallbackName;

  /// No description provided for @driverActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get driverActive;

  /// No description provided for @printAllInvoicesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Print all invoices'**
  String get printAllInvoicesTooltip;

  /// No description provided for @pickingListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Picking list'**
  String get pickingListTooltip;

  /// No description provided for @createInvoiceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create invoice'**
  String get createInvoiceTooltip;

  /// No description provided for @createDeliveryNoteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create delivery note'**
  String get createDeliveryNoteTooltip;

  /// No description provided for @autoCompletedPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-completed points ({count})'**
  String autoCompletedPointsTitle(Object count);

  /// No description provided for @skipClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip client?'**
  String get skipClientTitle;

  /// No description provided for @skipClientContent.
  ///
  /// In en, this message translates to:
  /// **'Skip {clientName} and continue?'**
  String skipClientContent(Object clientName);

  /// No description provided for @stopAllButton.
  ///
  /// In en, this message translates to:
  /// **'Stop all'**
  String get stopAllButton;

  /// No description provided for @skipAndContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Skip and continue'**
  String get skipAndContinueButton;

  /// No description provided for @invoicesPrintedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ {count} invoices printed'**
  String invoicesPrintedSuccess(Object count);

  /// No description provided for @printingErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'❌ Printing error: {error}'**
  String printingErrorMessage(Object error);

  /// No description provided for @finishCountButton.
  ///
  /// In en, this message translates to:
  /// **'Finish count'**
  String get finishCountButton;

  /// No description provided for @uncheckedItemsWarning.
  ///
  /// In en, this message translates to:
  /// **'There are still {count} items not counted.\nFinish anyway?'**
  String uncheckedItemsWarning(Object count);

  /// No description provided for @searchByCodeTypeNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Search by code / type / number'**
  String get searchByCodeTypeNumberHint;

  /// No description provided for @noResultsFoundLabel.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFoundLabel;

  /// No description provided for @noDifferencesLabel.
  ///
  /// In en, this message translates to:
  /// **'No differences'**
  String get noDifferencesLabel;

  /// No description provided for @noItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get noItemsLabel;

  /// No description provided for @totalItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total items'**
  String get totalItemsLabel;

  /// No description provided for @countedLabel.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get countedLabel;

  /// No description provided for @differencesLabel.
  ///
  /// In en, this message translates to:
  /// **'Differences'**
  String get differencesLabel;

  /// No description provided for @shortageLabel.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortageLabel;

  /// No description provided for @surplusLabel.
  ///
  /// In en, this message translates to:
  /// **'Surplus'**
  String get surplusLabel;

  /// No description provided for @countStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get countStartedLabel;

  /// No description provided for @countFinishedLabel.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get countFinishedLabel;

  /// No description provided for @errorLoadingCountMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading count: {error}'**
  String errorLoadingCountMessage(Object error);

  /// No description provided for @errorStartingCountMessage.
  ///
  /// In en, this message translates to:
  /// **'Error starting count: {error}'**
  String errorStartingCountMessage(Object error);

  /// No description provided for @errorCompletingCountMessage.
  ///
  /// In en, this message translates to:
  /// **'Error completing count: {error}'**
  String errorCompletingCountMessage(Object error);

  /// No description provided for @reopenPoint.
  ///
  /// In en, this message translates to:
  /// **'Reopen'**
  String get reopenPoint;

  /// No description provided for @deductionForOrderReason.
  ///
  /// In en, this message translates to:
  /// **'Stock deduction for order'**
  String get deductionForOrderReason;

  /// No description provided for @inventoryActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get inventoryActionAdd;

  /// No description provided for @inventoryActionDeduct.
  ///
  /// In en, this message translates to:
  /// **'Deducted'**
  String get inventoryActionDeduct;

  /// No description provided for @inventoryActionUpdate.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get inventoryActionUpdate;

  /// No description provided for @priceManagement.
  ///
  /// In en, this message translates to:
  /// **'Price Management'**
  String get priceManagement;

  /// No description provided for @updatePriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Price - {type} {number}'**
  String updatePriceTitle(String type, String number);

  /// No description provided for @priceBeforeVatLabel.
  ///
  /// In en, this message translates to:
  /// **'Price before VAT (₪)'**
  String get priceBeforeVatLabel;

  /// No description provided for @priceBeforeVatHint.
  ///
  /// In en, this message translates to:
  /// **'Price is before VAT (18%)'**
  String get priceBeforeVatHint;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get enterValidPrice;

  /// No description provided for @priceUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Price updated successfully'**
  String get priceUpdatedSuccess;

  /// No description provided for @priceUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating price: {error}'**
  String priceUpdateError(String error);

  /// No description provided for @searchBySkuTypeNumber.
  ///
  /// In en, this message translates to:
  /// **'Search by SKU, type or number'**
  String get searchBySkuTypeNumber;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @skuLabel.
  ///
  /// In en, this message translates to:
  /// **'SKU: {code}'**
  String skuLabel(String code);

  /// No description provided for @priceDisplay.
  ///
  /// In en, this message translates to:
  /// **'Price: ₪{price} (before VAT)'**
  String priceDisplay(String price);

  /// No description provided for @noPriceSet.
  ///
  /// In en, this message translates to:
  /// **'No price set'**
  String get noPriceSet;

  /// No description provided for @volumeMlDisplay.
  ///
  /// In en, this message translates to:
  /// **'{volume} ml'**
  String volumeMlDisplay(int volume);

  /// No description provided for @integrityCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Chain Integrity Check'**
  String get integrityCheckTitle;

  /// No description provided for @documentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Document type:'**
  String get documentTypeLabel;

  /// No description provided for @checkRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Check range:'**
  String get checkRangeLabel;

  /// No description provided for @lastNItems.
  ///
  /// In en, this message translates to:
  /// **'Last {count}'**
  String lastNItems(int count);

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @checkIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Check Integrity'**
  String get checkIntegrity;

  /// No description provided for @noDocumentsOfType.
  ///
  /// In en, this message translates to:
  /// **'No documents of this type'**
  String get noDocumentsOfType;

  /// No description provided for @rangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Range: {from}..{to}'**
  String rangeLabel(int from, int to);

  /// No description provided for @checkedCount.
  ///
  /// In en, this message translates to:
  /// **'Checked: {count}'**
  String checkedCount(int count);

  /// No description provided for @lastHashLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Hash: {hash}...'**
  String lastHashLabel(String hash);

  /// No description provided for @breakAtDocument.
  ///
  /// In en, this message translates to:
  /// **'Break at document: #{number}'**
  String breakAtDocument(int number);

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reasonLabel(String reason);

  /// No description provided for @integrityCheckExplain.
  ///
  /// In en, this message translates to:
  /// **'Verifies the document numbering crypto chain. Documents issued before the chain was enabled are skipped automatically — this is not an error.'**
  String get integrityCheckExplain;

  /// No description provided for @integrityLegacyOnly.
  ///
  /// In en, this message translates to:
  /// **'No chain entries: all documents of this type were issued before integrity checking. New documents will be verified normally.'**
  String get integrityLegacyOnly;

  /// No description provided for @integrityLegacySkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped legacy numbers #{from}–#{to} (before the first chain entry)'**
  String integrityLegacySkipped(int from, int to);

  /// No description provided for @integrityCheckedFrom.
  ///
  /// In en, this message translates to:
  /// **'Actually checked: #{from} through #{to}'**
  String integrityCheckedFrom(int from, int to);

  /// No description provided for @integrityReasonMissingEntry.
  ///
  /// In en, this message translates to:
  /// **'Chain entry missing'**
  String get integrityReasonMissingEntry;

  /// No description provided for @integrityReasonMissingPrevForRange.
  ///
  /// In en, this message translates to:
  /// **'Previous document before range is missing'**
  String get integrityReasonMissingPrevForRange;

  /// No description provided for @integrityReasonSchemaInvalid.
  ///
  /// In en, this message translates to:
  /// **'Corrupted chain entry'**
  String get integrityReasonSchemaInvalid;

  /// No description provided for @integrityReasonPrevHashMismatch.
  ///
  /// In en, this message translates to:
  /// **'Hash chain broken (prev mismatch)'**
  String get integrityReasonPrevHashMismatch;

  /// No description provided for @integrityReasonHashMismatch.
  ///
  /// In en, this message translates to:
  /// **'Hash mismatch'**
  String get integrityReasonHashMismatch;

  /// No description provided for @integrityOkSummary.
  ///
  /// In en, this message translates to:
  /// **'✅ Integrity OK — checked: {count}'**
  String integrityOkSummary(int count);

  /// No description provided for @integrityFailedSummary.
  ///
  /// In en, this message translates to:
  /// **'❌ Error at document #{number}'**
  String integrityFailedSummary(int number);

  /// No description provided for @createCompany.
  ///
  /// In en, this message translates to:
  /// **'Create company'**
  String get createCompany;

  /// No description provided for @createCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'New company'**
  String get createCompanyTitle;

  /// No description provided for @createCompanyDesc.
  ///
  /// In en, this message translates to:
  /// **'Creates the company, default settings and document counters. 14-day trial.'**
  String get createCompanyDesc;

  /// No description provided for @companyIdSlug.
  ///
  /// In en, this message translates to:
  /// **'Company ID (Latin slug)'**
  String get companyIdSlug;

  /// No description provided for @companyIdSlugHint.
  ///
  /// In en, this message translates to:
  /// **'acme-logistics'**
  String get companyIdSlugHint;

  /// No description provided for @companyCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company \"{name}\" created'**
  String companyCreatedSuccess(String name);

  /// No description provided for @companyAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A company with this ID already exists'**
  String get companyAlreadyExists;

  /// No description provided for @invalidCompanyId.
  ///
  /// In en, this message translates to:
  /// **'ID: Latin letters, digits, hyphen, 3–40 chars'**
  String get invalidCompanyId;

  /// No description provided for @counterInvoices.
  ///
  /// In en, this message translates to:
  /// **'Tax Invoices'**
  String get counterInvoices;

  /// No description provided for @counterReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get counterReceipts;

  /// No description provided for @counterCreditNotes.
  ///
  /// In en, this message translates to:
  /// **'Credit Notes'**
  String get counterCreditNotes;

  /// No description provided for @counterDeliveryNotes.
  ///
  /// In en, this message translates to:
  /// **'Delivery Notes'**
  String get counterDeliveryNotes;

  /// No description provided for @counterTaxInvoiceReceipts.
  ///
  /// In en, this message translates to:
  /// **'Tax Invoice/Receipts'**
  String get counterTaxInvoiceReceipts;

  /// No description provided for @creditNoteReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Credit note reason is required'**
  String get creditNoteReasonRequired;

  /// No description provided for @creditNoteOnlyForIssued.
  ///
  /// In en, this message translates to:
  /// **'Credit note can only be created for an issued document'**
  String get creditNoteOnlyForIssued;

  /// No description provided for @creditNoteNotForCreditNote.
  ///
  /// In en, this message translates to:
  /// **'Cannot create credit note for a credit note'**
  String get creditNoteNotForCreditNote;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason is required'**
  String get reasonRequired;

  /// No description provided for @creditNoteCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Credit Note'**
  String get creditNoteCreateTitle;

  /// No description provided for @originalInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Original Invoice #{number}'**
  String originalInvoiceLabel(int number);

  /// No description provided for @clientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client: {name}'**
  String clientLabel(String name);

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount: ₪{amount}'**
  String amountLabel(String amount);

  /// No description provided for @creditNoteDescription.
  ///
  /// In en, this message translates to:
  /// **'The credit note will create a new document with negative amounts.\nThe original document will not change.'**
  String get creditNoteDescription;

  /// No description provided for @creditNoteReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit note reason *'**
  String get creditNoteReasonLabel;

  /// No description provided for @creditNoteReasonHint.
  ///
  /// In en, this message translates to:
  /// **'For example: quantity error'**
  String get creditNoteReasonHint;

  /// No description provided for @createCreditNoteButton.
  ///
  /// In en, this message translates to:
  /// **'Create Credit Note'**
  String get createCreditNoteButton;

  /// No description provided for @creditNoteCreateError.
  ///
  /// In en, this message translates to:
  /// **'Error creating credit note: {error}'**
  String creditNoteCreateError(String error);

  /// No description provided for @creditNoteIssuanceError.
  ///
  /// In en, this message translates to:
  /// **'Error issuing credit note from server'**
  String get creditNoteIssuanceError;

  /// No description provided for @periodLockedError.
  ///
  /// In en, this message translates to:
  /// **'Cannot create credit note — document date ({docDate}) is in a closed accounting period (until {lockDate})'**
  String periodLockedError(String docDate, String lockDate);

  /// No description provided for @allNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedRead;

  /// No description provided for @timeAgoNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timeAgoNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeAgoMinutes(int minutes);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr ago'**
  String timeAgoHours(int hours);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeAgoDays(int days);

  /// No description provided for @resourceUsage.
  ///
  /// In en, this message translates to:
  /// **'Resource Usage'**
  String get resourceUsage;

  /// No description provided for @noUsageData.
  ///
  /// In en, this message translates to:
  /// **'No usage data'**
  String get noUsageData;

  /// No description provided for @usageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading usage data'**
  String get usageLoadError;

  /// No description provided for @usersUsage.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersUsage;

  /// No description provided for @docsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Documents/month'**
  String get docsPerMonth;

  /// No description provided for @routesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Routes/day'**
  String get routesPerDay;

  /// No description provided for @paidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get paidUntil;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String daysRemaining(int days);

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @paymentProvider.
  ///
  /// In en, this message translates to:
  /// **'Payment provider'**
  String get paymentProvider;

  /// No description provided for @gracePeriodBanner.
  ///
  /// In en, this message translates to:
  /// **'Company is in grace period. Payment required to continue service.'**
  String get gracePeriodBanner;

  /// No description provided for @paymentPageOpened.
  ///
  /// In en, this message translates to:
  /// **'Payment page opened'**
  String get paymentPageOpened;

  /// No description provided for @cannotOpenPayment.
  ///
  /// In en, this message translates to:
  /// **'Cannot open payment page'**
  String get cannotOpenPayment;

  /// No description provided for @selectFormat.
  ///
  /// In en, this message translates to:
  /// **'Select format'**
  String get selectFormat;

  /// No description provided for @downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download receipt'**
  String get downloadReceipt;

  /// No description provided for @receiptCopied.
  ///
  /// In en, this message translates to:
  /// **'Receipt copied'**
  String get receiptCopied;

  /// No description provided for @receiptExportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting receipt'**
  String get receiptExportError;

  /// No description provided for @companyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading company data'**
  String get companyLoadError;

  /// No description provided for @periodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period:'**
  String get periodLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get toLabel;

  /// No description provided for @deliveriesTab.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveriesTab;

  /// No description provided for @invoicesTab.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoicesTab;

  /// No description provided for @driversTab.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get driversTab;

  /// No description provided for @totalPointsReport.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get totalPointsReport;

  /// No description provided for @completedReport.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedReport;

  /// No description provided for @pendingReport.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingReport;

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get onTheWay;

  /// No description provided for @cancelledReport.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledReport;

  /// No description provided for @totalPalletsReport.
  ///
  /// In en, this message translates to:
  /// **'Total pallets'**
  String get totalPalletsReport;

  /// No description provided for @palletsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Pallets delivered'**
  String get palletsDelivered;

  /// No description provided for @completionPercent.
  ///
  /// In en, this message translates to:
  /// **'Completion rate'**
  String get completionPercent;

  /// No description provided for @totalDocumentsReport.
  ///
  /// In en, this message translates to:
  /// **'Total documents'**
  String get totalDocumentsReport;

  /// No description provided for @taxInvoicesReport.
  ///
  /// In en, this message translates to:
  /// **'Tax invoices'**
  String get taxInvoicesReport;

  /// No description provided for @taxInvoiceReceiptsReport.
  ///
  /// In en, this message translates to:
  /// **'Tax invoice/receipts'**
  String get taxInvoiceReceiptsReport;

  /// No description provided for @receiptsReport.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receiptsReport;

  /// No description provided for @deliveryNotesReport.
  ///
  /// In en, this message translates to:
  /// **'Delivery notes'**
  String get deliveryNotesReport;

  /// No description provided for @creditNotesReport.
  ///
  /// In en, this message translates to:
  /// **'Credit notes'**
  String get creditNotesReport;

  /// No description provided for @netBeforeVatReport.
  ///
  /// In en, this message translates to:
  /// **'Total before VAT'**
  String get netBeforeVatReport;

  /// No description provided for @vatAmountReport.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatAmountReport;

  /// No description provided for @grossWithVatReport.
  ///
  /// In en, this message translates to:
  /// **'Total with VAT'**
  String get grossWithVatReport;

  /// No description provided for @noDataForPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noDataForPeriod;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @cancelledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledLabel;

  /// No description provided for @palletsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pallets'**
  String get palletsLabel;

  /// No description provided for @completionLabel.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get completionLabel;

  /// No description provided for @noDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'No driver'**
  String get noDriverAssigned;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @overviewSection.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewSection;

  /// No description provided for @usersAndRoles.
  ///
  /// In en, this message translates to:
  /// **'Users & Roles'**
  String get usersAndRoles;

  /// No description provided for @billingSection.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billingSection;

  /// No description provided for @auditAndCompliance.
  ///
  /// In en, this message translates to:
  /// **'Audit & Compliance'**
  String get auditAndCompliance;

  /// No description provided for @operationsSection.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operationsSection;

  /// No description provided for @accountingSection.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get accountingSection;

  /// No description provided for @userMenu.
  ///
  /// In en, this message translates to:
  /// **'User menu'**
  String get userMenu;

  /// No description provided for @menuLabel.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menuLabel;

  /// No description provided for @companyDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Company data not found'**
  String get companyDataNotFound;

  /// No description provided for @noSectionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sections available'**
  String get noSectionsAvailable;

  /// No description provided for @unknownRoleError.
  ///
  /// In en, this message translates to:
  /// **'Unknown role: {role}'**
  String unknownRoleError(String role);

  /// No description provided for @pleaseSelectCompany.
  ///
  /// In en, this message translates to:
  /// **'Please select a company to continue.'**
  String get pleaseSelectCompany;

  /// No description provided for @moduleFilter.
  ///
  /// In en, this message translates to:
  /// **'Module'**
  String get moduleFilter;

  /// No description provided for @eventTypeFilter.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get eventTypeFilter;

  /// No description provided for @userFilter.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userFilter;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @clearDateRange.
  ///
  /// In en, this message translates to:
  /// **'Clear date range'**
  String get clearDateRange;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// No description provided for @auditExportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String auditExportError(String error);

  /// No description provided for @auditLogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading audit log'**
  String get auditLogLoadError;

  /// No description provided for @noAuditRecords.
  ///
  /// In en, this message translates to:
  /// **'No records in audit log'**
  String get noAuditRecords;

  /// No description provided for @auditHistory.
  ///
  /// In en, this message translates to:
  /// **'History: {title}'**
  String auditHistory(String title);

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get historyLoadError;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get noEventsYet;

  /// No description provided for @moduleLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get moduleLogistics;

  /// No description provided for @moduleWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get moduleWarehouse;

  /// No description provided for @moduleAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get moduleAccounting;

  /// No description provided for @moduleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get moduleDispatcher;

  /// No description provided for @eventReceiptCreated.
  ///
  /// In en, this message translates to:
  /// **'Receipt issued'**
  String get eventReceiptCreated;

  /// No description provided for @eventCreditNoteCreated.
  ///
  /// In en, this message translates to:
  /// **'Credit note issued'**
  String get eventCreditNoteCreated;

  /// No description provided for @eventDocumentVoided.
  ///
  /// In en, this message translates to:
  /// **'Document voided before delivery'**
  String get eventDocumentVoided;

  /// No description provided for @eventInvoiceVoided.
  ///
  /// In en, this message translates to:
  /// **'Invoice voided'**
  String get eventInvoiceVoided;

  /// No description provided for @eventBillingStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Billing status changed'**
  String get eventBillingStatusChanged;

  /// No description provided for @eventTrialUntilChanged.
  ///
  /// In en, this message translates to:
  /// **'Trial period updated'**
  String get eventTrialUntilChanged;

  /// No description provided for @eventAccountingLockedUntilChanged.
  ///
  /// In en, this message translates to:
  /// **'Accounting lock updated'**
  String get eventAccountingLockedUntilChanged;

  /// No description provided for @eventInvoiceIssued.
  ///
  /// In en, this message translates to:
  /// **'Invoice issued'**
  String get eventInvoiceIssued;

  /// No description provided for @eventInvoicePrinted.
  ///
  /// In en, this message translates to:
  /// **'Invoice printed'**
  String get eventInvoicePrinted;

  /// No description provided for @eventInventoryAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Inventory adjusted'**
  String get eventInventoryAdjusted;

  /// No description provided for @eventInventoryCountCompleted.
  ///
  /// In en, this message translates to:
  /// **'Inventory count completed'**
  String get eventInventoryCountCompleted;

  /// No description provided for @eventInventoryCountApproved.
  ///
  /// In en, this message translates to:
  /// **'Inventory count approved'**
  String get eventInventoryCountApproved;

  /// No description provided for @eventRoutePublished.
  ///
  /// In en, this message translates to:
  /// **'Route published'**
  String get eventRoutePublished;

  /// No description provided for @eventDeliveryPointStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Delivery point status changed'**
  String get eventDeliveryPointStatusChanged;

  /// No description provided for @eventManualAssignment.
  ///
  /// In en, this message translates to:
  /// **'Manual assignment'**
  String get eventManualAssignment;

  /// No description provided for @eventPaymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get eventPaymentReceived;

  /// No description provided for @eventModuleChanged.
  ///
  /// In en, this message translates to:
  /// **'Module changed'**
  String get eventModuleChanged;

  /// No description provided for @eventPlanChanged.
  ///
  /// In en, this message translates to:
  /// **'Plan changed'**
  String get eventPlanChanged;

  /// No description provided for @eventBackupRecorded.
  ///
  /// In en, this message translates to:
  /// **'Backup recorded'**
  String get eventBackupRecorded;

  /// No description provided for @eventRetentionChecked.
  ///
  /// In en, this message translates to:
  /// **'Data retention checked'**
  String get eventRetentionChecked;

  /// No description provided for @deliveriesToday.
  ///
  /// In en, this message translates to:
  /// **'Deliveries today'**
  String get deliveriesToday;

  /// No description provided for @invoicesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Invoices this month'**
  String get invoicesThisMonth;

  /// No description provided for @warehouseMovements.
  ///
  /// In en, this message translates to:
  /// **'Warehouse movements'**
  String get warehouseMovements;

  /// No description provided for @activeDriversKpi.
  ///
  /// In en, this message translates to:
  /// **'Active drivers'**
  String get activeDriversKpi;

  /// No description provided for @docsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Documents this month'**
  String get docsThisMonth;

  /// No description provided for @printErrorsToday.
  ///
  /// In en, this message translates to:
  /// **'Print errors today: {count}'**
  String printErrorsToday(int count);

  /// No description provided for @accountSuspendedPayment.
  ///
  /// In en, this message translates to:
  /// **'Account suspended — payment required'**
  String get accountSuspendedPayment;

  /// No description provided for @paymentOverdueGrace.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue — grace period'**
  String get paymentOverdueGrace;

  /// No description provided for @recentEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent events'**
  String get recentEventsTitle;

  /// No description provided for @errorLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading events'**
  String get errorLoadingEvents;

  /// No description provided for @noRecentEvents.
  ///
  /// In en, this message translates to:
  /// **'No recent events'**
  String get noRecentEvents;

  /// No description provided for @teamMembers.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get teamMembers;

  /// No description provided for @errorLoadingUsers.
  ///
  /// In en, this message translates to:
  /// **'Error loading users'**
  String get errorLoadingUsers;

  /// No description provided for @noTeamMembers.
  ///
  /// In en, this message translates to:
  /// **'No team members'**
  String get noTeamMembers;

  /// No description provided for @roleUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated successfully'**
  String get roleUpdatedSuccess;

  /// No description provided for @errorUpdatingRole.
  ///
  /// In en, this message translates to:
  /// **'Error updating role: {error}'**
  String errorUpdatingRole(Object error);

  /// No description provided for @removeUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove user'**
  String get removeUserTitle;

  /// No description provided for @removeUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeUserConfirm(String name);

  /// No description provided for @userRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User removed successfully'**
  String get userRemovedSuccess;

  /// No description provided for @errorRemovingUser.
  ///
  /// In en, this message translates to:
  /// **'Error removing user: {error}'**
  String errorRemovingUser(Object error);

  /// No description provided for @roleSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperAdmin;

  /// No description provided for @roleDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriverLabel;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @statusInvited.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get statusInvited;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @usersLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Users limit reached ({active} / {limit})'**
  String usersLimitReached(int active, int limit);

  /// No description provided for @usersLimitUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Cannot invite more users. Upgrade your plan to increase the limit.'**
  String get usersLimitUpgrade;

  /// No description provided for @changeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get changeRole;

  /// No description provided for @removeUser.
  ///
  /// In en, this message translates to:
  /// **'Remove user'**
  String get removeUser;

  /// No description provided for @retryAttempts.
  ///
  /// In en, this message translates to:
  /// **'Retry attempts'**
  String get retryAttempts;

  /// No description provided for @totalEventsKpi.
  ///
  /// In en, this message translates to:
  /// **'Total events'**
  String get totalEventsKpi;

  /// No description provided for @successRate.
  ///
  /// In en, this message translates to:
  /// **'Success rate'**
  String get successRate;

  /// No description provided for @printEvents.
  ///
  /// In en, this message translates to:
  /// **'Print events'**
  String get printEvents;

  /// No description provided for @systemEvents.
  ///
  /// In en, this message translates to:
  /// **'System events'**
  String get systemEvents;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get filterSuccess;

  /// No description provided for @filterError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get filterError;

  /// No description provided for @filterFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get filterFailed;

  /// No description provided for @errorLoadingPrintEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading print events'**
  String get errorLoadingPrintEvents;

  /// No description provided for @noPrintEvents.
  ///
  /// In en, this message translates to:
  /// **'No print events'**
  String get noPrintEvents;

  /// No description provided for @errorLoadingSystemEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading system events'**
  String get errorLoadingSystemEvents;

  /// No description provided for @noSystemEvents.
  ///
  /// In en, this message translates to:
  /// **'No system events'**
  String get noSystemEvents;

  /// No description provided for @invoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Invoice: {id}'**
  String invoiceLabel(String id);

  /// No description provided for @printerUserLabel.
  ///
  /// In en, this message translates to:
  /// **'Printer: {printer} · User: {user}'**
  String printerUserLabel(String printer, String user);

  /// No description provided for @retryCountLabel.
  ///
  /// In en, this message translates to:
  /// **' · Retries: {count}'**
  String retryCountLabel(int count);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @billingErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading billing data'**
  String get billingErrorLoading;

  /// No description provided for @billingAccountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Account suspended'**
  String get billingAccountSuspended;

  /// No description provided for @billingAccountCancelled.
  ///
  /// In en, this message translates to:
  /// **'Account cancelled'**
  String get billingAccountCancelled;

  /// No description provided for @billingPaymentRequired.
  ///
  /// In en, this message translates to:
  /// **'Payment required to restore account access.'**
  String get billingPaymentRequired;

  /// No description provided for @billingContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support to reactivate the account.'**
  String get billingContactSupport;

  /// No description provided for @billingGraceDefault.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue — grace period ({days} days).'**
  String billingGraceDefault(int days);

  /// No description provided for @billingGraceRemaining.
  ///
  /// In en, this message translates to:
  /// **'Payment overdue — {remaining} days remaining in grace period.'**
  String billingGraceRemaining(int remaining);

  /// No description provided for @billingTrialRemaining.
  ///
  /// In en, this message translates to:
  /// **'Trial period — {remaining} days remaining'**
  String billingTrialRemaining(int remaining);

  /// No description provided for @billingPlanDetails.
  ///
  /// In en, this message translates to:
  /// **'Plan details'**
  String get billingPlanDetails;

  /// No description provided for @billingPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get billingPlan;

  /// No description provided for @billingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get billingStatusLabel;

  /// No description provided for @billingTrialEnds.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get billingTrialEnds;

  /// No description provided for @billingPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get billingPaidUntil;

  /// No description provided for @billingModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get billingModules;

  /// No description provided for @billingIncludedInPlan.
  ///
  /// In en, this message translates to:
  /// **'Included in plan'**
  String get billingIncludedInPlan;

  /// No description provided for @billingAddons.
  ///
  /// In en, this message translates to:
  /// **'Add-ons (addon)'**
  String get billingAddons;

  /// No description provided for @billingNoModules.
  ///
  /// In en, this message translates to:
  /// **'No modules available'**
  String get billingNoModules;

  /// No description provided for @billingUsage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get billingUsage;

  /// No description provided for @billingDocsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Documents / month'**
  String get billingDocsPerMonth;

  /// No description provided for @billingUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get billingUsers;

  /// No description provided for @billingRoutesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Routes / day'**
  String get billingRoutesPerDay;

  /// No description provided for @billingLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit: {limit}'**
  String billingLimit(int limit);

  /// No description provided for @billingSensitiveFields.
  ///
  /// In en, this message translates to:
  /// **'Sensitive fields (super admin only)'**
  String get billingSensitiveFields;

  /// No description provided for @billingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get billingInvoices;

  /// No description provided for @billingErrorLoadingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Error loading invoices'**
  String get billingErrorLoadingInvoices;

  /// No description provided for @billingNoInvoices.
  ///
  /// In en, this message translates to:
  /// **'No invoices'**
  String get billingNoInvoices;

  /// No description provided for @billingInvoiceDefault.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get billingInvoiceDefault;

  /// No description provided for @billingPlanWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse only'**
  String get billingPlanWarehouse;

  /// No description provided for @billingPlanOps.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get billingPlanOps;

  /// No description provided for @billingPlanFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get billingPlanFull;

  /// No description provided for @billingPlanCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get billingPlanCustom;

  /// No description provided for @billingStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get billingStatusActive;

  /// No description provided for @billingStatusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get billingStatusTrial;

  /// No description provided for @billingStatusGrace.
  ///
  /// In en, this message translates to:
  /// **'Grace period'**
  String get billingStatusGrace;

  /// No description provided for @billingStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get billingStatusSuspended;

  /// No description provided for @billingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get billingStatusCancelled;

  /// No description provided for @billingModuleWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get billingModuleWarehouse;

  /// No description provided for @billingModuleLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get billingModuleLogistics;

  /// No description provided for @billingModuleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get billingModuleDispatcher;

  /// No description provided for @billingModuleAccounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get billingModuleAccounting;

  /// No description provided for @billingModuleReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get billingModuleReports;

  /// No description provided for @billingInvoicePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get billingInvoicePaid;

  /// No description provided for @billingInvoicePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get billingInvoicePending;

  /// No description provided for @billingInvoiceOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get billingInvoiceOverdue;

  /// No description provided for @billingInvoiceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get billingInvoiceCancelled;

  /// No description provided for @settingsCompanyProfile.
  ///
  /// In en, this message translates to:
  /// **'Company profile'**
  String get settingsCompanyProfile;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @settingsCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get settingsCompanyName;

  /// No description provided for @settingsNameHebrew.
  ///
  /// In en, this message translates to:
  /// **'Name in Hebrew *'**
  String get settingsNameHebrew;

  /// No description provided for @settingsNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'Name in English'**
  String get settingsNameEnglish;

  /// No description provided for @settingsTaxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID *'**
  String get settingsTaxId;

  /// No description provided for @settingsAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get settingsAddress;

  /// No description provided for @settingsAddressHebrew.
  ///
  /// In en, this message translates to:
  /// **'Address in Hebrew'**
  String get settingsAddressHebrew;

  /// No description provided for @settingsAddressEnglish.
  ///
  /// In en, this message translates to:
  /// **'Address in English'**
  String get settingsAddressEnglish;

  /// No description provided for @settingsCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get settingsCity;

  /// No description provided for @settingsZipCode.
  ///
  /// In en, this message translates to:
  /// **'Zip code'**
  String get settingsZipCode;

  /// No description provided for @settingsPoBox.
  ///
  /// In en, this message translates to:
  /// **'P.O. Box'**
  String get settingsPoBox;

  /// No description provided for @settingsContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get settingsContactDetails;

  /// No description provided for @settingsPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get settingsPhone;

  /// No description provided for @settingsFax.
  ///
  /// In en, this message translates to:
  /// **'Fax'**
  String get settingsFax;

  /// No description provided for @settingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmail;

  /// No description provided for @settingsWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get settingsWebsite;

  /// No description provided for @settingsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read only'**
  String get settingsReadOnly;

  /// No description provided for @settingsSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get settingsSaving;

  /// No description provided for @settingsSaveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get settingsSaveProfile;

  /// No description provided for @settingsSaveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get settingsSaveSettings;

  /// No description provided for @settingsProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully'**
  String get settingsProfileSaved;

  /// No description provided for @settingsProfileError.
  ///
  /// In en, this message translates to:
  /// **'Error saving profile: {error}'**
  String settingsProfileError(String error);

  /// No description provided for @settingsSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSettingsSaved;

  /// No description provided for @settingsSettingsError.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String settingsSettingsError(String error);

  /// No description provided for @settingsSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'System settings'**
  String get settingsSystemSettings;

  /// No description provided for @settingsTaxSettings.
  ///
  /// In en, this message translates to:
  /// **'Tax settings'**
  String get settingsTaxSettings;

  /// No description provided for @settingsTaxIdBn.
  ///
  /// In en, this message translates to:
  /// **'Tax ID / BN'**
  String get settingsTaxIdBn;

  /// No description provided for @settingsVatRate.
  ///
  /// In en, this message translates to:
  /// **'VAT rate'**
  String get settingsVatRate;

  /// No description provided for @settingsTaxManagedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Tax settings are managed by the system administrator'**
  String get settingsTaxManagedByAdmin;

  /// No description provided for @settingsInvoiceSettings.
  ///
  /// In en, this message translates to:
  /// **'Invoice settings'**
  String get settingsInvoiceSettings;

  /// No description provided for @settingsInvoiceFooter.
  ///
  /// In en, this message translates to:
  /// **'Invoice footer text'**
  String get settingsInvoiceFooter;

  /// No description provided for @settingsPaymentTerms.
  ///
  /// In en, this message translates to:
  /// **'Payment terms'**
  String get settingsPaymentTerms;

  /// No description provided for @settingsBankDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank details'**
  String get settingsBankDetails;

  /// No description provided for @settingsDocNumbering.
  ///
  /// In en, this message translates to:
  /// **'Document numbering'**
  String get settingsDocNumbering;

  /// No description provided for @settingsTaxInvoice.
  ///
  /// In en, this message translates to:
  /// **'Tax invoice'**
  String get settingsTaxInvoice;

  /// No description provided for @settingsReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get settingsReceipt;

  /// No description provided for @settingsDeliveryNote.
  ///
  /// In en, this message translates to:
  /// **'Delivery note'**
  String get settingsDeliveryNote;

  /// No description provided for @settingsCreditNote.
  ///
  /// In en, this message translates to:
  /// **'Credit note'**
  String get settingsCreditNote;

  /// No description provided for @settingsAutoNumbering.
  ///
  /// In en, this message translates to:
  /// **'Automatic sequential numbering'**
  String get settingsAutoNumbering;

  /// No description provided for @settingsNumberingManagedBySystem.
  ///
  /// In en, this message translates to:
  /// **'Document numbering is managed automatically by the system'**
  String get settingsNumberingManagedBySystem;

  /// No description provided for @settingsPrintTemplates.
  ///
  /// In en, this message translates to:
  /// **'Print templates'**
  String get settingsPrintTemplates;

  /// No description provided for @settingsDefaultTemplate.
  ///
  /// In en, this message translates to:
  /// **'Default template'**
  String get settingsDefaultTemplate;

  /// No description provided for @settingsTemplatesAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Print template management is available to administrators only'**
  String get settingsTemplatesAdminOnly;

  /// No description provided for @settingsIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settingsIntegrations;

  /// No description provided for @settingsPrinting.
  ///
  /// In en, this message translates to:
  /// **'Printing'**
  String get settingsPrinting;

  /// No description provided for @settingsEmailIntegration.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsEmailIntegration;

  /// No description provided for @settingsApiKeys.
  ///
  /// In en, this message translates to:
  /// **'API keys'**
  String get settingsApiKeys;

  /// No description provided for @settingsConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get settingsConfigured;

  /// No description provided for @settingsNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get settingsNotConfigured;

  /// No description provided for @settingsIntegrationsAdminOnly.
  ///
  /// In en, this message translates to:
  /// **'Integration management is available to administrators only'**
  String get settingsIntegrationsAdminOnly;

  /// No description provided for @settingsEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settingsEditTooltip;

  /// No description provided for @integrationPrinterIp.
  ///
  /// In en, this message translates to:
  /// **'Printer IP address'**
  String get integrationPrinterIp;

  /// No description provided for @integrationPrinterPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get integrationPrinterPort;

  /// No description provided for @integrationPrinterModel.
  ///
  /// In en, this message translates to:
  /// **'Printer model'**
  String get integrationPrinterModel;

  /// No description provided for @integrationPrinterPaperSize.
  ///
  /// In en, this message translates to:
  /// **'Paper size'**
  String get integrationPrinterPaperSize;

  /// No description provided for @integrationSmtpHost.
  ///
  /// In en, this message translates to:
  /// **'SMTP server'**
  String get integrationSmtpHost;

  /// No description provided for @integrationSmtpPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get integrationSmtpPort;

  /// No description provided for @integrationSmtpUser.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get integrationSmtpUser;

  /// No description provided for @integrationSmtpPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get integrationSmtpPassword;

  /// No description provided for @integrationSmtpFrom.
  ///
  /// In en, this message translates to:
  /// **'Sender email'**
  String get integrationSmtpFrom;

  /// No description provided for @integrationSmtpSsl.
  ///
  /// In en, this message translates to:
  /// **'Use SSL'**
  String get integrationSmtpSsl;

  /// No description provided for @integrationWhatsappApiUrl.
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get integrationWhatsappApiUrl;

  /// No description provided for @integrationWhatsappApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get integrationWhatsappApiKey;

  /// No description provided for @integrationWhatsappPhoneId.
  ///
  /// In en, this message translates to:
  /// **'Phone number ID'**
  String get integrationWhatsappPhoneId;

  /// No description provided for @integrationApiKeyGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate new key'**
  String get integrationApiKeyGenerate;

  /// No description provided for @integrationApiKeyValue.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get integrationApiKeyValue;

  /// No description provided for @integrationApiKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'API key copied to clipboard'**
  String get integrationApiKeyCopied;

  /// No description provided for @integrationSaved.
  ///
  /// In en, this message translates to:
  /// **'Integration settings saved'**
  String get integrationSaved;

  /// No description provided for @integrationSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String integrationSaveError(Object error);

  /// No description provided for @integrationTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get integrationTestConnection;

  /// No description provided for @integrationTestSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful'**
  String get integrationTestSuccess;

  /// No description provided for @integrationTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {error}'**
  String integrationTestFailed(Object error);

  /// No description provided for @integrationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Configure {name}'**
  String integrationDialogTitle(Object name);

  /// No description provided for @integrationEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get integrationEnabled;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionTitle;

  /// No description provided for @noCompanySelectedSub.
  ///
  /// In en, this message translates to:
  /// **'No company selected'**
  String get noCompanySelectedSub;

  /// No description provided for @subscriptionManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Management'**
  String get subscriptionManagementTitle;

  /// No description provided for @changePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Plan'**
  String get changePlanTitle;

  /// No description provided for @paymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistoryTitle;

  /// No description provided for @currentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlanLabel;

  /// No description provided for @planWarehouseOnly.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Only'**
  String get planWarehouseOnly;

  /// No description provided for @planLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get planLogistics;

  /// No description provided for @planOps.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get planOps;

  /// No description provided for @planFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get planFull;

  /// No description provided for @planCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get planCustom;

  /// No description provided for @planDescWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Inventory management only'**
  String get planDescWarehouse;

  /// No description provided for @planDescLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics + dispatcher + reports (no warehouse)'**
  String get planDescLogistics;

  /// No description provided for @planDescOps.
  ///
  /// In en, this message translates to:
  /// **'Warehouse + logistics + dispatcher + reports (no accounting)'**
  String get planDescOps;

  /// No description provided for @planDescFull.
  ///
  /// In en, this message translates to:
  /// **'All modules including accounting and Greeninvoice'**
  String get planDescFull;

  /// No description provided for @planDescCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom plan'**
  String get planDescCustom;

  /// No description provided for @planAccountingNote.
  ///
  /// In en, this message translates to:
  /// **'Accounting (invoices, VAT, Greeninvoice) is included only in the Full plan. No separate module fee.'**
  String get planAccountingNote;

  /// No description provided for @planBackupNote.
  ///
  /// In en, this message translates to:
  /// **'Cloud DR (Google Firestore Backup): included in Full; other plans get free audit journal, dedicated export +₪149/mo. Google bill is paid by LogiRoute (~₪30–120/mo for the whole project).'**
  String get planBackupNote;

  /// No description provided for @billingDedicatedExportMonthly.
  ///
  /// In en, this message translates to:
  /// **'+₪{price}/mo — optional quarterly company data export'**
  String billingDedicatedExportMonthly(int price);

  /// No description provided for @planModulesLabel.
  ///
  /// In en, this message translates to:
  /// **'Modules:'**
  String get planModulesLabel;

  /// No description provided for @planCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get planCurrentBadge;

  /// No description provided for @accountingProviderSection.
  ///
  /// In en, this message translates to:
  /// **'Tax API integration'**
  String get accountingProviderSection;

  /// No description provided for @accountingProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get accountingProviderLabel;

  /// No description provided for @accountingProviderNone.
  ///
  /// In en, this message translates to:
  /// **'Built-in (LogiRoute)'**
  String get accountingProviderNone;

  /// No description provided for @accountingProviderExport.
  ///
  /// In en, this message translates to:
  /// **'File export (uniform CSV)'**
  String get accountingProviderExport;

  /// No description provided for @accountingProviderGreeninvoice.
  ///
  /// In en, this message translates to:
  /// **'Greeninvoice / Morning'**
  String get accountingProviderGreeninvoice;

  /// No description provided for @accountingProviderIcount.
  ///
  /// In en, this message translates to:
  /// **'iCount'**
  String get accountingProviderIcount;

  /// No description provided for @accountingProviderHint.
  ///
  /// In en, this message translates to:
  /// **'External provider handles tax compliance and document numbering.'**
  String get accountingProviderHint;

  /// No description provided for @accountingProviderConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configure API credentials'**
  String get accountingProviderConfigure;

  /// No description provided for @accountingProviderConfigured.
  ///
  /// In en, this message translates to:
  /// **'Credentials saved'**
  String get accountingProviderConfigured;

  /// No description provided for @accountingProviderSaved.
  ///
  /// In en, this message translates to:
  /// **'Accounting integration settings saved'**
  String get accountingProviderSaved;

  /// No description provided for @accountingProviderApiKey.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get accountingProviderApiKey;

  /// No description provided for @accountingProviderSecret.
  ///
  /// In en, this message translates to:
  /// **'Secret key'**
  String get accountingProviderSecret;

  /// No description provided for @accountingProviderToken.
  ///
  /// In en, this message translates to:
  /// **'API token'**
  String get accountingProviderToken;

  /// No description provided for @accountingProviderSandbox.
  ///
  /// In en, this message translates to:
  /// **'Sandbox mode'**
  String get accountingProviderSandbox;

  /// No description provided for @accountingProviderSandboxHint.
  ///
  /// In en, this message translates to:
  /// **'Use Greeninvoice test API (sandbox.d.greeninvoice.co.il)'**
  String get accountingProviderSandboxHint;

  /// No description provided for @accountingProviderTest.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get accountingProviderTest;

  /// No description provided for @accountingProviderTestOk.
  ///
  /// In en, this message translates to:
  /// **'Provider connection successful'**
  String get accountingProviderTestOk;

  /// No description provided for @accountingProviderTestFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection test failed: {detail}'**
  String accountingProviderTestFailed(String detail);

  /// No description provided for @accountingSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'External accounting sync'**
  String get accountingSyncTitle;

  /// No description provided for @accountingSyncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get accountingSyncStatusSynced;

  /// No description provided for @accountingSyncStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get accountingSyncStatusFailed;

  /// No description provided for @accountingSyncStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get accountingSyncStatusProcessing;

  /// No description provided for @accountingSyncRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry sync'**
  String get accountingSyncRetry;

  /// No description provided for @accountingSyncNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No sync records yet — issued invoices appear here.'**
  String get accountingSyncNoEntries;

  /// No description provided for @accountingSyncRetried.
  ///
  /// In en, this message translates to:
  /// **'Sync retry started'**
  String get accountingSyncRetried;

  /// No description provided for @accountingSyncDistribution.
  ///
  /// In en, this message translates to:
  /// **'Allocation #: {number}'**
  String accountingSyncDistribution(String number);

  /// No description provided for @accountingExternalDocNumber.
  ///
  /// In en, this message translates to:
  /// **'External doc #: {number}'**
  String accountingExternalDocNumber(String number);

  /// No description provided for @accountingSyncStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get accountingSyncStatusPending;

  /// No description provided for @accountingDocSyncColumn.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get accountingDocSyncColumn;

  /// No description provided for @accountingExternalSyncFailedWith.
  ///
  /// In en, this message translates to:
  /// **'Document issued, sync failed: {error}'**
  String accountingExternalSyncFailedWith(String error);

  /// No description provided for @billingAddonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage-based add-ons'**
  String get billingAddonsTitle;

  /// No description provided for @billingExtraDriverMonthly.
  ///
  /// In en, this message translates to:
  /// **'+₪{price}/month per driver above {included} included'**
  String billingExtraDriverMonthly(int price, int included);

  /// No description provided for @billingExtraWarehouseMonthly.
  ///
  /// In en, this message translates to:
  /// **'+₪{price}/month per warehouse location above {included} included'**
  String billingExtraWarehouseMonthly(int price, int included);

  /// No description provided for @promoMonthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'₪{price}/month (first {months} months)'**
  String promoMonthlyPrice(int price, int months);

  /// No description provided for @thenMonthlyPrice.
  ///
  /// In en, this message translates to:
  /// **'Then ₪{price}/month'**
  String thenMonthlyPrice(int price);

  /// No description provided for @setupAndIntegration.
  ///
  /// In en, this message translates to:
  /// **'Setup & integration: ₪{fee}'**
  String setupAndIntegration(int fee);

  /// No description provided for @setupAndIntegrationStr.
  ///
  /// In en, this message translates to:
  /// **'Setup & integration: {fee}'**
  String setupAndIntegrationStr(String fee);

  /// No description provided for @minimumMonths.
  ///
  /// In en, this message translates to:
  /// **'Minimum {months} months'**
  String minimumMonths(int months);

  /// No description provided for @paidUntilDate.
  ///
  /// In en, this message translates to:
  /// **'Paid until: {date}'**
  String paidUntilDate(String date);

  /// No description provided for @paymentProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment provider: {provider}'**
  String paymentProviderLabel(String provider);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @payNowButton.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNowButton;

  /// No description provided for @currentChip.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentChip;

  /// No description provided for @monthlyPriceShort.
  ///
  /// In en, this message translates to:
  /// **'₪{price}/month'**
  String monthlyPriceShort(int price);

  /// No description provided for @afterPromoPrice.
  ///
  /// In en, this message translates to:
  /// **'After {months} months: ₪{price}'**
  String afterPromoPrice(int months, int price);

  /// No description provided for @changePlanConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to {name}?'**
  String changePlanConfirmTitle(String name);

  /// No description provided for @changePlanConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Plan will change to {name}.\n₪{promoPrice}/month (first {promoMonths} months), then ₪{price}/month.\nSetup: ₪{setupFee}. Minimum {minMonths} months.\nChange takes effect immediately.'**
  String changePlanConfirmBody(String name, int promoPrice, int promoMonths,
      int price, int setupFee, int minMonths);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @changePlanButton.
  ///
  /// In en, this message translates to:
  /// **'Change Plan'**
  String get changePlanButton;

  /// No description provided for @planChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan changed to {name}'**
  String planChangedSuccess(String name);

  /// No description provided for @noPaymentHistorySub.
  ///
  /// In en, this message translates to:
  /// **'No payment history'**
  String get noPaymentHistorySub;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment received'**
  String get paymentReceived;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get subscriptionCancelled;

  /// No description provided for @providerPrefix.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}'**
  String providerPrefix(String provider);

  /// No description provided for @moduleNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This module is not available in your current plan'**
  String get moduleNotAvailable;

  /// No description provided for @upgradePlanButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlanButton;

  /// No description provided for @moduleWarehouseTitle.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get moduleWarehouseTitle;

  /// No description provided for @moduleLogisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get moduleLogisticsTitle;

  /// No description provided for @moduleDispatcherTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get moduleDispatcherTitle;

  /// No description provided for @moduleAccountingTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get moduleAccountingTitle;

  /// No description provided for @moduleReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moduleReportsTitle;

  /// No description provided for @priceArrow.
  ///
  /// In en, this message translates to:
  /// **'{promoPrice}/month (first {promoMonths} months) → {price}/month'**
  String priceArrow(String promoPrice, int promoMonths, String price);

  /// No description provided for @importInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Inventory'**
  String get importInventoryTitle;

  /// No description provided for @importClientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Clients'**
  String get importClientsTitle;

  /// No description provided for @importPreviewTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {total} | Valid: {valid} | Errors: {errors}'**
  String importPreviewTotal(int total, int valid, int errors);

  /// No description provided for @importPreviewStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get importPreviewStatus;

  /// No description provided for @importRowsButton.
  ///
  /// In en, this message translates to:
  /// **'Import {count} rows'**
  String importRowsButton(int count);

  /// No description provided for @importResultMessage.
  ///
  /// In en, this message translates to:
  /// **'Added {added} | Errors {errors}'**
  String importResultMessage(int added, int errors);

  /// No description provided for @importClientResultMessage.
  ///
  /// In en, this message translates to:
  /// **'Added {added} | Skipped {skipped} | Errors {errors}'**
  String importClientResultMessage(int added, int skipped, int errors);

  /// No description provided for @importRowError.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {error}'**
  String importRowError(int row, String error);

  /// No description provided for @colProductCode.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get colProductCode;

  /// No description provided for @colType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get colType;

  /// No description provided for @colNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get colNumber;

  /// No description provided for @colQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get colQuantity;

  /// No description provided for @colQuantityPerPallet.
  ///
  /// In en, this message translates to:
  /// **'Qty/Pallet'**
  String get colQuantityPerPallet;

  /// No description provided for @colClientNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get colClientNumber;

  /// No description provided for @colName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get colName;

  /// No description provided for @colAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get colAddress;

  /// No description provided for @colPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get colPhone;

  /// No description provided for @colZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get colZones;

  /// No description provided for @importFromExcelMenu.
  ///
  /// In en, this message translates to:
  /// **'Import from Excel'**
  String get importFromExcelMenu;

  /// No description provided for @exportToExcelMenu.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcelMenu;

  /// No description provided for @downloadTemplateMenu.
  ///
  /// In en, this message translates to:
  /// **'Download Template'**
  String get downloadTemplateMenu;

  /// No description provided for @fileExportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'File exported successfully'**
  String get fileExportedSuccess;

  /// No description provided for @templateDownloadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Template downloaded successfully'**
  String get templateDownloadedSuccess;

  /// No description provided for @loadProductTemplate.
  ///
  /// In en, this message translates to:
  /// **'Load product template'**
  String get loadProductTemplate;

  /// No description provided for @syncFromWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Sync from warehouse'**
  String get syncFromWarehouse;

  /// No description provided for @permanentDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanent delete'**
  String get permanentDelete;

  /// No description provided for @permanentDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete \"{name}\"? This action cannot be undone.'**
  String permanentDeleteConfirm(String name);

  /// No description provided for @duplicateProductCode.
  ///
  /// In en, this message translates to:
  /// **'SKU {code} already exists. Choose a different SKU.'**
  String duplicateProductCode(String code);

  /// No description provided for @syncFromWarehouseTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync from warehouse'**
  String get syncFromWarehouseTitle;

  /// No description provided for @syncFromWarehouseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create new products in catalog for all items that exist in warehouse but are missing from catalog?'**
  String get syncFromWarehouseConfirm;

  /// No description provided for @colDiameter.
  ///
  /// In en, this message translates to:
  /// **'Diameter'**
  String get colDiameter;

  /// No description provided for @colVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get colVolume;

  /// No description provided for @colPiecesPerBox.
  ///
  /// In en, this message translates to:
  /// **'Pieces/Box'**
  String get colPiecesPerBox;

  /// No description provided for @colAdditionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Info'**
  String get colAdditionalInfo;

  /// No description provided for @colContactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get colContactPerson;

  /// No description provided for @colVatId.
  ///
  /// In en, this message translates to:
  /// **'VAT ID'**
  String get colVatId;

  /// No description provided for @colLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get colLatitude;

  /// No description provided for @colLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get colLongitude;

  /// No description provided for @columnMappingHint.
  ///
  /// In en, this message translates to:
  /// **'Map file columns to system fields. Fields marked * are required.'**
  String get columnMappingHint;

  /// No description provided for @targetField.
  ///
  /// In en, this message translates to:
  /// **'Target Field'**
  String get targetField;

  /// No description provided for @sourceColumn.
  ///
  /// In en, this message translates to:
  /// **'Source Column'**
  String get sourceColumn;

  /// No description provided for @sampleValue.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get sampleValue;

  /// No description provided for @duplicateHandling.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Handling'**
  String get duplicateHandling;

  /// No description provided for @duplicateSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get duplicateSkip;

  /// No description provided for @duplicateUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update Existing'**
  String get duplicateUpdate;

  /// No description provided for @duplicateAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Anyway'**
  String get duplicateAdd;

  /// No description provided for @continueImport.
  ///
  /// In en, this message translates to:
  /// **'Continue Import'**
  String get continueImport;

  /// No description provided for @mapColumnsInventory.
  ///
  /// In en, this message translates to:
  /// **'Map Columns — Inventory'**
  String get mapColumnsInventory;

  /// No description provided for @mapColumnsClients.
  ///
  /// In en, this message translates to:
  /// **'Map Columns — Clients'**
  String get mapColumnsClients;

  /// No description provided for @mapColumnsDeliveryPoints.
  ///
  /// In en, this message translates to:
  /// **'Map Columns — Delivery Points'**
  String get mapColumnsDeliveryPoints;

  /// No description provided for @importDeliveryPointsMenu.
  ///
  /// In en, this message translates to:
  /// **'Import delivery points'**
  String get importDeliveryPointsMenu;

  /// No description provided for @importDeliveryPointsTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Delivery Points'**
  String get importDeliveryPointsTitle;

  /// No description provided for @loadDemoDataMenu.
  ///
  /// In en, this message translates to:
  /// **'Demo data for video'**
  String get loadDemoDataMenu;

  /// No description provided for @loadDemoDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Load demo delivery scenario for a 2-minute product video?'**
  String get loadDemoDataConfirm;

  /// No description provided for @loadDemoDataReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'Existing demo points will be replaced.'**
  String get loadDemoDataReplaceWarning;

  /// No description provided for @loadDemoDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'Demo data loaded ({count} points)'**
  String loadDemoDataSuccess(int count);

  /// No description provided for @importResultUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {updated} | Errors {errors}'**
  String importResultUpdated(int updated, int errors);

  /// No description provided for @importClientResultUpdated.
  ///
  /// In en, this message translates to:
  /// **'Added {added} | Updated {updated} | Skipped {skipped} | Errors {errors}'**
  String importClientResultUpdated(
      int added, int updated, int skipped, int errors);

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'Import from File'**
  String get importFromFile;

  /// No description provided for @supportConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Console'**
  String get supportConsoleTitle;

  /// No description provided for @verifyIntegrity.
  ///
  /// In en, this message translates to:
  /// **'Verify Integrity'**
  String get verifyIntegrity;

  /// No description provided for @exportDiagnosticJson.
  ///
  /// In en, this message translates to:
  /// **'Export Diagnostic JSON'**
  String get exportDiagnosticJson;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshData;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabBillingAudit.
  ///
  /// In en, this message translates to:
  /// **'Billing Audit'**
  String get tabBillingAudit;

  /// No description provided for @tabPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments ({count})'**
  String tabPayments(int count);

  /// No description provided for @tabNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications ({count}/{unread})'**
  String tabNotifications(int count, int unread);

  /// No description provided for @tabPushErrors.
  ///
  /// In en, this message translates to:
  /// **'Push Errors ({count})'**
  String tabPushErrors(int count);

  /// No description provided for @tabEmailErrors.
  ///
  /// In en, this message translates to:
  /// **'Email Errors ({count})'**
  String tabEmailErrors(int count);

  /// No description provided for @searchCompany.
  ///
  /// In en, this message translates to:
  /// **'Search company...'**
  String get searchCompany;

  /// No description provided for @backToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get backToList;

  /// No description provided for @chipStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get chipStatus;

  /// No description provided for @chipPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get chipPlan;

  /// No description provided for @chipUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get chipUsers;

  /// No description provided for @chipDocsMonth.
  ///
  /// In en, this message translates to:
  /// **'Docs/month'**
  String get chipDocsMonth;

  /// No description provided for @chipUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get chipUnread;

  /// No description provided for @sectionBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get sectionBilling;

  /// No description provided for @sectionLimitsUsage.
  ///
  /// In en, this message translates to:
  /// **'Limits & Usage'**
  String get sectionLimitsUsage;

  /// No description provided for @sectionModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get sectionModules;

  /// No description provided for @labelPaidUntil.
  ///
  /// In en, this message translates to:
  /// **'Paid until'**
  String get labelPaidUntil;

  /// No description provided for @labelTrialUntil.
  ///
  /// In en, this message translates to:
  /// **'Trial until'**
  String get labelTrialUntil;

  /// No description provided for @labelGracePeriodDays.
  ///
  /// In en, this message translates to:
  /// **'Grace period days'**
  String get labelGracePeriodDays;

  /// No description provided for @labelPaymentProvider.
  ///
  /// In en, this message translates to:
  /// **'Payment provider'**
  String get labelPaymentProvider;

  /// No description provided for @labelPaymentCustomerId.
  ///
  /// In en, this message translates to:
  /// **'Payment customer ID'**
  String get labelPaymentCustomerId;

  /// No description provided for @labelSubscriptionId.
  ///
  /// In en, this message translates to:
  /// **'Subscription ID'**
  String get labelSubscriptionId;

  /// No description provided for @labelMaxUsers.
  ///
  /// In en, this message translates to:
  /// **'Max users'**
  String get labelMaxUsers;

  /// No description provided for @labelActualUsers.
  ///
  /// In en, this message translates to:
  /// **'Actual users'**
  String get labelActualUsers;

  /// No description provided for @labelMaxDocsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Max docs/month'**
  String get labelMaxDocsPerMonth;

  /// No description provided for @labelDocsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Docs this month'**
  String get labelDocsThisMonth;

  /// No description provided for @userLimitReached.
  ///
  /// In en, this message translates to:
  /// **'⚠️ User limit reached'**
  String get userLimitReached;

  /// No description provided for @moduleEnabled.
  ///
  /// In en, this message translates to:
  /// **'✅ Enabled'**
  String get moduleEnabled;

  /// No description provided for @moduleDisabled.
  ///
  /// In en, this message translates to:
  /// **'❌ Disabled'**
  String get moduleDisabled;

  /// No description provided for @noAuditEvents.
  ///
  /// In en, this message translates to:
  /// **'No audit events'**
  String get noAuditEvents;

  /// No description provided for @noPaymentEvents.
  ///
  /// In en, this message translates to:
  /// **'No payment events'**
  String get noPaymentEvents;

  /// No description provided for @noPushErrors.
  ///
  /// In en, this message translates to:
  /// **'✅ No push delivery errors'**
  String get noPushErrors;

  /// No description provided for @noEmailErrors.
  ///
  /// In en, this message translates to:
  /// **'✅ No email delivery errors'**
  String get noEmailErrors;

  /// No description provided for @integrityOk.
  ///
  /// In en, this message translates to:
  /// **'✅ Integrity OK'**
  String get integrityOk;

  /// No description provided for @integrityFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Integrity FAILED: {error}'**
  String integrityFailed(String error);

  /// No description provided for @diagnosticCopied.
  ///
  /// In en, this message translates to:
  /// **'📋 Diagnostic JSON copied to clipboard'**
  String get diagnosticCopied;

  /// No description provided for @readStatus.
  ///
  /// In en, this message translates to:
  /// **'✓ read'**
  String get readStatus;

  /// No description provided for @unreadStatus.
  ///
  /// In en, this message translates to:
  /// **'● unread'**
  String get unreadStatus;

  /// No description provided for @moduleManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Module Management'**
  String get moduleManagementTitle;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// No description provided for @modulesInPlan.
  ///
  /// In en, this message translates to:
  /// **'Modules in Plan'**
  String get modulesInPlan;

  /// No description provided for @planUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Plan updated successfully'**
  String get planUpdatedSuccess;

  /// No description provided for @moduleToggleInfo.
  ///
  /// In en, this message translates to:
  /// **'Changes take effect immediately. Users trying to access a disabled module will see a \"Module not available\" screen.'**
  String get moduleToggleInfo;

  /// No description provided for @moduleWarehouseDesc.
  ///
  /// In en, this message translates to:
  /// **'Inventory management, counts, box types'**
  String get moduleWarehouseDesc;

  /// No description provided for @moduleLogisticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Delivery points, routes, map'**
  String get moduleLogisticsDesc;

  /// No description provided for @moduleDispatcherDesc.
  ///
  /// In en, this message translates to:
  /// **'Driver management, auto-distribution'**
  String get moduleDispatcherDesc;

  /// No description provided for @moduleAccountingDesc.
  ///
  /// In en, this message translates to:
  /// **'Invoices, receipts, credits, export'**
  String get moduleAccountingDesc;

  /// No description provided for @moduleReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moduleReports;

  /// No description provided for @moduleReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Delivery, invoice, driver statistics'**
  String get moduleReportsDesc;

  /// No description provided for @backupManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Management'**
  String get backupManagementTitle;

  /// No description provided for @tabBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups'**
  String get tabBackups;

  /// No description provided for @tabRestoreTests.
  ///
  /// In en, this message translates to:
  /// **'Restore Tests'**
  String get tabRestoreTests;

  /// No description provided for @tabComplianceReport.
  ///
  /// In en, this message translates to:
  /// **'Compliance Report'**
  String get tabComplianceReport;

  /// No description provided for @registerBackup.
  ///
  /// In en, this message translates to:
  /// **'Register Backup'**
  String get registerBackup;

  /// No description provided for @registerBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Backup'**
  String get registerBackupTitle;

  /// No description provided for @registerLogiRouteCloudBackup.
  ///
  /// In en, this message translates to:
  /// **'Register LogiRoute cloud backup'**
  String get registerLogiRouteCloudBackup;

  /// No description provided for @registerBackupOther.
  ///
  /// In en, this message translates to:
  /// **'Other storage…'**
  String get registerBackupOther;

  /// No description provided for @backupCloudInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get backupCloudInfoTitle;

  /// No description provided for @backupCloudInfoBody.
  ///
  /// In en, this message translates to:
  /// **'LogiRoute data is stored in Firebase cloud (project logiroute-app). The button above is an audit log entry for compliance — not a separate Google billing item.'**
  String get backupCloudInfoBody;

  /// No description provided for @backupCloudPricingNote.
  ///
  /// In en, this message translates to:
  /// **'Full plan: cloud DR included (LogiRoute pays project backup). Other plans: audit journal only; dedicated data export — +₪149/mo addon.'**
  String get backupCloudPricingNote;

  /// No description provided for @backupFirebaseLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Firebase project name'**
  String get backupFirebaseLocationLabel;

  /// No description provided for @backupFirebaseHelper.
  ///
  /// In en, this message translates to:
  /// **'For LogiRoute clients, logiroute-app is usually sufficient.'**
  String get backupFirebaseHelper;

  /// No description provided for @storageRecommended.
  ///
  /// In en, this message translates to:
  /// **'(recommended)'**
  String get storageRecommended;

  /// No description provided for @storageType.
  ///
  /// In en, this message translates to:
  /// **'Storage Type'**
  String get storageType;

  /// No description provided for @exactLocation.
  ///
  /// In en, this message translates to:
  /// **'Exact Location *'**
  String get exactLocation;

  /// No description provided for @backupRecorded.
  ///
  /// In en, this message translates to:
  /// **'Backup recorded successfully'**
  String get backupRecorded;

  /// No description provided for @registerRestoreTest.
  ///
  /// In en, this message translates to:
  /// **'Register Restore Test'**
  String get registerRestoreTest;

  /// No description provided for @registerRestoreTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Register Restore Test'**
  String get registerRestoreTestTitle;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup *'**
  String get restoreFromBackup;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Restore succeeded?'**
  String get restoreSuccess;

  /// No description provided for @restoreTestRecorded.
  ///
  /// In en, this message translates to:
  /// **'Restore test recorded'**
  String get restoreTestRecorded;

  /// No description provided for @noBackupsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No backups recorded'**
  String get noBackupsRecorded;

  /// No description provided for @noBackupsYetRegisterFirst.
  ///
  /// In en, this message translates to:
  /// **'No backups recorded — register a backup first'**
  String get noBackupsYetRegisterFirst;

  /// No description provided for @quarterlyBackupRequired.
  ///
  /// In en, this message translates to:
  /// **'Quarterly backup required!'**
  String get quarterlyBackupRequired;

  /// No description provided for @noRestoreTests.
  ///
  /// In en, this message translates to:
  /// **'No restore tests'**
  String get noRestoreTests;

  /// No description provided for @restoreSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Restore succeeded'**
  String get restoreSucceeded;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailed;

  /// No description provided for @complianceOk.
  ///
  /// In en, this message translates to:
  /// **'Compliance — OK'**
  String get complianceOk;

  /// No description provided for @complianceIssues.
  ///
  /// In en, this message translates to:
  /// **'Compliance issues found'**
  String get complianceIssues;

  /// No description provided for @labelQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get labelQuarter;

  /// No description provided for @labelQuarterlyBackup.
  ///
  /// In en, this message translates to:
  /// **'Quarterly backup'**
  String get labelQuarterlyBackup;

  /// No description provided for @labelBackupDue.
  ///
  /// In en, this message translates to:
  /// **'Backup due'**
  String get labelBackupDue;

  /// No description provided for @labelBackupsRecorded.
  ///
  /// In en, this message translates to:
  /// **'Backups recorded'**
  String get labelBackupsRecorded;

  /// No description provided for @labelLastRestoreTest.
  ///
  /// In en, this message translates to:
  /// **'Last restore test'**
  String get labelLastRestoreTest;

  /// No description provided for @labelRestoreTests.
  ///
  /// In en, this message translates to:
  /// **'Restore tests'**
  String get labelRestoreTests;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'✅ Done'**
  String get statusDone;

  /// No description provided for @statusNotDone.
  ///
  /// In en, this message translates to:
  /// **'❌ Not done'**
  String get statusNotDone;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @statusSucceeded.
  ///
  /// In en, this message translates to:
  /// **'✅ Succeeded'**
  String get statusSucceeded;

  /// No description provided for @statusNotDoneOrFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Not done/Failed'**
  String get statusNotDoneOrFailed;

  /// No description provided for @storageGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get storageGoogleDrive;

  /// No description provided for @storageOneDrive.
  ///
  /// In en, this message translates to:
  /// **'OneDrive'**
  String get storageOneDrive;

  /// No description provided for @storageDropbox.
  ///
  /// In en, this message translates to:
  /// **'Dropbox'**
  String get storageDropbox;

  /// No description provided for @storageAwsS3.
  ///
  /// In en, this message translates to:
  /// **'AWS S3'**
  String get storageAwsS3;

  /// No description provided for @storageExternalHdd.
  ///
  /// In en, this message translates to:
  /// **'External HDD'**
  String get storageExternalHdd;

  /// No description provided for @storageNas.
  ///
  /// In en, this message translates to:
  /// **'NAS'**
  String get storageNas;

  /// No description provided for @storageUsb.
  ///
  /// In en, this message translates to:
  /// **'USB / Flash'**
  String get storageUsb;

  /// No description provided for @storageFirebase.
  ///
  /// In en, this message translates to:
  /// **'Firebase Backup'**
  String get storageFirebase;

  /// No description provided for @storageLocalServer.
  ///
  /// In en, this message translates to:
  /// **'Local Server'**
  String get storageLocalServer;

  /// No description provided for @storageFtp.
  ///
  /// In en, this message translates to:
  /// **'FTP / SFTP'**
  String get storageFtp;

  /// No description provided for @storageOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get storageOther;

  /// No description provided for @hintGoogleDrive.
  ///
  /// In en, this message translates to:
  /// **'Folder link (https://drive.google.com/...)'**
  String get hintGoogleDrive;

  /// No description provided for @hintOneDrive.
  ///
  /// In en, this message translates to:
  /// **'Folder link (https://onedrive.live.com/...)'**
  String get hintOneDrive;

  /// No description provided for @hintDropbox.
  ///
  /// In en, this message translates to:
  /// **'Folder link (https://dropbox.com/...)'**
  String get hintDropbox;

  /// No description provided for @hintAwsS3.
  ///
  /// In en, this message translates to:
  /// **'Bucket and path (s3://bucket/path/)'**
  String get hintAwsS3;

  /// No description provided for @hintExternalHdd.
  ///
  /// In en, this message translates to:
  /// **'Drive name and path (D:\\Backups\\LogiRoute)'**
  String get hintExternalHdd;

  /// No description provided for @hintNas.
  ///
  /// In en, this message translates to:
  /// **'Address and path (\\\\192.168.1.10\\backups)'**
  String get hintNas;

  /// No description provided for @hintUsb.
  ///
  /// In en, this message translates to:
  /// **'Device name and path (E:\\LogiRoute_Backup)'**
  String get hintUsb;

  /// No description provided for @hintFirebase.
  ///
  /// In en, this message translates to:
  /// **'Project name (logiroute-app)'**
  String get hintFirebase;

  /// No description provided for @hintLocalServer.
  ///
  /// In en, this message translates to:
  /// **'Server name and path (/srv/backups/logiroute)'**
  String get hintLocalServer;

  /// No description provided for @hintFtp.
  ///
  /// In en, this message translates to:
  /// **'Server address (ftp://server.com/backups/)'**
  String get hintFtp;

  /// No description provided for @hintOther.
  ///
  /// In en, this message translates to:
  /// **'Describe the exact location'**
  String get hintOther;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethodLabel;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @cheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get cheque;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get bankTransfer;

  /// No description provided for @creditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get creditCard;

  /// No description provided for @paymentBankNumber.
  ///
  /// In en, this message translates to:
  /// **'Bank no.'**
  String get paymentBankNumber;

  /// No description provided for @paymentBranchNumber.
  ///
  /// In en, this message translates to:
  /// **'Branch no.'**
  String get paymentBranchNumber;

  /// No description provided for @paymentAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account no.'**
  String get paymentAccountNumber;

  /// No description provided for @paymentChequeNumber.
  ///
  /// In en, this message translates to:
  /// **'Cheque no.'**
  String get paymentChequeNumber;

  /// No description provided for @paymentDueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment due date'**
  String get paymentDueDateLabel;

  /// No description provided for @paymentClearingHouse.
  ///
  /// In en, this message translates to:
  /// **'Clearing company'**
  String get paymentClearingHouse;

  /// No description provided for @paymentClearingIsracard.
  ///
  /// In en, this message translates to:
  /// **'Isracard'**
  String get paymentClearingIsracard;

  /// No description provided for @paymentClearingCal.
  ///
  /// In en, this message translates to:
  /// **'Cal'**
  String get paymentClearingCal;

  /// No description provided for @paymentClearingDiners.
  ///
  /// In en, this message translates to:
  /// **'Diners'**
  String get paymentClearingDiners;

  /// No description provided for @paymentClearingAmex.
  ///
  /// In en, this message translates to:
  /// **'American Express'**
  String get paymentClearingAmex;

  /// No description provided for @paymentClearingLeumi.
  ///
  /// In en, this message translates to:
  /// **'Leumi Card'**
  String get paymentClearingLeumi;

  /// No description provided for @paymentCardName.
  ///
  /// In en, this message translates to:
  /// **'Card name'**
  String get paymentCardName;

  /// No description provided for @paymentDealType.
  ///
  /// In en, this message translates to:
  /// **'Transaction type'**
  String get paymentDealType;

  /// No description provided for @paymentDealRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get paymentDealRegular;

  /// No description provided for @paymentDealInstallments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get paymentDealInstallments;

  /// No description provided for @paymentDealCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get paymentDealCredit;

  /// No description provided for @paymentInstallmentCount.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get paymentInstallmentCount;

  /// No description provided for @paymentBankRequired.
  ///
  /// In en, this message translates to:
  /// **'Bank number required'**
  String get paymentBankRequired;

  /// No description provided for @paymentBranchRequired.
  ///
  /// In en, this message translates to:
  /// **'Branch number required'**
  String get paymentBranchRequired;

  /// No description provided for @paymentAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Account number required'**
  String get paymentAccountRequired;

  /// No description provided for @paymentChequeRequired.
  ///
  /// In en, this message translates to:
  /// **'Cheque number required'**
  String get paymentChequeRequired;

  /// No description provided for @paymentDueDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Due date required'**
  String get paymentDueDateRequired;

  /// No description provided for @paymentInstallmentRange.
  ///
  /// In en, this message translates to:
  /// **'Installments: 2–36'**
  String get paymentInstallmentRange;

  /// No description provided for @dispatcherTaxInvoiceReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Tax invoice/receipt for dispatcher'**
  String get dispatcherTaxInvoiceReceiptTitle;

  /// No description provided for @dispatcherTaxInvoiceReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Allow dispatchers to issue חשבונית מס/קבלה when payment is received at delivery'**
  String get dispatcherTaxInvoiceReceiptHint;

  /// No description provided for @createTaxInvoiceReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Create tax invoice/receipt'**
  String get createTaxInvoiceReceiptTitle;

  /// No description provided for @createTaxInvoiceReceiptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Tax invoice/receipt (paid)'**
  String get createTaxInvoiceReceiptTooltip;

  /// No description provided for @notSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get notSelected;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidStatus;

  /// No description provided for @totalToPay.
  ///
  /// In en, this message translates to:
  /// **'Total to pay'**
  String get totalToPay;

  /// No description provided for @paymentReceivedCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Payment received (Tax Invoice/Receipt)'**
  String get paymentReceivedCheckbox;

  /// No description provided for @paymentReceivedHint.
  ///
  /// In en, this message translates to:
  /// **'Check if customer paid — document becomes tax invoice-receipt'**
  String get paymentReceivedHint;

  /// No description provided for @createDeliveryNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Delivery Note'**
  String get createDeliveryNoteTitle;

  /// No description provided for @createInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoiceTitle;

  /// No description provided for @creatingDoc.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creatingDoc;

  /// No description provided for @createAndPrint.
  ///
  /// In en, this message translates to:
  /// **'Create and print'**
  String get createAndPrint;

  /// No description provided for @createDeliveryNoteBtn.
  ///
  /// In en, this message translates to:
  /// **'Create delivery note'**
  String get createDeliveryNoteBtn;

  /// No description provided for @deliveryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery date:'**
  String get deliveryDateLabel;

  /// No description provided for @paymentTermsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment terms:'**
  String get paymentTermsLabel;

  /// No description provided for @days30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get days30;

  /// No description provided for @days60.
  ///
  /// In en, this message translates to:
  /// **'60 days'**
  String get days60;

  /// No description provided for @days90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get days90;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualEntry;

  /// No description provided for @payUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay until:'**
  String get payUntilLabel;

  /// No description provided for @itemLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemLabel;

  /// No description provided for @cartonsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cartons'**
  String get cartonsLabel;

  /// No description provided for @pricePerUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Price/unit'**
  String get pricePerUnitLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount:'**
  String get discountLabel;

  /// No description provided for @clientLabelColon.
  ///
  /// In en, this message translates to:
  /// **'Client:'**
  String get clientLabelColon;

  /// No description provided for @addressLabelColon.
  ///
  /// In en, this message translates to:
  /// **'Address:'**
  String get addressLabelColon;

  /// No description provided for @driverLabelColon.
  ///
  /// In en, this message translates to:
  /// **'Driver:'**
  String get driverLabelColon;

  /// No description provided for @truckLabelColon.
  ///
  /// In en, this message translates to:
  /// **'Truck:'**
  String get truckLabelColon;

  /// No description provided for @clientKvLabel.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientKvLabel;

  /// No description provided for @addressKvLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressKvLabel;

  /// No description provided for @driverKvLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverKvLabel;

  /// No description provided for @truckKvLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get truckKvLabel;

  /// No description provided for @deliveryDateKvLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery date'**
  String get deliveryDateKvLabel;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @departureTimeValue.
  ///
  /// In en, this message translates to:
  /// **'Departure: 07:00'**
  String get departureTimeValue;

  /// No description provided for @userNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'User not logged in — cannot create document'**
  String get userNotLoggedIn;

  /// No description provided for @serverIssuanceError.
  ///
  /// In en, this message translates to:
  /// **'Error issuing document from server'**
  String get serverIssuanceError;

  /// No description provided for @deliveryNoteAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Delivery note already exists (#{docNum})'**
  String deliveryNoteAlreadyExists(int docNum);

  /// No description provided for @deliveryNoteCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Delivery note created (#{docNum})'**
  String deliveryNoteCreatedSuccess(int docNum);

  /// No description provided for @taxInvoiceReceiptCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Tax invoice/receipt created (#{docNum})'**
  String taxInvoiceReceiptCreatedSuccess(int docNum);

  /// No description provided for @invoiceCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Invoice created (#{docNum})'**
  String invoiceCreatedSuccess(int docNum);

  /// No description provided for @invoicePeriodLockedError.
  ///
  /// In en, this message translates to:
  /// **'Date {date} is in a closed accounting period (until {lockedUntil}). Choose a later date.'**
  String invoicePeriodLockedError(String date, String lockedUntil);

  /// No description provided for @possibleDuplicateOrder.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate order'**
  String get possibleDuplicateOrder;

  /// No description provided for @exactDuplicateFound.
  ///
  /// In en, this message translates to:
  /// **'Exact duplicate found for {name}!'**
  String exactDuplicateFound(String name);

  /// No description provided for @existingOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'Existing orders found for {name}:'**
  String existingOrdersFound(String name);

  /// No description provided for @checkNotDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Make sure this is not a duplicate order!'**
  String get checkNotDuplicate;

  /// No description provided for @deleteDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Delete duplicates'**
  String get deleteDuplicates;

  /// No description provided for @driverRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver route'**
  String get driverRouteTitle;

  /// No description provided for @driverAnotherRoutePoints.
  ///
  /// In en, this message translates to:
  /// **'Another route: {count} stops'**
  String driverAnotherRoutePoints(int count);

  /// No description provided for @wazeOpenError.
  ///
  /// In en, this message translates to:
  /// **'Error opening Waze: {error}'**
  String wazeOpenError(String error);

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @percentCompleted.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String percentCompleted(Object percent);

  /// No description provided for @nPoints.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String nPoints(Object count);

  /// No description provided for @shiftScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Shift schedule'**
  String get shiftScheduleTitle;

  /// No description provided for @shiftWorkingDays.
  ///
  /// In en, this message translates to:
  /// **'Working days'**
  String get shiftWorkingDays;

  /// No description provided for @shiftDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get shiftDayMon;

  /// No description provided for @shiftDayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get shiftDayTue;

  /// No description provided for @shiftDayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get shiftDayWed;

  /// No description provided for @shiftDayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get shiftDayThu;

  /// No description provided for @shiftDayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get shiftDayFri;

  /// No description provided for @shiftDaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get shiftDaySat;

  /// No description provided for @shiftDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get shiftDaySun;

  /// No description provided for @shiftStart.
  ///
  /// In en, this message translates to:
  /// **'Shift start'**
  String get shiftStart;

  /// No description provided for @shiftEnd.
  ///
  /// In en, this message translates to:
  /// **'Shift end'**
  String get shiftEnd;

  /// No description provided for @shiftSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get shiftSaved;

  /// No description provided for @shiftRoutingSection.
  ///
  /// In en, this message translates to:
  /// **'Routing parameters'**
  String get shiftRoutingSection;

  /// No description provided for @routingAvgSpeedKmh.
  ///
  /// In en, this message translates to:
  /// **'Average speed (km/h)'**
  String get routingAvgSpeedKmh;

  /// No description provided for @routingServiceMinutes.
  ///
  /// In en, this message translates to:
  /// **'Service time per stop (min)'**
  String get routingServiceMinutes;

  /// No description provided for @routingDeliveryDayMode.
  ///
  /// In en, this message translates to:
  /// **'Default delivery date in invoices'**
  String get routingDeliveryDayMode;

  /// No description provided for @deliveryDaySame.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get deliveryDaySame;

  /// No description provided for @deliveryDayNext.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get deliveryDayNext;

  /// No description provided for @deliveryDayNextWorking.
  ///
  /// In en, this message translates to:
  /// **'Next working day'**
  String get deliveryDayNextWorking;

  /// No description provided for @shiftLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String shiftLoadError(String error);

  /// No description provided for @shiftSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String shiftSaveError(String error);

  /// No description provided for @shiftNoCompanyId.
  ///
  /// In en, this message translates to:
  /// **'Company not selected'**
  String get shiftNoCompanyId;

  /// No description provided for @shiftHolidaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Holidays (GPS off)'**
  String get shiftHolidaysTitle;

  /// No description provided for @shiftLoadHolidays.
  ///
  /// In en, this message translates to:
  /// **'Load holidays'**
  String get shiftLoadHolidays;

  /// No description provided for @shiftNoHolidays.
  ///
  /// In en, this message translates to:
  /// **'No holidays defined'**
  String get shiftNoHolidays;

  /// No description provided for @shiftHolidaysLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} holidays'**
  String shiftHolidaysLoaded(int count);

  /// No description provided for @shiftHolidaysLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading holidays: {error}'**
  String shiftHolidaysLoadError(String error);

  /// No description provided for @taskNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Task (no goods)'**
  String get taskNoteLabel;

  /// No description provided for @taskNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Collect check, return, etc.'**
  String get taskNoteHint;

  /// No description provided for @adminActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get adminActivityLog;

  /// No description provided for @appBarGroupReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get appBarGroupReports;

  /// No description provided for @appBarGroupWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get appBarGroupWarehouse;

  /// No description provided for @appBarGroupCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get appBarGroupCompany;

  /// No description provided for @appBarGroupBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get appBarGroupBilling;

  /// No description provided for @appBarGroupPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get appBarGroupPlatform;

  /// No description provided for @appBarGroupLogistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get appBarGroupLogistics;

  /// No description provided for @appBarGroupArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive & data'**
  String get appBarGroupArchive;

  /// No description provided for @appBarGroupOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get appBarGroupOperations;

  /// No description provided for @appBarGroupImportExport.
  ///
  /// In en, this message translates to:
  /// **'Import & export'**
  String get appBarGroupImportExport;

  /// No description provided for @appBarGroupHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get appBarGroupHelp;

  /// No description provided for @ownerNavOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get ownerNavOverview;

  /// No description provided for @ownerNavManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get ownerNavManagement;

  /// No description provided for @ownerNavOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get ownerNavOperations;

  /// No description provided for @ownerNavCompliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get ownerNavCompliance;

  /// No description provided for @period24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get period24h;

  /// No description provided for @period48h.
  ///
  /// In en, this message translates to:
  /// **'48 hours'**
  String get period48h;

  /// No description provided for @periodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// No description provided for @searchActivityHint.
  ///
  /// In en, this message translates to:
  /// **'Search user or action...'**
  String get searchActivityHint;

  /// No description provided for @noActivityEvents.
  ///
  /// In en, this message translates to:
  /// **'No events for selected period'**
  String get noActivityEvents;

  /// No description provided for @auditSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Business audit'**
  String get auditSourceLabel;

  /// No description provided for @accessSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Access log'**
  String get accessSourceLabel;

  /// No description provided for @accessEventLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get accessEventLogin;

  /// No description provided for @accessEventLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get accessEventLogout;

  /// No description provided for @accessEventViewDocument.
  ///
  /// In en, this message translates to:
  /// **'Viewed document'**
  String get accessEventViewDocument;

  /// No description provided for @accessEventPrintDocument.
  ///
  /// In en, this message translates to:
  /// **'Printed document'**
  String get accessEventPrintDocument;

  /// No description provided for @accessEventExportData.
  ///
  /// In en, this message translates to:
  /// **'Exported data'**
  String get accessEventExportData;

  /// No description provided for @accessEventCreateDocument.
  ///
  /// In en, this message translates to:
  /// **'Created document'**
  String get accessEventCreateDocument;

  /// No description provided for @accessEventCancelDocument.
  ///
  /// In en, this message translates to:
  /// **'Cancelled document'**
  String get accessEventCancelDocument;

  /// No description provided for @accessEventViewAuditLog.
  ///
  /// In en, this message translates to:
  /// **'Viewed audit log'**
  String get accessEventViewAuditLog;

  /// No description provided for @accessEventViewReport.
  ///
  /// In en, this message translates to:
  /// **'Viewed report'**
  String get accessEventViewReport;

  /// No description provided for @accessEventAdminAction.
  ///
  /// In en, this message translates to:
  /// **'Admin action'**
  String get accessEventAdminAction;

  /// No description provided for @activityCsvUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get activityCsvUser;

  /// No description provided for @activityCsvAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get activityCsvAction;

  /// No description provided for @activityCsvWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get activityCsvWhen;

  /// No description provided for @activityCsvSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get activityCsvSource;

  /// No description provided for @errorLoadingWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error loading: {error}'**
  String errorLoadingWithDetail(String error);

  /// No description provided for @errorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'❌ Error: {error}'**
  String errorWithDetail(String error);

  /// No description provided for @savedSuccessCheck.
  ///
  /// In en, this message translates to:
  /// **'✅ Saved'**
  String get savedSuccessCheck;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get pickDate;

  /// No description provided for @billingStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Billing Status'**
  String get billingStatusSection;

  /// No description provided for @trialPeriodSection.
  ///
  /// In en, this message translates to:
  /// **'Trial Period'**
  String get trialPeriodSection;

  /// No description provided for @trialPeriodDesc.
  ///
  /// In en, this message translates to:
  /// **'When billingStatus = trial, access expires after this date.'**
  String get trialPeriodDesc;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @paymentPaidUntilSection.
  ///
  /// In en, this message translates to:
  /// **'Payment — Paid Until'**
  String get paymentPaidUntilSection;

  /// No description provided for @paymentPaidUntilDesc.
  ///
  /// In en, this message translates to:
  /// **'Source of truth for billing automation. After this date → grace → suspended.'**
  String get paymentPaidUntilDesc;

  /// No description provided for @accountingPeriodLockSection.
  ///
  /// In en, this message translates to:
  /// **'Accounting Period Lock'**
  String get accountingPeriodLockSection;

  /// No description provided for @accountingPeriodLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Documents with deliveryDate ≤ this date cannot be created or modified.'**
  String get accountingPeriodLockDesc;

  /// No description provided for @notSetAllPeriodsOpen.
  ///
  /// In en, this message translates to:
  /// **'Not set (all periods open)'**
  String get notSetAllPeriodsOpen;

  /// No description provided for @unlockAllPeriods.
  ///
  /// In en, this message translates to:
  /// **'Unlock all periods'**
  String get unlockAllPeriods;

  /// No description provided for @usersLoseAccessWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Users will lose all access (read + write blocked)'**
  String get usersLoseAccessWarning;

  /// No description provided for @trialExpiredBlocked.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Trial has expired — access is blocked'**
  String get trialExpiredBlocked;

  /// No description provided for @paymentExpiredWarning.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Payment expired — billingEnforcer will transition to grace/suspended'**
  String get paymentExpiredWarning;

  /// No description provided for @gracePeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace period:'**
  String get gracePeriodLabel;

  /// No description provided for @companyIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Company: {id}'**
  String companyIdLabel(String id);

  /// No description provided for @locationNotReady.
  ///
  /// In en, this message translates to:
  /// **'Location is not ready'**
  String get locationNotReady;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to continue.'**
  String get locationPermissionRequired;

  /// No description provided for @enableDeviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enable device location to continue.'**
  String get enableDeviceLocation;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @checkAgain.
  ///
  /// In en, this message translates to:
  /// **'Check Again'**
  String get checkAgain;

  /// No description provided for @locationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Permission is permanently denied. Open app settings to allow location.'**
  String get locationDeniedForever;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get pendingApprovalTitle;

  /// No description provided for @pendingApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'Registration received successfully.\nThe system administrator will assign you to a company and assign a role.'**
  String get pendingApprovalBody;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Register for LogiRoute'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After registration, the system administrator will assign you to a company'**
  String get registerSubtitle;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerButton;

  /// No description provided for @alreadyHaveAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account — Login'**
  String get alreadyHaveAccountLogin;

  /// No description provided for @minSixCharacters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get minSixCharacters;

  /// No description provided for @invalidEmailShort.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmailShort;

  /// No description provided for @creditNoteCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Credit note created successfully'**
  String get creditNoteCreatedSuccess;

  /// No description provided for @originalDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Original document'**
  String get originalDocumentLabel;

  /// No description provided for @correctionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Correction type'**
  String get correctionTypeLabel;

  /// No description provided for @fullCorrectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Full correction'**
  String get fullCorrectionTitle;

  /// No description provided for @fullCorrectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All lines from the original document'**
  String get fullCorrectionSubtitle;

  /// No description provided for @partialCorrectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Partial correction'**
  String get partialCorrectionTitle;

  /// No description provided for @partialCorrectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit/remove lines'**
  String get partialCorrectionSubtitle;

  /// No description provided for @correctionLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit lines'**
  String get correctionLinesTitle;

  /// No description provided for @correctionSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Credit summary'**
  String get correctionSummaryTitle;

  /// No description provided for @correctionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Correction reason *'**
  String get correctionReasonLabel;

  /// No description provided for @descriptionIndex.
  ///
  /// In en, this message translates to:
  /// **'Description {index}'**
  String descriptionIndex(int index);

  /// No description provided for @importNoCompanySelected.
  ///
  /// In en, this message translates to:
  /// **'Error: no company selected'**
  String get importNoCompanySelected;

  /// No description provided for @importBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get importBack;

  /// No description provided for @importClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get importClose;

  /// No description provided for @importCount.
  ///
  /// In en, this message translates to:
  /// **'Import ({count})'**
  String importCount(int count);

  /// No description provided for @noBusinessTypesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No business types available'**
  String get noBusinessTypesAvailable;

  /// No description provided for @noTemplatesForBusinessType.
  ///
  /// In en, this message translates to:
  /// **'No templates available for this business type'**
  String get noTemplatesForBusinessType;

  /// No description provided for @importingProductsWait.
  ///
  /// In en, this message translates to:
  /// **'Importing products, please wait...'**
  String get importingProductsWait;

  /// No description provided for @loadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Loading document...'**
  String get loadingDocument;

  /// No description provided for @documentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Document not found'**
  String get documentNotFound;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @itemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsTitle;

  /// No description provided for @skuColumn.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get skuColumn;

  /// No description provided for @typeColumn.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeColumn;

  /// No description provided for @numberColumn.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get numberColumn;

  /// No description provided for @quantityColumn.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityColumn;

  /// No description provided for @priceColumn.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceColumn;

  /// No description provided for @totalColumn.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalColumn;

  /// No description provided for @cancellationDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation details'**
  String get cancellationDetailsTitle;

  /// No description provided for @docIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Doc ID: {id}'**
  String docIdLabel(String id);

  /// No description provided for @documentTypeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Opening document type {collection} is not yet supported'**
  String documentTypeUnsupported(String collection);

  /// No description provided for @linkCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Link copied to clipboard'**
  String get linkCopiedToClipboard;

  /// No description provided for @saveProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfileTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileNameLabel;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile \"{name}\" saved'**
  String profileSaved(String name);

  /// No description provided for @accountingExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export to accounting'**
  String get accountingExportTitle;

  /// No description provided for @downloadBkmv.
  ///
  /// In en, this message translates to:
  /// **'Download BKMV'**
  String get downloadBkmv;

  /// No description provided for @bkmvExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'OPENFRMT ZIP (INI.TXT + BKMVDATA.TXT) for Tax Authority'**
  String get bkmvExportSubtitle;

  /// No description provided for @bkmvTaxIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Company tax ID (ח.פ) is required for BKMV export'**
  String get bkmvTaxIdRequired;

  /// No description provided for @bkmvExportEmpty.
  ///
  /// In en, this message translates to:
  /// **'No issued documents in the selected period'**
  String get bkmvExportEmpty;

  /// No description provided for @bkmvSimulatorFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'OPENFRMT check failed'**
  String get bkmvSimulatorFailedTitle;

  /// No description provided for @bkmvSimulatorFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The file was not downloaded. Fix the issues below and try again.'**
  String get bkmvSimulatorFailedBody;

  /// No description provided for @bkmvSimulatorPassed.
  ///
  /// In en, this message translates to:
  /// **'Local Tax Authority format check passed'**
  String get bkmvSimulatorPassed;

  /// No description provided for @bkmvSimulatorWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get bkmvSimulatorWarnings;

  /// No description provided for @bkmvSoftwareRegistrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Software registration no. (BKMV)'**
  String get bkmvSoftwareRegistrationLabel;

  /// No description provided for @bkmvSoftwareRegistrationHint.
  ///
  /// In en, this message translates to:
  /// **'8 digits from Tax Authority — A100 field'**
  String get bkmvSoftwareRegistrationHint;

  /// No description provided for @targetSoftwareLabel.
  ///
  /// In en, this message translates to:
  /// **'Target software'**
  String get targetSoftwareLabel;

  /// No description provided for @periodSection.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get periodSection;

  /// No description provided for @untilLabel.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get untilLabel;

  /// No description provided for @documentTypeSection.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get documentTypeSection;

  /// No description provided for @fileSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'File settings'**
  String get fileSettingsSection;

  /// No description provided for @separatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Separator'**
  String get separatorLabel;

  /// No description provided for @encodingSection.
  ///
  /// In en, this message translates to:
  /// **'Encoding'**
  String get encodingSection;

  /// No description provided for @exportErrorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportErrorWithDetail(String error);

  /// No description provided for @lastCheckResult.
  ///
  /// In en, this message translates to:
  /// **'Last check result'**
  String get lastCheckResult;

  /// No description provided for @noPreviousChecks.
  ///
  /// In en, this message translates to:
  /// **'No previous checks. Press ▶ to run a check.'**
  String get noPreviousChecks;

  /// No description provided for @gapsLabel.
  ///
  /// In en, this message translates to:
  /// **'Gaps'**
  String get gapsLabel;

  /// No description provided for @quantityCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Quantity cannot be negative'**
  String get quantityCannotBeNegative;

  /// No description provided for @excelExportWebOnly.
  ///
  /// In en, this message translates to:
  /// **'Excel export available on web only'**
  String get excelExportWebOnly;

  /// No description provided for @exportErrorDetail.
  ///
  /// In en, this message translates to:
  /// **'❌ Export error: {error}'**
  String exportErrorDetail(String error);

  /// No description provided for @productCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'SKU *'**
  String get productCodeRequired;

  /// No description provided for @typeRequired.
  ///
  /// In en, this message translates to:
  /// **'Type *'**
  String get typeRequired;

  /// No description provided for @numberRequired.
  ///
  /// In en, this message translates to:
  /// **'Number *'**
  String get numberRequired;

  /// No description provided for @volumeMlOptional.
  ///
  /// In en, this message translates to:
  /// **'Volume in ml (optional)'**
  String get volumeMlOptional;

  /// No description provided for @quantityOnPalletRequired.
  ///
  /// In en, this message translates to:
  /// **'Quantity on pallet *'**
  String get quantityOnPalletRequired;

  /// No description provided for @diameterOptional.
  ///
  /// In en, this message translates to:
  /// **'Diameter (optional)'**
  String get diameterOptional;

  /// No description provided for @packedCartonOptional.
  ///
  /// In en, this message translates to:
  /// **'Packed — quantity per carton (optional)'**
  String get packedCartonOptional;

  /// No description provided for @additionalInfoOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional info (optional)'**
  String get additionalInfoOptional;

  /// No description provided for @hashbonitUnderConstruction.
  ///
  /// In en, this message translates to:
  /// **'Hashbonit is under construction'**
  String get hashbonitUnderConstruction;

  /// No description provided for @errorSavingWithDetail.
  ///
  /// In en, this message translates to:
  /// **'Error saving: {error}'**
  String errorSavingWithDetail(String error);

  /// No description provided for @testEmailSent.
  ///
  /// In en, this message translates to:
  /// **'✅ Test email sent'**
  String get testEmailSent;

  /// No description provided for @testWhatsAppSent.
  ///
  /// In en, this message translates to:
  /// **'✅ Test WhatsApp sent'**
  String get testWhatsAppSent;

  /// No description provided for @testFailedWithDetail.
  ///
  /// In en, this message translates to:
  /// **'❌ Test failed: {error}'**
  String testFailedWithDetail(String error);

  /// No description provided for @paperSize80mmReceipt.
  ///
  /// In en, this message translates to:
  /// **'80mm (receipt)'**
  String get paperSize80mmReceipt;

  /// No description provided for @noDocumentId.
  ///
  /// In en, this message translates to:
  /// **'No document ID'**
  String get noDocumentId;

  /// No description provided for @urgencyVeryUrgent.
  ///
  /// In en, this message translates to:
  /// **'Very urgent'**
  String get urgencyVeryUrgent;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @orderInRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Order in route'**
  String get orderInRouteLabel;

  /// No description provided for @newCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'New category *'**
  String get newCategoryRequired;

  /// No description provided for @cancellationReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason (required)'**
  String get cancellationReasonRequired;

  /// No description provided for @searchBoxTypesHint.
  ///
  /// In en, this message translates to:
  /// **'Search by SKU / type / number'**
  String get searchBoxTypesHint;

  /// No description provided for @loginTimeout.
  ///
  /// In en, this message translates to:
  /// **'Login timeout (20s)'**
  String get loginTimeout;

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// No description provided for @retentionPolicyInfo.
  ///
  /// In en, this message translates to:
  /// **'Under bookkeeping law, documents must be kept for at least 7 years.\nThe check verifies no documents were deleted and there are no numbering gaps.'**
  String get retentionPolicyInfo;

  /// No description provided for @podRetentionInfo.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery photos are kept for 90 days, then deleted automatically. GPS coordinates and delivery time are retained.'**
  String get podRetentionInfo;

  /// No description provided for @oldestDocumentDate.
  ///
  /// In en, this message translates to:
  /// **'Oldest document: {date}'**
  String oldestDocumentDate(String date);

  /// No description provided for @retentionCutoffDate.
  ///
  /// In en, this message translates to:
  /// **'Cutoff date: {date}'**
  String retentionCutoffDate(String date);

  /// No description provided for @retentionGapsCount.
  ///
  /// In en, this message translates to:
  /// **'Gaps: {actual} of {expected} expected'**
  String retentionGapsCount(int actual, int expected);

  /// No description provided for @retentionHistoryEntry.
  ///
  /// In en, this message translates to:
  /// **'{user} • {count} documents'**
  String retentionHistoryEntry(String user, int count);

  /// No description provided for @retentionDocumentsCount.
  ///
  /// In en, this message translates to:
  /// **'Documents: {count}'**
  String retentionDocumentsCount(int count);

  /// No description provided for @issuesFound.
  ///
  /// In en, this message translates to:
  /// **'Issues found'**
  String get issuesFound;

  /// No description provided for @exportFormatHashavshevet.
  ///
  /// In en, this message translates to:
  /// **'Hashavshevet'**
  String get exportFormatHashavshevet;

  /// No description provided for @exportFormatHashavshevetDesc.
  ///
  /// In en, this message translates to:
  /// **'Tab-separated text file — compatible with Hashavshevet import'**
  String get exportFormatHashavshevetDesc;

  /// No description provided for @exportFormatPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority ERP'**
  String get exportFormatPriority;

  /// No description provided for @exportFormatPriorityDesc.
  ///
  /// In en, this message translates to:
  /// **'CSV file compatible with Priority import'**
  String get exportFormatPriorityDesc;

  /// No description provided for @exportFormatCsv.
  ///
  /// In en, this message translates to:
  /// **'Universal CSV'**
  String get exportFormatCsv;

  /// No description provided for @exportFormatCsvDesc.
  ///
  /// In en, this message translates to:
  /// **'Universal CSV file — works with any software'**
  String get exportFormatCsvDesc;

  /// No description provided for @encodingUtf8Bom.
  ///
  /// In en, this message translates to:
  /// **'UTF-8 + BOM (recommended for Excel)'**
  String get encodingUtf8Bom;

  /// No description provided for @encodingUtf8.
  ///
  /// In en, this message translates to:
  /// **'UTF-8 (no BOM)'**
  String get encodingUtf8;

  /// No description provided for @encodingWindows1255.
  ///
  /// In en, this message translates to:
  /// **'Windows-1255 (legacy Hashavshevet)'**
  String get encodingWindows1255;

  /// No description provided for @separatorComma.
  ///
  /// In en, this message translates to:
  /// **'Comma (,)'**
  String get separatorComma;

  /// No description provided for @separatorSemicolon.
  ///
  /// In en, this message translates to:
  /// **'Semicolon (;)'**
  String get separatorSemicolon;

  /// No description provided for @separatorTab.
  ///
  /// In en, this message translates to:
  /// **'Tab'**
  String get separatorTab;

  /// No description provided for @hashavshevetEncodingHint.
  ///
  /// In en, this message translates to:
  /// **'For older Hashavshevet versions — choose Windows-1255'**
  String get hashavshevetEncodingHint;

  /// No description provided for @exportCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Export complete'**
  String get exportCompleteTitle;

  /// No description provided for @exportRecordsCount.
  ///
  /// In en, this message translates to:
  /// **'Export complete — {count} records ({fileName})'**
  String exportRecordsCount(int count, String fileName);

  /// No description provided for @fileLabel.
  ///
  /// In en, this message translates to:
  /// **'File: {name}'**
  String fileLabel(String name);

  /// No description provided for @recordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Records: {count}'**
  String recordsLabel(int count);

  /// No description provided for @formatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format: {name}'**
  String formatLabel(String name);

  /// No description provided for @downloadFileBtn.
  ///
  /// In en, this message translates to:
  /// **'Download file'**
  String get downloadFileBtn;

  /// No description provided for @exportAction.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportAction;

  /// No description provided for @loginRequiredFirst.
  ///
  /// In en, this message translates to:
  /// **'Please log in first'**
  String get loginRequiredFirst;

  /// No description provided for @documentNotFoundAtPath.
  ///
  /// In en, this message translates to:
  /// **'Document not found at path: {path}'**
  String documentNotFoundAtPath(String path);

  /// No description provided for @documentNotFoundOrNoAccess.
  ///
  /// In en, this message translates to:
  /// **'Document not found or no access'**
  String get documentNotFoundOrNoAccess;

  /// No description provided for @companyLabelColon.
  ///
  /// In en, this message translates to:
  /// **'Company: {name}'**
  String companyLabelColon(String name);

  /// No description provided for @documentNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Document number'**
  String get documentNumberLabel;

  /// No description provided for @createdAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAtLabel;

  /// No description provided for @createdByLabel.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdByLabel;

  /// No description provided for @assignmentNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment number'**
  String get assignmentNumberLabel;

  /// No description provided for @cancelledByLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled by'**
  String get cancelledByLabel;

  /// No description provided for @cancellationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation date'**
  String get cancellationDateLabel;

  /// No description provided for @totalBeforeDiscountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total before discount'**
  String get totalBeforeDiscountLabel;

  /// No description provided for @discountPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount ({percent}%)'**
  String discountPercentLabel(int percent);

  /// No description provided for @vat18Label.
  ///
  /// In en, this message translates to:
  /// **'VAT (18%)'**
  String get vat18Label;

  /// No description provided for @invoiceManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice management'**
  String get invoiceManagementTitle;

  /// No description provided for @errorLoadingInvoices.
  ///
  /// In en, this message translates to:
  /// **'❌ Error loading invoices: {error}'**
  String errorLoadingInvoices(String error);

  /// No description provided for @assignmentNumberReceived.
  ///
  /// In en, this message translates to:
  /// **'✅ Assignment number received: {number}'**
  String assignmentNumberReceived(String number);

  /// No description provided for @assignmentRequestError.
  ///
  /// In en, this message translates to:
  /// **'❌ Assignment request error: {error}'**
  String assignmentRequestError(String error);

  /// No description provided for @standaloneInvoiceInDev.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Standalone invoice creation in development'**
  String get standaloneInvoiceInDev;

  /// No description provided for @receiptPeriodLockedError.
  ///
  /// In en, this message translates to:
  /// **'🔒 Cannot create receipt — document date ({docDate}) is in a closed accounting period (until {lockDate})'**
  String receiptPeriodLockedError(String docDate, String lockDate);

  /// No description provided for @receiptCreatedAndPrinted.
  ///
  /// In en, this message translates to:
  /// **'✅ Receipt created and printed'**
  String get receiptCreatedAndPrinted;

  /// No description provided for @receiptCreateError.
  ///
  /// In en, this message translates to:
  /// **'❌ Error creating receipt: {error}'**
  String receiptCreateError(String error);

  /// No description provided for @receiptIssuanceError.
  ///
  /// In en, this message translates to:
  /// **'Error issuing receipt from server'**
  String get receiptIssuanceError;

  /// No description provided for @invoicePrintedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Invoice printed'**
  String get invoicePrintedSuccess;

  /// No description provided for @cancelInvoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel invoice'**
  String get cancelInvoiceTitle;

  /// No description provided for @cancelInvoiceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel invoice for {clientName}?'**
  String cancelInvoiceConfirm(String clientName);

  /// No description provided for @cancelInvoiceLawNote.
  ///
  /// In en, this message translates to:
  /// **'Under bookkeeping law, invoices cannot be deleted, only cancelled.'**
  String get cancelInvoiceLawNote;

  /// No description provided for @enterCancellationReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter a cancellation reason'**
  String get enterCancellationReason;

  /// No description provided for @cancelInvoiceButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel invoice'**
  String get cancelInvoiceButton;

  /// No description provided for @invoiceCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Invoice cancelled'**
  String get invoiceCancelledSuccess;

  /// No description provided for @cancelInvoiceError.
  ///
  /// In en, this message translates to:
  /// **'❌ Cancellation error: {error}'**
  String cancelInvoiceError(String error);

  /// No description provided for @deliveryNoteShort.
  ///
  /// In en, this message translates to:
  /// **'Del. note'**
  String get deliveryNoteShort;

  /// No description provided for @taxInvoiceReceiptShort.
  ///
  /// In en, this message translates to:
  /// **'Tax inv./receipt'**
  String get taxInvoiceReceiptShort;

  /// No description provided for @originalPrintedLabel.
  ///
  /// In en, this message translates to:
  /// **'Original printed'**
  String get originalPrintedLabel;

  /// No description provided for @copiesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Copies: {count}'**
  String copiesCountLabel(int count);

  /// No description provided for @assignmentApprovedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment: {number}'**
  String assignmentApprovedLabel(String number);

  /// No description provided for @assignmentPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Awaiting assignment'**
  String get assignmentPendingLabel;

  /// No description provided for @assignmentRejectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment rejected'**
  String get assignmentRejectedLabel;

  /// No description provided for @assignmentErrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment error'**
  String get assignmentErrorLabel;

  /// No description provided for @assignmentRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment required'**
  String get assignmentRequiredLabel;

  /// No description provided for @historyTooltip.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTooltip;

  /// No description provided for @reprintTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reprint'**
  String get reprintTooltip;

  /// No description provided for @createReceiptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create receipt'**
  String get createReceiptTooltip;

  /// No description provided for @cancelInvoiceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel invoice'**
  String get cancelInvoiceTooltip;

  /// No description provided for @retryAssignmentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Retry assignment'**
  String get retryAssignmentTooltip;

  /// No description provided for @invoiceNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoice #{number}'**
  String invoiceNumberTitle(int number);

  /// No description provided for @driverWithName.
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String driverWithName(String name);

  /// No description provided for @deliveryDateWithValue.
  ///
  /// In en, this message translates to:
  /// **'Delivery date: {date}'**
  String deliveryDateWithValue(String date);

  /// No description provided for @totalWithAmount.
  ///
  /// In en, this message translates to:
  /// **'Total: ₪{amount}'**
  String totalWithAmount(String amount);

  /// No description provided for @newInvoiceButton.
  ///
  /// In en, this message translates to:
  /// **'New invoice'**
  String get newInvoiceButton;

  /// No description provided for @reprintDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reprint'**
  String get reprintDialogTitle;

  /// No description provided for @copyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyTypeLabel;

  /// No description provided for @copyNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy number {number}'**
  String copyNumberLabel(int number);

  /// No description provided for @trueToOriginalLabel.
  ///
  /// In en, this message translates to:
  /// **'True to original'**
  String get trueToOriginalLabel;

  /// No description provided for @replacesOriginalLabel.
  ///
  /// In en, this message translates to:
  /// **'Replaces the original'**
  String get replacesOriginalLabel;

  /// No description provided for @printCopiesButton.
  ///
  /// In en, this message translates to:
  /// **'Print {count} copies'**
  String printCopiesButton(int count);

  /// No description provided for @createReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Create receipt'**
  String get createReceiptTitle;

  /// No description provided for @receiptForInvoice.
  ///
  /// In en, this message translates to:
  /// **'Receipt for invoice #{number}'**
  String receiptForInvoice(int number);

  /// No description provided for @clientWithName.
  ///
  /// In en, this message translates to:
  /// **'Client: {name}'**
  String clientWithName(String name);

  /// No description provided for @amountWithValue.
  ///
  /// In en, this message translates to:
  /// **'Amount: ₪{amount}'**
  String amountWithValue(String amount);

  /// No description provided for @createReceiptButton.
  ///
  /// In en, this message translates to:
  /// **'Create receipt'**
  String get createReceiptButton;

  /// No description provided for @addBoxTypeButton.
  ///
  /// In en, this message translates to:
  /// **'Add box type'**
  String get addBoxTypeButton;

  /// No description provided for @inStockCount.
  ///
  /// In en, this message translates to:
  /// **'In stock: {count} units'**
  String inStockCount(int count);

  /// No description provided for @onPalletCount.
  ///
  /// In en, this message translates to:
  /// **'On pallet: {count}'**
  String onPalletCount(String count);

  /// No description provided for @volumeWithUnit.
  ///
  /// In en, this message translates to:
  /// **'Volume: {value} ml'**
  String volumeWithUnit(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
