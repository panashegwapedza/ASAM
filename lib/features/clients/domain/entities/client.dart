class Client {
  const Client({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final bool isActive;
}
