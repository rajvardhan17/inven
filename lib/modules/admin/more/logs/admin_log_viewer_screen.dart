import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LOG TYPE METADATA
// ─────────────────────────────────────────────────────────────────────────────

class _LogMeta {
  final Color color;
  final IconData icon;
  final String label;
  const _LogMeta({required this.color, required this.icon, required this.label});
}

final _logTypes = <String, _LogMeta>{
  'payment': _LogMeta(color: AppTheme.green,  icon: Icons.payments_outlined,       label: 'Payment'),
  'order':   _LogMeta(color: AppTheme.accent, icon: Icons.receipt_long_outlined,   label: 'Order'),
  'error':   _LogMeta(color: AppTheme.red,    icon: Icons.error_outline_rounded,   label: 'Error'),
  'auth':    _LogMeta(color: AppTheme.blue,   icon: Icons.lock_outline_rounded,    label: 'Auth'),
  'system':  _LogMeta(color: AppTheme.purple, icon: Icons.settings_outlined,       label: 'System'),
};

_LogMeta _metaFor(String type) => _logTypes[type] ??
    const _LogMeta(color: AppTheme.textSecondary, icon: Icons.info_outline, label: 'Info');

// ─────────────────────────────────────────────────────────────────────────────
//  ADMIN LOGS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  String _filter = 'all';
  String _search = '';

  static const _filterOptions = ['all', 'order', 'payment', 'auth', 'error', 'system'];

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text("System Logs"),
        backgroundColor: AppTheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: Column(children: [
        _searchBar(),
        _filterChips(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // ✅ No compound orderBy — 'timestamp' is a single-field index
            //    auto-created by Firestore. Client-side sort applied.
            stream: FirebaseFirestore.instance
                .collection('logs')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoader();
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}",
                    style: const TextStyle(color: AppTheme.red, fontSize: 13)));
              }

              // Sort client-side newest first
              final all = (snapshot.data?.docs ?? []).toList()
                ..sort((a, b) {
                  final aTs = _getTs(a.data());
                  final bTs = _getTs(b.data());
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs);
                });

              // Type filter
              var docs = _filter == 'all'
                  ? all
                  : all.where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return (data['type'] ?? '') == _filter;
                    }).toList();

              // Search
              if (_search.isNotEmpty) {
                docs = docs.where((d) {
                  final data    = d.data() as Map<String, dynamic>;
                  final msg     = (data['message'] ?? '').toString().toLowerCase();
                  final userId  = (data['userId'] ?? '').toString().toLowerCase();
                  final action  = (data['action'] ?? '').toString().toLowerCase();
                  final module  = (data['module'] ?? '').toString().toLowerCase();
                  return msg.contains(_search)
                      || userId.contains(_search)
                      || action.contains(_search)
                      || module.contains(_search);
                }).toList();
              }

              // Stats strip (from all docs, not filtered)
              final counts = <String, int>{};
              for (final d in all) {
                final t = ((d.data() as Map)['type'] ?? 'system').toString();
                counts[t] = (counts[t] ?? 0) + 1;
              }

              if (docs.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.history_outlined,
                  title: "No Logs",
                  subtitle: "Log entries will appear here",
                );
              }

              return Column(children: [
                _statsStrip(counts, all.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 32, top: 4),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _LogCard(data: data);
                    },
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  // ── Stats strip ───────────────────────────────────────────

  Widget _statsStrip(Map<String, int> counts, int total) {
    final priority = ['error', 'order', 'payment'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("TOTAL", style: TextStyle(
            color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text("$total", style: const TextStyle(
            color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
        ])),
        Container(width: 1, height: 36, color: AppTheme.border,
            margin: const EdgeInsets.symmetric(horizontal: 12)),
        ...priority.map((t) {
          final m = _metaFor(t);
          final n = counts[t] ?? 0;
          return Expanded(child: Column(children: [
            Icon(m.icon, color: m.color, size: 16),
            const SizedBox(height: 4),
            Text("$n", style: TextStyle(
              color: m.color, fontSize: 16, fontWeight: FontWeight.w800)),
            Text(m.label, style: const TextStyle(
              color: AppTheme.textMuted, fontSize: 9)),
          ])),
        }),
      ]),
    );
  }

  // ── Search ────────────────────────────────────────────────

  Widget _searchBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _search = v.toLowerCase()),
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: "Search logs…",
          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 18),
          suffixIcon: _search.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 16),
                  onPressed: () => setState(() => _search = ''))
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────

  Widget _filterChips() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterOptions.map((f) {
            final sel = _filter == f;
            final m   = f == 'all' ? null : _metaFor(f);
            return GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel
                      ? (m != null ? m.color.withOpacity(0.2) : AppTheme.accentSoft)
                      : AppTheme.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? (m != null ? m.color.withOpacity(0.5) : AppTheme.accent)
                        : AppTheme.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (m != null) ...[
                    Icon(m.icon,
                      color: sel ? m.color : AppTheme.textSecondary, size: 13),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    f == 'all' ? 'All' : m!.label,
                    style: TextStyle(
                      color: sel
                          ? (m != null ? m.color : AppTheme.accent)
                          : AppTheme.textSecondary,
                      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                  ),
                ]),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Helper ────────────────────────────────────────────────

  Timestamp? _getTs(dynamic data) {
    if (data is Map) {
      final ts = data['timestamp'] ?? data['createdAt'];
      if (ts is Timestamp) return ts;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  LOG CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _LogCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _LogCard({required this.data});

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d       = widget.data;
    final type    = (d['type'] ?? 'system').toString();
    final message = (d['message'] ?? '').toString();
    final userId  = (d['userId'] ?? '—').toString();
    final action  = (d['action'] ?? '').toString();
    final module  = (d['module'] ?? '').toString();
    final meta    = d['meta'] as Map? ?? {};

    // Prefer 'timestamp', fall back to 'createdAt'
    final rawTs = d['timestamp'] ?? d['createdAt'];
    final dt    = rawTs is Timestamp ? rawTs.toDate() : null;
    final fmtDate = dt != null
        ? "${dt.day}/${dt.month}/${dt.year}"
        : '—';
    final fmtTime = dt != null
        ? "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}"
        : '';

    final m = _metaFor(type);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Icon
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8)),
                  child: Icon(m.icon, color: m.color, size: 18),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action + type chips on one line
                    Row(children: [
                      _chip(type, m.color),
                      if (action.isNotEmpty && action != type) ...[
                        const SizedBox(width: 6),
                        _chip(action, AppTheme.textSecondary),
                      ],
                      if (module.isNotEmpty && module != type) ...[
                        const SizedBox(width: 6),
                        _chip(module, AppTheme.textMuted),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    // Message
                    Text(message, style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500,
                      height: 1.4),
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // User + time
                    Row(children: [
                      const Icon(Icons.person_outline, color: AppTheme.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(userId, style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
                      const Spacer(),
                      Text("$fmtDate  $fmtTime", style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
                    ]),
                  ],
                )),

                // Expand chevron
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textMuted, size: 18),
                ),
              ]),
            ),

            // ── Expanded meta ──────────────────────────────
            if (_expanded && meta.isNotEmpty) ...[
              Container(height: 1, color: AppTheme.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("META", style: TextStyle(
                      color: AppTheme.textMuted, fontSize: 9,
                      letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...meta.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(
                          width: 110,
                          child: Text(e.key, style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11,
                            fontWeight: FontWeight.w600)),
                        ),
                        Expanded(child: Text(
                          e.value?.toString() ?? '—',
                          style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 11,
                            fontFamily: 'monospace'),
                        )),
                      ]),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(label.toUpperCase(), style: TextStyle(
      color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
  );
}