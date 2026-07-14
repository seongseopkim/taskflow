/// 백엔드 position 규칙과 동일: 새 항목은 max + 65536.0, 두 항목 사이는 중간값.
/// (HANDOFF.md 6번 섹션 참고)
class PositionCalculator {
  PositionCalculator._();

  static const double gap = 65536.0;

  /// [positions]는 대상 리스트의 카드 position들 (정렬됨, 옮기는 카드 자신은 제외).
  /// [insertIndex]는 0..positions.length, 이 인덱스 "앞"에 삽입한다는 의미.
  static double calculate(List<double> positions, int insertIndex) {
    if (positions.isEmpty) return gap;
    if (insertIndex <= 0) return positions.first / 2;
    if (insertIndex >= positions.length) return positions.last + gap;
    final before = positions[insertIndex - 1];
    final after = positions[insertIndex];
    return (before + after) / 2;
  }
}
