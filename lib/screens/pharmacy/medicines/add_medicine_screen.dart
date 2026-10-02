import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../models/medicine_model.dart';
import '../../../repositories/medicine_repository.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/notifications/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final String pharmacyId;

  const AddMedicineScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<AddMedicineScreen> createState() =>
      _AddMedicineScreenState();
}

class _AddMedicineScreenState
    extends State<AddMedicineScreen> {
  AppLocalizations get _l10n =>
      AppLocalizations.of(context);

  final MedicineRepository _medicineRepository =
      MedicineRepository();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService.instance;

  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _categoryController =
      TextEditingController();

  final _quantityController =
      TextEditingController();

  final _buyingPriceController =
      TextEditingController();

  final _sellingPriceController =
      TextEditingController();

  final _barcodeController =
      TextEditingController();

  final _batchNumberController =
      TextEditingController();

  String? _selectedProductType;
  String? _selectedUnit;

  DateTime? _expiryDate;

  bool _saving = false;
  bool _scanning = false;

  static const List<String> _productTypes = [
    'Medicine',
    'Other Pharmacy Item',
  ];

  static const List<String> _units = [
    'pcs',
    'tablet',
    'capsule',
    'bottle',
    'box',
    'strip',
    'vial',
    'tube',
    'sachet',
    'pack',
    'pair',
    'roll',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _barcodeController.dispose();
    _batchNumberController.dispose();

    super.dispose();
  }

  String? _requiredValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return '$fieldName ${_l10n.fieldRequiredSuffix}';
    }

    return null;
  }

  String? _numberValidator(
    String? value,
    String fieldName,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return '$fieldName ${_l10n.fieldRequiredSuffix}';
    }

    final number = double.tryParse(
      value.trim(),
    );

    if (number == null) {
      return _l10n.enterValidNumber;
    }

    if (number < 0) {
      return '$fieldName ${_l10n.cannotBeNegative}';
    }

    return null;
  }

  String? _quantityValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return _l10n.quantityRequired;
    }

    final quantity = int.tryParse(
      value.trim(),
    );

    if (quantity == null) {
      return _l10n.enterWholeNumber;
    }

    if (quantity < 0) {
      return _l10n.quantityCannotBeNegative;
    }

    return null;
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();

    final initialDate =
        _expiryDate ?? now;

    final selectedDate =
        await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(
        now.year - 1,
      ),
      lastDate: DateTime(
        now.year + 20,
      ),
      helpText:
          _l10n.selectExpiryDate,
    );

    if (selectedDate == null ||
        !mounted) {
      return;
    }

    setState(() {
      _expiryDate = selectedDate;
    });
  }

  Future<void> _scanBarcode() async {
    if (_scanning || _saving) {
      return;
    }

    setState(() {
      _scanning = true;
    });

    try {
      final result =
          await Navigator.push<
              _BarcodeScanResult>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const _BarcodeScannerScreen(),
        ),
      );

      if (result == null ||
          !mounted) {
        return;
      }

      await _handleScannedBarcode(
        result.rawValue,
      );
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
        });
      }
    }
  }

  Future<void> _handleScannedBarcode(
    String rawValue,
  ) async {
    final barcode = rawValue.trim();

    if (barcode.isEmpty) {
      return;
    }

    final parsed =
        _parseGs1Barcode(
      barcode,
    );

    setState(() {
      _barcodeController.text =
          barcode;

      if (parsed.batchNumber != null &&
          parsed.batchNumber!.isNotEmpty) {
        _batchNumberController.text =
            parsed.batchNumber!;
      }

      if (parsed.expiryDate != null) {
        _expiryDate =
            parsed.expiryDate;
      }
    });

    final autoFilledMessage =
        _l10n.barcodeAutoFilled;

    final scannedSuccessMessage =
        _l10n.barcodeScannedSuccessfully;

    final existingProductMessage =
        _l10n.existingProductFound;

    final barcodeInfoMessage =
        _l10n.barcodeInfoFilled;

    try {
      final existingMedicine =
          await _medicineRepository
              .findByBarcode(
        pharmacyId: widget.pharmacyId,
        barcode: barcode,
      );

      if (!mounted) {
        return;
      }

      if (existingMedicine == null) {
        _showMessage(
          parsed.hasAutoFilledData
              ? autoFilledMessage
              : scannedSuccessMessage,
        );

        return;
      }

      setState(() {
        if (_nameController.text
            .trim()
            .isEmpty) {
          _nameController.text =
              existingMedicine.name;
        }

        if (_categoryController
            .text
            .trim()
            .isEmpty) {
          _categoryController.text =
              existingMedicine.category;
        }

        _selectedProductType ??=
            existingMedicine.isMedicine
                ? 'Medicine'
                : 'Other Pharmacy Item';

        if (_selectedUnit == null &&
            existingMedicine.unit
                .isNotEmpty) {
          _selectedUnit =
              _units.contains(
            existingMedicine.unit,
          )
                  ? existingMedicine.unit
                  : null;
        }

        if (_batchNumberController
            .text
            .trim()
            .isEmpty) {
          _batchNumberController.text =
              existingMedicine.batchNumber;
        }

        _expiryDate ??=
            existingMedicine.expiryDate;
      });

      _showMessage(
        existingProductMessage,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        parsed.hasAutoFilledData
            ? barcodeInfoMessage
            : scannedSuccessMessage,
      );
    }
  }

  _ParsedGs1Data _parseGs1Barcode(
    String rawValue,
  ) {
    final value = rawValue.trim();

    String? batchNumber;
    DateTime? expiryDate;

    final expiryWithParentheses =
        RegExp(
      r'\(17\)(\d{6})',
    ).firstMatch(value);

    if (expiryWithParentheses !=
        null) {
      expiryDate =
          _parseGs1Date(
        expiryWithParentheses
            .group(1)!,
      );
    }

    final batchWithParentheses =
        RegExp(
      r'\(10\)([^()]+)',
    ).firstMatch(value);

    if (batchWithParentheses !=
        null) {
      batchNumber =
          batchWithParentheses
              .group(1)!
              .replaceAll(
                String.fromCharCode(29),
                '',
              )
              .trim();
    }

    final separator =
        String.fromCharCode(29);

    final expiryPlain =
        RegExp(
      r'17(\d{6})',
    ).firstMatch(value);

    if (expiryDate == null &&
        expiryPlain != null) {
      expiryDate =
          _parseGs1Date(
        expiryPlain.group(1)!,
      );
    }

    final batchPlainIndex =
        value.indexOf('10');

    if (batchNumber == null &&
        batchPlainIndex >= 0) {
      final start =
          batchPlainIndex + 2;

      var batch =
          value.substring(start);

      final separatorIndex =
          batch.indexOf(
        separator,
      );

      if (separatorIndex >= 0) {
        batch = batch.substring(
          0,
          separatorIndex,
        );
      }

      final nextAi =
          RegExp(
        r'(01|17|21)\d{2,}',
      ).firstMatch(batch);

      if (nextAi != null &&
          nextAi.start > 0) {
        batch = batch.substring(
          0,
          nextAi.start,
        );
      }

      batch = batch.trim();

      if (batch.isNotEmpty) {
        batchNumber = batch;
      }
    }

    return _ParsedGs1Data(
      batchNumber: batchNumber,
      expiryDate: expiryDate,
    );
  }

  DateTime? _parseGs1Date(
    String value,
  ) {
    if (value.length != 6) {
      return null;
    }

    final year = int.tryParse(
      value.substring(0, 2),
    );

    final month = int.tryParse(
      value.substring(2, 4),
    );

    final day = int.tryParse(
      value.substring(4, 6),
    );

    if (year == null ||
        month == null ||
        day == null ||
        month < 1 ||
        month > 12) {
      return null;
    }

    final fullYear = 2000 + year;

    if (day == 0) {
      return DateTime(
        fullYear,
        month + 1,
        0,
      );
    }

    if (day < 1 || day > 31) {
      return null;
    }

    final parsed = DateTime(
      fullYear,
      month,
      day,
    );

    if (parsed.year != fullYear ||
        parsed.month != month ||
        parsed.day != day) {
      return null;
    }

    return parsed;
  }

  Future<bool> _isCurrentUserStaff() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final profile =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      return profile.data()?['role']
              ?.toString() ==
          'staff';
    } catch (_) {
      return false;
    }
  }

  Future<void>
      _createProductNotifications(
    MedicineModel medicine,
  ) async {
    final isStaff =
        await _isCurrentUserStaff();

    if (!isStaff) {
      return;
    }

    // ------------------------------------------------------------
    // 1. STAFF: PRODUCT ADDED
    // 2. OWNER: STAFF ADDED PRODUCT
    // ------------------------------------------------------------

    try {
      await _notificationService
          .createStaffNotification(
        pharmacyId:
            widget.pharmacyId,
        type:
            'product_added',
        title:
            'Product added successfully',
        message:
            'You added a new product to the pharmacy.',
        itemName:
            medicine.name,
        status:
            'success',
        relatedId:
            medicine.id,
      );
    } catch (_) {
      // Product save should not fail
      // because of notification failure.
    }

    try {
      await _notificationService
          .createOwnerNotification(
        pharmacyId:
            widget.pharmacyId,
        type:
            'staff_product_added',
        title:
            'Staff added a product',
        message:
            'A staff member added a new product.',
        itemName:
            medicine.name,
        status:
            'success',
        relatedId:
            medicine.id,
      );
    } catch (_) {
      // Product save should not fail
      // because of notification failure.
    }

    // ------------------------------------------------------------
    // 3. LOW STOCK
    // 4. EXPIRY
    // ------------------------------------------------------------

    try {
      await _notificationService
          .checkAndCreateMedicineAlerts(
        pharmacyId:
            widget.pharmacyId,
        medicineId:
            medicine.id,
        medicineName:
            medicine.name,
        quantity:
            medicine.quantity,
        isLowStock:
            medicine.isLowStock,
        expiryDate:
            medicine.expiryDate,
        isExpired:
            medicine.isExpired,
        expiresWithin30Days:
            medicine.expiresWithin30Days,
        unit:
            medicine.unit,
      );
    } catch (_) {
      // Product save should not fail
      // because of notification failure.
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final productTypeRequiredMessage =
        _l10n.pleaseSelectProductType;

    final unitRequiredMessage =
        _l10n.pleaseSelectUnit;

    final sellingPriceErrorMessage =
        _l10n.sellingPriceLowerThanBuying;

    final productAddedMessage =
        _l10n.productAddedSuccessfully;

    if (_selectedProductType ==
        null) {
      _showMessage(
        productTypeRequiredMessage,
      );

      return;
    }

    if (_selectedUnit == null) {
      _showMessage(
        unitRequiredMessage,
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final quantity =
          int.parse(
        _quantityController.text
            .trim(),
      );

      final buyingPrice =
          double.parse(
        _buyingPriceController
            .text
            .trim(),
      );

      final sellingPrice =
          double.parse(
        _sellingPriceController
            .text
            .trim(),
      );

      if (sellingPrice <
          buyingPrice) {
        throw Exception(
          sellingPriceErrorMessage,
        );
      }

      final productType =
          _selectedProductType ==
                  'Medicine'
              ? 'medicine'
              : 'other';

      final medicine =
          MedicineModel(
        id: '',
        pharmacyId:
            widget.pharmacyId,
        name:
            _nameController.text
                .trim(),
        category:
            _categoryController.text
                .trim(),
        productType:
            productType,
        unit:
            _selectedUnit!,
        quantity:
            quantity,
        buyingPrice:
            buyingPrice,
        sellingPrice:
            sellingPrice,
        barcode:
            _barcodeController.text
                .trim(),
        batchNumber:
            _batchNumberController
                .text
                .trim(),
        expiryDate:
            _expiryDate,
        createdAt:
            DateTime.now(),
        updatedAt:
            DateTime.now(),
      );

      final medicineId =
          await _medicineRepository
              .addMedicine(
        medicine,
      );

      final savedMedicine =
          MedicineModel(
        id: medicineId,
        pharmacyId:
            medicine.pharmacyId,
        name:
            medicine.name,
        category:
            medicine.category,
        productType:
            medicine.productType,
        unit:
            medicine.unit,
        quantity:
            medicine.quantity,
        buyingPrice:
            medicine.buyingPrice,
        sellingPrice:
            medicine.sellingPrice,
        barcode:
            medicine.barcode,
        batchNumber:
            medicine.batchNumber,
        expiryDate:
            medicine.expiryDate,
        createdAt:
            medicine.createdAt,
        updatedAt:
            medicine.updatedAt,
      );

      await _createProductNotifications(
        savedMedicine,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        productAddedMessage,
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _cleanError(
    Object error,
  ) {
    final message =
        error.toString();

    if (message.startsWith(
        'Exception: ')) {
      return message.replaceFirst(
        'Exception: ',
        '',
      );
    }

    return message;
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          Icon(icon),
      suffixIcon:
          suffixIcon,
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide(
          color:
              Colors.grey.shade300,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            BorderSide(
          color:
              Theme.of(context)
                  .colorScheme
                  .primary,
          width: 2,
        ),
      ),
      filled: true,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_l10n.addProduct),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ),
            children: [
              Container(
                padding:
                    const EdgeInsets.all(
                  16,
                ),
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                  color:
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(
                    alpha: 0.08,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                        color:
                            Theme.of(
                          context,
                        )
                                .colorScheme
                                .primary
                                .withValues(
                          alpha: 0.12,
                        ),
                      ),
                      child: Icon(
                        Icons
                            .inventory_2_rounded,
                        color:
                            Theme.of(
                          context,
                        )
                                .colorScheme
                                .primary,
                      ),
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            _l10n
                                .productInformation,
                            style:
                                const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            _l10n
                                .addProductSubtitle,
                            style:
                                const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              DropdownButtonFormField<
                  String>(
                initialValue:
                    _selectedProductType,
                decoration:
                    _inputDecoration(
                  _l10n.productType,
                  Icons.category_rounded,
                  hint: _l10n
                      .selectProductType,
                ),
                items:
                    _productTypes.map(
                  (type) {
                    return DropdownMenuItem<
                        String>(
                      value: type,
                      child: Text(
                        type ==
                                'Medicine'
                            ? _l10n
                                .medicine
                            : _l10n
                                .otherPharmacyItem,
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    _saving
                        ? null
                        : (value) {
                            setState(() {
                              _selectedProductType =
                                  value;
                            });
                          },
                validator:
                    (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return _l10n
                        .productTypeRequired;
                  }

                  return null;
                },
              ),

              const SizedBox(
                height: 14,
              ),

              TextFormField(
                controller:
                    _nameController,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    _inputDecoration(
                  _l10n.productName,
                  Icons
                      .medication_outlined,
                  hint: _l10n
                      .productNameExample,
                ),
                validator:
                    (value) =>
                        _requiredValidator(
                  value,
                  _l10n.productName,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              TextFormField(
                controller:
                    _categoryController,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    _inputDecoration(
                  _l10n.category,
                  Icons.category_outlined,
                  hint: _l10n
                      .categoryExample,
                ),
                validator:
                    (value) =>
                        _requiredValidator(
                  value,
                  _l10n.category,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Expanded(
                    child:
                        DropdownButtonFormField<
                            String>(
                      initialValue:
                          _selectedUnit,
                      isExpanded:
                          true,
                      decoration:
                          _inputDecoration(
                        _l10n.unit,
                        Icons
                            .inventory_2_outlined,
                        hint: _l10n
                            .selectUnit,
                      ),
                      items:
                          _units.map(
                        (unit) {
                          return DropdownMenuItem<
                              String>(
                            value: unit,
                            child:
                                Text(unit),
                          );
                        },
                      ).toList(),
                      onChanged:
                          _saving
                              ? null
                              : (value) {
                                  setState(
                                    () {
                                      _selectedUnit =
                                          value;
                                    },
                                  );
                                },
                      validator:
                          (value) {
                        if (value ==
                                null ||
                            value.isEmpty) {
                          return _l10n
                              .unitRequired;
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        TextFormField(
                      controller:
                          _quantityController,
                      keyboardType:
                          TextInputType
                              .number,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          _inputDecoration(
                        _l10n.quantity,
                        Icons
                            .numbers_rounded,
                        hint: '0',
                      ),
                      validator:
                          _quantityValidator,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Expanded(
                    child:
                        TextFormField(
                      controller:
                          _buyingPriceController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          _inputDecoration(
                        _l10n
                            .buyingPrice,
                        Icons
                            .shopping_cart_outlined,
                        hint: '0',
                      ),
                      validator:
                          (value) =>
                              _numberValidator(
                        value,
                        _l10n
                            .buyingPrice,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child:
                        TextFormField(
                      controller:
                          _sellingPriceController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          _inputDecoration(
                        _l10n
                            .sellingPrice,
                        Icons
                            .sell_outlined,
                        hint: '0',
                      ),
                      validator:
                          (value) =>
                              _numberValidator(
                        value,
                        _l10n
                            .sellingPrice,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 14,
              ),

              TextFormField(
                controller:
                    _barcodeController,
                readOnly: true,
                decoration:
                    _inputDecoration(
                  _l10n.barcode,
                  Icons
                      .qr_code_2_rounded,
                  hint: _l10n
                      .barcodeHint,
                  suffixIcon:
                      IconButton(
                    tooltip:
                        _l10n.scanBarcode,
                    onPressed:
                        _saving ||
                                _scanning
                            ? null
                            : _scanBarcode,
                    icon: _scanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                            ),
                          )
                        : const Icon(
                            Icons
                                .qr_code_scanner_rounded,
                          ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              SizedBox(
                width:
                    double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed:
                      _saving ||
                              _scanning
                          ? null
                          : _scanBarcode,
                  icon:
                      const Icon(
                    Icons
                        .qr_code_scanner_rounded,
                  ),
                  label: Text(
                    _scanning
                        ? _l10n
                            .openingScanner
                        : _l10n
                            .scanBarcode,
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              TextFormField(
                controller:
                    _batchNumberController,
                textInputAction:
                    TextInputAction.next,
                decoration:
                    _inputDecoration(
                  _l10n.batchNumber,
                  Icons
                      .confirmation_number_outlined,
                  hint: _l10n
                      .optional,
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              InkWell(
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                onTap:
                    _saving
                        ? null
                        : _selectExpiryDate,
                child:
                    InputDecorator(
                  decoration:
                      _inputDecoration(
                    _l10n.expiryDate,
                    Icons
                        .event_outlined,
                    hint: _l10n
                        .optional,
                  ),
                  child: Text(
                    _expiryDate == null
                        ? _l10n
                            .selectExpiryDate
                        : _formatDate(
                            _expiryDate!,
                          ),
                    style:
                        TextStyle(
                      color:
                          _expiryDate ==
                                  null
                              ? Colors
                                  .grey
                                  .shade600
                              : Colors
                                  .black87,
                      fontSize:
                          16,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                height: 52,
                child:
                    FilledButton.icon(
                  onPressed:
                      _saving
                          ? null
                          : _saveMedicine,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_rounded,
                        ),
                  label: Text(
                    _saving
                        ? _l10n
                            .saving
                        : _l10n
                            .saveProduct,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final day = date.day
        .toString()
        .padLeft(2, '0');

    final month = date.month
        .toString()
        .padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _BarcodeScanResult {
  final String rawValue;

  const _BarcodeScanResult({
    required this.rawValue,
  });
}

class _ParsedGs1Data {
  final String? batchNumber;
  final DateTime? expiryDate;

  const _ParsedGs1Data({
    this.batchNumber,
    this.expiryDate,
  });

  bool get hasAutoFilledData {
    return (batchNumber != null &&
            batchNumber!.isNotEmpty) ||
        expiryDate != null;
  }
}

class _BarcodeScannerScreen
    extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen>
      createState() =>
          _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState
    extends State<_BarcodeScannerScreen> {
  AppLocalizations get _l10n =>
      AppLocalizations.of(context);

  bool _handled = false;

  void _onDetect(
    BarcodeCapture capture,
  ) {
    if (_handled) {
      return;
    }

    for (final barcode
        in capture.barcodes) {
      final rawValue =
          barcode.rawValue?.trim();

      if (rawValue != null &&
          rawValue.isNotEmpty) {
        _handled = true;

        Navigator.pop(
          context,
          _BarcodeScanResult(
            rawValue: rawValue,
          ),
        );

        return;
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.black,
      appBar: AppBar(
        title:
            Text(_l10n.scanBarcode),
        backgroundColor:
            Colors.black,
        foregroundColor:
            Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect:
                _onDetect,
          ),
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration:
                  BoxDecoration(
                border:
                    Border.all(
                  color:
                      Colors.white,
                  width: 3,
                ),
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Container(
              padding:
                  const EdgeInsets.all(14),
              decoration:
                  BoxDecoration(
                color:
                    Colors.black
                        .withValues(
                  alpha: 0.65,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: Text(
                _l10n.scanInstruction,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  color:
                      Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}