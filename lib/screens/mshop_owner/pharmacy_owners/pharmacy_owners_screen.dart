import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PharmacyOwnersScreen extends StatefulWidget {
  const PharmacyOwnersScreen({super.key});

  @override
  State<PharmacyOwnersScreen> createState() => _PharmacyOwnersScreenState();
}

class _PharmacyOwnersScreenState extends State<PharmacyOwnersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  bool _matchesSearch({
    required Map<String, dynamic> owner,
    required Map<String, dynamic>? pharmacy,
  }) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final values = <String>[
      owner['fullName']?.toString() ?? '',
      owner['email']?.toString() ?? '',
      owner['phone']?.toString() ?? '',
      owner['id']?.toString() ?? '',
      owner['uid']?.toString() ?? '',
      pharmacy?['name']?.toString() ?? '',
      pharmacy?['id']?.toString() ?? '',
    ];

    return values.any(
      (value) => value.toLowerCase().contains(_searchQuery),
    );
  }

  String _ownerName(Map<String, dynamic> owner) {
    final fullName = owner['fullName']?.toString().trim();

    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final email = owner['email']?.toString().trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Unknown Owner';
  }

  String _ownerEmail(Map<String, dynamic> owner) {
    final email = owner['email']?.toString().trim();

    if (email == null || email.isEmpty) {
      return '—';
    }

    return email;
  }

  String _ownerPhone(Map<String, dynamic> owner) {
    final phone = owner['phone']?.toString().trim();

    if (phone == null || phone.isEmpty) {
      return '—';
    }

    return phone;
  }

  String _ownerStatus(Map<String, dynamic> owner) {
    return owner['status']?.toString() == 'inactive'
        ? 'inactive'
        : 'active';
  }

  Future<void> _setOwnerStatus({
    required String userId,
    required String status,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'status': status,
      });

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              status == 'active'
                  ? 'Pharmacy Owner activated successfully.'
                  : 'Pharmacy Owner deactivated successfully.',
            ),
          ),
        );

      setState(() {});
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update owner status: ${e.message ?? e.code}',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Failed to update owner status.'),
          ),
        );
    }
  }

  Future<List<Map<String, dynamic>>> _loadOwners() async {
    final ownerSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'pharmacy_owner')
        .get();

    final pharmacySnapshot =
        await _firestore.collection('pharmacies').get();

    final pharmaciesByOwnerId = <String, Map<String, dynamic>>{};

    for (final doc in pharmacySnapshot.docs) {
      final data = doc.data();

      final ownerId = data['ownerId']?.toString();

      if (ownerId != null && ownerId.isNotEmpty) {
        pharmaciesByOwnerId[ownerId] = {
          ...data,
          'id': data['id']?.toString() ?? doc.id,
          '_documentId': doc.id,
        };
      }
    }

    final owners = <Map<String, dynamic>>[];

    for (final doc in ownerSnapshot.docs) {
      final data = doc.data();

      final owner = <String, dynamic>{
        ...data,
        'id': data['id']?.toString() ?? doc.id,
        '_documentId': doc.id,
      };

      final ownerId = doc.id;

      owner['_pharmacy'] = pharmaciesByOwnerId[ownerId];

      owners.add(owner);
    }

    owners.sort(
      (a, b) => _ownerName(a)
          .toLowerCase()
          .compareTo(_ownerName(b).toLowerCase()),
    );

    return owners;
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(
      const Duration(milliseconds: 300),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Owners'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadOwners(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(
                context,
                'Failed to load pharmacy owners.',
              );
            }

            final owners = snapshot.data ?? <Map<String, dynamic>>[];

            final filteredOwners = owners.where((owner) {
              final pharmacy =
                  owner['_pharmacy'] as Map<String, dynamic>?;

              return _matchesSearch(
                owner: owner,
                pharmacy: pharmacy,
              );
            }).toList();

            final activeCount = owners.where(
              (owner) => _ownerStatus(owner) == 'active',
            ).length;

            final inactiveCount = owners.length - activeCount;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                children: [
                  _buildSummary(
                    context,
                    total: owners.length,
                    active: activeCount,
                    inactive: inactiveCount,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search owner, pharmacy, phone or email...',
                      prefixIcon:
                          const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed:
                                  _searchController.clear,
                              icon:
                                  const Icon(Icons.clear_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (filteredOwners.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...filteredOwners.map(
                      (owner) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 12),
                        child: _buildOwnerCard(
                          context,
                          owner,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context, {
    required int total,
    required int active,
    required int inactive,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        final cards = [
          _SummaryCard(
            title: 'Total',
            value: total.toString(),
            icon: Icons.people_alt_outlined,
          ),
          _SummaryCard(
            title: 'Active',
            value: active.toString(),
            icon: Icons.check_circle_outline_rounded,
          ),
          _SummaryCard(
            title: 'Inactive',
            value: inactive.toString(),
            icon: Icons.pause_circle_outline_rounded,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1)
                  const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Column(
          children: [
            cards[0],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: cards[1]),
                const SizedBox(width: 12),
                Expanded(child: cards[2]),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildOwnerCard(
    BuildContext context,
    Map<String, dynamic> owner,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final pharmacy =
        owner['_pharmacy'] as Map<String, dynamic>?;

    final ownerId =
        owner['_documentId']?.toString() ??
        owner['id']?.toString() ??
        '';

    final status = _ownerStatus(owner);
    final isActive = status == 'active';

    final pharmacyName =
        pharmacy?['name']?.toString().trim();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:
                        colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ownerName(owner),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pharmacyName != null &&
                                pharmacyName.isNotEmpty
                            ? pharmacyName
                            : 'No pharmacy linked',
                        style: TextStyle(
                          color: colorScheme
                              .onSurfaceVariant,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: ownerId.isEmpty
                      ? null
                      : (value) async {
                          if (value ==
                              'toggle') {
                            await _setOwnerStatus(
                              userId: ownerId,
                              status: isActive
                                  ? 'inactive'
                                  : 'active',
                            );
                          }
                        },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
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
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: _ownerEmail(owner),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _ownerPhone(owner),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(
                          alpha: 0.10,
                        )
                      : Colors.orange.withValues(
                          alpha: 0.10,
                        ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  child: Text(
                    isActive
                        ? 'Active'
                        : 'Inactive',
                    style: TextStyle(
                      color: isActive
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 100),
      child: Column(
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 62,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            _searchQuery.isEmpty
                ? 'No pharmacy owners found yet.'
                : 'No pharmacy owner matches your search.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String message,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 58,
              color: colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
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
    final colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color:
          colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color:
                    colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: TextStyle(
              color:
                  colorScheme.onSurfaceVariant,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}