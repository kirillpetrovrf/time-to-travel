import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  try {
    print('Обновляем цены на дополнительный багаж...');
    
    await firestore
        .collection('settings')
        .doc('baggage_pricing')
        .set({
      'extra_s_price': 500.0,    // S: 500₽
      'extra_m_price': 1000.0,   // M: 1000₽
      'extra_l_price': 2000.0,   // L: 2000₽
      'extra_custom_price': 2000.0, // Custom: 2000₽
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Цены успешно обновлены!');
    print('  S (малый):   500₽');
    print('  M (средний): 1000₽');
    print('  L (большой): 2000₽');
    print('  Custom:      2000₽');
    
  } catch (e) {
    print('❌ Ошибка обновления цен: $e');
  }
}
