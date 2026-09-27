enum Tier { free, pro }

class AdPolicy {
  const AdPolicy(this.tier);

  final Tier tier;
  bool get showPassiveAd => tier == Tier.free;
}

abstract interface class EntitlementService {
  Tier get tier;
  Future<void> restorePurchases();
  Future<void> purchasePro();
}

class PreviewEntitlementService implements EntitlementService {
  PreviewEntitlementService({this.tier = Tier.free});

  @override
  Tier tier;

  @override
  Future<void> purchasePro() async {
    throw UnsupportedError('출시 준비 단계에서 스토어 SDK를 연결합니다.');
  }

  @override
  Future<void> restorePurchases() async {
    throw UnsupportedError('출시 준비 단계에서 스토어 SDK를 연결합니다.');
  }
}
