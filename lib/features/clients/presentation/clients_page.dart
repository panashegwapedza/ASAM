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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [IconButton(onPressed: _loading ? null : _loadClients, icon: const Icon(Icons.refresh))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientDialog(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Client'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.error_outline, size: 48), const SizedBox(height: 12), Text('Could not load clients'), const SizedBox(height: 8), Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 16), FilledButton(onPressed: _loadClients, child: const Text('Retry'))]))
                : Column(
                    children: [
                      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: TextField(controller: _searchController, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search clients…', border: OutlineInputBorder(), suffixIcon: Icon(Icons.tune)))),
                      Expanded(
                        child: clients.isEmpty
                            ? Center(child: Text(_clients.isEmpty ? 'No clients yet.\nAdd your first client.' : 'No clients match your search.', textAlign: TextAlign.center))
                            : RefreshIndicator(
                                onRefresh: _loadClients,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: clients.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final client = clients[index];
                                    final detail = [client.companyName, client.phone ?? client.whatsapp, client.email].whereType<String>().where((v) => v.isNotEmpty).join(' • ');
                                    return Card(
                                      child: ListTile(
                                        leading: CircleAvatar(child: Text(client.name.isEmpty ? '?' : client.name[0].toUpperCase())),
                                        title: Text(client.name),
                                        subtitle: Text(detail.isEmpty ? client.status : '$detail • ${client.status}'),
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
    );
  }
}
