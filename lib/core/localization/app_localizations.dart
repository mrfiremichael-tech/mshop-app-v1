import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Central localization for the entire M-Shop Pharmacy application.
///
/// All screens should obtain this object from the current BuildContext using:
///
///   final l10n = AppLocalizations.of(context);
///
/// and then use getters such as `l10n.sales`, `l10n.profit`, etc.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Gets the active localization instance from the current widget tree.
  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );

    assert(value != null, 'AppLocalizations is not registered in MaterialApp.');
    return value!;
  }

  bool get isEnglish => locale.languageCode == 'en';

  bool get isSwahili => locale.languageCode == 'sw';

  String _text(String english, String swahili) {
    return isSwahili ? swahili : english;
  }

  // ---------------------------------------------------------------------------
  // APP / LANGUAGE
  // ---------------------------------------------------------------------------

  String get appName => 'M-Shop Pharmacy';

  String get language => _text('Language', 'Lugha');

  String get english => _text('English', 'Kiingereza');

  String get swahili => _text('Swahili', 'Kiswahili');

  String get welcome => _text(
        'Welcome to M-Shop Pharmacy',
        'Karibu M-Shop Pharmacy',
      );

  // ---------------------------------------------------------------------------
  // AUTHENTICATION
  // ---------------------------------------------------------------------------

  String get signInSubtitle => _text(
        'Sign in to manage your pharmacy',
        'Ingia kusimamia famasi yako',
      );

  String get email => _text(
        'Email',
        'Barua pepe',
      );

  String get emailHint => _text(
        'Enter your email',
        'Ingiza barua pepe yako',
      );

  String get password => _text(
        'Password',
        'Nenosiri',
      );

  String get passwordHint => _text(
        'Enter your password',
        'Ingiza nenosiri lako',
      );

  String get enterEmail => _text(
        'Please enter your email',
        'Tafadhali ingiza barua pepe yako',
      );

  String get invalidEmail => _text(
        'Invalid email address',
        'Anwani ya barua pepe si sahihi',
      );

  String get enterPassword => _text(
        'Please enter your password',
        'Tafadhali ingiza nenosiri lako',
      );

  String get passwordTooShort => _text(
        'Password must be at least 6 characters',
        'Nenosiri lazima liwe na angalau herufi 6',
      );

  String get login => _text(
        'LOGIN',
        'INGIA',
      );

  String get forgotPassword => _text(
        'Forgot Password?',
        'Umesahau nenosiri?',
      );

  String get register => _text(
        'Register',
        'Jisajili',
      );

  String get dontHaveAccount => _text(
        "Don't have an account?",
        'Huna akaunti?',
      );

  String get alreadyHaveAccount => _text(
        'Already have an account?',
        'Una akaunti tayari?',
      );

  String get fullName => _text(
        'Full Name',
        'Jina Kamili',
      );

  String get fullNameHint => _text(
        'Enter your full name',
        'Ingiza jina lako kamili',
      );

  String get enterFullName => _text(
        'Please enter your full name',
        'Tafadhali ingiza jina lako kamili',
      );

  String get pharmacyName => _text(
        'Pharmacy Name',
        'Jina la Famasi',
      );

  String get pharmacyNameHint => _text(
        'Enter pharmacy name',
        'Ingiza jina la famasi',
      );

  String get enterPharmacyName => _text(
        'Please enter pharmacy name',
        'Tafadhali ingiza jina la famasi',
      );

  String get phone => _text(
        'Phone Number',
        'Namba ya Simu',
      );

  String get phoneHint => _text(
        'Enter phone number',
        'Ingiza namba ya simu',
      );

  String get enterPhone => _text(
        'Please enter phone number',
        'Tafadhali ingiza namba ya simu',
      );

  String get confirmPassword => _text(
        'Confirm Password',
        'Thibitisha Nenosiri',
      );

  String get confirmPasswordHint => _text(
        'Confirm your password',
        'Thibitisha nenosiri lako',
      );

  String get enterConfirmPassword => _text(
        'Please confirm your password',
        'Tafadhali thibitisha nenosiri lako',
      );

  String get passwordsDoNotMatch => _text(
        'Passwords do not match',
        'Nenosiri hazifanani',
      );

  String get createAccount => _text(
        'CREATE ACCOUNT',
        'FUNGUA AKAUNTI',
      );

  String get registration => _text(
        'Registration',
        'Usajili',
      );

  String get pharmacyOwner => _text(
        'Pharmacy Owner',
        'Mmiliki wa Famasi',
      );

  String get accountCreated => _text(
        'Account created successfully',
        'Akaunti imetengenezwa kwa mafanikio',
      );

  String get loginFailed => _text(
        'Login failed',
        'Kuingia kumeshindikana',
      );

  String get incorrectCredentials => _text(
        'Incorrect email or password',
        'Barua pepe au nenosiri si sahihi',
      );

  String get networkError => _text(
        'Network error',
        'Tatizo la mtandao',
      );

  String get accountDisabled => _text(
        'This account has been disabled',
        'Akaunti hii imezuiwa',
      );

  String get accountNotRecognized => _text(
        'Account role is not recognized',
        'Aina ya akaunti haijatambuliwa',
      );

  String get somethingWentWrong => _text(
        'Something went wrong',
        'Kuna tatizo limetokea',
      );

  // ---------------------------------------------------------------------------
  // DASHBOARD
  // ---------------------------------------------------------------------------

  String get dashboard => _text(
        'Pharmacy Dashboard',
        'Dashibodi ya Famasi',
      );

  String get welcomeBack => _text(
        'Welcome back',
        'Karibu tena',
      );

  String get today => _text(
        'Today',
        'Leo',
      );

  String get sales => _text(
        'Sales',
        'Mauzo',
      );

  String get profit => _text(
        'Profit',
        'Faida',
      );

  String get currentStock => _text(
        'Current Stock',
        'Stock Iliyopo',
      );

  String get totalStock => _text(
        'Total Stock',
        'Jumla ya Stock',
      );

  String get lowStock => _text(
        'Low Stock',
        'Stock Ndogo',
      );

  String get recentSales => _text(
        'Recent Sales',
        'Mauzo ya Karibuni',
      );

  String get expiryAlerts => _text(
        'Expiry Alerts',
        'Tahadhari za Muda wa Kuisha',
      );

  String get monthlyPerformance => _text(
        'Monthly Performance',
        'Utendaji wa Mwezi',
      );

  String get stockIn => _text(
        'Stock In',
        'Stock Iliyoingia',
      );

  String get unitsSold => _text(
        'Units Sold',
        'Vipimo Vilivyouzwa',
      );

  String get sellThrough => _text(
        'Sell-through',
        'Kiwango cha Mauzo',
      );

  String get unitsSoldStockInFormula => _text(
        'Units Sold ÷ Stock In × 100',
        'Vipimo Vilivyouzwa ÷ Stock Iliyoingia × 100',
      );

  String get medicineSalesRate => _text(
        'Medicine Sales Rate',
        'Kiwango cha Mauzo ya Dawa',
      );

  String get noMonthlyMedicineSalesData => _text(
        'No monthly medicine sales data yet.',
        'Hakuna taarifa za mauzo ya dawa za mwezi bado.',
      );

  String get quickActions => _text(
        'Quick Actions',
        'Vitendo vya Haraka',
      );

  String get newSale => _text(
        'New Sale',
        'Uuzaji Mpya',
      );

  String get attention => _text(
        'Attention',
        'Tahadhari',
      );

  String get moreManagement => _text(
        'More Management',
        'Usimamizi Zaidi',
      );

  String get retry => _text(
        'Retry',
        'Jaribu Tena',
      );

  // ---------------------------------------------------------------------------
  // MANAGEMENT / MODULES
  // ---------------------------------------------------------------------------

  String get medicines => _text(
        'Medicines',
        'Dawa',
      );

  String get addMedicine => _text(
        'Add Medicine',
        'Ongeza Dawa',
      );

  String get editMedicine => _text(
        'Edit Medicine',
        'Hariri Dawa',
      );

  String get deleteMedicine => _text(
        'Delete Medicine',
        'Futa Dawa',
      );

  String get purchases => _text(
        'Purchases',
        'Manunuzi',
      );

  String get purchaseStock => _text(
        'Purchase Stock',
        'Nunua Stock',
      );

  String get customers => _text(
        'Customers',
        'Wateja',
      );

  String get suppliers => _text(
        'Suppliers',
        'Wasambazaji',
      );

  String get expenses => _text(
        'Expenses',
        'Gharama',
      );

  String get reports => _text(
        'Reports',
        'Ripoti',
      );

  String get staff => _text(
        'Staff',
        'Watumishi',
      );

  String get management => _text(
        'Management',
        'Usimamizi',
      );

  String get profile => _text(
        'Profile',
        'Wasifu',
      );

  String get pharmacy => _text(
        'Pharmacy',
        'Famasi',
      );

  String get owner => _text(
        'Owner',
        'Mmiliki',
      );

  String get close => _text(
        'Close',
        'Funga',
      );

  String get logout => _text(
        'Logout',
        'Toka',
      );

  String get cancel => _text(
        'Cancel',
        'Ghairi',
      );

  String get confirm => _text(
        'Confirm',
        'Thibitisha',
      );

  String get logoutConfirmation => _text(
        'Are you sure you want to logout?',
        'Una uhakika unataka kutoka?',
      );

  // ---------------------------------------------------------------------------
  // COMMON PHARMACY TERMS
  // ---------------------------------------------------------------------------

  String get scanBarcode => _text(
        'Scan Barcode',
        'Changanua Msimbo Pau',
      );

  String get scanMedicineBarcode => _text(
        'Scan Medicine Barcode',
        'Changanua Msimbo Pau wa Dawa',
      );

  String get searchMedicine => _text(
        'Search medicine, category, barcode...',
        'Tafuta dawa, aina, msimbo pau...',
      );

  String get medicine => _text(
        'Medicine',
        'Dawa',
      );

  String get product => _text(
        'Product',
        'Bidhaa',
      );

  String get products => _text(
        'Products',
        'Bidhaa',
      );

  String get productInformation => _text(
        'Product Information',
        'Taarifa za Bidhaa',
      );

  String get productType => _text(
        'Product Type',
        'Aina ya Bidhaa',
      );

  String get selectProductType => _text(
        'Select product type',
        'Chagua aina ya bidhaa',
      );

  String get productName => _text(
        'Product Name',
        'Jina la Bidhaa',
      );

  String get category => _text(
        'Category',
        'Aina',
      );

  String get unit => _text(
        'Unit',
        'Kipimo',
      );

  String get selectUnit => _text(
        'Select unit',
        'Chagua kipimo',
      );

  String get quantity => _text(
        'Quantity',
        'Kiasi',
      );

  String get buyingPrice => _text(
        'Buying Price',
        'Bei ya Kununua',
      );

  String get sellingPrice => _text(
        'Selling Price',
        'Bei ya Kuuza',
      );

  String get barcode => _text(
        'Barcode',
        'Msimbo Pau',
      );

  String get batchNumber => _text(
        'Batch Number',
        'Namba ya Kundi',
      );

  String get expiryDate => _text(
        'Expiry Date',
        'Tarehe ya Kuisha',
      );

  String get supplier => _text(
        'Supplier',
        'Msambazaji',
      );

  String get customer => _text(
        'Customer',
        'Mteja',
      );

  String get walkInCustomer => _text(
        'Walk-in Customer',
        'Mteja wa Kawaida',
      );

  String get optional => _text(
        'Optional',
        'Si lazima',
      );

  // ---------------------------------------------------------------------------
  // PURCHASE
  // ---------------------------------------------------------------------------

  String get addPurchase => _text(
        'Add Purchase',
        'Ongeza Manunuzi',
      );

  String get purchaseStockTitle => _text(
        'Purchase Stock',
        'Nunua Stock',
      );

  String get purchaseStockSubtitle => _text(
        'Add purchased medicines and increase stock automatically.',
        'Ongeza dawa zilizonunuliwa na kuongeza stock moja kwa moja.',
      );

  String get totalPurchaseCost => _text(
        'Total Purchase Cost',
        'Jumla ya Gharama za Manunuzi',
      );

  String get savePurchase => _text(
        'Save Purchase',
        'Hifadhi Manunuzi',
      );

  // ---------------------------------------------------------------------------
  // SALES
  // ---------------------------------------------------------------------------

  String get addSale => _text(
        'Add Sale',
        'Ongeza Uuzaji',
      );

  String get newSaleTitle => _text(
        'New Sale',
        'Uuzaji Mpya',
      );

  String get newSaleSubtitle => _text(
        'Scan barcode or select medicine, then complete the sale.',
        'Changanua msimbo pau au chagua dawa, kisha kamilisha uuzaji.',
      );

  String get unitSellingPrice => _text(
        'Unit Selling Price',
        'Bei ya Kuuza kwa Kipimo',
      );

  String get totalSale => _text(
        'Total Sale',
        'Jumla ya Uuzaji',
      );

  String get saveSale => _text(
        'Save Sale',
        'Hifadhi Uuzaji',
      );

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS / ACTIVITY
  // ---------------------------------------------------------------------------

  String get notificationsAndActivity => _text(
        'Notifications & Activity',
        'Arifa na Shughuli',
      );

  String get notifications => _text(
        'Notifications',
        'Arifa',
      );

  String get alerts => _text(
        'Alerts',
        'Tahadhari',
      );

  String get recentActivity => _text(
        'Recent Activity',
        'Shughuli za Karibuni',
      );

  String get saleCompleted => _text(
        'Sale completed',
        'Uuzaji umekamilika',
      );

  String get supplierAddedUpdated => _text(
        'Supplier added/updated',
        'Msambazaji ameongezwa/kusasishwa',
      );

  String get expenseRecorded => _text(
        'Expense recorded',
        'Gharama imerekodiwa',
      );

  String get productAddedUpdated => _text(
        'Product added/updated',
        'Bidhaa imeongezwa/kusasishwa',
      );

  String get lowStockRemaining => _text(
        'remaining',
        'zimebaki',
      );

  // ---------------------------------------------------------------------------
  // ERRORS / STATES
  // ---------------------------------------------------------------------------

  String get failedToLoadPharmacyInformation => _text(
        'Failed to load pharmacy information.',
        'Imeshindikana kupakia taarifa za famasi.',
      );

  String get failedToLoadMedicineData => _text(
        'Failed to load medicine data.',
        'Imeshindikana kupakia taarifa za dawa.',
      );

  String get failedToLoadSalesData => _text(
        'Failed to load sales data.',
        'Imeshindikana kupakia taarifa za mauzo.',
      );

  String get failedToLoadStockRecords => _text(
        'Failed to load stock records.',
        'Imeshindikana kupakia taarifa za stock.',
      );

  // ---------------------------------------------------------------------------
  // MONTHS
  // ---------------------------------------------------------------------------

  String monthName(int month) {
    const english = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    const swahili = <String>[
      'Januari',
      'Februari',
      'Machi',
      'Aprili',
      'Mei',
      'Juni',
      'Julai',
      'Agosti',
      'Septemba',
      'Oktoba',
      'Novemba',
      'Desemba',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return isSwahili ? swahili[month - 1] : english[month - 1];
  }

  String monthYear(DateTime date) {
    return '${monthName(date.month)} ${date.year}';
  }

  // ---------------------------------------------------------------------------
  // MEDICINE / PRODUCT FORM
  // ---------------------------------------------------------------------------

  String get addProduct => _text(
        'Add Product',
        'Ongeza Bidhaa',
      );

  String get addProductSubtitle => _text(
        'Add medicines and other pharmacy items to your inventory.',
        'Ongeza dawa na bidhaa nyingine za famasi kwenye stoo yako.',
      );

  String get otherPharmacyItem => _text(
        'Other Pharmacy Item',
        'Bidhaa Nyingine ya Famasi',
      );

  String get enterValidNumber => _text(
        'Enter a valid number.',
        'Ingiza namba sahihi.',
      );

  String get fieldRequiredSuffix => _text(
        'is required.',
        'inahitajika.',
      );

  String get cannotBeNegative => _text(
        'cannot be negative.',
        'haiwezi kuwa chini ya sifuri.',
      );

  String get quantityRequired => _text(
        'Quantity is required.',
        'Kiasi kinahitajika.',
      );

  String get enterWholeNumber => _text(
        'Enter a whole number.',
        'Ingiza namba kamili.',
      );

  String get quantityCannotBeNegative => _text(
        'Quantity cannot be negative.',
        'Kiasi hakiwezi kuwa chini ya sifuri.',
      );

  String get selectExpiryDate => _text(
        'Select expiry date',
        'Chagua tarehe ya kuisha',
      );

  String get barcodeAutoFilled => _text(
        'Barcode scanned. Batch and expiry information filled automatically.',
        'Msimbo pau umechanganuliwa. Namba ya kundi na tarehe ya kuisha zimejazwa kiotomatiki.',
      );

  String get barcodeScannedSuccessfully => _text(
        'Barcode scanned successfully.',
        'Msimbo pau umechanganuliwa kwa mafanikio.',
      );

  String get existingProductFound => _text(
        'Existing product found. Available information loaded.',
        'Bidhaa iliyopo imepatikana. Taarifa zilizopo zimejazwa.',
      );

  String get barcodeInfoFilled => _text(
        'Barcode scanned and available information filled.',
        'Msimbo pau umechanganuliwa na taarifa zilizopo zimejazwa.',
      );

  String get pleaseSelectProductType => _text(
        'Please select product type.',
        'Tafadhali chagua aina ya bidhaa.',
      );

  String get pleaseSelectUnit => _text(
        'Please select unit.',
        'Tafadhali chagua kipimo.',
      );

  String get sellingPriceLowerThanBuying => _text(
        'Selling price cannot be lower than buying price.',
        'Bei ya kuuza haiwezi kuwa chini ya bei ya kununua.',
      );

  String get productAddedSuccessfully => _text(
        'Product added successfully.',
        'Bidhaa imeongezwa kwa mafanikio.',
      );

  String get productTypeRequired => _text(
        'Product type is required.',
        'Aina ya bidhaa inahitajika.',
      );

  String get productNameRequired => _text(
        'Product name is required.',
        'Jina la bidhaa linahitajika.',
      );

  String get categoryRequired => _text(
        'Category is required.',
        'Aina inahitajika.',
      );

  String get unitRequired => _text(
        'Unit is required.',
        'Kipimo kinahitajika.',
      );

  String get productNameExample => _text(
        'e.g. Paracetamol 500mg',
        'mf. Paracetamol 500mg',
      );

  String get categoryExample => _text(
        'e.g. Painkillers',
        'mf. Dawa za maumivu',
      );

  String get barcodeHint => _text(
        'Scan barcode',
        'Changanua msimbo pau',
      );

  String get openingScanner => _text(
        'Opening Scanner...',
        'Inafungua kichanganua...',
      );

  String get batchNumberOptional => _text(
        'Optional',
        'Si lazima',
      );

  String get saveProduct => _text(
        'Save Product',
        'Hifadhi Bidhaa',
      );

  String get saving => _text(
        'Saving...',
        'Inahifadhi...',
      );

  String get scanInstruction => _text(
        'Position the barcode inside the frame.',
        'Weka msimbo pau ndani ya fremu.',
      );


  // ---------------------------------------------------------------------------
  // MEDICINE LIST
  // ---------------------------------------------------------------------------

  String get refresh => _text('Refresh', 'Onyesha Upya');

  String get outOfStock => _text('Out of stock', 'Imeisha');

  String get inStock => _text('In stock', 'Ipo Stoo');

  String get noExpiryDate => _text('No expiry date', 'Hakuna tarehe ya kuisha');

  String get expired => _text('Expired', 'Imeisha muda');

  String get expiresSoon => _text('Expires soon', 'Inaisha muda hivi karibuni');

  String get good => _text('Good', 'Nzuri');

  String get noCategory => _text('No category', 'Hakuna aina');

  String get noMedicinesFound => _text(
        'No medicines found',
        'Hakuna dawa zilizopatikana',
      );

  String get noMedicinesYet => _text(
        'No medicines yet',
        'Bado hakuna dawa',
      );

  String get tryDifferentSearch => _text(
        'Try a different search or remove the filters.',
        'Jaribu utafutaji mwingine au ondoa vichujio.',
      );

  String get addFirstMedicine => _text(
        'Add your first medicine to start managing stock.',
        'Ongeza dawa yako ya kwanza ili kuanza kusimamia stock.',
      );

  String deleteMedicineConfirmation(String medicineName) {
    return isSwahili
        ? 'Una uhakika unataka kufuta "$medicineName"?'
        : 'Are you sure you want to delete "$medicineName"?';
  }

  String get medicineDeletedSuccessfully => _text(
        'Medicine deleted successfully.',
        'Dawa imefutwa kwa mafanikio.',
      );

  String get failedToDeleteMedicine => _text(
        'Failed to delete medicine',
        'Imeshindikana kufuta dawa',
      );

  String get failedToLoadMedicines => _text(
        'Failed to load medicines.',
        'Imeshindikana kupakia dawa.',
      );


  // ---------------------------------------------------------------------------
  // STOCK RECORDS
  // ---------------------------------------------------------------------------

  String get stock => _text(
        'Stock',
        'Stock',
      );

  String get stockRecords => _text(
        'Stock Records',
        'Rekodi za Stock',
      );

  String get stockEntries => _text(
        'Stock Entries',
        'Ingizo za Stock',
      );

  String get totalQuantity => _text(
        'Total Quantity',
        'Jumla ya Kiasi',
      );

  String get totalCost => _text(
        'Total Cost',
        'Jumla ya Gharama',
      );

  String get unitCost => _text(
        'Unit Cost',
        'Gharama kwa Kipimo',
      );

  String stockAdded(String dateTime) {
    return isSwahili
        ? 'Stock imeongezwa: $dateTime'
        : 'Stock added: $dateTime';
  }

  String get notSpecified => _text(
        'Not specified',
        'Haijaainishwa',
      );

  String get unknown => _text(
        'Unknown',
        'Haijulikani',
      );

  String get addedBy => _text(
        'Added By',
        'Imeongezwa na',
      );

  String get noStockRecords => _text(
        'No Stock Records',
        'Hakuna Rekodi za Stock',
      );

  String get noStockRecordsDescription => _text(
        'Stock entries will appear here with their date, quantity, supplier, cost and staff details.',
        'Ingizo za stock zitaonekana hapa pamoja na tarehe, kiasi, msambazaji, gharama na taarifa za mtumishi.',
      );

}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return locale.languageCode == 'en' ||
        locale.languageCode == 'sw';
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(locale),
    );
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<AppLocalizations> old,
  ) {
    return false;
  }
}
