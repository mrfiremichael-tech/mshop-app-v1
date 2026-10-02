import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../models/medicine_model.dart';
import '../../../models/purchase_model.dart';
import '../../../models/supplier_model.dart';
import '../../../repositories/medicine_repository.dart';
import '../../../repositories/supplier_repository.dart';
import '../../../services/notifications/notification_service.dart';

class AddPurchaseScreen extends StatefulWidget {
  final String pharmacyId;

  const AddPurchaseScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  final MedicineRepository _medicineRepository = MedicineRepository();
  final SupplierRepository _supplierRepository = SupplierRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final NotificationService _notificationService =
      NotificationService.instance;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityController =
      TextEditingController();

  final TextEditingController _unitCostController =
      TextEditingController();

  MedicineModel? _selectedMedicine;
  SupplierModel? _selectedSupplier;

  List<MedicineModel> _medicines = [];
  List<SupplierModel> _suppliers = [];

  bool _loadingData = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _quantityController.addListener(_updateTotal);
  }

  @override
  void dispose() {
    _quantityController
      ..removeListener(_updateTotal)
      ..dispose();

    _unitCostController.dispose();

    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _medicineRepository.getMedicines(widget.pharmacyId),
        _supplierRepository.getSuppliers(widget.pharmacyId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _medicines = results[0] as List<MedicineModel>;
        _suppliers = results[1] as List<SupplierModel>;
        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingData = false;
      });

      _showMessage(
        'Failed to load purchase data: ${_cleanError(e)}',
      );
    }
  }

  void _updateTotal() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  void _onMedicineChanged(MedicineModel? medicine) {
    setState(() {
      _selectedMedicine = medicine;

      if (medicine != null) {
        _unitCostController.text =
            _formatNumber(medicine.buyingPrice);
      } else {
        _unitCostController.clear();
      }
    });
  }

  double get _unitCost {
    return double.tryParse(
          _unitCostController.text.trim(),
        ) ??
        0;
  }

  int get _quantity {
    return int.tryParse(
          _quantityController.text.trim(),
        ) ??
        0;
  }

  double get _totalCost {
    return _quantity * _unitCost;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  String? _quantityValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required.';
    }

    final quantity = int.tryParse(value.trim());

    if (quantity == null) {
      return 'Quantity must be a whole number.';
    }

    if (quantity <= 0) {
      return 'Quantity must be greater than 0.';
    }

    return null;
  }

  String? _supplierValidator(SupplierModel? value) {
    if (value == null) {
      return 'Please select a supplier.';
    }

    return null;
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }

    return message;
  }

  Future<void> _savePurchase() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMedicine == null) {
      _showMessage('Please select a medicine.');
      return;
    }

    if (_selectedSupplier == null) {
      _showMessage('Please select a supplier.');
      return;
    }

    if (_unitCost <= 0) {
      _showMessage('Buying price must be greater than 0.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showMessage('You must be logged in to record stock.');
      return;
    }

    setState(() {
      _saving = true;
    });

    final medicine = _selectedMedicine!;
    final supplier = _selectedSupplier!;
    final quantity = _quantity;

    String? purchaseId;
    double? savedTotalCost;

    try {
      final purchaseRef =
          _firestore.collection('purchases').doc();

      final medicineRef =
          _firestore.collection('medicines').doc(medicine.id);

      final stockRecordRef = _firestore
          .collection('pharmacies')
          .doc(widget.pharmacyId)
          .collection('stock_records')
          .doc();

      final addedByName =
          (currentUser.displayName?.trim().isNotEmpty ?? false)
              ? currentUser.displayName!.trim()
              : (currentUser.email?.trim().isNotEmpty ?? false)
                  ? currentUser.email!.trim()
                  : 'Unknown User';

      await _firestore.runTransaction(
        (transaction) async {
          final medicineSnapshot =
              await transaction.get(medicineRef);

          if (!medicineSnapshot.exists) {
            throw Exception(
              'Medicine no longer exists.',
            );
          }

          final medicineData = medicineSnapshot.data();

          if (medicineData == null) {
            throw Exception(
              'Medicine data could not be read.',
            );
          }

          final medicinePharmacyId =
              medicineData['pharmacyId']?.toString();

          if (medicinePharmacyId != widget.pharmacyId) {
            throw Exception(
              'This medicine does not belong to this pharmacy.',
            );
          }

          final currentQuantity =
              _toInt(medicineData['quantity']);

          final currentBuyingPrice =
              _toDouble(medicineData['buyingPrice']);

          final actualUnitCost =
              currentBuyingPrice > 0
                  ? currentBuyingPrice
                  : _unitCost;

          final actualTotalCost =
              quantity * actualUnitCost;

          final newQuantity =
              currentQuantity + quantity;

          final now = Timestamp.now();

          final batchNumber =
              medicineData['batchNumber']?.toString() ?? '';

          final expiryDateValue =
              medicineData['expiryDate'];

          transaction.update(
            medicineRef,
            {
              'quantity': newQuantity,
              'buyingPrice': actualUnitCost,
              'updatedAt': now,
            },
          );

          final purchase = PurchaseModel(
            id: purchaseRef.id,
            pharmacyId: widget.pharmacyId,
            medicineId: medicine.id,
            medicineName: medicine.name,
            supplierId: supplier.id,
            supplierName: supplier.name,
            quantity: quantity,
            unitCost: actualUnitCost,
            totalCost: actualTotalCost,
            createdAt: now.toDate(),
            updatedAt: now.toDate(),
          );

          transaction.set(
            purchaseRef,
            purchase.toFirestore(),
          );

          transaction.set(
            stockRecordRef,
            {
              'pharmacyId': widget.pharmacyId,
              'medicineId': medicine.id,
              'medicineName': medicine.name,
              'supplierId': supplier.id,
              'supplierName': supplier.name,
              'quantity': quantity,
              'unitCost': actualUnitCost,
              'totalCost': actualTotalCost,
              'stockDate': now,
              'addedByUid': currentUser.uid,
              'addedByName': addedByName,
              'batchNumber': batchNumber,
              'expiryDate': expiryDateValue,
              'createdAt': now,
            },
          );

          purchaseId = purchaseRef.id;
          savedTotalCost = actualTotalCost;
        },
      );

      // ============================================================
      // OWNER NOTIFICATION - PURCHASE SUCCESS
      // ============================================================
      try {
        await _notificationService.createOwnerNotification(
          pharmacyId: widget.pharmacyId,
          type: 'staff_purchase',
          title: 'Staff completed a purchase',
          message:
              '$addedByName completed a purchase of $quantity unit(s) of ${medicine.name} from ${supplier.name}. Total cost: ${_formatCurrency(savedTotalCost ?? _totalCost)}.',
          itemName: medicine.name,
          status: 'success',
          relatedId: purchaseId,
        );
      } catch (_) {
        // Notification failure must not undo the successful purchase.
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Purchase saved and stock record created successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      // ============================================================
      // OWNER NOTIFICATION - PURCHASE FAILED
      // ============================================================
      try {
        final staffName =
            (currentUser.displayName?.trim().isNotEmpty ?? false)
                ? currentUser.displayName!.trim()
                : (currentUser.email?.trim().isNotEmpty ?? false)
                    ? currentUser.email!.trim()
                    : 'Staff';

        await _notificationService.createOwnerNotification(
          pharmacyId: widget.pharmacyId,
          type: 'staff_purchase',
          title: 'Staff purchase failed',
          message:
              '$staffName failed to complete a purchase of ${medicine.name}. Error: ${_cleanError(e)}',
          itemName: medicine.name,
          status: 'failed',
          relatedId: null,
        );
      } catch (_) {
        // Keep original purchase error.
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        'Failed to save purchase: ${_cleanError(e)}',
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Purchase'),
      ),
      body: _loadingData
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    32,
                  ),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildMedicineSelector(),
                    if (_selectedMedicine != null) ...[
                      const SizedBox(height: 14),
                      _buildMedicineInfo(),
                    ],
                    const SizedBox(height: 14),
                    _buildSupplierSelector(),
                    const SizedBox(height: 14),
                    _buildQuantityField(),
                    const SizedBox(height: 14),
                    _buildUnitCostField(),
                    const SizedBox(height: 20),
                    _buildTotalCard(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed:
                            _saving ? null : _savePurchase,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.save_rounded,
                              ),
                        label: Text(
                          _saving
                              ? 'Saving...'
                              : 'Save Purchase',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.add_shopping_cart_rounded,
              color:
                  Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase Stock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Add purchased medicines and increase stock automatically.',
                  style: TextStyle(
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

  Widget _buildMedicineSelector() {
    return DropdownButtonFormField<MedicineModel>(
      initialValue: _selectedMedicine,
      isExpanded: true,
      decoration: _inputDecoration(
        'Medicine',
        Icons.medication_outlined,
      ),
      items: _medicines.map(
        (medicine) {
          return DropdownMenuItem<MedicineModel>(
            value: medicine,
            child: Text(
              medicine.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged:
          _saving ? null : _onMedicineChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select a medicine.';
        }

        return null;
      },
    );
  }

  Widget _buildMedicineInfo() {
    final medicine = _selectedMedicine!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SmallInfo(
              label: 'Current Stock',
              value:
                  '${medicine.quantity} ${medicine.unit}',
            ),
          ),
          Expanded(
            child: _SmallInfo(
              label: 'Buying Price',
              value:
                  _formatCurrency(medicine.buyingPrice),
            ),
          ),
          Expanded(
            child: _SmallInfo(
              label: 'New Stock',
              value:
                  '${medicine.quantity + _quantity} ${medicine.unit}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierSelector() {
    return DropdownButtonFormField<SupplierModel>(
      initialValue: _selectedSupplier,
      isExpanded: true,
      decoration: _inputDecoration(
        'Supplier',
        Icons.local_shipping_outlined,
      ),
      items: _suppliers.map(
        (supplier) {
          return DropdownMenuItem<SupplierModel>(
            value: supplier,
            child: Text(
              supplier.name,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: _saving
          ? null
          : (supplier) {
              setState(() {
                _selectedSupplier = supplier;
              });
            },
      validator: _supplierValidator,
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(
        'Quantity',
        Icons.numbers_rounded,
        hint: 'Enter quantity',
      ),
      validator: _quantityValidator,
    );
  }

  Widget _buildUnitCostField() {
    return TextFormField(
      controller: _unitCostController,
      readOnly: true,
      decoration: _inputDecoration(
        'Buying Price',
        Icons.shopping_cart_outlined,
        hint: 'Automatic',
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context)
            .colorScheme
            .primary
            .withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.payments_rounded,
              color:
                  Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Purchase Cost',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(_totalCost),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallInfo extends StatelessWidget {
  final String label;
  final String value;

  const _SmallInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}