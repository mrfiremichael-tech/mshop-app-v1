import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/customer_model.dart';
import '../../../repositories/customer_repository.dart';
import '../../../services/auth_service.dart';
import 'add_customer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({
    super.key,
  });

  @override
  State<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState
    extends State<CustomerListScreen> {
  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  final CustomerRepository _customerRepository =
      CustomerRepository();

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
        'Failed to load pharmacy information: $e',
      );
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery =
          _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _openAddCustomer() async {
    if (_pharmacyId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(
          pharmacyId: _pharmacyId!,
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(
    CustomerModel customer,
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
              'Delete Customer',
              'Futa Mteja',
            ),
          ),
          content: Text(
            _t(
              AppLocalizations.of(dialogContext),
              'Are you sure you want to delete "${customer.name}"?',
              'Una uhakika unataka kumfuta "${customer.name}"?',
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
      await _customerRepository.deleteCustomer(
        pharmacyId: _pharmacyId!,
        customerId: customer.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        _t(
          AppLocalizations.of(context),
          'Customer deleted successfully.',
          'Mteja amefutwa kwa mafanikio.',
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _t(
          AppLocalizations.of(context),
          'Failed to delete customer: ${_cleanError(e)}',
          'Imeshindikana kufuta mteja: ${_cleanError(e)}',
        ),
      );
    }
  }

  Future<void> _editCustomer(
    CustomerModel customer,
  ) async {
    if (!mounted) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(
          pharmacyId: _pharmacyId!,
          customer: customer,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  List<CustomerModel> _filterCustomers(
    List<CustomerModel> customers,
  ) {
    if (_searchQuery.isEmpty) {
      return customers;
    }

    return customers.where((customer) {
      return customer.name
              .toLowerCase()
              .contains(_searchQuery) ||
          customer.phone
              .toLowerCase()
              .contains(_searchQuery) ||
          customer.email
              .toLowerCase()
              .contains(_searchQuery) ||
          customer.address
              .toLowerCase()
              .contains(_searchQuery);
    }).toList();
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
          _t(l10n, 'Customers', 'Wateja'),
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
        onPressed: _openAddCustomer,
        icon: const Icon(
          Icons.person_add_alt_1_rounded,
        ),
        label: Text(
          _t(l10n, 'Add Customer', 'Ongeza Mteja'),
        ),
      ),
      body: _pharmacyId == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<List<CustomerModel>>(
              stream:
                  _customerRepository.watchCustomers(
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
                          'Failed to load customers.',
                          'Imeshindikana kupakia wateja.',
                        ),
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                final customers =
                    snapshot.data ?? [];

                final filteredCustomers =
                    _filterCustomers(
                  customers,
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
                                        'Search customer, phone or email...',
                                        'Tafuta mteja, simu au barua pepe...',
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
                              _SummaryCard(
                                count:
                                    customers.length,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (filteredCustomers
                          .isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child:
                              _EmptyCustomers(
                            hasSearch:
                                _searchQuery
                                    .isNotEmpty,
                            onAdd:
                                _openAddCustomer,
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
                                filteredCustomers
                                    .length,
                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              final customer =
                                  filteredCustomers[
                                      index];

                              return _CustomerCard(
                                customer:
                                    customer,
                                onEdit: () =>
                                    _editCustomer(
                                  customer,
                                ),
                                onDelete: () =>
                                    _deleteCustomer(
                                  customer,
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
  final int count;

  const _SummaryCard({
    required this.count,
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
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(16),
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
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(13),
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(
                    alpha: 0.12,
                  ),
            ),
            child: Icon(
              Icons.people_alt_rounded,
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
                  _t(l10n, 'Total Customers', 'Jumla ya Wateja'),
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
                  count.toString(),
                  style:
                      const TextStyle(
                    fontSize: 20,
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

class _CustomerCard
    extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
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
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(
                          alpha: 0.1,
                        ),
                  ),
                  child: Icon(
                    Icons.person_rounded,
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
                        customer.name,
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
                        customer.phone
                                .isEmpty
                            ? _t(l10n, 'No phone number', 'Hakuna namba ya simu')
                            : customer.phone,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
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
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_rounded),
                          const SizedBox(width: 10),
                          Text(_t(l10n, 'Edit', 'Hariri')),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Text(_t(l10n, 'Delete', 'Futa')),
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
            if (customer.email.isNotEmpty)
              _InfoRow(
                icon:
                    Icons.email_outlined,
                value:
                    customer.email,
              ),
            if (customer.address.isNotEmpty)
              _InfoRow(
                icon:
                    Icons.location_on_outlined,
                value:
                    customer.address,
              ),
            if (customer.notes.isNotEmpty)
              _InfoRow(
                icon:
                    Icons.notes_rounded,
                value:
                    customer.notes,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow
    extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.grey.shade600,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCustomers
    extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onAdd;

  const _EmptyCustomers({
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
                  ? Icons
                      .search_off_rounded
                  : Icons
                      .people_outline_rounded,
              size: 64,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              hasSearch
                  ? _t(l10n, 'No customers found', 'Hakuna wateja waliopatikana')
                  : _t(l10n, 'No customers yet', 'Bado hakuna wateja'),
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
                      'Add your first customer to start keeping customer records.',
                      'Ongeza mteja wako wa kwanza kuanza kuhifadhi kumbukumbu za wateja.',
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
                  Icons
                      .person_add_alt_1_rounded,
                ),
                label: Text(
                  _t(l10n, 'Add Customer', 'Ongeza Mteja'),
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
              Icons
                  .error_outline_rounded,
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