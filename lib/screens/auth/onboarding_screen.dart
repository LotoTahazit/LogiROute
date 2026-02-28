import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/company_settings_service.dart';

/// מסך הרשמה עצמית — יצירת חשבון חדש + חברה + trial
/// Flow: email+password → company name + taxId → create all → redirect to app
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isLoading = false;
  int _step = 0; // 0 = credentials, 1 = company info

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _companyNameCtrl.dispose();
    _taxIdCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // 1. Create Firebase Auth user
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final uid = cred.user!.uid;

      // 2. Generate company ID from taxId or timestamp
      final companyId = _taxIdCtrl.text.trim().isNotEmpty
          ? 'company_${_taxIdCtrl.text.trim()}'
          : 'company_$uid';

      // 3. Create company document with trial status
      final trialEnd = DateTime.now().add(const Duration(days: 14));
      await firestore.collection('companies').doc(companyId).set({
        'nameHebrew': _companyNameCtrl.text.trim(),
        'nameEnglish': '',
        'taxId': _taxIdCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'billingStatus': 'trial',
        'trialUntil': Timestamp.fromDate(trialEnd),
        'plan': 'full',
        'gracePeriodDays': 7,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      // 4. Initialize company settings
      try {
        final settingsService = CompanySettingsService(companyId: companyId);
        await settingsService.createDefaultSettings();
      } catch (_) {}

      // 5. Initialize counters
      try {
        final countersRef = firestore
            .collection('companies')
            .doc(companyId)
            .collection('counters');
        final batch = firestore.batch();
        for (final docType in [
          'invoice',
          'receipt',
          'delivery',
          'creditNote'
        ]) {
          batch.set(countersRef.doc(docType), {'lastNumber': 0});
        }
        await batch.commit();
      } catch (_) {}

      // 6. Create user profile as admin of this company
      await firestore.collection('users').doc(uid).set({
        'email': _emailCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'role': 'admin',
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
        'onboarded': true,
      });

      // 7. Welcome notification — создаётся серверным триггером onCompanyCreated
      // (клиентский create в notifications запрещён правилами безопасности)

      // 8. Audit
      try {
        await firestore
            .collection('companies')
            .doc(companyId)
            .collection('audit')
            .add({
          'moduleKey': 'billing',
          'type': 'billing_status_changed',
          'entity': {'collection': 'companies', 'docId': companyId},
          'createdBy': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'fromStatus': 'none',
          'toStatus': 'trial',
          'reason': 'Self-service onboarding',
        });
      } catch (_) {}

      // Auth state listener in main.dart will pick up the new user
      // and redirect to AdminDashboard automatically
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg;
        switch (e.code) {
          case 'email-already-in-use':
            msg = 'כתובת האימייל כבר בשימוש';
            break;
          case 'weak-password':
            msg = 'הסיסמה חלשה מדי (מינימום 6 תווים)';
            break;
          case 'invalid-email':
            msg = 'כתובת אימייל לא תקינה';
            break;
          default:
            msg = 'שגיאה: ${e.code}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('הרשמה ל-LogiRoute'),
        backgroundColor: Colors.blue,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', width: 64, height: 64),
                    const SizedBox(height: 12),
                    const Text(
                      'הרשמה — 14 ימי ניסיון חינם',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'שלב ${_step + 1} מתוך 2',
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),

                    // Step indicator
                    Row(
                      children: [
                        Expanded(
                            child: Container(height: 3, color: Colors.blue)),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Container(
                                height: 3,
                                color: _step >= 1
                                    ? Colors.blue
                                    : Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (_step == 0) ..._buildStep1(),
                    if (_step == 1) ..._buildStep2(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStep1() {
    return [
      TextFormField(
        controller: _nameCtrl,
        decoration: const InputDecoration(
          labelText: 'שם מלא',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'שדה חובה' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _emailCtrl,
        decoration: const InputDecoration(
          labelText: 'אימייל',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.email),
        ),
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'שדה חובה';
          if (!v.contains('@')) return 'אימייל לא תקין';
          return null;
        },
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _passwordCtrl,
        decoration: const InputDecoration(
          labelText: 'סיסמה',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.lock),
        ),
        obscureText: true,
        validator: (v) {
          if (v == null || v.isEmpty) return 'שדה חובה';
          if (v.length < 6) return 'מינימום 6 תווים';
          return null;
        },
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              setState(() => _step = 1);
            }
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('המשך'),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('כבר יש לי חשבון — התחברות'),
      ),
    ];
  }

  List<Widget> _buildStep2() {
    return [
      TextFormField(
        controller: _companyNameCtrl,
        decoration: const InputDecoration(
          labelText: 'שם החברה',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.business),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'שדה חובה' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _taxIdCtrl,
        decoration: const InputDecoration(
          labelText: 'ח.פ / ע.מ (אופציונלי)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.numbers),
        ),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _phoneCtrl,
        decoration: const InputDecoration(
          labelText: 'טלפון (אופציונלי)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.phone),
        ),
        keyboardType: TextInputType.phone,
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _isLoading ? null : _register,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('צור חשבון והתחל'),
        ),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: () => setState(() => _step = 0),
        child: const Text('חזרה'),
      ),
    ];
  }
}
