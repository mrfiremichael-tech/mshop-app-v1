import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/customer_model.dart';
import '../../../models/medicine_model.dart';
import '../../../models/sale_model.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/medicine_repository.dart';
import '../../../services/notifications/notification_service.dart';

String _t(
  AppLocalizations l10n,
  String english,
  String swahili,
) =>
    l10n.isSwahili ? swahili : english;

class AddSaleScreen extends StatefulWidget {
  final String pharmacyId;

  const AddSaleScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends State<AddSaleScreen> {
  final MedicineRepository _medicineRepository =
      MedicineRepository();

  final CustomerRepository _customerRepository =
      CustomerRepository();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final NotificationService _notificationService =
      NotificationService.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  MedicineModel? _selectedMedicine;
  CustomerModel? _selectedCustomer;

  List<MedicineModel> _medicines = [];
  List<CustomerModel> _customers = [];

  bool _loadingData = true;
  bool _saving = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();

    _loadData();

    _quantityController.addListener(_updateTotals);
  }

  @override
  void dispose() {
    _quantityController
      ..removeListener(_updateTotals)
      ..dispose();

    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _medicineRepository.getMedicines(
          widget.pharmacyId,
        ),
        _customerRepository.getCustomers(
          widget.pharmacyId,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _medicines =
            results[0] as List<MedicineModel>;

        _customers =
            results[1] as List<CustomerModel>;

        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingData = false;
      });

      final l10n =
          AppLocalizations.of(context);

