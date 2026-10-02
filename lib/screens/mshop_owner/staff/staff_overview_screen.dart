import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffOverviewScreen extends StatefulWidget {
  const StaffOverviewScreen({super.key});

  @override
  State<StaffOverviewScreen> createState() => _StaffOverviewScreenState();
}

class _StaffOverviewScreenState extends State<StaffOverviewScreen> {
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

  Future<_StaffPageData> _loadStaff() async {
    final staffSnapshot =
        await _firestore.collection('staff').get();

    final pharmacySnapshot =
        await _firestore.collection('pharmacies').get();

    final pharmaciesById = <String, Map<String, dynamic>>{};

    for (final doc in pharmacySnapshot.docs) {
      final data = doc.data();

      pharmaciesById[doc.id] = {
        ...data,
        'id': data['id']?.toString() ?? doc.id,
      };
    }

    final rows = <_StaffRow>[];

    for (final doc in staffSnapshot.docs) {
      final data = doc.data();

      final pharmacyId =
          data['pharmacyId']?.toString();

      rows.add(
        _StaffRow(
          data: data,
          documentId: doc.id,
          pharmacy: pharmacyId == null
              ? null
              : pharmaciesById[pharmacyId],
        ),
      );
    }

    rows.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(b.name.toLowerCase()),
    );

    return _StaffPageData(rows);
  }

  bool _matchesSearch(_StaffRow row) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    final values = <String>[
      row.name,
      row.email,
      row.phone,
      row.staffId,
      row.pharmacyName,
      row.pharmacyId,
    ];

    return values.any(
      (value) => value.toLowerCase().contains(_searchQuery),
    );
  }

  String _status(Map<String, dynamic> data) {
    return data['status']?.toString() == 'inactive'
        ? 'inactive'
        : 'active';
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
        title: const Text('Staff'),
      ),
      body: SafeArea(
        child: FutureBuilder<_StaffPageData>(
          future: _loadStaff(),
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
                'Failed to load Staff.',
              );
            }

            final data =
                snapshot.data ?? _StaffPageData(const []);

            final rows = data.rows
                .where(_matchesSearch)
                .toList();

            final total = data.rows.length;

            final active = data.rows
                .where(
                  (row) =>
                      _status(row.data) == 'active',
                )
                .length;

            final inactive = total - active;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  28,
                ),
                children: [
                  _buildSummary(
                    context,
                    total: total,
                    active: active,
                    inactive: inactive,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Search staff, pharmacy, phone or email...',
                      prefixIcon:
                          const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed:
                                  _searchController.clear,
                              icon: const Icon(
                                Icons.clear_rounded,
                              ),
                            ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (rows.isEmpty)
                    _buildEmptyState(context)
                  else
                    ...rows.map(
                      (row) => Padding(
                        padding:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child:
                            _buildStaffCard(
                          context,
                          row,
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
        final isWide =
            constraints.maxWidth >= 760;

        final cards = [
          _SummaryCard(
            title: 'Total',
            value: total.toString(),
            icon: Icons.groups_outlined,
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
              for (var i = 0;
                  i < cards.length;
                  i++) ...[
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

  Widget _buildStaffCard(
    BuildContext context,
    _StaffRow row,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    final status = _status(row.data);
    final isActive = status == 'active';

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
                    color:
                        colorScheme.primary,
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
                        row.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row.pharmacyName.isEmpty
                            ? 'No pharmacy linked'
                            : row.pharmacyName,
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
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _InfoRow(
              icon:
                  Icons.email_outlined,
              label: 'Email',
              value: row.email,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon:
                  Icons.phone_outlined,
              label: 'Phone',
              value: row.phone,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon:
                  Icons.badge_outlined,
              label: 'Staff ID',
              value: row.staffId,
            ),
            const SizedBox(height: 10),
            Align(
              alignment:
                  Alignment.centerLeft,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(
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

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 100,
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 62,
            color:
                colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            _searchQuery.isEmpty
                ? 'No Staff found yet.'
                : 'No Staff member matches your search.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  colorScheme.onSurfaceVariant,
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
    final colorScheme =
        Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
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

class _StaffPageData {
  final List<_StaffRow> rows;

  const _StaffPageData(this.rows);
}

class _StaffRow {
  final Map<String, dynamic> data;
  final String documentId;
  final Map<String, dynamic>? pharmacy;

  const _StaffRow({
    required this.data,
    required this.documentId,
    required this.pharmacy,
  });

  String get name {
    final value =
        data['fullName']?.toString().trim();

    return value == null || value.isEmpty
        ? 'Unknown Staff'
        : value;
  }

  String get email {
    final value =
        data['email']?.toString().trim();

    return value == null || value.isEmpty
        ? '—'
        : value;
  }

  String get phone {
    final value =
        data['phone']?.toString().trim();

    return value == null || value.isEmpty
        ? '—'
        : value;
  }

  String get staffId {
    final value =
        data['id']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return documentId;
  }

  String get pharmacyId {
    return data['pharmacyId']?.toString() ?? '';
  }

  String get pharmacyName {
    final value =
        pharmacy?['name']?.toString().trim();

    return value ?? '';
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
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color:
                  colorScheme.primary,
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
