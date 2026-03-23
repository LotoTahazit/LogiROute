import 'package:flutter/material.dart';

/// ויזואליזציה לדמו בלבד — לא נתונים אמיתיים, לא Firestore.
class DispatcherDemoProcessVisual extends StatelessWidget {
  const DispatcherDemoProcessVisual({super.key, required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context) {
    switch (stepIndex.clamp(0, 4)) {
      case 0:
        return _stepCreatePoint();
      case 1:
        return _stepProductsInOrder();
      case 2:
        return _stepReadyForRoute();
      case 3:
        return _stepRouteAndDriver();
      default:
        return _stepToDriverApp();
    }
  }

  Widget _arrow() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.arrow_forward, color: Colors.blue.shade700, size: 22),
      );

  Widget _stepCreatePoint() {
    return Column(
      key: const ValueKey(0),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleIcon(Icons.warehouse, 'מחסן'),
            _arrow(),
            _circleIcon(Icons.add_location_alt, 'נקודת משלוח'),
          ],
        ),
        const SizedBox(height: 14),
        _fakeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'כפתור + בתחתית — פותחים הזמנה (נקודה) ללקוח',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'דוגמה: לקוח + כתובת (כמו במסך האמיתי)',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepProductsInOrder() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleIcon(Icons.shopping_cart_outlined, 'הזמנה'),
            _arrow(),
            _circleIcon(Icons.inventory_2_outlined, 'מוצרים'),
          ],
        ),
        const SizedBox(height: 12),
        _fakeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'בנקודה: מוסיפים מוצרים וכמויות',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.grey.shade900,
                ),
              ),
              const Divider(height: 16),
              _fakeLine('קרטון מים', '× 5'),
              _fakeLine('משקל אריזה', '× 2'),
              _fakeLine('מארז רביעייה', '× 3'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepReadyForRoute() {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleIcon(Icons.fact_check, 'מוכן'),
            _arrow(),
            _circleIcon(Icons.alt_route, 'מסלול'),
          ],
        ),
        const SizedBox(height: 12),
        _fakeCard(
          child: Row(
            children: [
              Icon(Icons.navigate_next, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'עוברים ללשונית «מסלולים פעילים» — בונים מסלול ומשייכים נהג',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepRouteAndDriver() {
    return Column(
      key: const ValueKey(3),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleIcon(Icons.route, 'מסלול'),
            _arrow(),
            _circleIcon(Icons.local_shipping, 'נהג'),
          ],
        ),
        const SizedBox(height: 12),
        _fakeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, color: Colors.blue.shade800),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'נהג: דוד (דוגמה)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        Text(
                          'סדר עצירות · קווים על המפה',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: Icon(Icons.flag, size: 16, color: Colors.orange.shade800),
                    label: const Text('עצירה 1'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Chip(
                    avatar: Icon(Icons.flag, size: 16, color: Colors.orange.shade800),
                    label: const Text('עצירה 2'),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepToDriverApp() {
    return Column(
      key: const ValueKey(4),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleIcon(Icons.cloud_done, 'מערכת'),
            _arrow(),
            _circleIcon(Icons.smartphone, 'אפליקציית נהג'),
          ],
        ),
        const SizedBox(height: 12),
        _fakeCard(
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'המשימות יורדות לנהג — אחר כך רואים את הנסיעה במפה',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Icon(icon, color: Colors.blue.shade800, size: 26),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _fakeLine(String name, String qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_box_outlined, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Text(
            qty,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fakeCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }
}
