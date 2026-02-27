// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get autoDistributePallets => 'Auto-distribute pallets';

  @override
  String get autoDistributeSuccess =>
      'Pallets have been automatically assigned to drivers!';

  @override
  String get autoDistributeError => 'Auto-distribution error';

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
  String get clientNumber => 'Client Number';

  @override
  String get clientManagement => 'Client Management';

  @override
  String get editClient => 'Edit Client';

  @override
  String get clientUpdated => 'Client updated successfully';

  @override
  String get noClientsFound => 'No clients found';

  @override
  String get searchClientHint => 'Search by name, number or address';

  @override
  String get addressWillBeGeocoded => 'Address will be geocoded to coordinates';

  @override
  String get addressNotFound => 'Address not found';

  @override
  String get geocodingError => 'Geocoding error';

  @override
  String get contactPerson => 'Contact Person';

  @override
  String get phone => 'Phone';

  @override
  String get required => 'Required';

  @override
  String get search => 'Search';

  @override
  String get urgency => 'Urgency';

  @override
  String get pallets => 'Pallets';

  @override
  String get boxes => 'Boxes';

  @override
  String get boxesPerPallet => 'Boxes per Pallet';

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
  String get navigate => 'Navigate';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get selectDriver => 'Select Driver';

  @override
  String get addUser => 'Add User';

  @override
  String get addNewUser => 'Add New User';

  @override
  String get fullName => 'Full Name';

  @override
  String get role => 'Role';

  @override
  String get palletCapacity => 'Pallet Capacity';

  @override
  String get truckWeight => 'Truck Weight (tons)';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get error => 'Error';

  @override
  String get fillAllFields => 'Please fill in all required fields';

  @override
  String get userAddedSuccessfully => 'User added successfully';

  @override
  String get errorCreatingUser => 'Error creating user';

  @override
  String get emailAlreadyInUse => 'Email address is already in use';

  @override
  String get weakPassword => 'Password is too weak';

  @override
  String get warehouse => 'Warehouse';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get systemManager => 'System Manager';

  @override
  String get ok => 'OK';

  @override
  String get noDriversAvailable => 'No drivers available';

  @override
  String get filterByDriver => 'Filter by driver';

  @override
  String get allDrivers => 'All drivers';

  @override
  String get viewingAs => 'You are viewing as';

  @override
  String get backToAdmin => 'Back to Admin';

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
  String get routePointsReordered => 'Route order and ETA updated';

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
  String get map => 'Map';

  @override
  String get noRoutesYet => 'No routes yet';

  @override
  String get points => 'points';

  @override
  String get refreshMap => 'Refresh map';

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

  @override
  String get active => 'Active';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get passwordResetEmailSent => 'Password reset email sent';

  @override
  String get companyId => 'Company ID';

  @override
  String get gpsTrackingActive => 'GPS tracking active';

  @override
  String get gpsTrackingStopped => 'GPS tracking stopped';

  @override
  String get weekendDay => 'Weekend day';

  @override
  String get workDayEnded => 'Work day ended';

  @override
  String workStartsIn(int minutes) {
    return 'Work starts in $minutes minutes';
  }

  @override
  String workEndsIn(int minutes) {
    return 'Work ends in $minutes minutes';
  }

  @override
  String get edit => 'Edit';

  @override
  String editUser(String name) {
    return 'Edit $name';
  }

  @override
  String deleteUser(String name) {
    return 'Delete $name?';
  }

  @override
  String get leaveEmptyToKeep => 'leave empty to keep current';

  @override
  String get userUpdated => 'User updated';

  @override
  String get userDeleted => 'User deleted';

  @override
  String get updateError => 'Update error';

  @override
  String get deleteError => 'Delete error';

  @override
  String get noPermissionToEdit =>
      'You don\'t have permission to edit this user';

  @override
  String get warehouseStartPoint => 'Starting point for all routes';

  @override
  String get vehicleNumber => 'Vehicle Number';

  @override
  String get biometricLoginTitle => 'Enable Fingerprint Login?';

  @override
  String get biometricLoginMessage =>
      'You will be able to log in using your fingerprint instead of a password.';

  @override
  String get biometricLoginYes => 'Yes, enable';

  @override
  String get biometricLoginNo => 'No';

  @override
  String get biometricLoginEnabled => '✅ Fingerprint login enabled';

  @override
  String get biometricLoginCancelled => 'Authentication cancelled';

  @override
  String get biometricLoginError => 'Biometric error';

  @override
  String get biometricLoginButton => 'Login with fingerprint';

  @override
  String get biometricLoginButtonFace => 'Login with Face ID';

  @override
  String get biometricLoginOr => 'or';

  @override
  String get biometricAuthReason => 'Log in using your fingerprint';

  @override
  String get viewModeWarehouse => 'View Mode: Warehouse Keeper';

  @override
  String get returnToAdmin => 'Return';

  @override
  String get manageBoxTypes => 'Manage Box Types Catalog';

  @override
  String get boxTypesManager => 'Manage Box Types Catalog';

  @override
  String get noBoxTypesInCatalog => 'No types in catalog';

  @override
  String get editBoxType => 'Edit Type';

  @override
  String get deleteBoxType => 'Delete Type';

  @override
  String deleteBoxTypeConfirm(Object number, Object type) {
    return 'Delete $type $number from catalog?';
  }

  @override
  String get boxTypeUpdated => 'Type updated successfully!';

  @override
  String get boxTypeDeleted => 'Type deleted successfully!';

  @override
  String get addNewBoxType => 'Add New Type to Catalog';

  @override
  String get newBoxTypeAdded => 'New type added to inventory successfully!';

  @override
  String get typeLabel => 'Type (bottle, cap, cup)';

  @override
  String get numberLabel => 'Number (100, 200, etc.)';

  @override
  String get volumeMlLabel => 'Volume in ml (optional)';

  @override
  String get quantityLabel => 'Quantity (units)';

  @override
  String get quantityPerPalletLabel => 'Quantity per pallet';

  @override
  String get diameterLabel => 'Diameter (optional)';

  @override
  String get piecesPerBoxLabel => 'Packed - quantity per box (optional)';

  @override
  String get additionalInfoLabel => 'Additional information (optional)';

  @override
  String get requiredField => 'Required field';

  @override
  String get close => 'Close';

  @override
  String formatHours(int hours) {
    return '${hours}h';
  }

  @override
  String formatMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String formatHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get setWarehouseLocation => 'Set warehouse location';

  @override
  String get latitudeWarehouse => 'Latitude (Warehouse in Mishmarot)';

  @override
  String get longitudeWarehouse => 'Longitude (Warehouse in Mishmarot)';

  @override
  String get clearPendingPoints => 'Clear Pending Points';

  @override
  String get clearPendingPointsConfirm =>
      'This will delete ONLY pending delivery points (not active routes). Continue?';

  @override
  String get clearPending => 'Clear Pending';

  @override
  String get clearAllData => 'Clear All Data';

  @override
  String get clearAllDataConfirm =>
      'This will delete ALL delivery points. Are you sure?';

  @override
  String get deleteAll => 'Delete All';

  @override
  String get fixRouteNumbers => 'Fix Route Numbers';

  @override
  String get fixRouteNumbersConfirm =>
      'This will recalculate route numbers for all drivers (1, 2, 3...). Continue?';

  @override
  String get fixNumbers => 'Fix Numbers';

  @override
  String get dataMigration => 'Data Migration';

  @override
  String get daysToMigrate => 'Days to migrate';

  @override
  String get oneTimeSetup => 'One-Time Setup';

  @override
  String get migrationDescription =>
      'This will build summary documents for existing invoices and deliveries.';

  @override
  String get migrationInstructions =>
      '• Run this ONCE after deploying the update\n• Takes ~1 minute for 30 days of data\n• Safe to run multiple times (will rebuild)';

  @override
  String get days => 'days';

  @override
  String get warehouseInventoryManagement => 'Warehouse - Inventory Management';

  @override
  String get addNewBoxTypeToCatalog => 'Add New Type to Catalog';

  @override
  String get showLowStockOnly => 'Show Low Stock Only';

  @override
  String get changeHistory => 'Change History';

  @override
  String get exportReport => 'Export Report';

  @override
  String get searchByTypeOrNumber => 'Search by type or number...';

  @override
  String get noItemsToExport => 'No items to export';

  @override
  String get reportExportedSuccessfully => 'Report exported successfully';

  @override
  String get exportError => 'Export error';

  @override
  String get noItemsInInventory => 'No items in inventory';

  @override
  String get noItemsFound => 'No items found';

  @override
  String get productCode => 'Product Code';

  @override
  String get productCodeLabel => 'Product Code *';

  @override
  String get productCodeHelper => 'Unique code for each product';

  @override
  String get productCodeSearchHelper =>
      'Enter product code to search in catalog';

  @override
  String get productCodeFoundInCatalog => 'Product code found in catalog';

  @override
  String get productCodeNotFoundInCatalog =>
      'Product code not found in catalog';

  @override
  String get productCodeNotFoundAddFirst =>
      'Product code not found in catalog. Add new type to catalog first.';

  @override
  String get orSelectFromList => 'or select product code from list';

  @override
  String get selectFromFullList => 'Select from full list';

  @override
  String get lowStock => 'Low Stock!';

  @override
  String get limitedStock => 'Limited Stock';

  @override
  String get volume => 'Volume (L)';

  @override
  String get ml => 'ml';

  @override
  String get diameter => 'Diameter';

  @override
  String get packed => 'Packed';

  @override
  String get piecesInBox => 'pcs per box';

  @override
  String get quantityPerPallet => 'Quantity per pallet';

  @override
  String get additionalInfo => 'Additional Information';

  @override
  String get quantity => 'Quantity';

  @override
  String get units => 'units';

  @override
  String remainingUnitsOnly(int count) {
    return 'Only $count units remaining';
  }

  @override
  String get urgentOrderStock => 'Urgent! Need to order stock';

  @override
  String get updated => 'Updated';

  @override
  String get by => 'by';

  @override
  String get addInventory => 'Add Inventory';

  @override
  String get inventoryUpdatedSuccessfully => 'Inventory updated successfully!';

  @override
  String get catalogEmpty => 'Catalog is empty. Add new type to catalog first.';

  @override
  String get editItem => 'Edit Item';

  @override
  String get itemUpdatedSuccessfully => 'Item updated successfully!';

  @override
  String get fillAllRequiredFields => 'Please fill in all required fields';

  @override
  String get fillAllRequiredFieldsIncludingProductCode =>
      'Please fill in all required fields (including product code)';

  @override
  String get typeUpdatedSuccessfully => 'Type updated successfully!';

  @override
  String get deletedSuccessfully => 'Deleted successfully!';

  @override
  String get deleteConfirmation => 'Delete';

  @override
  String get searchByProductCode => 'Search by product code, type or number...';

  @override
  String get warehouseInventory => 'Warehouse Inventory';

  @override
  String get inventoryChangesReport => 'Inventory Changes Report';

  @override
  String get inventoryCountReportsTooltip => 'Inventory Count Reports';

  @override
  String get archiveManagement => 'Archive Management';

  @override
  String get inventoryCount => 'Inventory Count';

  @override
  String get inventoryCountReports => 'Inventory Count Reports';

  @override
  String get startNewCount => 'Start New Inventory Count';

  @override
  String get startNewCountConfirm =>
      'Start a new inventory count?\nThis will create a list of all items in inventory.';

  @override
  String get start => 'Start';

  @override
  String get noActiveCount => 'No active inventory count';

  @override
  String get countStarted => 'New inventory count started';

  @override
  String get errorStartingCount => 'Error starting count';

  @override
  String get errorLoadingCount => 'Error loading count';

  @override
  String get errorUpdatingItem => 'Error updating item';

  @override
  String get completeCount => 'Complete Count';

  @override
  String completeCountConfirm(int count) {
    return 'There are still $count items not counted.\nComplete anyway?';
  }

  @override
  String get finish => 'Finish';

  @override
  String get countCompleted => 'Inventory count completed successfully';

  @override
  String get errorCompletingCount => 'Error completing count';

  @override
  String get showOnlyDifferences => 'Show only differences';

  @override
  String get counted => 'Counted';

  @override
  String get differences => 'Differences';

  @override
  String get shortage => 'Shortage';

  @override
  String get surplus => 'Surplus';

  @override
  String get searchByProductCodeTypeNumber => 'Search by code / type / number';

  @override
  String get noResults => 'No results found';

  @override
  String get noDifferences => 'No differences';

  @override
  String get noItems => 'No items';

  @override
  String get expected => 'Expected';

  @override
  String get actualCounted => 'Counted';

  @override
  String get difference => 'Difference';

  @override
  String get suspiciousOrders => 'Suspicious Orders';

  @override
  String get notes => 'Notes';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get enterValidNumber => 'Please enter a valid number';

  @override
  String get noCountReports => 'No inventory count reports';

  @override
  String get countReport => 'Inventory Count Report';

  @override
  String get performedBy => 'Performed by';

  @override
  String get started => 'Started';

  @override
  String get finished => 'Finished';

  @override
  String get totalItems => 'Total Items';

  @override
  String get viewDetails => 'View Details';

  @override
  String get approved => 'Approved';

  @override
  String get approveCount => 'Approve Count';

  @override
  String get approveCountConfirm =>
      'Approve the count and update inventory?\nThis will update inventory quantities according to the count.';

  @override
  String get approveAndUpdate => 'Approve and Update';

  @override
  String get countApproved =>
      'Count approved and inventory updated successfully';

  @override
  String get errorApprovingCount => 'Error approving count';

  @override
  String get countNotFound => 'Report not found';

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String get exportToExcelSoon => 'Export to Excel - coming soon';

  @override
  String get countNotCompleted => 'Count not completed';

  @override
  String get errorLoadingReport => 'Error loading report';

  @override
  String get items => 'Items';

  @override
  String get selectDates => 'Select Dates';

  @override
  String get allPeriod => 'All Period';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get all => 'All';

  @override
  String get searchByProductCodeTypeNumberHint =>
      'Search by product code, type or number...';

  @override
  String foundChanges(int count) {
    return 'Found: $count changes';
  }

  @override
  String get added => 'Added';

  @override
  String get deducted => 'Deducted';

  @override
  String noResultsFor(String query) {
    return 'No results found for \"$query\"';
  }

  @override
  String get noChangesInPeriod => 'No changes in this period';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get reason => 'Reason';

  @override
  String get statistics => 'Statistics';

  @override
  String get totalArchives => 'Total Archives';

  @override
  String get totalSize => 'Total Size';

  @override
  String get records => 'Records';

  @override
  String get archiveActions => 'Archive Actions';

  @override
  String get archiveInventoryHistory => 'Archive Inventory History';

  @override
  String get archiveOrders => 'Archive Orders';

  @override
  String get existingArchives => 'Existing Archives';

  @override
  String get noArchives => 'No Archives';

  @override
  String get archiveInventoryHistoryTitle => 'Archive Inventory History';

  @override
  String get archiveInventoryHistoryConfirm =>
      'Archive old records from the last 3 months?\n\nRecords will be marked as archived and will not be deleted.';

  @override
  String get archiveCompletedOrdersTitle => 'Archive Completed Orders';

  @override
  String get archiveCompletedOrdersConfirm =>
      'Archive orders completed a month ago?\n\nOrders will be marked as archived and will not be deleted.';

  @override
  String get archive => 'Archive';

  @override
  String get errorLoadingArchives => 'Error loading archives';

  @override
  String get size => 'Size';

  @override
  String get created => 'Created';

  @override
  String get download => 'Download';

  @override
  String get mb => 'MB';

  @override
  String get insufficientStock => 'Insufficient Stock';

  @override
  String get cannotCreateOrderInsufficientStock =>
      'Cannot create order - insufficient stock:';

  @override
  String get pleaseContactWarehouseKeeper =>
      'Please contact the warehouse keeper to update inventory.';

  @override
  String get understood => 'Understood';

  @override
  String get available => 'Available';

  @override
  String get requested => 'Requested';

  @override
  String get itemNotFoundInInventory => 'Item not found in inventory';

  @override
  String get productCodeNotFound => 'Product code not found';

  @override
  String get companySettings => 'Company Settings';

  @override
  String get companyDetails => 'Company Details';

  @override
  String get companyNameHebrew => 'Company Name (Hebrew)';

  @override
  String get companyNameEnglish => 'Company Name (English)';

  @override
  String get taxId => 'Tax ID';

  @override
  String get addressHebrew => 'Address (Hebrew)';

  @override
  String get addressEnglish => 'Address (English)';

  @override
  String get poBox => 'P.O. Box';

  @override
  String get city => 'City';

  @override
  String get zipCode => 'Zip Code';

  @override
  String get contact => 'Contact';

  @override
  String get fax => 'Fax';

  @override
  String get website => 'Website';

  @override
  String get defaultDriver => 'Default Driver';

  @override
  String get driverName => 'Driver Name';

  @override
  String get driverPhone => 'Driver Phone';

  @override
  String get departureTime => 'Departure Time';

  @override
  String get invoice => 'Invoice';

  @override
  String get invoiceFooterText => 'Invoice Footer Text';

  @override
  String get paymentTerms => 'Payment Terms';

  @override
  String get bankDetails => 'Bank Details';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings Saved';

  @override
  String get errorSavingSettings => 'Error Saving Settings';

  @override
  String get errorLoadingSettings => 'Error Loading Settings';

  @override
  String get warning => 'Warning';

  @override
  String get migrationWarning =>
      'This operation will add company ID to all existing records in the database. Make sure you have a backup before proceeding.';

  @override
  String get currentCompanyId => 'Current Company ID';

  @override
  String get startMigration => 'Start Migration';

  @override
  String get migrating => 'Migrating...';

  @override
  String get migrationStatistics => 'Migration Statistics';

  @override
  String get migrationLog => 'Migration Log';

  @override
  String get noMigrationYet => 'No migration performed yet';

  @override
  String get overloadWarning => 'Overload Warning';

  @override
  String overloadWarningMessage(String driverName, int currentLoad, int newLoad,
      int totalLoad, int capacity) {
    return 'Driver $driverName is already carrying $currentLoad pallets, adding $newLoad pallets will increase the total to $totalLoad pallets (capacity: $capacity pallets). Continue?';
  }

  @override
  String get continueAnyway => 'Continue Anyway';

  @override
  String get productManagement => 'Product Management';

  @override
  String get addProduct => 'Add Product';

  @override
  String get editProduct => 'Edit Product';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get productName => 'Product Name';

  @override
  String get category => 'Category';

  @override
  String get unitsPerBox => 'Units per Box';

  @override
  String get weight => 'Weight (kg)';

  @override
  String get inactive => 'Inactive';

  @override
  String get showInactive => 'Show Inactive';

  @override
  String get hideInactive => 'Hide Inactive';

  @override
  String get importFromExcel => 'Import from Excel';

  @override
  String get noProducts => 'No Products';

  @override
  String get addFirstProduct => 'Add First Product';

  @override
  String get productAdded => 'Product Added';

  @override
  String get productUpdated => 'Product Updated';

  @override
  String get productDeleted => 'Product Deleted';

  @override
  String deleteProductConfirm(Object productName) {
    return 'Delete $productName?';
  }

  @override
  String get allCategories => 'All';

  @override
  String get categoryGeneral => 'General';

  @override
  String get categoryCups => 'Cups';

  @override
  String get categoryLids => 'Lids';

  @override
  String get categoryContainers => 'Containers';

  @override
  String get categoryBread => 'Bread';

  @override
  String get categoryDairy => 'Dairy';

  @override
  String get categoryShirts => 'Shirts';

  @override
  String get categoryTrays => 'Trays';

  @override
  String get categoryBottles => 'Bottles';

  @override
  String get categoryBags => 'Bags';

  @override
  String get categoryBoxes => 'Boxes';

  @override
  String get terminology => 'Terminology';

  @override
  String get businessType => 'Business Type';

  @override
  String get selectBusinessType => 'Select Business Type';

  @override
  String get businessTypePackaging => 'Packaging & Plastic';

  @override
  String get businessTypeFood => 'Food Products';

  @override
  String get businessTypeClothing => 'Clothing & Textile';

  @override
  String get businessTypeConstruction => 'Construction Materials';

  @override
  String get businessTypeCustom => 'Custom';

  @override
  String get unitName => 'Unit Name (singular)';

  @override
  String get unitNamePlural => 'Unit Name (plural)';

  @override
  String get palletName => 'Pallet Name (singular)';

  @override
  String get palletNamePlural => 'Pallet Name (plural)';

  @override
  String get usesPallets => 'Uses Pallets';

  @override
  String get capacityCalculation => 'Capacity Calculation';

  @override
  String get capacityByUnits => 'By Units';

  @override
  String get capacityByWeight => 'By Weight';

  @override
  String get capacityByVolume => 'By Volume';

  @override
  String get terminologyUpdated => 'Terminology Updated';

  @override
  String get applyTemplate => 'Apply Template';

  @override
  String get customTerminology => 'Custom Terminology';

  @override
  String get invalidNumber => 'Invalid number';

  @override
  String get noCompanySelected => 'No company selected';

  @override
  String get addNewProduct => 'Add New Product';

  @override
  String get terminologySettings => 'Terminology Settings';

  @override
  String get selectTemplate => 'Select Template';

  @override
  String get or => 'or';

  @override
  String get customSettings => 'Custom Settings';

  @override
  String get downloadTemplate => 'Download Template';

  @override
  String importSuccess(Object count) {
    return 'Imported $count products';
  }

  @override
  String get importError => 'Import Error';

  @override
  String get exportSuccess => 'File Downloaded';

  @override
  String get templateDownloaded => 'Template Downloaded';
}
