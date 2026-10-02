import 'package:flutter/material.dart';

import '../../../models/medicine_model.dart';
import '../../../repositories/medicine_repository.dart';
import '../../../core/localization/app_localizations.dart';

class EditMedicineScreen extends StatefulWidget {
  final String pharmacyId;
  final MedicineModel medicine;

  const EditMedicineScreen({
    super.key,
    required this.pharmacyId,
    required this.medicine,
  });

  @override
  State<EditMedicineScreen> createState() =>
      _EditMedicineScreenState();
}

class _EditMedicineScreenState
    extends State<EditMedicineScreen> {
  final MedicineRepository _medicineRepository =
      MedicineRepository();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _unitController;
  late final TextEditingController _quantityController;
  late final TextEditingController _buyingPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _batchNumberController;

  DateTime? _expiryDate;
  bool _saving = false;

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
  ];

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.medicine.name,
    );

    _categoryController = TextEditingController(
      text: widget.medicine.category,
    );

    _unitController = TextEditingController(
      text: widget.medicine.unit.trim().isEmpty
          ? 'pcs'
          : widget.medicine.unit.trim(),
    );

    _quantityController = TextEditingController(
      text: widget.medicine.quantity.toString(),
    );

    _buyingPriceController = TextEditingController(
      text: _formatNumber(widget.medicine.buyingPrice),
    );

    _sellingPriceController = TextEditingController(
      text: _formatNumber(widget.medicine.sellingPrice),
    );

    _barcodeController = TextEditingController(
      text: widget.medicine.barcode,
    );

    _batchNumberController = TextEditingController(
      text: widget.medicine.batchNumber,
    );

    _expiryDate = widget.medicine.expiryDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _quantityController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _barcodeController.dispose();
    _batchNumberController.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  String? _requiredValidator(
    BuildContext context,
    String? value,
    String englishFieldName,
    String swahiliFieldName,
  ) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.trim().isEmpty) {
      return l10n.isSwahili
          ? '$swahiliFieldName inahitajika.'
          : '$englishFieldName is required.';
    }

    return null;
  }

  String? _quantityValidator(
    BuildContext context,
    String? value,
  ) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.trim().isEmpty) {
      return l10n.quantityRequired;
    }

    final quantity = int.tryParse(value.trim());

    if (quantity == null) {
      return l10n.enterWholeNumber;
    }

    if (quantity < 0) {
      return l10n.quantityCannotBeNegative;
    }

    return null;
  }

  String? _priceValidator(
    BuildContext context,
    String? value,
    String englishFieldName,
    String swahiliFieldName,
  ) {
    final l10n = AppLocalizations.of(context);

    if (value == null || value.trim().isEmpty) {
      return l10n.isSwahili
          ? '$swahiliFieldName inahitajika.'
          : '$englishFieldName is required.';
    }

    final price = double.tryParse(value.trim());

    if (price == null) {
      return l10n.enterValidNumber;
    }

    if (price < 0) {
      return l10n.isSwahili
          ? '$swahiliFieldName haiwezi kuwa hasi.'
          : '$englishFieldName cannot be negative.';
    }

    return null;
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();

    final initialDate = _expiryDate ??
        now.add(
          const Duration(days: 365),
        );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
      helpText: AppLocalizations.of(context).selectExpiryDate,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _expiryDate = selectedDate;
    });
  }

  void _selectQuantityText() {
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
    );
  }

  Future<void> _clearExpiryDate() async {
    setState(() {
      _expiryDate = null;
    });
  }

  Future<void> _updateMedicine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final priceError = l10n.isSwahili
        ? 'Bei ya kuuza haiwezi kuwa chini ya bei ya kununua.'
        : 'Selling price cannot be lower than buying price.';
    final successMessage = l10n.isSwahili
        ? 'Dawa imesasishwa kwa mafanikio.'
        : 'Medicine updated successfully.';

    setState(() {
      _saving = true;
    });

    try {
      final quantity = int.parse(
        _quantityController.text.trim(),
      );

      final buyingPrice = double.parse(
        _buyingPriceController.text.trim(),
      );

      final sellingPrice = double.parse(
        _sellingPriceController.text.trim(),
      );

      if (sellingPrice < buyingPrice) {
        throw Exception(priceError);
      }

      final updatedMedicine = widget.medicine.copyWith(
        pharmacyId: widget.pharmacyId,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        unit: _unitController.text.trim(),
        quantity: quantity,
        buyingPrice: buyingPrice,
        sellingPrice: sellingPrice,
        barcode: _barcodeController.text.trim(),
        batchNumber: _batchNumberController.text.trim(),
        expiryDate: _expiryDate,
        updatedAt: DateTime.now(),
      );

      await _medicineRepository.updateMedicine(
        updatedMedicine,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _cleanErrorMessage(e),
          ),
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

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.replaceFirst(
        'Exception: ',
        '',
      );
    }

    return message;
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
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
          color: Theme.of(context)
              .colorScheme
              .primary,
          width: 2,
        ),
      ),
      filled: true,
    );
  }

  String _unitDisplay(String unit) {
    final value = unit.trim();

    if (_units.contains(value)) {
      return value;
    }

    return value.isEmpty ? 'pcs' : value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUnit = _unitDisplay(
      _unitController.text,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editMedicine),
      ),
      body: SafeArea(
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
              Container(
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
                        borderRadius:
                            BorderRadius.circular(14),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.isSwahili
                                ? 'Sasisha Dawa'
                                : 'Update Medicine',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.isSwahili
                                ? 'Sasisha taarifa za dawa, bei na stock.'
                                : 'Update medicine details, pricing and stock.',
                            style: const TextStyle(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  l10n.isSwahili ? 'Jina la Dawa' : 'Medicine Name',
                  Icons.medication_outlined,
                ),
                validator: (value) =>
                    _requiredValidator(
                    context,
                    value,
                    'Medicine name',
                    'Jina la dawa',
                  ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _categoryController,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  l10n.category,
                  Icons.category_outlined,
                ),
                validator: (value) =>
                    _requiredValidator(
                    context,
                    value,
                    'Category',
                    'Aina',
                  ),
              ),

              const SizedBox(height: 14),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          _units.contains(currentUnit)
                              ? currentUnit
                              : null,
                      decoration: _inputDecoration(
                        l10n.unit,
                        Icons.inventory_2_outlined,
                      ),
                      items: _units.map(
                        (unit) {
                          return DropdownMenuItem<String>(
                            value: unit,
                            child: Text(unit),
                          );
                        },
                      ).toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _unitController.text = value;
                        });
                      },
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return l10n.isSwahili
                              ? 'Kipimo kinahitajika.'
                              : 'Unit is required.';
                        }

                        return null;
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType:
                          TextInputType.number,
                      textInputAction:
                          TextInputAction.next,
                      onTap: _selectQuantityText,
                      decoration: _inputDecoration(
                        l10n.quantity,
                        Icons.numbers_rounded,
                      ).copyWith(
                        suffixText: currentUnit,
                      ),
                      validator: (value) =>
                          _quantityValidator(
                        context,
                        value,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller:
                          _buyingPriceController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction:
                          TextInputAction.next,
                      decoration: _inputDecoration(
                        l10n.buyingPrice,
                        Icons.shopping_cart_outlined,
                      ),
                      validator: (value) =>
                          _priceValidator(
                            context,
                            value,
                            'Buying price',
                            'Bei ya kununua',
                          ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: TextFormField(
                      controller:
                          _sellingPriceController,
                      keyboardType:
                          const TextInputType
                              .numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction:
                          TextInputAction.next,
                      decoration: _inputDecoration(
                        l10n.sellingPrice,
                        Icons.sell_outlined,
                      ),
                      validator: (value) =>
                          _priceValidator(
                            context,
                            value,
                            'Selling price',
                            'Bei ya kuuza',
                          ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                textInputAction:
                    TextInputAction.next,
                decoration: _inputDecoration(
                  l10n.barcode,
                  Icons.qr_code_2_rounded,
                  hint: l10n.isSwahili
                      ? 'Ingiza msimbo pau'
                      : 'Enter barcode',
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _batchNumberController,
                textInputAction:
                    TextInputAction.done,
                decoration: _inputDecoration(
                  l10n.batchNumber,
                  Icons.confirmation_number_outlined,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(14),
                      onTap: _selectExpiryDate,
                      child: InputDecorator(
                        decoration: _inputDecoration(
                          l10n.expiryDate,
                          Icons.event_outlined,
                        ),
                        child: Text(
                          _expiryDate == null
                              ? l10n.selectExpiryDate
                              : _formatDate(
                                  _expiryDate!,
                                ),
                          style: TextStyle(
                            color: _expiryDate == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_expiryDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: l10n.isSwahili
                          ? 'Futa tarehe ya mwisho wa matumizi'
                          : 'Clear expiry date',
                      onPressed: _clearExpiryDate,
                      icon: const Icon(
                        Icons.clear_rounded,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _saving ? null : _updateMedicine,
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
                        ? (l10n.isSwahili
                            ? 'Inasasisha...'
                            : 'Updating...')
                        : (l10n.isSwahili
                            ? 'Sasisha Dawa'
                            : 'Update Medicine'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}