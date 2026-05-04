import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cpapp/core/theme/app_colors.dart';
import 'package:cpapp/core/theme/app_typography.dart';
import 'package:cpapp/features/auth/presentation/providers/auth_providers.dart';

/// Developer-only seeding screen.  Accessible only in debug builds.
/// Wipes all listings and demo users, then inserts fresh sample data.
/// The currently logged-in user's profile is always preserved.
class SeedScreen extends ConsumerStatefulWidget {
  const SeedScreen({super.key});

  @override
  ConsumerState<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends ConsumerState<SeedScreen> {
  final _log = <String>[];
  bool _running = false;

  final _db = FirebaseFirestore.instance;

  void _emit(String msg) {
    if (kDebugMode) debugPrint('[Seed] $msg');
    if (mounted) setState(() => _log.add(msg));
  }

  Future<void> _deleteCollection(String col) async {
    _emit('Deleting $col…');
    QuerySnapshot snap;
    do {
      snap = await _db.collection(col).limit(100).get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      if (snap.docs.isNotEmpty) await batch.commit();
    } while (snap.docs.length == 100);
    _emit('  ✓ $col cleared');
  }

  Future<void> _run() async {
    setState(() {
      _running = true;
      _log.clear();
    });

    final currentUid =
        ref.read(authStateChangesProvider).valueOrNull?.uid;

    try {
      // 1. Save current user's Firestore doc before wiping
      Map<String, dynamic>? savedUser;
      if (currentUid != null) {
        final snap =
            await _db.collection('users').doc(currentUid).get();
        savedUser = snap.data();
        _emit('Preserving current user ($currentUid)…');
      }

      // 2. Wipe listings only (not the full users collection)
      await _deleteCollection('listings');

      // 3. Seed demo users (fixed UIDs starting with seed_)
      _emit('Creating demo users…');
      final batch = _db.batch();
      for (final u in _users) {
        final uid = u['uid'] as String;
        // Never overwrite the logged-in user with a seed doc
        if (uid == currentUid) continue;
        batch.set(
          _db.collection('users').doc(uid),
          {
            ...u,
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(
                Duration(days: u['daysAgo'] as int? ?? 0),
              ),
            ),
            'lastSeen': Timestamp.fromDate(
              DateTime.now().subtract(
                Duration(days: (u['daysAgo'] as int? ?? 0) ~/ 3),
              ),
            ),
            'updatedAt': FieldValue.serverTimestamp(),
          }..remove('daysAgo'),
        );
      }
      await batch.commit();

      // Restore current user if they were accidentally removed
      if (savedUser != null && currentUid != null) {
        await _db
            .collection('users')
            .doc(currentUid)
            .set(savedUser, SetOptions(merge: true));
      }
      _emit('  ✓ ${_users.length} demo users seeded');

      // 4. Seed listings
      _emit('Creating listings…');
      int count = 0;
      for (final l in _listings) {
        final ref = _db.collection('listings').doc();
        await ref.set(
          {
            ...l,
            'id': ref.id,
            'createdAt': Timestamp.fromDate(
              DateTime.now().subtract(
                Duration(
                  days: (l['daysAgo'] as int? ?? 0),
                  hours: count * 2,
                ),
              ),
            ),
            'updatedAt': FieldValue.serverTimestamp(),
          }..remove('daysAgo'),
        );
        count++;
      }
      _emit('  ✓ $count listings created');
      _emit('');
      _emit('🎉 Seed complete!');
    } catch (e, st) {
      _emit('❌ Error: $e');
      if (kDebugMode) debugPrint(st.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.navyDark,
        title: Text(
          '🌱  Seed Data',
          style: AppTypography.titleMedium.copyWith(color: AppColors.gold),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.error.withValues(alpha: 0.12),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              '⚠️  Wipes all listings and demo users, then inserts fresh '
              'sample data.  Your account is preserved.  Debug mode only.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.error),
            ),
          ),
          Expanded(
            child: _log.isEmpty
                ? Center(
                    child: Text(
                      'Press the button to seed Firestore.',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _log.length,
                    itemBuilder: (_, i) => Text(
                      _log[i],
                      style: AppTypography.bodySmall.copyWith(
                        color: _log[i].startsWith('❌')
                            ? AppColors.error
                            : _log[i].startsWith('🎉')
                                ? AppColors.success
                                : (isDark
                                    ? AppColors.white
                                    : AppColors.navyDark),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _running ? null : _run,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navyDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _running
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.navyDark,
                          ),
                        )
                      : Text(
                          '🌱  Wipe & Seed Firestore',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.navyDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SEED DATA
// ═══════════════════════════════════════════════════════════════════════════

String _img(String id) =>
    'https://images.unsplash.com/photo-$id?w=900&q=80&auto=format&fit=crop';

String _avatar(String name) {
  final encoded = Uri.encodeComponent(name);
  return 'https://ui-avatars.com/api/?name=$encoded'
      '&background=0A1628&color=C9A84C&size=256&bold=true&format=png';
}

final _imgLuxury = [
  _img('1600596542815-ffad4c1539a9'),
  _img('1564013799919-ab600027ffc6'),
  _img('1580587771525-78b9dba3b914'),
];
final _imgApartment = [
  _img('1582407947304-fd86f28f8631'),
  _img('1583608205776-bfd35f0d9f83'),
  _img('1460317442991-0ec209397118'),
];
final _imgModernHome = [
  _img('1512917774080-9991f1c4c750'),
  _img('1568605114967-8130f3a36994'),
  _img('1600047509807-ba8f99d2cdde'),
];
final _imgOffice = [
  _img('1486325212027-8081e485255e'),
  _img('1497366216548-37526070297c'),
  _img('1565953522043-baea26b83b7e'),
];
final _imgCommercial = [
  _img('1543286386-2e659306cd6c'),
  _img('1497366811353-6870744d04b2'),
  _img('1450101499163-c8848c66ca85'),
];
final _imgWarehouse = [
  _img('1595526114035-0d45ed16cfbe'),
  _img('1586528116311-ad8dd3c8310d'),
];
final _imgConstruction = [
  _img('1600566753190-17f0baa2a6c3'),
  _img('1555636222-cae831e670b3'),
  _img('1504307651254-35680f356dfd'),
];
final _imgVilla = [
  _img('1564013799919-ab600027ffc6'),
  _img('1580587771525-78b9dba3b914'),
  _img('1512917774080-9991f1c4c750'),
];
final _imgPlot = [
  _img('1600607687939-ce8a6c25118c'),
  _img('1570129477492-45c003edd2be'),
];

// ═══════════════════════════════════════════════════════════════════════════
//  USERS  (10 brokers across cities)
// ═══════════════════════════════════════════════════════════════════════════

final _users = <Map<String, dynamic>>[
  {
    'uid': 'seed_u1',
    'name': 'Rajesh Kumar',
    'email': 'rajesh.kumar@cpapp.dev',
    'mobile': '9821234567',
    'city': 'Mumbai',
    'role': 'broker',
    'reraNumber': 'MH10221234',
    'referralCode': 'RAJESH01',
    'isProfileComplete': true,
    'isVerified': true,
    'listingsCount': 8,
    'connectionsCount': 42,
    'photoUrl': _avatar('Rajesh Kumar'),
    'daysAgo': 90,
  },
  {
    'uid': 'seed_u2',
    'name': 'Priya Sharma',
    'email': 'priya.sharma@cpapp.dev',
    'mobile': '9765432100',
    'city': 'Pune',
    'role': 'broker',
    'reraNumber': 'MH20459876',
    'referralCode': 'PRIYA002',
    'isProfileComplete': true,
    'isVerified': true,
    'listingsCount': 5,
    'connectionsCount': 31,
    'photoUrl': _avatar('Priya Sharma'),
    'daysAgo': 75,
  },
  {
    'uid': 'seed_u3',
    'name': 'Arjun Mehta',
    'email': 'arjun.mehta@cpapp.dev',
    'mobile': '9900112233',
    'city': 'Bengaluru',
    'role': 'broker',
    'referralCode': 'ARJUN003',
    'isProfileComplete': true,
    'isVerified': false,
    'listingsCount': 3,
    'connectionsCount': 18,
    'photoUrl': _avatar('Arjun Mehta'),
    'daysAgo': 60,
  },
  {
    'uid': 'seed_u4',
    'name': 'Sunita Patel',
    'email': 'sunita.patel@cpapp.dev',
    'mobile': '9712345678',
    'city': 'Ahmedabad',
    'role': 'broker',
    'referralCode': 'SUNITA04',
    'isProfileComplete': true,
    'isVerified': false,
    'listingsCount': 2,
    'connectionsCount': 9,
    'photoUrl': _avatar('Sunita Patel'),
    'daysAgo': 50,
  },
  {
    'uid': 'seed_u5',
    'name': 'Vikram Singh',
    'email': 'vikram.singh@cpapp.dev',
    'mobile': '9811223344',
    'city': 'Delhi',
    'role': 'broker',
    'reraNumber': 'DL10112233',
    'referralCode': 'VIKRAM05',
    'isProfileComplete': true,
    'isVerified': true,
    'listingsCount': 6,
    'connectionsCount': 55,
    'photoUrl': _avatar('Vikram Singh'),
    'daysAgo': 80,
  },
  {
    'uid': 'seed_u6',
    'name': 'Neha Desai',
    'email': 'neha.desai@cpapp.dev',
    'mobile': '9820111222',
    'city': 'Mumbai',
    'role': 'broker',
    'reraNumber': 'MH10334455',
    'referralCode': 'NEHA0006',
    'isProfileComplete': true,
    'isVerified': true,
    'listingsCount': 4,
    'connectionsCount': 27,
    'photoUrl': _avatar('Neha Desai'),
    'daysAgo': 45,
  },
  {
    'uid': 'seed_u7',
    'name': 'Ramesh Nair',
    'email': 'ramesh.nair@cpapp.dev',
    'mobile': '9988776655',
    'city': 'Hyderabad',
    'role': 'broker',
    'reraNumber': 'TS10556677',
    'referralCode': 'RAMESH07',
    'isProfileComplete': true,
    'isVerified': true,
    'listingsCount': 3,
    'connectionsCount': 22,
    'photoUrl': _avatar('Ramesh Nair'),
    'daysAgo': 30,
  },
  {
    'uid': 'seed_u8',
    'name': 'Anjali Chopra',
    'email': 'anjali.chopra@cpapp.dev',
    'mobile': '9876543210',
    'city': 'Gurugram',
    'role': 'broker',
    'referralCode': 'ANJALI08',
    'isProfileComplete': true,
    'isVerified': false,
    'listingsCount': 2,
    'connectionsCount': 14,
    'photoUrl': _avatar('Anjali Chopra'),
    'daysAgo': 20,
  },
  {
    'uid': 'seed_u9',
    'name': 'Suresh Joshi',
    'email': 'suresh.joshi@cpapp.dev',
    'mobile': '9712233445',
    'city': 'Nashik',
    'role': 'broker',
    'reraNumber': 'MH12889900',
    'referralCode': 'SURESH09',
    'isProfileComplete': true,
    'isVerified': true,
    'listingsCount': 4,
    'connectionsCount': 19,
    'photoUrl': _avatar('Suresh Joshi'),
    'daysAgo': 40,
  },
  {
    'uid': 'seed_u10',
    'name': 'Pooja Iyer',
    'email': 'pooja.iyer@cpapp.dev',
    'mobile': '9944221133',
    'city': 'Chennai',
    'role': 'broker',
    'reraNumber': 'TN10223344',
    'referralCode': 'POOJA010',
    'isProfileComplete': true,
    'isVerified': true,
    'listingsCount': 3,
    'connectionsCount': 16,
    'photoUrl': _avatar('Pooja Iyer'),
    'daysAgo': 15,
  },
];

// ═══════════════════════════════════════════════════════════════════════════
//  LISTINGS  (30 across 7 categories)
// ═══════════════════════════════════════════════════════════════════════════

final _listings = <Map<String, dynamic>>[
  // ── BARTER DEALS (5) ────────────────────────────────────────────────────
  {
    'brokerUid': 'seed_u1',
    'brokerName': 'Rajesh Kumar',
    'brokerPhone': '9821234567',
    'brokerPhotoUrl': _avatar('Rajesh Kumar'),
    'posterRole': 'broker',
    'category': 'barter',
    'propertyType': 'bhk3',
    'city': 'Mumbai',
    'location': 'Andheri West, Lokhandwala Complex',
    'area': 1850.0,
    'areaUnit': 'sqFt',
    'price': 14500000.0,
    'description': 'Spacious 3 BHK in prime Lokhandwala Complex available for barter. '
        'Fully furnished with modular kitchen and 2 covered parking. '
        'Interested in a commercial plot or shop anywhere in Mumbai suburbs.',
    'heroImageUrl': _imgLuxury[0],
    'additionalImageUrls': [_imgModernHome[0], _imgApartment[1]],
    'brokerageAmount': '1.5%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 24,
    'viewsCount': 312,
    'commentsCount': 5,
    'daysAgo': 2,
  },
  {
    'brokerUid': 'seed_u2',
    'brokerName': 'Priya Sharma',
    'brokerPhone': '9765432100',
    'brokerPhotoUrl': _avatar('Priya Sharma'),
    'posterRole': 'broker',
    'category': 'barter',
    'propertyType': 'villa',
    'city': 'Pune',
    'location': 'Koregaon Park, Lane 7',
    'area': 3200.0,
    'areaUnit': 'sqFt',
    'price': 28000000.0,
    'description': 'Premium villa in the heart of Koregaon Park up for barter. '
        '4 bed, 4 bath, private garden, 2-car garage. '
        'Looking to exchange against a Mumbai flat (Bandra / Juhu preferred).',
    'heroImageUrl': _imgVilla[0],
    'additionalImageUrls': [_imgVilla[1], _imgModernHome[1]],
    'brokerageAmount': '1%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 41,
    'viewsCount': 578,
    'commentsCount': 9,
    'daysAgo': 5,
  },
  {
    'brokerUid': 'seed_u9',
    'brokerName': 'Suresh Joshi',
    'brokerPhone': '9712233445',
    'brokerPhotoUrl': _avatar('Suresh Joshi'),
    'posterRole': 'builder',
    'category': 'barter',
    'propertyType': 'plot',
    'city': 'Nashik',
    'location': 'Nashik Road, Near Railway Station',
    'area': 2400.0,
    'areaUnit': 'sqFt',
    'price': 4800000.0,
    'description': 'NA-converted residential plot on Nashik Road. '
        'Clear title, 40-ft road access, all utilities available. '
        'Open to barter against 2/3 BHK flat in Nashik, Pune, or Mumbai.',
    'heroImageUrl': _imgPlot[0],
    'additionalImageUrls': [_imgPlot[1]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 14,
    'viewsCount': 189,
    'commentsCount': 2,
    'daysAgo': 7,
  },
  {
    'brokerUid': 'seed_u4',
    'brokerName': 'Sunita Patel',
    'brokerPhone': '9712345678',
    'brokerPhotoUrl': _avatar('Sunita Patel'),
    'posterRole': 'owner',
    'category': 'barter',
    'propertyType': 'rowHouse',
    'city': 'Ahmedabad',
    'location': 'Bopal, South Bopal Township',
    'area': 1800.0,
    'areaUnit': 'sqFt',
    'price': 8500000.0,
    'description': 'Independent row house in gated township, Bopal. '
        '3 bed, study room, terrace, servant quarters. '
        'Barter offer: interested in a Pune flat or Surat commercial shop.',
    'heroImageUrl': _imgModernHome[2],
    'additionalImageUrls': [_imgModernHome[0], _imgLuxury[2]],
    'visibility': 'all',
    'status': 'active',
    'likesCount': 11,
    'viewsCount': 145,
    'commentsCount': 1,
    'daysAgo': 10,
  },
  {
    'brokerUid': 'seed_u6',
    'brokerName': 'Neha Desai',
    'brokerPhone': '9820111222',
    'brokerPhotoUrl': _avatar('Neha Desai'),
    'posterRole': 'broker',
    'category': 'barter',
    'propertyType': 'penthouse',
    'city': 'Mumbai',
    'location': 'Bandra West, Pali Hill',
    'area': 2200.0,
    'areaUnit': 'sqFt',
    'price': 38000000.0,
    'description': 'Stunning Pali Hill penthouse with 360° sea & city views. '
        '3 bed + home theatre, private terrace with jacuzzi. '
        'Barter against Alibaug farmhouse or Lonavala villa.',
    'heroImageUrl': _imgLuxury[2],
    'additionalImageUrls': [_imgLuxury[0], _imgApartment[0]],
    'brokerageAmount': '0.5%',
    'visibility': 'network',
    'status': 'active',
    'likesCount': 67,
    'viewsCount': 892,
    'commentsCount': 13,
    'daysAgo': 3,
  },

  // ── PROJECT DEALS (5) ───────────────────────────────────────────────────
  {
    'brokerUid': 'seed_u5',
    'brokerName': 'Vikram Singh',
    'brokerPhone': '9811223344',
    'brokerPhotoUrl': _avatar('Vikram Singh'),
    'posterRole': 'builder',
    'category': 'project',
    'propertyType': 'bhk2',
    'city': 'Thane',
    'location': 'Thane West, Hiranandani Estate',
    'area': 950.0,
    'areaUnit': 'sqFt',
    'price': 8200000.0,
    'description': 'Pre-launch 2 BHK in Hiranandani Estate, Thane. '
        'RERA-approved, possession Q4 2026. Club house, swimming pool, 24x7 security.',
    'heroImageUrl': _imgConstruction[0],
    'additionalImageUrls': [_imgApartment[2], _imgConstruction[1]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 88,
    'viewsCount': 1204,
    'commentsCount': 19,
    'daysAgo': 1,
  },
  {
    'brokerUid': 'seed_u2',
    'brokerName': 'Priya Sharma',
    'brokerPhone': '9765432100',
    'brokerPhotoUrl': _avatar('Priya Sharma'),
    'posterRole': 'broker',
    'category': 'project',
    'propertyType': 'bhk3',
    'city': 'Pune',
    'location': 'Wakad, Spine Road',
    'area': 1350.0,
    'areaUnit': 'sqFt',
    'price': 11000000.0,
    'description': 'Under-construction 3 BHK with study, 2 balconies. '
        'RERA Ref: P52100047892. Possession March 2026. Premium finishes — Italian marble.',
    'heroImageUrl': _imgConstruction[1],
    'additionalImageUrls': [_imgApartment[1], _imgModernHome[0]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 52,
    'viewsCount': 741,
    'commentsCount': 8,
    'daysAgo': 4,
  },
  {
    'brokerUid': 'seed_u9',
    'brokerName': 'Suresh Joshi',
    'brokerPhone': '9712233445',
    'brokerPhotoUrl': _avatar('Suresh Joshi'),
    'posterRole': 'builder',
    'category': 'project',
    'propertyType': 'penthouse',
    'city': 'Mumbai',
    'location': 'Bandra West, Turner Road',
    'area': 2800.0,
    'areaUnit': 'sqFt',
    'price': 52000000.0,
    'description': 'Signature penthouse in new luxury tower, Bandra West. '
        'Duplex layout — 4 bed + 4 bath + sky lounge + private lift. Just 8 units.',
    'heroImageUrl': _imgLuxury[1],
    'additionalImageUrls': [_imgLuxury[0], _imgLuxury[2]],
    'brokerageAmount': '1%',
    'visibility': 'network',
    'status': 'active',
    'likesCount': 103,
    'viewsCount': 1567,
    'commentsCount': 24,
    'daysAgo': 6,
  },
  {
    'brokerUid': 'seed_u5',
    'brokerName': 'Vikram Singh',
    'brokerPhone': '9811223344',
    'brokerPhotoUrl': _avatar('Vikram Singh'),
    'posterRole': 'builder',
    'category': 'project',
    'propertyType': 'plot',
    'city': 'Bengaluru',
    'location': 'Sarjapur Road, Infosys Corridor',
    'area': 1200.0,
    'areaUnit': 'sqFt',
    'price': 7500000.0,
    'description': 'BMRDA-approved residential plot on Sarjapur Road. '
        '30×40 site, east-facing, 40-ft BDA road access. Part of gated layout.',
    'heroImageUrl': _imgPlot[1],
    'additionalImageUrls': [_imgPlot[0], _imgConstruction[2]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 37,
    'viewsCount': 523,
    'commentsCount': 7,
    'daysAgo': 8,
  },
  {
    'brokerUid': 'seed_u8',
    'brokerName': 'Anjali Chopra',
    'brokerPhone': '9876543210',
    'brokerPhotoUrl': _avatar('Anjali Chopra'),
    'posterRole': 'investor',
    'category': 'project',
    'propertyType': 'studio',
    'city': 'Noida',
    'location': 'Noida Sector 150, Sports City',
    'area': 650.0,
    'areaUnit': 'sqFt',
    'price': 3500000.0,
    'description': 'Compact studio in Sports City township — ideal first investment. '
        'RERA-approved. Assured rental of ₹18,000/mo for 3 years from developer.',
    'heroImageUrl': _imgApartment[0],
    'additionalImageUrls': [_imgApartment[2]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 29,
    'viewsCount': 398,
    'commentsCount': 4,
    'daysAgo': 12,
  },

  // ── INVESTOR DEALS (4) ──────────────────────────────────────────────────
  {
    'brokerUid': 'seed_u3',
    'brokerName': 'Arjun Mehta',
    'brokerPhone': '9900112233',
    'brokerPhotoUrl': _avatar('Arjun Mehta'),
    'posterRole': 'investor',
    'category': 'investor',
    'propertyType': 'bhk2',
    'city': 'Mumbai',
    'location': 'Powai, Lake-facing Hiranandani Gardens',
    'area': 1100.0,
    'areaUnit': 'sqFt',
    'price': 16500000.0,
    'description': 'Occupied 2 BHK with lake view generating ₹65,000/month rental income. '
        'Current yield: 4.7% annually — best in Powai micro-market.',
    'heroImageUrl': _imgApartment[1],
    'additionalImageUrls': [_imgModernHome[0], _imgLuxury[0]],
    'brokerageAmount': '1.5%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 58,
    'viewsCount': 811,
    'commentsCount': 12,
    'daysAgo': 3,
  },
  {
    'brokerUid': 'seed_u6',
    'brokerName': 'Neha Desai',
    'brokerPhone': '9820111222',
    'brokerPhotoUrl': _avatar('Neha Desai'),
    'posterRole': 'broker',
    'category': 'investor',
    'propertyType': 'shopOffice',
    'city': 'Mumbai',
    'location': 'BKC, G Block',
    'area': 1800.0,
    'areaUnit': 'sqFt',
    'price': 55000000.0,
    'description': 'Grade-A commercial floor in BKC — fully leased to MNC at '
        '₹4.2 L/month. Lease term: 5+5 years. Yield: 9.1% p.a.',
    'heroImageUrl': _imgOffice[0],
    'additionalImageUrls': [_imgOffice[1], _imgOffice[2]],
    'brokerageAmount': '1%',
    'visibility': 'network',
    'status': 'active',
    'likesCount': 74,
    'viewsCount': 1089,
    'commentsCount': 17,
    'daysAgo': 5,
  },
  {
    'brokerUid': 'seed_u3',
    'brokerName': 'Arjun Mehta',
    'brokerPhone': '9900112233',
    'brokerPhotoUrl': _avatar('Arjun Mehta'),
    'posterRole': 'investor',
    'category': 'investor',
    'propertyType': 'land',
    'city': 'Bengaluru',
    'location': 'Devanahalli, Near BIAL',
    'area': 10890.0,
    'areaUnit': 'sqFt',
    'price': 32000000.0,
    'description': 'Agricultural land (convertible) near BIAL — 1 acre. '
        'Surrounded by IT park and residential projects. BIAL expansion zone.',
    'heroImageUrl': _imgPlot[0],
    'additionalImageUrls': [_imgPlot[1], _imgConstruction[0]],
    'brokerageAmount': '1.5%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 44,
    'viewsCount': 622,
    'commentsCount': 9,
    'daysAgo': 9,
  },
  {
    'brokerUid': 'seed_u8',
    'brokerName': 'Anjali Chopra',
    'brokerPhone': '9876543210',
    'brokerPhotoUrl': _avatar('Anjali Chopra'),
    'posterRole': 'investor',
    'category': 'investor',
    'propertyType': 'warehouse',
    'city': 'Thane',
    'location': 'Bhiwandi, NH-48 Logistics Hub',
    'area': 12000.0,
    'areaUnit': 'sqFt',
    'price': 48000000.0,
    'description': 'Grade-A warehouse on NH-48, Bhiwandi. '
        '12,000 sq.ft ground floor + 2,000 sq.ft mezzanine. Leased at ₹3.8 L/mo.',
    'heroImageUrl': _imgWarehouse[0],
    'additionalImageUrls': [_imgWarehouse[1], _imgCommercial[0]],
    'brokerageAmount': '1%',
    'visibility': 'network',
    'status': 'active',
    'likesCount': 31,
    'viewsCount': 443,
    'commentsCount': 6,
    'daysAgo': 14,
  },

  // ── DISCOUNT DEALS (5) ──────────────────────────────────────────────────
  {
    'brokerUid': 'seed_u1',
    'brokerName': 'Rajesh Kumar',
    'brokerPhone': '9821234567',
    'brokerPhotoUrl': _avatar('Rajesh Kumar'),
    'posterRole': 'broker',
    'category': 'discount',
    'propertyType': 'bhk2',
    'city': 'Mumbai',
    'location': 'Kurla West, LBS Marg',
    'area': 750.0,
    'areaUnit': 'sqFt',
    'price': 5200000.0,
    'originalPrice': 7500000.0,
    'description': 'Bank auction property — below market rate. '
        'Clear title post-auction, OC in hand. 2 BHK with 1 car park. Ready to move in.',
    'heroImageUrl': _imgApartment[2],
    'additionalImageUrls': [_imgModernHome[2]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 112,
    'viewsCount': 1842,
    'commentsCount': 28,
    'daysAgo': 1,
  },
  {
    'brokerUid': 'seed_u2',
    'brokerName': 'Priya Sharma',
    'brokerPhone': '9765432100',
    'brokerPhotoUrl': _avatar('Priya Sharma'),
    'posterRole': 'broker',
    'category': 'discount',
    'propertyType': 'bhk3',
    'city': 'Pune',
    'location': 'Baner, Sus Road',
    'area': 1450.0,
    'areaUnit': 'sqFt',
    'price': 7200000.0,
    'originalPrice': 9500000.0,
    'description': 'Distress sale — owner needs funds urgently. '
        '3 BHK semi-furnished in gated society with gym, pool. Saving ₹23 L.',
    'heroImageUrl': _imgModernHome[1],
    'additionalImageUrls': [_imgApartment[1], _imgModernHome[0]],
    'brokerageAmount': '1.5%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 96,
    'viewsCount': 1531,
    'commentsCount': 22,
    'daysAgo': 2,
  },
  {
    'brokerUid': 'seed_u3',
    'brokerName': 'Arjun Mehta',
    'brokerPhone': '9900112233',
    'brokerPhotoUrl': _avatar('Arjun Mehta'),
    'posterRole': 'investor',
    'category': 'discount',
    'propertyType': 'bhk2',
    'city': 'Bengaluru',
    'location': 'HSR Layout, Sector 2',
    'area': 1250.0,
    'areaUnit': 'sqFt',
    'price': 8500000.0,
    'originalPrice': 11000000.0,
    'description': 'Resale flat in premium HSR Layout at 23% below current market. '
        'Seller relocating to US. Fully furnished. Immediate registration possible.',
    'heroImageUrl': _imgApartment[0],
    'additionalImageUrls': [_imgModernHome[0], _imgLuxury[0]],
    'brokerageAmount': '1%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 82,
    'viewsCount': 1109,
    'commentsCount': 15,
    'daysAgo': 3,
  },
  {
    'brokerUid': 'seed_u4',
    'brokerName': 'Sunita Patel',
    'brokerPhone': '9712345678',
    'brokerPhotoUrl': _avatar('Sunita Patel'),
    'posterRole': 'owner',
    'category': 'discount',
    'propertyType': 'villa',
    'city': 'Pune',
    'location': 'Lonavala, Amby Valley Road',
    'area': 2600.0,
    'areaUnit': 'sqFt',
    'price': 12000000.0,
    'originalPrice': 18000000.0,
    'description': '4 BHK weekend villa — 33% off market rate. '
        'Private pool, 4-car garage, fully furnished, hill view.',
    'heroImageUrl': _imgVilla[1],
    'additionalImageUrls': [_imgVilla[0], _imgLuxury[2]],
    'brokerageAmount': '1%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 145,
    'viewsCount': 2203,
    'commentsCount': 34,
    'daysAgo': 6,
  },
  {
    'brokerUid': 'seed_u1',
    'brokerName': 'Rajesh Kumar',
    'brokerPhone': '9821234567',
    'brokerPhotoUrl': _avatar('Rajesh Kumar'),
    'posterRole': 'broker',
    'category': 'discount',
    'propertyType': 'plot',
    'city': 'Navi Mumbai',
    'location': 'Kharghar, Sector 12',
    'area': 900.0,
    'areaUnit': 'sqFt',
    'price': 3200000.0,
    'originalPrice': 4500000.0,
    'description': 'NA plot in Kharghar — CIDCO-approved layout. '
        '30×30 corner plot, 40-ft road, all utilities. Clearance sale.',
    'heroImageUrl': _imgPlot[0],
    'additionalImageUrls': [_imgPlot[1]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 53,
    'viewsCount': 712,
    'commentsCount': 10,
    'daysAgo': 4,
  },

  // ── RENTAL DEALS (5) ────────────────────────────────────────────────────
  {
    'brokerUid': 'seed_u6',
    'brokerName': 'Neha Desai',
    'brokerPhone': '9820111222',
    'brokerPhotoUrl': _avatar('Neha Desai'),
    'posterRole': 'broker',
    'category': 'rental',
    'propertyType': 'bhk2',
    'city': 'Mumbai',
    'location': 'Powai, Central Avenue, Hiranandani',
    'area': 1050.0,
    'areaUnit': 'sqFt',
    'price': 45000.0,
    'description': 'Fully furnished 2 BHK — lake view, modular kitchen, 2 ACs. '
        'Society amenities: gym, pool. Available 1st next month.',
    'heroImageUrl': _imgApartment[1],
    'additionalImageUrls': [_imgModernHome[0], _imgLuxury[0]],
    'brokerageAmount': '1 month rent',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 68,
    'viewsCount': 934,
    'commentsCount': 14,
    'daysAgo': 1,
  },
  {
    'brokerUid': 'seed_u10',
    'brokerName': 'Pooja Iyer',
    'brokerPhone': '9944221133',
    'brokerPhotoUrl': _avatar('Pooja Iyer'),
    'posterRole': 'broker',
    'category': 'rental',
    'propertyType': 'bhk3',
    'city': 'Bengaluru',
    'location': 'Koramangala, 6th Block',
    'area': 1650.0,
    'areaUnit': 'sqFt',
    'price': 55000.0,
    'description': 'Semi-furnished 3 BHK in premium Koramangala society. '
        'Wardrobes, chimney, hot water geyser included. Pet-friendly.',
    'heroImageUrl': _imgApartment[0],
    'additionalImageUrls': [_imgModernHome[1]],
    'brokerageAmount': '1 month rent',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 49,
    'viewsCount': 671,
    'commentsCount': 8,
    'daysAgo': 2,
  },
  {
    'brokerUid': 'seed_u5',
    'brokerName': 'Vikram Singh',
    'brokerPhone': '9811223344',
    'brokerPhotoUrl': _avatar('Vikram Singh'),
    'posterRole': 'builder',
    'category': 'rental',
    'propertyType': 'studio',
    'city': 'Delhi',
    'location': 'Connaught Place, Inner Circle',
    'area': 600.0,
    'areaUnit': 'sqFt',
    'price': 35000.0,
    'description': 'Premium studio office space in CP — fully serviced. '
        'Dedicated cabin, high-speed fibre, 24x7 access, CCTV, reception.',
    'heroImageUrl': _imgOffice[1],
    'additionalImageUrls': [_imgOffice[2]],
    'brokerageAmount': '15 days rent',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 33,
    'viewsCount': 445,
    'commentsCount': 5,
    'daysAgo': 3,
  },
  {
    'brokerUid': 'seed_u2',
    'brokerName': 'Priya Sharma',
    'brokerPhone': '9765432100',
    'brokerPhotoUrl': _avatar('Priya Sharma'),
    'posterRole': 'broker',
    'category': 'rental',
    'propertyType': 'shopOffice',
    'city': 'Pune',
    'location': 'FC Road, Model Colony',
    'area': 380.0,
    'areaUnit': 'sqFt',
    'price': 22000.0,
    'description': 'Busy FC Road ground-floor shop — high footfall. '
        'Glass facade, 12-ft ceiling, 1 car park, power backup.',
    'heroImageUrl': _imgCommercial[0],
    'additionalImageUrls': [_imgCommercial[1]],
    'brokerageAmount': '1 month rent',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 27,
    'viewsCount': 388,
    'commentsCount': 6,
    'daysAgo': 5,
  },
  {
    'brokerUid': 'seed_u10',
    'brokerName': 'Pooja Iyer',
    'brokerPhone': '9944221133',
    'brokerPhotoUrl': _avatar('Pooja Iyer'),
    'posterRole': 'broker',
    'category': 'rental',
    'propertyType': 'bhk1',
    'city': 'Chennai',
    'location': 'Adyar, Gandhi Nagar',
    'area': 580.0,
    'areaUnit': 'sqFt',
    'price': 14000.0,
    'description': 'Cosy 1 BHK near Adyar river — bachelor/couple friendly. '
        'Painted fresh, tiled flooring, water purifier.',
    'heroImageUrl': _imgModernHome[2],
    'additionalImageUrls': [],
    'visibility': 'all',
    'status': 'active',
    'likesCount': 18,
    'viewsCount': 251,
    'commentsCount': 3,
    'daysAgo': 7,
  },

  // ── COMMERCIAL DEALS (4) ─────────────────────────────────────────────────
  {
    'brokerUid': 'seed_u7',
    'brokerName': 'Ramesh Nair',
    'brokerPhone': '9988776655',
    'brokerPhotoUrl': _avatar('Ramesh Nair'),
    'posterRole': 'broker',
    'category': 'commercial',
    'propertyType': 'shopOffice',
    'city': 'Hyderabad',
    'location': 'HITEC City, Madhapur',
    'area': 2500.0,
    'areaUnit': 'sqFt',
    'price': 32000000.0,
    'description': 'Strata office floor in Grade-A HITEC City tower. '
        '2,500 sq.ft — can be leased or sold. Ready for immediate fit-out.',
    'heroImageUrl': _imgOffice[0],
    'additionalImageUrls': [_imgOffice[1], _imgCommercial[2]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 41,
    'viewsCount': 589,
    'commentsCount': 8,
    'daysAgo': 4,
  },
  {
    'brokerUid': 'seed_u5',
    'brokerName': 'Vikram Singh',
    'brokerPhone': '9811223344',
    'brokerPhotoUrl': _avatar('Vikram Singh'),
    'posterRole': 'builder',
    'category': 'commercial',
    'propertyType': 'shopOffice',
    'city': 'Delhi',
    'location': 'Connaught Place, Block A',
    'area': 1200.0,
    'areaUnit': 'sqFt',
    'price': 36000000.0,
    'description': 'Rare CP retail space — ground floor, corner unit. '
        'Previously: luxury watch outlet. Annual appreciation 12%+ historically.',
    'heroImageUrl': _imgCommercial[1],
    'additionalImageUrls': [_imgCommercial[0], _imgOffice[2]],
    'brokerageAmount': '1.5%',
    'visibility': 'network',
    'status': 'active',
    'likesCount': 76,
    'viewsCount': 1033,
    'commentsCount': 18,
    'daysAgo': 8,
  },
  {
    'brokerUid': 'seed_u6',
    'brokerName': 'Neha Desai',
    'brokerPhone': '9820111222',
    'brokerPhotoUrl': _avatar('Neha Desai'),
    'posterRole': 'broker',
    'category': 'commercial',
    'propertyType': 'warehouse',
    'city': 'Pune',
    'location': 'Hinjewadi Phase 2, IT Park',
    'area': 8000.0,
    'areaUnit': 'sqFt',
    'price': 72000000.0,
    'description': 'Large-format IT park space — 8,000 sq.ft bare-shell. '
        'Rooftop solar, EV charging, 3-tier security. Possession: June 2025.',
    'heroImageUrl': _imgOffice[2],
    'additionalImageUrls': [_imgOffice[0], _imgWarehouse[0]],
    'brokerageAmount': '1%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 34,
    'viewsCount': 478,
    'commentsCount': 7,
    'daysAgo': 11,
  },
  {
    'brokerUid': 'seed_u7',
    'brokerName': 'Ramesh Nair',
    'brokerPhone': '9988776655',
    'brokerPhotoUrl': _avatar('Ramesh Nair'),
    'posterRole': 'broker',
    'category': 'commercial',
    'propertyType': 'shopOffice',
    'city': 'Hyderabad',
    'location': 'Banjara Hills, Road No. 12',
    'area': 1800.0,
    'areaUnit': 'sqFt',
    'price': 25000000.0,
    'description': 'Premium Banjara Hills showroom on Road 12. '
        'Ground + mezzanine, 14-ft ceiling, 3 glass facades. Lease or purchase.',
    'heroImageUrl': _imgCommercial[0],
    'additionalImageUrls': [_imgCommercial[2], _imgOffice[1]],
    'brokerageAmount': '1.5%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 28,
    'viewsCount': 391,
    'commentsCount': 5,
    'daysAgo': 13,
  },

  // ── URGENT SALE (4) ─────────────────────────────────────────────────────
  {
    'brokerUid': 'seed_u1',
    'brokerName': 'Rajesh Kumar',
    'brokerPhone': '9821234567',
    'brokerPhotoUrl': _avatar('Rajesh Kumar'),
    'posterRole': 'broker',
    'category': 'urgentSale',
    'propertyType': 'bhk2',
    'city': 'Mumbai',
    'location': 'Borivali West, Ekta Nagar',
    'area': 900.0,
    'areaUnit': 'sqFt',
    'price': 7800000.0,
    'originalPrice': 9200000.0,
    'description': 'NRI owner urgent sale — must close in 15 days. '
        '2 BHK, 9th floor, city view. Priced at ₹78 L vs market ₹92 L.',
    'heroImageUrl': _imgApartment[2],
    'additionalImageUrls': [_imgModernHome[1]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 134,
    'viewsCount': 2108,
    'commentsCount': 41,
    'daysAgo': 1,
  },
  {
    'brokerUid': 'seed_u2',
    'brokerName': 'Priya Sharma',
    'brokerPhone': '9765432100',
    'brokerPhotoUrl': _avatar('Priya Sharma'),
    'posterRole': 'broker',
    'category': 'urgentSale',
    'propertyType': 'bhk3',
    'city': 'Pune',
    'location': 'Hadapsar, Magarpatta Road',
    'area': 1300.0,
    'areaUnit': 'sqFt',
    'price': 5800000.0,
    'originalPrice': 7500000.0,
    'description': 'Medical emergency sale — family needs cash within 7 days. '
        '3 BHK near Magarpatta IT hub. OC in hand, loan-approved property.',
    'heroImageUrl': _imgModernHome[0],
    'additionalImageUrls': [_imgApartment[1]],
    'brokerageAmount': '1%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 189,
    'viewsCount': 3241,
    'commentsCount': 56,
    'daysAgo': 0,
  },
  {
    'brokerUid': 'seed_u8',
    'brokerName': 'Anjali Chopra',
    'brokerPhone': '9876543210',
    'brokerPhotoUrl': _avatar('Anjali Chopra'),
    'posterRole': 'investor',
    'category': 'urgentSale',
    'propertyType': 'bhk4',
    'city': 'Gurugram',
    'location': 'Golf Course Road, DLF Phase 5',
    'area': 3500.0,
    'areaUnit': 'sqFt',
    'price': 28500000.0,
    'originalPrice': 36000000.0,
    'description': 'Luxury 4 BHK + servant room in DLF Phase 5 — motivated seller. '
        'Italian marble, Kohler fittings, Häfele kitchen, 3 car parks.',
    'heroImageUrl': _imgLuxury[1],
    'additionalImageUrls': [_imgLuxury[0], _imgLuxury[2]],
    'brokerageAmount': '0.75%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 228,
    'viewsCount': 3897,
    'commentsCount': 63,
    'daysAgo': 2,
  },
  {
    'brokerUid': 'seed_u6',
    'brokerName': 'Neha Desai',
    'brokerPhone': '9820111222',
    'brokerPhotoUrl': _avatar('Neha Desai'),
    'posterRole': 'broker',
    'category': 'urgentSale',
    'propertyType': 'bhk1',
    'city': 'Mumbai',
    'location': 'Andheri East, JB Nagar',
    'area': 650.0,
    'areaUnit': 'sqFt',
    'price': 4800000.0,
    'originalPrice': 6200000.0,
    'description': 'Relocating overseas — selling 1 BHK below market in 10 days. '
        'Vacant possession, freshly painted, OC + NOC ready. Saving ₹14 L.',
    'heroImageUrl': _imgModernHome[2],
    'additionalImageUrls': [_imgApartment[0]],
    'brokerageAmount': '2%',
    'visibility': 'all',
    'status': 'active',
    'likesCount': 97,
    'viewsCount': 1452,
    'commentsCount': 23,
    'daysAgo': 1,
  },
];
