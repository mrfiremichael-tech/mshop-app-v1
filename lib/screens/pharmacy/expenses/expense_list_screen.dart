import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/expense_model.dart';
import '../../../repositories/expense_repository.dart';
import '../../../services/auth_service.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({
    super.key,
  });

  @override
  State<ExpenseListScreen> createState() =>
      _ExpenseListScreenState();
}

class _ExpenseListScreenState
    extends State<ExpenseListScreen> {
  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  final ExpenseRepository _expenseRepository =
      ExpenseRepository();

  final AuthService _authService = AuthService();

  final TextEditingController _searchController =
      TextEditingController();

  String? _pharmacyId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _loadPharmacy();

    _searchController.addListener(
      _onSearchChanged,
    );
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  Future<void> _loadPharmacy() async {
    try {
      final pharmacyId =
          await _authService.getCurrentPharmacyId();

      if (!mounted) {
        return;
      }

      setState(() {
        _pharmacyId = pharmacyId;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _t(
          AppLocalizations.of(context),
          'Failed to load pharmacy information: ${_cleanError(e)}',
          'Imeshindikana kupakia taarifa za famasi: ${_cleanError(e)}',
        ),
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery =
          _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _openAddExpense() async {
    if (_pharmacyId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          pharmacyId: _pharmacyId!,
        ),
      ),
    );
  }

  Future<void> _editExpense(
    ExpenseModel expense,
  ) async {
    if (_pharmacyId == null) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          pharmacyId: _pharmacyId!,
          expense: expense,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteExpense(
    ExpenseModel expense,
  ) async {
    if (_pharmacyId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            _t(
              AppLocalizations.of(dialogContext),
              'Delete Expense',
              'Futa Gharama',
            ),
          ),
          content: Text(
            _t(
              AppLocalizations.of(dialogContext),
              'Are you sure you want to delete "${expense.description}"?',
              'Una uhakika unataka kufuta "${expense.description}"?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                _t(
                  AppLocalizations.of(dialogContext),
                  'Cancel',
                  'Ghairi',
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
                _t(
                  AppLocalizations.of(dialogContext),
                  'Delete',
                  'Futa',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _expenseRepository.deleteExpense(
        pharmacyId: _pharmacyId!,
        expenseId: expense.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _t(
          AppLocalizations.of(context),
          'Expense deleted successfully.',
          'Gharama imefutwa kwa mafanikio.',
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _t(
          AppLocalizations.of(context),
          'Failed to delete expense: ${_cleanError(e)}',
          'Imeshindikana kufuta gharama: ${_cleanError(e)}',
        ),
      );
    }
  }

  List<ExpenseModel> _filterExpenses(
    List<ExpenseModel> expenses,
  ) {
    if (_searchQuery.isEmpty) {
      return expenses;
    }

    return expenses.where((expense) {
      return expense.category
              .toLowerCase()
              .contains(_searchQuery) ||
          expense.description
              .toLowerCase()
              .contains(_searchQuery) ||
          expense.paymentMethod
              .toLowerCase()
              .contains(_searchQuery) ||
          expense.reference
              .toLowerCase()
              .contains(_searchQuery);
    }).toList();
  }

  double _totalAmount(
    List<ExpenseModel> expenses,
  ) {
    return expenses.fold<double>(
      0,
      (total, expense) =>
          total + expense.amount,
    );
  }

  String _formatCurrency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t(l10n, 'Expenses', 'Gharama'),
        ),
        actions: [
          IconButton(
            tooltip: _t(l10n, 'Refresh', 'Onyesha upya'),
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openAddExpense,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: Text(
          _t(l10n, 'Add Expense', 'Ongeza Gharama'),
        ),
      ),
      body: _pharmacyId == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<List<ExpenseModel>>(
              stream:
                  _expenseRepository.watchExpenses(
                _pharmacyId!,
              ),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return _ErrorState(
                    message:
                        _t(
                          l10n,
                          'Failed to load expenses.',
                          'Imeshindikana kupakia gharama.',
                        ),
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                final expenses =
                    snapshot.data ?? [];

                final filteredExpenses =
                    _filterExpenses(
                  expenses,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: CustomScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            8,
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller:
                                    _searchController,
                                decoration:
                                    InputDecoration(
                                  hintText:
                                      _t(
                                        l10n,
                                        'Search category, description or payment method...',
                                        'Tafuta aina, maelezo au njia ya malipo...',
                                      ),
                                  prefixIcon:
                                      const Icon(
                                    Icons
                                        .search_rounded,
                                  ),
                                  suffixIcon:
                                      _searchQuery
                                              .isNotEmpty
                                          ? IconButton(
                                              onPressed: () {
                                                _searchController
                                                    .clear();
                                              },
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .clear_rounded,
                                              ),
                                            )
                                          : null,
                                  border:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                      14,
                                    ),
                                  ),
                                  filled: true,
                                ),
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        _SummaryCard(
                                      title:
                                          _t(l10n, 'Expenses', 'Gharama'),
                                      value:
                                          expenses
                                              .length
                                              .toString(),
                                      icon: Icons
                                          .receipt_long_rounded,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child:
                                        _SummaryCard(
                                      title:
                                          _t(l10n, 'Total Amount', 'Jumla ya Kiasi'),
                                      value:
                                          _formatCurrency(
                                        _totalAmount(
                                          expenses,
                                        ),
                                      ),
                                      icon: Icons
                                          .payments_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (filteredExpenses
                          .isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child:
                              _EmptyExpenses(
                            hasSearch:
                                _searchQuery
                                    .isNotEmpty,
                            onAdd:
                                _openAddExpense,
                          ),
                        )
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            100,
                          ),
                          sliver:
                              SliverList.builder(
                            itemCount:
                                filteredExpenses
                                    .length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final expense =
                                  filteredExpenses[
                                      index];

                              return _ExpenseCard(
                                expense:
                                    expense,
                                onEdit: () =>
                                    _editExpense(
                                  expense,
                                ),
                                onDelete: () =>
                                    _deleteExpense(
                                  expense,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _SummaryCard
    extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
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
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(12),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(
                    alpha: 0.12,
                  ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
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
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
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

class _ExpenseCard
    extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatCurrency(double value) {
    return 'TSh ${value.toStringAsFixed(0)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 1,
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                    color: Colors
                        .orange
                        .withValues(
                      alpha: 0.1,
                    ),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.orange,
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
                        expense.description
                                .isEmpty
                            ? _t(l10n, 'Expense', 'Gharama')
                            : expense.description,
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
                        expense.category
                                .isEmpty
                            ? _t(l10n, 'No category', 'Hakuna aina')
                            : expense.category,
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value ==
                        'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded),
                          const SizedBox(width: 10),
                          Text(
                            _t(l10n, 'Edit', 'Hariri'),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _t(l10n, 'Delete', 'Futa'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            _InfoRow(
              label: _t(l10n, 'Amount', 'Kiasi'),
              value:
                  _formatCurrency(
                expense.amount,
              ),
              valueColor: Colors.orange,
            ),
            _InfoRow(
              label: _t(l10n, 'Payment', 'Malipo'),
              value:
                  expense.paymentMethod
                          .isEmpty
                      ? '-'
                      : expense.paymentMethod,
            ),
            _InfoRow(
              label: _t(l10n, 'Date', 'Tarehe'),
              value:
                  _formatDate(
                expense.expenseDate,
              ),
            ),
            if (expense.reference
                .isNotEmpty)
              _InfoRow(
                label: _t(l10n, 'Reference', 'Kumbukumbu'),
                value:
                    expense.reference,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w600,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyExpenses
    extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _EmptyExpenses({
    required this.hasSearch,
    required this.onAdd,
  });

  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off_rounded
                  : Icons.receipt_long_outlined,
              size: 64,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              hasSearch
                  ? _t(l10n, 'No expenses found', 'Hakuna gharama zilizopatikana')
                  : _t(l10n, 'No expenses yet', 'Bado hakuna gharama'),
              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              hasSearch
                  ? _t(l10n, 'Try a different search.', 'Jaribu utafutaji mwingine.')
                  : _t(
                      l10n,
                      'Add your first expense to start tracking pharmacy costs.',
                      'Ongeza gharama yako ya kwanza kuanza kufuatilia gharama za famasi.',
                    ),
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(
                height: 20,
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: Text(
                  _t(l10n, 'Add Expense', 'Ongeza Gharama'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState
    extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton(
              onPressed: onRetry,
              child: Text(
                _t(
                  AppLocalizations.of(context),
                  'Retry',
                  'Jaribu tena',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}