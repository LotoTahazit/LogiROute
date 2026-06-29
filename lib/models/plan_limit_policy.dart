/// H5: единая модель enforcement лимитов тарифа (pilot = soft).
enum PlanLimitKey { maxUsers, maxDocsPerMonth, maxRoutesPerDay }

enum LimitEnforcement { soft, hard, notEnforced }

class PlanLimitPolicy {
  PlanLimitPolicy._();

  /// Pilot: users/docs — soft warning; routes/day — не отслеживается в UI.
  static LimitEnforcement enforcement(PlanLimitKey key) {
    switch (key) {
      case PlanLimitKey.maxUsers:
      case PlanLimitKey.maxDocsPerMonth:
        return LimitEnforcement.soft;
      case PlanLimitKey.maxRoutesPerDay:
        return LimitEnforcement.notEnforced;
    }
  }

  static bool blocks(PlanLimitKey key) =>
      enforcement(key) == LimitEnforcement.hard;

  static bool isOverLimit(int usage, int limit) =>
      limit > 0 && usage >= limit;

  static bool isNearLimit(int usage, int limit) =>
      limit > 0 && usage >= (limit * 0.8).round() && usage < limit;
}
