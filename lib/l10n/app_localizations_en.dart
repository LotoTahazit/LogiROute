// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LogiRoute';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get logout => 'Logout';

  @override
  String get admin => 'Administrator';

  @override
  String get dispatcher => 'Dispatcher';

  @override
  String get driver => 'Driver';

  @override
  String get viewAs => 'View as';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get users => 'Users';

  @override
  String get routes => 'Routes';

  @override
  String get deliveryPoints => 'Delivery Points';

  @override
  String get addPoint => 'Add Point';

  @override
  String get createRoute => 'Create Route';

  @override
  String get address => 'Address';

  @override
  String get clientName => 'Client Name';

  @override
  String get urgency => 'Urgency';

  @override
  String get pallets => 'Pallets';

  @override
  String get boxes => 'Boxes';

  @override
  String get boxesPerPallet => 'Boxes per pallet (16-48)';

  @override
  String get openingTime => 'Opening Time';

  @override
  String get status => 'Status';

  @override
  String get pending => 'Pending';

  @override
  String get assigned => 'Assigned';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get selectDriver => 'Select Driver';

  @override
  String get cancelPoint => 'Cancel Point';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get distance => 'Distance';

  @override
  String get language => 'Language';

  @override
  String get hebrew => 'Hebrew';

  @override
  String get russian => 'Russian';

  @override
  String get english => 'English';

  @override
  String get capacity => 'Capacity';

  @override
  String get totalPallets => 'Total Pallets';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get pointDone => 'Point Done';

  @override
  String get noActivePoints => 'No active points';

  @override
  String get pointCompleted => 'Point completed';

  @override
  String get next => 'Next';

  @override
  String get pointAdded => 'Point added';

  @override
  String get error => 'Error';

  @override
  String get required => 'Required';

  @override
  String get noPointsForRoute => 'No points for route creation';

  @override
  String get routeCreated => 'Route created';

  @override
  String get noDeliveryPoints => 'No delivery points';

  @override
  String get markComplete => 'Mark Complete';

  @override
  String get mapViewRequiresApi => 'Map view - requires Google Maps API';

  @override
  String get unknownDriver => 'Unknown Driver';

  @override
  String get fixExistingRoutes => 'Fix Existing Routes';

  @override
  String get printRoute => 'Print Route';

  @override
  String get routesFixed => 'Routes fixed!';

  @override
  String get statusPending => 'pending';

  @override
  String get statusAssigned => 'assigned';

  @override
  String get statusInProgress => 'in_progress';

  @override
  String get statusCompleted => 'completed';

  @override
  String get statusCancelled => 'cancelled';

  @override
  String get statusActive => 'active';

  @override
  String get roleDriver => 'driver';

  @override
  String get cancelAction => 'cancel';

  @override
  String get completeAction => 'complete';

  @override
  String get boxesHint => '1-672 boxes';

  @override
  String get urgencyNormal => 'Normal';

  @override
  String get urgencyUrgent => 'Urgent';

  @override
  String get changeDriver => 'Change driver';

  @override
  String get cancelRoute => 'Cancel route';

  @override
  String get cancelRouteTitle => 'Cancel route?';

  @override
  String get cancelRouteDescription =>
      'All points will return to \'pending\'. Continue?';

  @override
  String get routeCancelled => 'Route cancelled, points returned to pending';

  @override
  String get selectNewDriver => 'Select a new driver';

  @override
  String get noAvailableDrivers => 'No available drivers';

  @override
  String driverChangedTo(Object name) {
    return 'Driver changed to $name';
  }

  @override
  String get noUsersFound => 'No users found';

  @override
  String get palletStatistics => 'Pallet Statistics';

  @override
  String get total => 'Total';

  @override
  String get delivered => 'Delivered';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get activeRoutes => 'Active Routes';

  @override
  String get order => 'Order';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleDispatcher => 'Dispatcher';

  @override
  String get refresh => 'Refresh';

  @override
  String get analytics => 'Analytics';

  @override
  String get settings => 'Settings';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get routeCopiedToClipboard => 'Route copied to clipboard';

  @override
  String get printError => 'Printing error';

  @override
  String get no => 'No';

  @override
  String get routeNotFound => 'Route not found';

  @override
  String get noDriversAvailable => 'No drivers available';

  @override
  String get map => 'Map';

  @override
  String get noRoutesYet => 'No routes yet';

  @override
  String get points => 'points';

  @override
  String get refreshMap => 'Refresh map';

  @override
  String get phone => 'Phone';

  @override
  String get clientNumberLabel => 'Client Number (6 digits)';

  @override
  String get delete => 'Delete';

  @override
  String get deletePoint => 'Delete point';

  @override
  String get pointDeleted => 'Point deleted';

  @override
  String get assignDriver => 'Assign driver';

  @override
  String get pointAssigned => 'Point assigned';

  @override
  String get addressNotFound => 'Address not found';

  @override
  String addressNotFoundDescription(String address) {
    return 'Could not find coordinates for address:\n\"$address\"\n\nThe system tried many variants but geocoding failed.\n\nTry:\n• Check address spelling\n• Use full address with city\n• Verify address exists in maps\n• Contact administrator for help';
  }

  @override
  String get fixAddress => 'Fix address';

  @override
  String get fixOldCoordinates => 'Fix old coordinates';

  @override
  String get fixOldCoordinatesDescription =>
      'This will delete points with old Jerusalem coordinates. Continue?';

  @override
  String get oldCoordinatesFixed => 'Old coordinates fixed';

  @override
  String get fixHebrewSearch => 'Fix Hebrew search';

  @override
  String get fixHebrewSearchDescription =>
      'This will fix the search index for Hebrew client names. Continue?';

  @override
  String get hebrewSearchFixed => 'Hebrew search index fixed';

  @override
  String get clientNumberRequired => 'Enter client number';

  @override
  String get clientNumberLength => 'Number must contain 6 digits';

  @override
  String get bridgeHeightError => 'Bridge height error';

  @override
  String get bridgeHeightErrorDescription =>
      'Route blocked by low bridge (height < 4m). Contact dispatcher to select alternative route.';

  @override
  String get routeBlockedByBridge => 'Route blocked by bridge';

  @override
  String get alternativeRouteFound => 'Alternative route found';

  @override
  String get navigation => 'Navigation';

  @override
  String get loadingNavigation => 'Loading route...';

  @override
  String get navigationError => 'Navigation error';

  @override
  String get noNavigationRoute => 'Route not found';

  @override
  String get retry => 'Retry';

  @override
  String get previous => 'Previous';

  @override
  String get showMap => 'Show map';

  @override
  String get pointCancelled => 'Point cancelled';

  @override
  String get temporaryAddress => 'Temporary Address';

  @override
  String get temporaryAddressHint => 'Address for this delivery only...';

  @override
  String get temporaryAddressHelper => 'Does not change client\'s main address';

  @override
  String get temporaryAddressTooltip =>
      'This address will be used only for the current delivery. The client\'s main address will remain unchanged.';

  @override
  String get originalAddress => 'Original Address';
}
