class MarketingInteraction {
  const MarketingInteraction({
    required this.id,
    required this.clientId,
    required this.occurredAt,
    required this.type,
    required this.outcome,
  });

  final String id;
  final String clientId;
  final DateTime occurredAt;
  final String type;
  final String outcome;
}
