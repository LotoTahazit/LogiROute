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

  /// No description provided for @routePointsReordered.
  ///
  /// In en, this message translates to:
  /// **'Route order and ETA updated'**
  String get routePointsReordered;

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
  /// **'Company Name (Hebrew)'**
  String get companyNameHebrew;

  /// No description provided for @companyNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'Company Name (English)'**
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
