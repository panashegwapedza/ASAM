class Client {
  const Client({
    required this.id,
    required this.name,
    this.clientCode,
    this.companyName,
    this.phone,
    this.whatsapp,
    this.email,
    this.address,
    this.clientType,
    this.status = 'active',
    this.notes,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? clientCode;
  final String? companyName;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? address;
  final String? clientType;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  bool get isActive => status == 'active';

  factory Client.fromMap(Map<String, dynamic> map) => Client(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        clientCode: map['client_code'] as String?,
        companyName: map['company_name'] as String?,
        phone: map['phone'] as String?,
        whatsapp: map['whatsapp'] as String?,
        email: map['email'] as String?,
        address: map['address'] as String?,
        clientType: map['client_type'] as String?,
        status: map['status'] as String? ?? 'active',
        notes: map['notes'] as String?,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.tryParse(map['created_at'].toString()),
      );
}
