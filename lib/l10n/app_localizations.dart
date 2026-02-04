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
  /// **'Boxes per pallet (16-48)'**
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

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

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
  /// **'active'**
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
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get roleDispatcher;

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
  /// **'Printing error'**
  String get printError;

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

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

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

  /// No description provided for @addressNotFound.
  ///
  /// In en, this message translates to:
  /// **'Address not found'**
  String get addressNotFound;

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
  /// **'Password reset email sent'**
  String get passwordResetEmailSent;

  /// No description provided for @companyId.
  ///
  /// In en, this message translates to:
  /// **'Company ID'**
  String get companyId;
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
