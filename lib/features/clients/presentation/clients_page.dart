import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_client_repository.dart';
import '../domain/entities/client.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late final SupabaseClientRepository _repository;
  final _searchController = TextEditingController();
  List<Client> _clients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = SupabaseClientRepository(Supabase.instance.client);
    _searchController.addListener(_refreshView);
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.removeListener(_refreshView);
    _searchController.dispose();
    super.dispose();
  }

  void _refreshView() => setState(() {});

  Future<void> _loadClients() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clients = await _repository.getClients();
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is PostgrestException ? error.message : error.toString();
        _loading = false;
      });
    }
  }

  List<Client> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _clients;
    return _clients.where((client) {
      final haystack = [
        client.name,
        client.companyName,
        client.clientCode,
        client.phone,
        client.whatsapp,
        client.email,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _showClientDialog({Client? client}) async {
    final name = TextEditingController(text: client?.name ?? '');
    final code = TextEditingController(text: client?.clientCode ?? '');
    final company = TextEditingController(text: client?.companyName ?? '');
    final phone = TextEditingController(text: client?.phone ?? '');
    final whatsapp = TextEditingController(text: client?.whatsapp ?? '');
    final email = TextEditingController(text: client?.email ?? '');
    final address = TextEditingController(text: client?.address ?? '');
    final type = TextEditingController(text: client?.clientType ?? '');
    final notes = TextEditingController(text: client?.notes ?? '');
    var status = client?.status ?? 'active';
    var saving = false;

    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(client == null ? 'Add Client' : 'Edit Client'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Client name *')),
                    TextField(controller: company, decoration: const InputDecoration(labelText: 'Company')),
                    TextField(controller: code, decoration: const InputDecoration(labelText: 'Client code')),
                    TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
                    TextField(controller: whatsapp, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp')),
                    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                    TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
                    TextField(controller: type, decoration: const InputDecoration(labelText: 'Client type')),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        DropdownMenuItem(value: 'prospect', child: Text('Prospect')),
                        DropdownMenuItem(value: 'archived', child: Text('Archived')),
                      ],
                      onChanged: saving ? null : (value) => setDialogState(() => status = value ?? 'active'),
                    ),
                    TextField(controller: notes, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Notes')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
              FilledButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        if (name.text.trim().isEmpty) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Client name is required.')));
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          if (client == null) {
                            await _repository.createClient(
                              name: name.text.trim(), clientCode: _nullable(code), companyName: _nullable(company),
                              phone: _nullable(phone), whatsapp: _nullable(whatsapp), email: _nullable(email),
                              address: _nullable(address), clientType: _nullable(type), status: status, notes: _nullable(notes),
                            );
                          } else {
                            await _repository.updateClient(
                              id: client.id, name: name.text.trim(), clientCode: _nullable(code), companyName: _nullable(company),
                              phone: _nullable(phone), whatsapp: _nullable(whatsapp), email: _nullable(email),
                              address: _nullable(address), clientType: _nullable(type), status: status, notes: _nullable(notes),
                            );
                          }
                          if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                        } catch (error) {
                          if (!dialogContext.mounted) return;
                          setDialogState(() => saving = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
                        }
                      },
                icon: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      );
      if (saved == true) await _loadClients();
    } finally {
      for (final controller in [name, code, company, phone, whatsapp, email, address, type, notes]) {
        controller.dispose();
      }
    }
  }

  String? _nullable(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  String _errorMessage(Object error) => error is PostgrestException && error.message.trim().isNotEmpty ? error.message : error.toString();

  Future<void> _delete(Client client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text('Delete ${client.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteClient(client.id);
      await _loadClients();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filtered;
    final active = _clients.where((c) => c.status == 'active').length;
    final prospects = _clients.where((c) => c.status == 'prospect').length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 28, 30, 34),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CLIENT MANAGEMENT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.7, color: Color(0xFF294B68))),
                            SizedBox(height: 7),
                            Text('Clients', style: TextStyle(fontSize: 36, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                            SizedBox(height: 7),
                            Text('Know who you serve, what they buy and where the next opportunity sits.', style: TextStyle(fontSize: 15, color: Color(0xFF69736D))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      FilledButton.icon(
                        onPressed: () => _showClientDialog(),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Add Client'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _ClientStat(label: 'Total clients', value: '${_clients.length}', icon: Icons.groups_outlined),
                      const SizedBox(width: 12),
                      _ClientStat(label: 'Active', value: '$active', icon: Icons.check_circle_outline),
                      const SizedBox(width: 12),
                      _ClientStat(label: 'Prospects', value: '$prospects', icon: Icons.person_search_outlined),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(child: Text('Client directory', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                                SizedBox(
                                  width: 330,
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search clients…', suffixIcon: Icon(Icons.tune)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                IconButton(onPressed: _loading ? null : _loadClients, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _loading
                                  ? const Center(child: CircularProgressIndicator())
                                  : _error != null
                                      ? _ClientsMessage(error: _error!, onRetry: _loadClients)
                                      : clients.isEmpty
                                          ? Center(child: Text(_clients.isEmpty ? 'No clients yet.\nAdd your first client.' : 'No clients match your search.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Color(0xFF69736D))))
                                          : RefreshIndicator(
                                              onRefresh: _loadClients,
                                              child: ListView.separated(
                                                padding: const EdgeInsets.only(top: 6, bottom: 12),
                                                itemCount: clients.length,
                                                separatorBuilder: (_, __) => const SizedBox(height: 7),
                                                itemBuilder: (context, index) {
                                                  final client = clients[index];
                                                  final detail = [client.companyName, client.phone ?? client.whatsapp, client.email].whereType<String>().where((v) => v.isNotEmpty).join(' • ');
                                                  return Container(
                                                    decoration: BoxDecoration(color: const Color(0xFFF8FAF8), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE0E5E2))),
                                                    child: ListTile(
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                                                      leading: CircleAvatar(radius: 23, backgroundColor: const Color(0xFFE5EEF4), foregroundColor: const Color(0xFF294B68), child: Text(client.name.isEmpty ? '?' : client.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800))),
                                                      title: Text(client.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                                      subtitle: Padding(padding: const EdgeInsets.only(top: 3), child: Text(detail.isEmpty ? client.status : '$detail • ${client.status}', style: const TextStyle(fontSize: 13, color: Color(0xFF69736D)))),
                                                      trailing: PopupMenuButton<String>(
                                                        onSelected: (value) { if (value == 'edit') _showClientDialog(client: client); if (value == 'delete') _delete(client); },
                                                        itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientStat extends StatelessWidget {
  const _ClientStat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFE5EEF4), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF294B68), size: 23)),
            const SizedBox(width: 13),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF69736D), fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            ]),
          ],
        ),
      ),
    ),
  );
}

class _ClientsMessage extends StatelessWidget {
  const _ClientsMessage({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFC45C5C)),
      const SizedBox(height: 12),
      const Text('Could not load clients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(error, textAlign: TextAlign.center),
      const SizedBox(height: 14),
      FilledButton(onPressed: onRetry, child: const Text('Retry')),
    ]),
  );
}
