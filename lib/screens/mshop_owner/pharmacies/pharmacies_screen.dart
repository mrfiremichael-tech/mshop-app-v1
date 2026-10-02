import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../services/mshop_owner_notification_service.dart';

class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  State<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final MshopOwnerNotificationService
      _notificationService =
      MshopOwnerNotificationService.instance;

  bool _isLoading = true;
  String _searchText = '';
  List<_PharmacyItem> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadPharmacies();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }

    setState(() {
      _searchText =
          _searchController.text.trim().toLowerCase();
    });
  }

  Future<void> _loadPharmacies() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final pharmacySnapshot = await _firestore
          .collection('pharmacies')
          .orderBy('name')
          .get();

      final userSnapshot =
          await _firestore.collection('users').get();

      final ownersById =
          <String, Map<String, dynamic>>{};

      for (final document in userSnapshot.docs) {
        final data = document.data();
        final role = data['role']?.toString();

        if (role == 'pharmacy_owner') {
          ownersById[document.id] = data;

          final uid = data['uid']?.toString();

          if (uid != null && uid.isNotEmpty) {
            ownersById[uid] = data;
          }
        }
      }

      final items = <_PharmacyItem>[];

      for (final document in pharmacySnapshot.docs) {
        final data = document.data();

        final pharmacyId = document.id;

        final ownerId =
            data['ownerId']?.toString() ??
                data['ownerUID']?.toString() ??
                '';

        final ownerData = ownersById[ownerId];

        items.add(
          _PharmacyItem(
            id: pharmacyId,
            name:
                data['name']?.toString() ??
                    'Unnamed Pharmacy',
            email:
                data['email']?.toString() ??
                    ownerData?['email']?.toString() ??
                    '',
            phone:
                data['phone']?.toString() ??
                    ownerData?['phone']?.toString() ??
                    '',
            ownerName:
                ownerData?['fullName']?.toString() ??
                    ownerData?['name']?.toString() ??
                    'Unknown owner',
            ownerId: ownerId,
            status:
                data['status']?.toString() ??
                    'active',
          ),
        );
      }

      items.sort(
        (a, b) => a.name
            .toLowerCase()
            .compareTo(
              b.name.toLowerCase(),
            ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pharmacies = items;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Imeshindikana kupakia pharmacies. Jaribu tena.',
      );
    }
  }

  List<_PharmacyItem> get _filteredPharmacies {
    if (_searchText.isEmpty) {
      return _pharmacies;
    }

    return _pharmacies.where((pharmacy) {
      final searchable = [
        pharmacy.name,
        pharmacy.ownerName,
        pharmacy.email,
        pharmacy.phone,
      ].join(' ').toLowerCase();

      return searchable.contains(_searchText);
    }).toList();
  }

  int get _activeCount =>
      _pharmacies
          .where(
            (item) => item.status == 'active',
          )
          .length;

  int get _inactiveCount =>
      _pharmacies
          .where(
            (item) => item.status != 'active',
          )
          .length;

  Future<void> _toggleStatus(
    _PharmacyItem pharmacy,
  ) async {
    final newStatus =
        pharmacy.status == 'active'
            ? 'inactive'
            : 'active';

    try {
      await _firestore
          .collection('pharmacies')
          .doc(pharmacy.id)
          .update({
        'status': newStatus,
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      // Notification is secondary.
      // Even if notification fails,
      // pharmacy status remains successfully changed.
      try {
        await _notificationService
            .pharmacyStatusChanged(
          pharmacyId: pharmacy.id,
          pharmacyName: pharmacy.name,
          newStatus: newStatus,
        );
      } catch (_) {
        // Do not fail the pharmacy status update
        // because of notification failure.
      }

      if (!mounted) {
        return;
      }

      setState(() {
        final index = _pharmacies.indexWhere(
          (item) => item.id == pharmacy.id,
        );

        if (index != -1) {
          _pharmacies[index] =
              pharmacy.copyWith(
            status: newStatus,
          );
        }
      });

      _showMessage(
        newStatus == 'active'
            ? '${pharmacy.name} imewezeshwa.'
            : '${pharmacy.name} imezuiwa.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Imeshindikana kubadilisha status ya pharmacy.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  void _openDetails(
    _PharmacyItem pharmacy,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme =
            Theme.of(context);

        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              24,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  pharmacy.name,
                  style:
                      const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Owner',
                  value:
                      pharmacy.ownerName,
                  icon: Icons
                      .person_outline_rounded,
                ),
                _DetailRow(
                  label: 'Email',
                  value:
                      pharmacy.email.isEmpty
                          ? '—'
                          : pharmacy.email,
                  icon: Icons
                      .email_outlined,
                ),
                _DetailRow(
                  label: 'Phone',
                  value:
                      pharmacy.phone.isEmpty
                          ? '—'
                          : pharmacy.phone,
                  icon: Icons
                      .phone_outlined,
                ),
                _DetailRow(
                  label: 'Status',
                  value:
                      pharmacy.status ==
                              'active'
                          ? 'Active'
                          : 'Inactive',
                  icon: pharmacy.status ==
                          'active'
                      ? Icons
                          .check_circle_outline_rounded
                      : Icons
                          .pause_circle_outline_rounded,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child:
                      FilledButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop();

                      _toggleStatus(
                        pharmacy,
                      );
                    },
                    icon: Icon(
                      pharmacy.status ==
                              'active'
                          ? Icons
                              .pause_circle_outline_rounded
                          : Icons
                              .play_circle_outline_rounded,
                    ),
                    label: Text(
                      pharmacy.status ==
                              'active'
                          ? 'Deactivate Pharmacy'
                          : 'Activate Pharmacy',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'M-Shop Owner anaona taarifa za pharmacy bila kuingia kwenye data za mauzo, stock au biashara.',
                  style: theme
                      .textTheme.bodySmall
                      ?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        Theme.of(context);

    final filtered =
        _filteredPharmacies;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Pharmacies'),
      ),
      body: RefreshIndicator(
        onRefresh:
            _loadPharmacies,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            28,
          ),
          children: [
            _buildSummary(theme),
            const SizedBox(height: 16),
            TextField(
              controller:
                  _searchController,
              decoration:
                  InputDecoration(
                hintText:
                    'Search pharmacy, owner, email or phone...',
                prefixIcon:
                    const Icon(
                  Icons.search_rounded,
                ),
                suffixIcon:
                    _searchText.isEmpty
                        ? null
                        : IconButton(
                            tooltip:
                                'Clear',
                            onPressed:
                                _searchController
                                    .clear,
                            icon:
                                const Icon(
                              Icons
                                  .clear_rounded,
                            ),
                          ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding:
                    EdgeInsets.only(
                  top: 80,
                ),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else if (filtered.isEmpty)
              _buildEmptyState(theme)
            else
              ...filtered.map(
                (pharmacy) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child:
                      _buildPharmacyCard(
                    theme,
                    pharmacy,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total',
            value:
                _pharmacies.length
                    .toString(),
            icon: Icons
                .local_pharmacy_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Active',
            value:
                _activeCount.toString(),
            icon: Icons
                .check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: 'Inactive',
            value:
                _inactiveCount
                    .toString(),
            icon: Icons
                .pause_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildPharmacyCard(
    ThemeData theme,
    _PharmacyItem pharmacy,
  ) {
    final isActive =
        pharmacy.status == 'active';

    return Card(
      elevation: 0,
      clipBehavior:
          Clip.antiAlias,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
        side: BorderSide(
          color: theme
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: () =>
            _openDetails(
          pharmacy,
        ),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration:
                    BoxDecoration(
                  color: theme
                      .colorScheme
                      .primaryContainer,
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                ),
                child: Icon(
                  Icons
                      .local_pharmacy_outlined,
                  color: theme
                      .colorScheme
                      .primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      pharmacy.name,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                        height: 6),
                    Text(
                      'Owner: ${pharmacy.ownerName}',
                      style: TextStyle(
                        color: theme
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    if (pharmacy
                        .email
                        .isNotEmpty) ...[
                      const SizedBox(
                          height: 3),
                      Text(
                        pharmacy.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (pharmacy
                        .phone
                        .isNotEmpty) ...[
                      const SizedBox(
                          height: 3),
                      Text(
                        pharmacy.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(
                        height: 10),
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color: isActive
                            ? Colors.green
                                .withValues(
                                alpha: 0.12,
                              )
                            : Colors.orange
                                .withValues(
                                alpha: 0.12,
                              ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          999,
                        ),
                      ),
                      child: Text(
                        isActive
                            ? 'Active'
                            : 'Inactive',
                        style:
                            TextStyle(
                          color: isActive
                              ? Colors.green
                                  .shade700
                              : Colors.orange
                                  .shade800,
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<
                  String>(
                onSelected:
                    (value) {
                  if (value ==
                      'toggle') {
                    _toggleStatus(
                      pharmacy,
                    );
                  } else if (value ==
                      'details') {
                    _openDetails(
                      pharmacy,
                    );
                  }
                },
                itemBuilder:
                    (context) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Text(
                      'View details',
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(
                      isActive
                          ? 'Deactivate'
                          : 'Activate',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        top: 70,
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .local_pharmacy_outlined,
            size: 52,
            color: theme
                .colorScheme
                .onSurfaceVariant,
          ),
          const SizedBox(
              height: 12),
          Text(
            _searchText.isEmpty
                ? 'Hakuna pharmacy iliyosajiliwa bado.'
                : 'Hakuna pharmacy inayolingana na utafutaji.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: theme
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyItem {
  final String id;
  final String name;
  final String ownerName;
  final String ownerId;
  final String email;
  final String phone;
  final String status;

  const _PharmacyItem({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.ownerId,
    required this.email,
    required this.phone,
    required this.status,
  });

  _PharmacyItem copyWith({
    String? status,
  }) {
    return _PharmacyItem(
      id: id,
      name: name,
      ownerName: ownerName,
      ownerId: ownerId,
      email: email,
      phone: phone,
      status: status ?? this.status,
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
  Widget build(
    BuildContext context,
  ) {
    final theme =
        Theme.of(context);

    return Card(
      elevation: 0,
      color: theme
          .colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha: 0.45,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color:
                  theme.colorScheme.primary,
            ),
            const SizedBox(
                height: 12),
            Text(
              value,
              style:
                  const TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(
                height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow
    extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
          const SizedBox(
              width: 12),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}