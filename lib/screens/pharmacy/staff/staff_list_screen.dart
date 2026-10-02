import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../models/staff_model.dart';
import '../../../repositories/staff_repository.dart';
import '../../../services/auth_service.dart';
import 'add_staff_screen.dart';

class StaffListScreen extends StatefulWidget {
  final String? pharmacyId;

  const StaffListScreen({
    super.key,
    this.pharmacyId,
  });

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  String _t(
    AppLocalizations l10n,
    String english,
    String swahili,
  ) {
    return l10n.isSwahili ? swahili : english;
  }

  final StaffRepository _staffRepository = StaffRepository();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String? _pharmacyId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _resolvePharmacy();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _resolvePharmacy() async {
    final currentUser = _authService.currentUser;

    final resolvedPharmacyId =
        widget.pharmacyId ?? currentUser?.uid;

    if (!mounted) return;

    setState(() {
      _pharmacyId = resolvedPharmacyId;
    });
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  List<StaffModel> _filterStaff(List<StaffModel> staff) {
    if (_searchQuery.isEmpty) {
      return staff;
    }

    return staff.where((member) {
      final fullName = member.fullName.toLowerCase();
      final email = member.email.toLowerCase();
      final phone = member.phone.toLowerCase();

      return fullName.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          phone.contains(_searchQuery);
    }).toList();
  }

  Future<void> _openAddStaff() async {
    final pharmacyId = _pharmacyId;

    if (pharmacyId == null || pharmacyId.isEmpty) {
      _showMessage(_t(AppLocalizations.of(context), 'Pharmacy information is not available.', 'Taarifa za famasi hazipatikani.'));
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStaffScreen(
          pharmacyId: pharmacyId,
        ),
      ),
    );
  }