      _showMessage(
        _t(
          l10n,
          'Failed to load sales data: ${_cleanError(e)}',
          'Imeshindwa kupakia taarifa za mauzo: ${_cleanError(e)}',
        ),
      );
    }
  }

  void _updateTotals() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _onMedicineChanged(
    MedicineModel? medicine, {
    bool resetQuantity = true,
  }) {
    setState(() {
      _selectedMedicine = medicine;

      if (resetQuantity && medicine != null) {
        _quantityController.text = '1';
      }
    });
  }

  void _onCustomerChanged(
    CustomerModel? customer,
  ) {
    setState(() {
      _selectedCustomer = customer;
    });
  }

  int get _quantity {
    return int.tryParse(
          _quantityController.text.trim(),
        ) ??
        0;
  }

  double get _sellingPrice {
    return _selectedMedicine?.sellingPrice ?? 0;
  }

  double get _buyingPrice {
    return _selectedMedicine?.buyingPrice ?? 0;
  }

  double get _totalAmount {
    return _quantity * _sellingPrice;
  }

  double get _profit {
    return _quantity *
        (_sellingPrice - _buyingPrice);
  }

  String _formatCurrency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  String? _quantityValidator(String? value) {
    final l10n =
        AppLocalizations.of(context);

    if (value == null ||
        value.trim().isEmpty) {
      return _t(
        l10n,
        'Quantity is required.',
        'Kiasi kinahitajika.',
      );
    }

    final quantity = int.tryParse(
      value.trim(),
    );

    if (quantity == null) {
      return _t(
        l10n,
        'Quantity must be a whole number.',
        'Kiasi lazima kiwe namba kamili.',
      );
    }

    if (quantity <= 0) {
      return _t(
        l10n,
        'Quantity must be greater than 0.',
        'Kiasi lazima kiwe zaidi ya 0.',
      );
    }

    if (_selectedMedicine != null &&
        quantity > _selectedMedicine!.quantity) {
      return _t(
        l10n,
        'Not enough stock. Available: ${_selectedMedicine!.quantity}.',
        'Stock haitoshi. Iliyopo: ${_selectedMedicine!.quantity}.',
      );
    }

    return null;
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.replaceFirst(
        'Exception: ',
        '',
      );
    }

    return message;
  }

  Future<bool> _currentUserIsStaff() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final profile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = profile.data();

      return data?['role']?.toString() == 'staff';
    } catch (_) {
      return false;
    }
  }

  Future<void> _scanBarcode() async {
    final l10n =
        AppLocalizations.of(context);

    if (_scanning || _saving) {
      return;
    }

    setState(() {
      _scanning = true;
    });

    final String? scannedBarcode =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const _BarcodeScannerScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _scanning = false;
    });

    if (scannedBarcode == null ||
        scannedBarcode.trim().isEmpty) {
      return;
    }

    final barcode =
        scannedBarcode.trim();

    MedicineModel? foundMedicine;

    for (final medicine in _medicines) {
      if (medicine.barcode.trim() ==
          barcode) {
        foundMedicine = medicine;
        break;
      }
    }

    if (foundMedicine == null) {
      _showMessage(
        _t(
          l10n,
          'No product found with barcode: $barcode',
          'Hakuna bidhaa iliyopatikana yenye barcode: $barcode',
        ),
      );

      return;
    }

    if (foundMedicine.quantity <= 0) {
      _showMessage(
        _t(
          l10n,
          '${foundMedicine.name} is out of stock.',
          '${foundMedicine.name} imekwisha stock.',
        ),
      );

      return;
    }

    setState(() {
      _selectedMedicine =
          foundMedicine;

      _quantityController.text = '1';
    });

    _showMessage(
      _t(
        l10n,
        '${foundMedicine.name} selected automatically.',
        '${foundMedicine.name} imechaguliwa moja kwa moja.',
      ),
    );
  }

  Future<void> _saveSale() async {
    final l10n =
        AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMedicine == null) {
      _showMessage(
        _t(
          l10n,
          'Please select a product.',
          'Tafadhali chagua bidhaa.',
        ),
      );

      return;
    }

    if (_quantity <= 0) {
      _showMessage(
        _t(
          l10n,
          'Quantity must be greater than 0.',
          'Kiasi lazima kiwe zaidi ya 0.',
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    String? medicineNameForNotification;
    String? saleId;

    try {
      final medicine = _selectedMedicine!;
      final customer = _selectedCustomer;

      final currentUser = _auth.currentUser;
      final staffId = (await _currentUserIsStaff()) ? (currentUser?.uid ?? '') : '';

      medicineNameForNotification =
          medicine.name;

      final medicineRef =
          _firestore
              .collection('medicines')
              .doc(medicine.id);

      final saleRef =
          _firestore.collection('sales').doc();

      saleId = saleRef.id;

      await _firestore.runTransaction(
        (transaction) async {
          final medicineSnapshot =
              await transaction.get(
            medicineRef,
          );

          if (!medicineSnapshot.exists) {
            throw Exception(
              _t(
                l10n,
                'Product no longer exists.',
                'Bidhaa hii haipo tena.',
              ),
            );
          }

          final medicineData =
              medicineSnapshot.data();

          if (medicineData == null) {
            throw Exception(
              _t(
                l10n,
                'Product data could not be read.',
                'Taarifa za bidhaa hazikuweza kusomwa.',
              ),
            );
          }

          final medicinePharmacyId =
              medicineData['pharmacyId']
                  ?.toString();

          if (medicinePharmacyId !=
              widget.pharmacyId) {
            throw Exception(
              _t(
                l10n,
                'This product does not belong to this pharmacy.',
                'Bidhaa hii si ya pharmacy hii.',
              ),
            );
          }

          final currentQuantity =
              _toInt(
            medicineData['quantity'],
          );

          if (_quantity >
              currentQuantity) {
            throw Exception(
              _t(
                l10n,
                'Not enough stock. Available: $currentQuantity.',
                'Stock haitoshi. Iliyopo: $currentQuantity.',
              ),
            );
          }

          final currentSellingPrice =
              _toDouble(
            medicineData['sellingPrice'],
          );

          final currentBuyingPrice =
              _toDouble(
            medicineData['buyingPrice'],
          );

          if (currentSellingPrice <= 0) {
            throw Exception(
              _t(
                l10n,
                'Product selling price is not set.',
                'Bei ya kuuza bidhaa haijawekwa.',
              ),
            );
          }

          final totalAmount =
              _quantity *
                  currentSellingPrice;

          final profit =
              _quantity *
                  (currentSellingPrice -
                      currentBuyingPrice);

          final newQuantity =
              currentQuantity -
                  _quantity;

          final now =
              Timestamp.now();

          transaction.update(
            medicineRef,
            {
              'quantity': newQuantity,
              'updatedAt': now,
            },
          );

          final sale = SaleModel(
            id: saleRef.id,
            pharmacyId: widget.pharmacyId,
            staffId: staffId,
            medicineId: medicine.id,
            medicineName:
                medicine.name,
            customerId:
                customer?.id ?? '',
            customerName:
                customer?.name ?? '',
            quantity: _quantity,
            unitPrice:
                currentSellingPrice,
            totalAmount:
                totalAmount,
            profit: profit,
            createdAt:
                DateTime.now(),
            updatedAt:
                DateTime.now(),
          );

          transaction.set(
            saleRef,
            sale.toFirestore(),
          );
        },
      );

      // ------------------------------------------------------------
      // TWO-WAY NOTIFICATION KWA STAFF TU
      // ------------------------------------------------------------

      final isStaff =
          await _currentUserIsStaff();

      if (isStaff) {
        try {
          await _notificationService
              .createTwoWayNotification(
            pharmacyId:
                widget.pharmacyId,
            staffType:
                'sale_result',
            staffTitle:
                'Sale completed successfully',
            staffMessage:
                'Sale completed successfully',
            ownerType:
                'staff_sale',
            ownerTitle:
                'Staff completed a sale',
            ownerMessage:
                'A staff member completed a sale',
            itemName:
                medicineNameForNotification,
            status:
                'success',
            relatedId:
                saleId,
          );
        } catch (_) {
          // Sale imefanikiwa.
          // Notification ikifeli, sale haifutwi.
        }
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _t(
              l10n,
              'Sale saved, stock decreased and profit calculated successfully.',
              'Mauzo yamehifadhiwa, stock imepungua na faida imekokotolewa kwa mafanikio.',
            ),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      // ------------------------------------------------------------
      // FAILURE NOTIFICATION KWA STAFF TU
      // ------------------------------------------------------------

      final isStaff =
          await _currentUserIsStaff();

      if (isStaff) {
        try {
          await _notificationService
              .createStaffNotification(
            pharmacyId:
                widget.pharmacyId,
            type:
                'sale_result',
            title:
                'Sale failed',
            message:
                'The sale could not be completed.',
            itemName:
                medicineNameForNotification,
            status:
                'failed',
            relatedId:
                saleId,
          );

          await _notificationService
              .createOwnerNotification(
            pharmacyId:
                widget.pharmacyId,
            type:
                'staff_sale_failed',
            title:
                'Staff sale failed',
            message:
                'A staff sale could not be completed.',
            itemName:
                medicineNameForNotification,
            status:
                'failed',
            relatedId:
                saleId,
          );
        } catch (_) {
          // Usifiche ujumbe wa error ya sale
          // kama notification imefeli.
        }
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        _t(
          l10n,
          'Failed to save sale: ${_cleanError(e)}',
          'Imeshindwa kuhifadhi mauzo: ${_cleanError(e)}',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context)
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
    final l10n =
        AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(
            l10n,
            'Add Sale',
            'Ongeza Mauzo',
          ),
        ),
      ),
      body: _loadingData
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SafeArea(
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
                    _buildHeader(),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildBarcodeSection(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildMedicineSelector(),

                    if (_selectedMedicine !=
                        null) ...[
                      const SizedBox(
                        height: 14,
                      ),
                      _buildMedicineInfo(),
                    ],

                    const SizedBox(
                      height: 14,
                    ),

                    _buildCustomerSelector(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildQuantityField(),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildSaleSummary(),

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
                                : _saveSale,
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
                                Icons
                                    .check_circle_rounded,
                              ),
                        label:
                            Text(
                          _saving
                              ? _t(
                                  l10n,
                                  'Saving...',
                                  'Inahifadhi...',
                                )
                              : _t(
                                  l10n,
                                  'Complete Sale',
                                  'Kamilisha Mauzo',
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final l10n =
        AppLocalizations.of(context);

    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: Theme.of(context)
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
                  BorderRadius.circular(
                14,
              ),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(
                    alpha: 0.12,
                  ),
            ),
            child: Icon(
              Icons
                  .point_of_sale_rounded,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    l10n,
                    'New Sale',
                    'Mauzo Mapya',
                  ),
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _t(
                    l10n,
                    'Scan barcode or select a product, then complete the sale.',
                    'Changanua barcode au chagua bidhaa, kisha kamilisha mauzo.',
                  ),
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
    );
  }

  Widget _buildBarcodeSection() {
    final l10n =
        AppLocalizations.of(context);

    return SizedBox(
      width: double.infinity,
      child:
          OutlinedButton.icon(
        onPressed:
            _saving || _scanning
                ? null
                : _scanBarcode,
        icon: _scanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons
                    .qr_code_scanner_rounded,
              ),
        label: Text(
          _scanning
              ? _t(
                  l10n,
                  'Opening Scanner...',
                  'Inafungua Scanner...',
                )
              : _t(
                  l10n,
                  'Scan Product Barcode',
                  'Scan Barcode ya Bidhaa',
                ),
        ),
        style:
            OutlinedButton.styleFrom(
          minimumSize:
              const Size(
            double.infinity,
            52,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineSelector() {
    final l10n =
        AppLocalizations.of(context);

    final availableProducts =
        _medicines
            .where(
              (product) =>
                  product.quantity > 0,
            )
            .toList();

    return DropdownButtonFormField<
        MedicineModel>(
      initialValue:
          _selectedMedicine,
      isExpanded: true,
      decoration:
          _inputDecoration(
        _t(
          l10n,
          'Product',
          'Bidhaa',
        ),
        Icons
            .medication_outlined,
      ),
      items:
          availableProducts
              .map(
        (product) {
          return DropdownMenuItem<
              MedicineModel>(
            value: product,
            child: Text(
              '${product.name} '
              '(Stock: ${product.quantity})',
              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: _saving
          ? null
          : (medicine) {
              _onMedicineChanged(
                medicine,
              );
            },
      validator: (value) {
        if (value == null) {
          return _t(
            l10n,
            'Please select a product.',
            'Tafadhali chagua bidhaa.',
          );
        }

        if (value.quantity <= 0) {
          return _t(
            l10n,
            'This product is out of stock.',
            'Bidhaa hii imekwisha stock.',
          );
        }

        return null;
      },
    );
  }

  Widget _buildMedicineInfo() {
    final l10n =
        AppLocalizations.of(context);

    final medicine =
        _selectedMedicine!;

    final remainingStock =
        medicine.quantity -
            _quantity;

    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          if (medicine.barcode
              .trim()
              .isNotEmpty) ...[
            _SmallInfo(
              label: _t(
                l10n,
                'Barcode',
                'Msimbo Pau',
              ),
              value:
                  medicine.barcode,
            ),
            const SizedBox(
              height: 12,
            ),
          ],
          _SmallInfo(
            label: _t(
              l10n,
              'Product Type',
              'Aina ya Bidhaa',
            ),
            value:
                medicine.productType ==
                        'medicine'
                    ? _t(
                        l10n,
                        'Medicine',
                        'Dawa',
                      )
                    : _t(
                        l10n,
                        'Other',
                        'Nyingine',
                      ),
          ),
          const SizedBox(
            height: 12,
          ),
          Row(
            children: [
              Expanded(
                child: _SmallInfo(
                  label: _t(
                    l10n,
                    'Available',
                    'Iliyopo',
                  ),
                  value:
                      '${medicine.quantity} ${medicine.unit}',
                ),
              ),
              Expanded(
                child: _SmallInfo(
                  label: _t(
                    l10n,
                    'Selling Price',
                    'Bei ya Kuuza',
                  ),
                  value:
                      _formatCurrency(
                    medicine
                        .sellingPrice,
                  ),
                ),
              ),
              Expanded(
                child: _SmallInfo(
                  label: _t(
                    l10n,
                    'Remaining',
                    'Iliyobaki',
                  ),
                  value:
                      '${remainingStock < 0 ? 0 : remainingStock} ${medicine.unit}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelector() {
    final l10n =
        AppLocalizations.of(context);

    return DropdownButtonFormField<
        CustomerModel>(
      initialValue:
          _selectedCustomer,
      isExpanded: true,
      decoration:
          _inputDecoration(
        _t(
          l10n,
          'Customer (Optional)',
          'Mteja (Hiari)',
        ),
        Icons
            .person_outline_rounded,
      ),
      items: [
        DropdownMenuItem<
            CustomerModel>(
          value: null,
          child: Text(
            _t(
              l10n,
              'Walk-in Customer',
              'Mteja wa Moja kwa Moja',
            ),
          ),
        ),
        ..._customers.map(
          (customer) {
            return DropdownMenuItem<
                CustomerModel>(
              value: customer,
              child: Text(
                customer.name,
                overflow:
                    TextOverflow
                        .ellipsis,
              ),
            );
          },
        ),
      ],
      onChanged: _saving
          ? null
          : _onCustomerChanged,
    );
  }

  Widget _buildQuantityField() {
    final l10n =
        AppLocalizations.of(context);

    return TextFormField(
      controller:
          _quantityController,
      keyboardType:
          TextInputType.number,
      textInputAction:
          TextInputAction.done,
      decoration:
          _inputDecoration(
        _t(
          l10n,
          'Quantity',
          'Kiasi',
        ),
        Icons.numbers_rounded,
        hint: _t(
          l10n,
          'Enter quantity',
          'Ingiza kiasi',
        ),
      ).copyWith(
        suffixText:
            _selectedMedicine?.unit,
      ),
      validator:
          _quantityValidator,
    );
  }

  Widget _buildSaleSummary() {
    final l10n =
        AppLocalizations.of(context);

    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(
              alpha: 0.08,
            ),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: _t(
              l10n,
              'Unit Selling Price',
              'Bei ya Kuuza kwa Kimoja',
            ),
            value:
                _formatCurrency(
              _sellingPrice,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          _SummaryRow(
            label: _t(
              l10n,
              'Quantity',
              'Kiasi',
            ),
            value:
                _quantity.toString(),
          ),
          const Divider(
            height: 24,
          ),
          _SummaryRow(
            label: _t(
              l10n,
              'Total Sale',
              'Jumla ya Mauzo',
            ),
            value:
                _formatCurrency(
              _totalAmount,
            ),
            bold: true,
          ),
          const SizedBox(
            height: 10,
          ),
          _SummaryRow(
            label: _t(
              l10n,
              'Profit',
              'Faida',
            ),
            value:
                _formatCurrency(
              _profit,
            ),
            valueColor:
                Colors.green,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _BarcodeScannerScreen
    extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<
      _BarcodeScannerScreen>
      createState() =>
          _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState
    extends State<
        _BarcodeScannerScreen> {
  final MobileScannerController
      _controller =
      MobileScannerController();

  bool _alreadyScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetection(
    BarcodeCapture capture,
  ) {
    if (_alreadyScanned) {
      return;
    }

    for (final barcode
        in capture.barcodes) {
      final value =
          barcode.rawValue;

      if (value != null &&
          value.trim().isNotEmpty) {
        _alreadyScanned = true;

        Navigator.pop(
          context,
          value.trim(),
        );

        return;
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final l10n =
        AppLocalizations.of(context);

    return Scaffold(
      backgroundColor:
          Colors.black,
      appBar: AppBar(
        backgroundColor:
            Colors.black,
        foregroundColor:
            Colors.white,
        title: Text(
          _t(
            l10n,
            'Scan Product Barcode',
            'Scan Barcode ya Bidhaa',
          ),
        ),
      ),
      body: Stack(
        fit:
            StackFit.expand,
        children: [
          MobileScanner(
            controller:
                _controller,
            onDetect:
                _handleDetection,
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
            bottom: 50,
            child: Text(
              _t(
                l10n,
                'Place the product barcode inside the box',
                'Weka barcode ya bidhaa ndani ya kisanduku',
              ),
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color:
                    Colors.white,
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfo
    extends StatelessWidget {
  final String label;
  final String value;

  const _SmallInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow
    extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color:
                  Colors.grey.shade700,
              fontSize: 14,
              fontWeight: bold
                  ? FontWeight.w700
                  : null,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize:
                bold ? 17 : 14,
            fontWeight:
                bold
                    ? FontWeight.bold
                    : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}