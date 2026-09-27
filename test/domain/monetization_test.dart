import 'package:flutter_test/flutter_test.dart';
import 'package:j_life/features/monetization/domain/monetization.dart';

void main() {
  test('free tier shows a passive ad slot', () {
    expect(const AdPolicy(Tier.free).showPassiveAd, isTrue);
  });

  test('pro tier removes ad slot including reserved space', () {
    expect(const AdPolicy(Tier.pro).showPassiveAd, isFalse);
  });
}