  Future<void> _editStaff(StaffModel staff) async {
    final pharmacyId = _pharmacyId;

    if (pharmacyId == null || pharmacyId.isEmpty) {
      _showMessage(_t(AppLocalizations.of(context), 'Pharmacy information is not available.', 'Taarifa za famasi hazipatikani.'));
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddStaffScreen(
          pharmacyId: pharmacyId,
          staff: staff,
        ),
      ),
    );
  }

  Future<void> _deleteStaff(StaffModel staff) async {
    final pharmacyId = _pharmacyId;

    if (pharmacyId == null || pharmacyId.isEmpty) {
      _showMessage(_t(AppLocalizations.of(context), 'Pharmacy information is not available.', 'Taarifa za famasi hazipatikani.'));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_t(AppLocalizations.of(context), 'Delete Staff', 'Futa Mfanyakazi')),
          content: Text(
            _t(
              AppLocalizations.of(context),
              'Are you sure you want to delete ${staff.fullName}?',
              'Una uhakika unataka kumfuta ${staff.fullName}?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_t(AppLocalizations.of(context), 'Cancel', 'Ghairi')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_t(AppLocalizations.of(context), 'Delete', 'Futa')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _staffRepository.deleteStaff(
        pharmacyId: pharmacyId,
        staffId: staff.id,
      );

      if (!mounted) return;
      _showMessage(_t(AppLocalizations.of(context), 'Staff deleted successfully.', 'Mfanyakazi amefutwa kwa mafanikio.'));
    } catch (e) {
      if (!mounted) return;
      _showMessage(_t(AppLocalizations.of(context), 'Failed to delete staff: $e', 'Imeshindikana kufuta mfanyakazi: $e'));
    }
  }

  Future<void> _changeStaffStatus(StaffModel staff) async {
    final pharmacyId = _pharmacyId;

    if (pharmacyId == null || pharmacyId.isEmpty) {
      _showMessage(_t(AppLocalizations.of(context), 'Pharmacy information is not available.', 'Taarifa za famasi hazipatikani.'));
      return;
    }

    final newStatus = staff.isActive ? 'inactive' : 'active';

    try {
      await _staffRepository.updateStaffStatus(
        pharmacyId: pharmacyId,
        staffId: staff.id,
        status: newStatus,
      );

      if (!mounted) return;

      _showMessage(
        newStatus == 'active'
            ? _t(
                AppLocalizations.of(context),
                '${staff.fullName} is now active.',
                '${staff.fullName} sasa yupo kazini.',
              )
            : _t(
                AppLocalizations.of(context),
                '${staff.fullName} is now inactive.',
                '${staff.fullName} sasa hayupo kazini.',
              ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(_t(AppLocalizations.of(context), 'Failed to update staff status: $e', 'Imeshindikana kusasisha hali ya mfanyakazi: $e'));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  int _activeCount(List<StaffModel> staff) {
    return staff.where((member) => member.isActive).length;
  }

  int _inactiveCount(List<StaffModel> staff) {
    return staff.where((member) => !member.isActive).length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pharmacyId = _pharmacyId;

    if (pharmacyId == null || pharmacyId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_t(l10n, 'Staff', 'Wafanyakazi')),
        ),
        body: Center(
          child: Text(
            _t(
              l10n,
              'Pharmacy information is not available.',
              'Taarifa za famasi hazipatikani.',
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(l10n, 'Staff', 'Wafanyakazi')),
        actions: [
          IconButton(
            tooltip: _t(l10n, 'Add Staff', 'Ongeza Mfanyakazi'),
            onPressed: _openAddStaff,
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStaff,
        icon: const Icon(Icons.person_add),
        label: Text(_t(l10n, 'Add Staff', 'Ongeza Mfanyakazi')),
      ),
      body: StreamBuilder<List<StaffModel>>(
        stream: _staffRepository.watchStaff(pharmacyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: _t(l10n, 'Failed to load staff.', 'Imeshindikana kupakia wafanyakazi.'),
              onRetry: () {
                setState(() {});
              },
            );
          }

          final allStaff = snapshot.data ?? <StaffModel>[];
          final filteredStaff = _filterStaff(allStaff);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                _StaffSummary(
                  total: allStaff.length,
                  active: _activeCount(allStaff),
                  inactive: _inactiveCount(allStaff),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _t(l10n, 'Search staff, phone or email...', 'Tafuta mfanyakazi, simu au barua pepe...'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (allStaff.isEmpty)
                  _EmptyStaff(
                    onAdd: _openAddStaff,
                  )
                else if (filteredStaff.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        _t(l10n, 'No staff found.', 'Hakuna mfanyakazi aliyepatikana.'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                else
                  ...filteredStaff.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _StaffCard(
                        staff: member,
                        onEdit: () => _editStaff(member),
                        onDelete: () => _deleteStaff(member),
                        onToggleStatus: () =>
                            _changeStaffStatus(member),
                      ),
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

class _StaffSummary extends StatelessWidget {
  final int total;
  final int active;
  final int inactive;

  const _StaffSummary({
    required this.total,
    required this.active,
    required this.inactive,
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

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: _t(l10n, 'Total Staff', 'Jumla ya Wafanyakazi'),
            value: total.toString(),
            icon: Icons.people_alt_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: _t(l10n, 'Active', 'Wapo Kazini'),
            value: active.toString(),
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            title: _t(l10n, 'Inactive', 'Hawapo Kazini'),
            value: inactive.toString(),
            icon: Icons.pause_circle_outline,
          ),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 26,
                  child: Text(
                    _initials(staff.fullName),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName.isEmpty
                            ? _t(l10n, 'Unnamed Staff', 'Mfanyakazi bila jina')
                            : staff.fullName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _t(l10n, 'Staff', 'Mfanyakazi'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'status':
                        onToggleStatus();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.edit_outlined),
                          title: Text(
                            _t(l10n, 'Edit', 'Hariri'),
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'status',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.power_settings_new_outlined,
                          ),
                          title: Text(
                            staff.isActive
                                ? _t(l10n, 'Deactivate', 'Zima')
                                : _t(l10n, 'Activate', 'Washa'),
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.delete_outline,
                          ),
                          title: Text(
                            _t(l10n, 'Delete', 'Futa'),
                          ),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.email_outlined,
              label: _t(l10n, 'Email', 'Barua pepe'),
              value: staff.email.isEmpty
                  ? _t(l10n, 'Not provided', 'Haijatolewa')
                  : staff.email,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: _t(l10n, 'Phone', 'Simu'),
              value: staff.phone.isEmpty
                  ? _t(l10n, 'Not provided', 'Haijatolewa')
                  : staff.phone,
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.security_outlined,
              label: _t(l10n, 'Access', 'Ruhusa'),
              value:
                  '${staff.permissions.length} ${_t(l10n, 'permission(s)', 'ruhusa')}',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  staff.isActive
                      ? Icons.check_circle
                      : Icons.pause_circle,
                  size: 18,
                  color: staff.isActive
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  staff.isActive ? _t(l10n, 'Active', 'Wapo Kazini') : _t(l10n, 'Inactive', 'Hawapo Kazini'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: staff.isActive
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    staff.isActive
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(
                    staff.isActive
                        ? _t(l10n, 'Deactivate', 'Zima')
                        : _t(l10n, 'Activate', 'Washa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return 'S';
    }

    final parts = cleaned.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(
        0,
        parts.first.length >= 2 ? 2 : 1,
      ).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyStaff extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyStaff({
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

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 56,
          ),
          const SizedBox(height: 14),
          Text(
            _t(l10n, 'No staff added yet', 'Bado hakuna wafanyakazi walioongezwa'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              l10n,
              'Add staff members so they can help operate the pharmacy.',
              'Ongeza wafanyakazi ili wasaidie kuendesha famasi.',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add),
            label: Text(_t(l10n, 'Add Staff', 'Ongeza Mfanyakazi')),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
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