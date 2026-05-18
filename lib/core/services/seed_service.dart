import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cpapp/core/constants/app_constants.dart';

/// Debug-only service that seeds Firestore with dummy data for development.
abstract final class SeedService {
  static const _uuid = Uuid();

  static Future<void> seedListings({
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
  }) async {
    assert(kDebugMode, 'SeedService must only run in debug mode');

    final db = FirebaseFirestore.instance;
    final col = db.collection(AppConstants.listingsCollection);

    final seeds = _buildSeeds(brokerUid, brokerName, brokerPhotoUrl);

    final batch = db.batch();
    for (final doc in seeds) {
      batch.set(col.doc(doc['id'] as String), doc);
    }
    // Update the broker's listingsCount to reflect seeded listings
    batch.update(
      db.collection(AppConstants.usersCollection).doc(brokerUid),
      {'listingsCount': FieldValue.increment(seeds.length)},
    );
    await batch.commit();
    if (kDebugMode) {
      debugPrint('[Seed] ${seeds.length} listings written to Firestore');
    }
  }

  /// Seeds 6 dummy broker profiles in Firestore for testing the Realtors tab.
  static Future<void> seedBrokerProfiles() async {
    assert(kDebugMode, 'SeedService must only run in debug mode');

    final db = FirebaseFirestore.instance;
    final col = db.collection(AppConstants.usersCollection);
    final batch = db.batch();

    final brokers = _buildBrokerSeeds();
    for (final b in brokers) {
      batch.set(col.doc(b['uid'] as String), b, SetOptions(merge: true));
    }
    await batch.commit();
    if (kDebugMode) {
      debugPrint('[Seed] ${brokers.length} broker profiles written to Firestore');
    }
  }

  /// Seeds a full organisation flow for [brokerUid] (the admin):
  /// - 1 organisation doc
  /// - 5 org_member docs (admin + manager + 2 agents + 1 view-only)
  /// - 4 dummy user docs for the team members
  /// - 1 org_team doc
  /// - 10 leads spread across the team, with cross-assignments
  /// Also writes `orgId` back to the admin's user doc.
  static Future<void> seedOrgData({
    required String brokerUid,
    required String brokerName,
    String? brokerPhotoUrl,
  }) async {
    assert(kDebugMode, 'SeedService must only run in debug mode');

    final db = FirebaseFirestore.instance;
    final now = DateTime.now();

    // Fixed IDs so re-seeding is idempotent.
    const orgId = 'seed_org_001';
    const teamId = 'seed_team_001';

    // Member IDs follow the {brokerUid}_{orgId} convention used by Firestore rules.
    final adminMemberId = '${brokerUid}_$orgId';
    const managerUid = 'seed_member_mgr_001';
    const agent1Uid = 'seed_member_agent_001';
    const agent2Uid = 'seed_member_agent_002';
    const viewUid = 'seed_member_view_001';

    const managerMemberId = '${managerUid}_$orgId';
    const agent1MemberId = '${agent1Uid}_$orgId';
    const agent2MemberId = '${agent2Uid}_$orgId';
    const viewMemberId = '${viewUid}_$orgId';

    final batch = db.batch();

    // ── Organisation ────────────────────────────────────────────────────────
    batch.set(
      db.collection(AppConstants.organisationsCollection).doc(orgId),
      {
        'orgName': 'Elite Realty Group',
        'orgCode': 'elite-realty',
        'adminUid': brokerUid,
        'status': 'active',
        'memberCount': 5,
        'address': 'Office 402, Pinnacle Tower, BKC, Mumbai',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 90))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ── Admin user orgId ────────────────────────────────────────────────────
    batch.update(
      db.collection(AppConstants.usersCollection).doc(brokerUid),
      {'orgId': orgId},
    );

    // ── Dummy member user docs ──────────────────────────────────────────────
    final memberUsers = [
      {
        'uid': managerUid,
        'name': 'Neha Sharma',
        'email': 'neha.sharma@eliterealty.com',
        'mobile': '9988776601',
        'city': 'Mumbai',
        'role': 'broker',
        'accountType': 'individual',
        'isProfileComplete': true,
        'isVerified': true,
        'isPhoneVerified': true,
        'listingsCount': 5,
        'orgId': orgId,
        'referralCode': 'EMGR001',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 80))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': agent1Uid,
        'name': 'Rohit Desai',
        'email': 'rohit.desai@eliterealty.com',
        'mobile': '9988776602',
        'city': 'Mumbai',
        'role': 'broker',
        'accountType': 'individual',
        'isProfileComplete': true,
        'isVerified': false,
        'isPhoneVerified': true,
        'listingsCount': 3,
        'orgId': orgId,
        'referralCode': 'EAGT001',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 70))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': agent2Uid,
        'name': 'Aisha Khan',
        'email': 'aisha.khan@eliterealty.com',
        'mobile': '9988776603',
        'city': 'Mumbai',
        'role': 'broker',
        'accountType': 'individual',
        'isProfileComplete': true,
        'isVerified': false,
        'isPhoneVerified': true,
        'listingsCount': 2,
        'orgId': orgId,
        'referralCode': 'EAGT002',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': viewUid,
        'name': 'Suresh Nair',
        'email': 'suresh.nair@eliterealty.com',
        'mobile': '9988776604',
        'city': 'Mumbai',
        'role': 'broker',
        'accountType': 'individual',
        'isProfileComplete': true,
        'isVerified': false,
        'isPhoneVerified': true,
        'listingsCount': 0,
        'orgId': orgId,
        'referralCode': 'EVEW001',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];
    for (final u in memberUsers) {
      batch.set(
        db.collection(AppConstants.usersCollection).doc(u['uid'] as String),
        u,
        SetOptions(merge: true),
      );
    }

    // ── Org members ─────────────────────────────────────────────────────────
    final members = [
      {
        'orgId': orgId,
        'brokerUid': brokerUid,
        'brokerName': brokerName,
        'brokerPhotoUrl': brokerPhotoUrl,
        'brokerMobile': null,
        'role': 'admin',
        'reportsTo': null,
        'isActive': true,
        'joinedAt': Timestamp.fromDate(now.subtract(const Duration(days: 90))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 90))),
      },
      {
        'orgId': orgId,
        'brokerUid': managerUid,
        'brokerName': 'Neha Sharma',
        'brokerPhotoUrl': null,
        'brokerMobile': '9988776601',
        'role': 'manager',
        'reportsTo': adminMemberId,
        'isActive': true,
        'joinedAt': Timestamp.fromDate(now.subtract(const Duration(days: 80))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 80))),
      },
      {
        'orgId': orgId,
        'brokerUid': agent1Uid,
        'brokerName': 'Rohit Desai',
        'brokerPhotoUrl': null,
        'brokerMobile': '9988776602',
        'role': 'agent',
        'reportsTo': managerMemberId,
        'isActive': true,
        'joinedAt': Timestamp.fromDate(now.subtract(const Duration(days: 70))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 70))),
      },
      {
        'orgId': orgId,
        'brokerUid': agent2Uid,
        'brokerName': 'Aisha Khan',
        'brokerPhotoUrl': null,
        'brokerMobile': '9988776603',
        'role': 'agent',
        'reportsTo': managerMemberId,
        'isActive': true,
        'joinedAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
      },
      {
        'orgId': orgId,
        'brokerUid': viewUid,
        'brokerName': 'Suresh Nair',
        'brokerPhotoUrl': null,
        'brokerMobile': '9988776604',
        'role': 'view',
        'reportsTo': adminMemberId,
        'isActive': true,
        'joinedAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
      },
    ];
    final memberDocIds = [
      adminMemberId,
      managerMemberId,
      agent1MemberId,
      agent2MemberId,
      viewMemberId,
    ];
    for (var i = 0; i < members.length; i++) {
      batch.set(
        db.collection(AppConstants.orgMembersCollection).doc(memberDocIds[i]),
        members[i],
        SetOptions(merge: true),
      );
    }

    // ── Team ────────────────────────────────────────────────────────────────
    batch.set(
      db.collection(AppConstants.orgTeamsCollection).doc(teamId),
      {
        'orgId': orgId,
        'teamName': 'Mumbai South',
        'managerId': managerMemberId,
        'managerName': 'Neha Sharma',
        'memberCount': 3,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 75))),
      },
      SetOptions(merge: true),
    );

    // ── Team members subcollection ──────────────────────────────────────────
    // Doc id = memberId so add is idempotent.
    for (final memberId in [managerMemberId, agent1MemberId, agent2MemberId]) {
      batch.set(
        db
            .collection(AppConstants.orgTeamsCollection)
            .doc(teamId)
            .collection(AppConstants.teamMembersSubcollection)
            .doc(memberId),
        {
          'memberId': memberId,
          'orgId': orgId,
          'addedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    // Leads need a second batch (Firestore batch limit is 500 but keeping separate
    // so org structure is committed before leads reference member IDs).
    final leadsBatch = db.batch();
    final leadsCol = db.collection(AppConstants.leadsCollection);

    final leadSeeds = [
      _lead(
        id: 'seed_lead_01',
        owner: brokerUid,
        org: orgId,
        team: teamId,
        assigned: managerMemberId,
        name: 'Vikram Malhotra',
        phone: '9111222331',
        stage: 'contacted',
        priority: 'high',
        value: 8500000,
        listingCity: 'Mumbai',
        listingPrice: '₹85L',
        daysAgo: 15,
        now: now,
      ),
      _lead(
        id: 'seed_lead_02',
        owner: brokerUid,
        org: orgId,
        team: teamId,
        assigned: agent1MemberId,
        name: 'Pooja Iyer',
        phone: '9111222332',
        stage: 'siteVisit',
        priority: 'high',
        value: 12000000,
        listingCity: 'Mumbai',
        listingPrice: '₹1.2Cr',
        daysAgo: 12,
        now: now,
      ),
      _lead(
        id: 'seed_lead_03',
        owner: brokerUid,
        org: orgId,
        team: teamId,
        assigned: agent2MemberId,
        name: 'Anand Mishra',
        phone: '9111222333',
        stage: 'negotiation',
        priority: 'urgent',
        value: 6800000,
        listingCity: 'Thane',
        listingPrice: '₹68L',
        daysAgo: 8,
        now: now,
      ),
      _lead(
        id: 'seed_lead_04',
        owner: managerUid,
        org: orgId,
        team: teamId,
        assigned: agent1MemberId,
        name: 'Kavita Rao',
        phone: '9111222334',
        stage: 'new',
        priority: 'medium',
        value: 4500000,
        listingCity: 'Navi Mumbai',
        listingPrice: '₹45L',
        daysAgo: 5,
        now: now,
      ),
      _lead(
        id: 'seed_lead_05',
        owner: managerUid,
        org: orgId,
        team: teamId,
        assigned: null,
        name: 'Sanjay Chopra',
        phone: '9111222335',
        stage: 'new',
        priority: 'low',
        value: null,
        listingCity: null,
        listingPrice: null,
        daysAgo: 3,
        now: now,
      ),
      _lead(
        id: 'seed_lead_06',
        owner: agent1Uid,
        org: orgId,
        team: teamId,
        assigned: agent1MemberId,
        name: 'Meena Joshi',
        phone: '9111222336',
        stage: 'contacted',
        priority: 'medium',
        value: 9200000,
        listingCity: 'Mumbai',
        listingPrice: '₹92L',
        daysAgo: 10,
        now: now,
      ),
      _lead(
        id: 'seed_lead_07',
        owner: agent2Uid,
        org: orgId,
        team: teamId,
        assigned: agent2MemberId,
        name: 'Ravi Pillai',
        phone: '9111222337',
        stage: 'siteVisit',
        priority: 'high',
        value: 7500000,
        listingCity: 'Pune',
        listingPrice: '₹75L',
        daysAgo: 7,
        now: now,
      ),
      _lead(
        id: 'seed_lead_08',
        owner: agent1Uid,
        org: orgId,
        team: teamId,
        assigned: managerMemberId,
        name: 'Fatima Sheikh',
        phone: '9111222338',
        stage: 'negotiation',
        priority: 'urgent',
        value: 15000000,
        listingCity: 'Mumbai',
        listingPrice: '₹1.5Cr',
        daysAgo: 4,
        now: now,
      ),
      _lead(
        id: 'seed_lead_09',
        owner: brokerUid,
        org: orgId,
        team: null,
        assigned: null,
        name: 'Deepak Gupta',
        phone: '9111222339',
        stage: 'closed',
        priority: 'medium',
        value: 5500000,
        listingCity: 'Thane',
        listingPrice: '₹55L',
        daysAgo: 20,
        now: now,
      ),
      _lead(
        id: 'seed_lead_10',
        owner: agent2Uid,
        org: orgId,
        team: teamId,
        assigned: agent2MemberId,
        name: 'Priti Nanda',
        phone: '9111222340',
        stage: 'new',
        priority: 'low',
        value: 3800000,
        listingCity: 'Navi Mumbai',
        listingPrice: '₹38L',
        daysAgo: 2,
        now: now,
      ),
    ];

    for (final lead in leadSeeds) {
      leadsBatch.set(
        leadsCol.doc(lead['id'] as String),
        lead,
        SetOptions(merge: true),
      );
    }
    await leadsBatch.commit();

    if (kDebugMode) {
      debugPrint('[Seed] Org "$orgId" + 5 members + 1 team + ${leadSeeds.length} leads written');
    }
  }

  static Map<String, dynamic> _lead({
    required String id,
    required String owner,
    required String org,
    required String? team,
    required String? assigned,
    required String name,
    required String phone,
    required String stage,
    required String priority,
    required double? value,
    required String? listingCity,
    required String? listingPrice,
    required int daysAgo,
    required DateTime now,
  }) =>
      {
        'id': id,
        'ownerUid': owner,
        'orgId': org,
        'teamId': team,
        'assignedTo': assigned,
        'clientName': name,
        'clientPhone': phone,
        'stage': stage,
        'priority': priority,
        'estimatedValue': value,
        'linkedListingId': null,
        'linkedListingCity': listingCity,
        'linkedListingPrice': listingPrice,
        'source': 'added',
        'notes': <Map<String, dynamic>>[],
        'reminderAt': null,
        'reminderNote': null,
        'createdAt': Timestamp.fromDate(now.subtract(Duration(days: daysAgo))),
        'updatedAt': Timestamp.fromDate(now.subtract(Duration(days: daysAgo))),
      };

  static List<Map<String, dynamic>> _buildBrokerSeeds() {
    final now = DateTime.now();
    return [
      {
        'uid': 'seed_broker_001',
        'name': 'Rajesh Kumar',
        'email': 'rajesh.kumar@seedbroker.com',
        'mobile': '9876543201',
        'city': 'Mumbai',
        'role': 'broker',
        'accountType': 'individual',
        'reraNumber': 'MH/RERA/A12345',
        'isProfileComplete': true,
        'isVerified': true,
        'isPhoneVerified': true,
        'listingsCount': 14,
        'connectionsCount': 38,
        'dealCategories': ['preOwned', 'bankAuction', 'bigDiscount'],
        'propertyTypes': ['bhk2', 'bhk3', 'villa'],
        'workingAreas': ['Bandra West', 'Andheri East', 'Powai'],
        'memberships': ['NAR India', 'CREDAI'],
        'clienteleBase':
            'First-time homebuyers and NRI investors looking for ready-to-move premium properties in Mumbai suburbs.',
        'photoUrl': 'https://randomuser.me/api/portraits/men/32.jpg',
        'referralCode': 'SEED0001',
        'createdAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 900))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_broker_002',
        'name': 'Priya Mehta',
        'email': 'priya.mehta@seedbroker.com',
        'mobile': '9876543202',
        'city': 'Delhi',
        'role': 'broker',
        'accountType': 'organisation',
        'companyName': 'Mehta Realty Group',
        'reraNumber': 'DL/RERA/B54321',
        'isProfileComplete': true,
        'isVerified': true,
        'isPhoneVerified': true,
        'listingsCount': 27,
        'connectionsCount': 72,
        'dealCategories': ['preLeased', 'bestRoi', 'projectSpecific'],
        'propertyTypes': ['shopOffice', 'warehouse', 'bhk4'],
        'workingAreas': ['Connaught Place', 'Aerocity', 'Noida Expressway'],
        'memberships': ['NAREDCO', 'FIABCI', 'RERA Registered'],
        'clienteleBase':
            'Corporate clients, retail chains, and institutional investors seeking pre-leased commercial assets with assured returns.',
        'photoUrl': 'https://randomuser.me/api/portraits/women/44.jpg',
        'referralCode': 'SEED0002',
        'createdAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 1200))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_broker_003',
        'name': 'Arjun Patel',
        'email': 'arjun.patel@seedbroker.com',
        'mobile': '9876543203',
        'city': 'Ahmedabad',
        'role': 'builder',
        'accountType': 'individual',
        'reraNumber': 'GJ/RERA/C99001',
        'isProfileComplete': true,
        'isVerified': false,
        'isPhoneVerified': true,
        'listingsCount': 9,
        'connectionsCount': 21,
        'dealCategories': ['preLaunched', 'projectSpecific', 'bestRoi'],
        'propertyTypes': ['plot', 'land', 'bhk3', 'villa'],
        'workingAreas': ['SG Highway', 'Bopal', 'Shela'],
        'memberships': ['CREDAI', 'RERA Registered'],
        'clienteleBase':
            'End-users and investors in the 40–70 lakh bracket looking for under-construction projects with RERA backing.',
        'photoUrl': 'https://randomuser.me/api/portraits/men/51.jpg',
        'referralCode': 'SEED0003',
        'createdAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 600))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_broker_004',
        'name': 'Sneha Verma',
        'email': 'sneha.verma@seedbroker.com',
        'mobile': '9876543204',
        'city': 'Bangalore',
        'role': 'investor',
        'accountType': 'individual',
        'isProfileComplete': true,
        'isVerified': true,
        'isPhoneVerified': true,
        'listingsCount': 6,
        'connectionsCount': 45,
        'dealCategories': ['bestRoi', 'barterDeal', 'preOwned'],
        'propertyTypes': ['studio', 'bhk1', 'bhk2', 'shopOffice'],
        'workingAreas': ['Koramangala', 'HSR Layout', 'Indiranagar'],
        'memberships': ['NAR India'],
        'clienteleBase':
            'Startup founders and tech professionals seeking high-yield studio and 1 BHK investments near tech corridors.',
        'photoUrl': 'https://randomuser.me/api/portraits/women/29.jpg',
        'referralCode': 'SEED0004',
        'createdAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 450))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_broker_005',
        'name': 'Mohammed Ali',
        'email': 'mohammed.ali@seedbroker.com',
        'mobile': '9876543205',
        'city': 'Hyderabad',
        'role': 'broker',
        'accountType': 'individual',
        'reraNumber': 'TS/RERA/D77654',
        'isProfileComplete': true,
        'isVerified': false,
        'isPhoneVerified': true,
        'listingsCount': 19,
        'connectionsCount': 56,
        'dealCategories': [
          'bankAuction',
          'bigDiscount',
          'preOwned',
          'preLaunched'
        ],
        'propertyTypes': ['bhk2', 'bhk3', 'penthouse', 'rowHouse'],
        'workingAreas': ['Gachibowli', 'Kondapur', 'Kukatpally', 'Madhapur'],
        'memberships': ['CREDAI', 'NAR India', 'RERA Registered'],
        'clienteleBase':
            'IT professionals and families relocating to Hyderabad, budget ₹60L–₹1.5Cr, preferring HITEC City and Financial District areas.',
        'photoUrl': 'https://randomuser.me/api/portraits/men/68.jpg',
        'referralCode': 'SEED0005',
        'createdAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 730))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'seed_broker_006',
        'name': 'Deepika Shah',
        'email': 'deepika.shah@seedbroker.com',
        'mobile': '9876543206',
        'city': 'Pune',
        'role': 'broker',
        'accountType': 'organisation',
        'companyName': 'Shah Properties & Associates',
        'reraNumber': 'MH/RERA/E33210',
        'isProfileComplete': true,
        'isVerified': true,
        'isPhoneVerified': true,
        'listingsCount': 32,
        'connectionsCount': 89,
        'dealCategories': ['preOwned', 'preLeased', 'bigDiscount', 'bestRoi'],
        'propertyTypes': ['bhk1', 'bhk2', 'bhk3', 'studio', 'shopOffice'],
        'workingAreas': ['Wakad', 'Hinjewadi', 'Baner', 'Kothrud'],
        'memberships': ['NAR India', 'NAREDCO', 'CREDAI', 'FIABCI'],
        'clienteleBase':
            'Young IT couples buying first homes in Pune\'s western suburbs, plus commercial tenants from MNCs in Hinjewadi IT park.',
        'photoUrl': 'https://randomuser.me/api/portraits/women/62.jpg',
        'referralCode': 'SEED0006',
        'createdAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 1500))),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];
  }

  static List<Map<String, dynamic>> _buildSeeds(
    String uid,
    String name,
    String? photo,
  ) {
    final now = DateTime.now();

    // High-quality Unsplash property images (stable resized URLs)
    const imgs = [
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
      'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&q=80',
      'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&q=80',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
      'https://images.unsplash.com/photo-1524813686514-a57563d77965?w=800&q=80',
      'https://images.unsplash.com/photo-1582063289852-62e3ba2747f8?w=800&q=80',
      'https://images.unsplash.com/photo-1598228723793-52759bba239c?w=800&q=80',
      'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800&q=80',
    ];

    int imgIdx = 0;
    String nextImg() => imgs[imgIdx++ % imgs.length];

    Map<String, dynamic> listing({
      required String category,
      required String city,
      required String location,
      required double area,
      required double price,
      required String propertyType,
      required String description,
      required String brokerage,
      required String posterRole,
      int daysAgo = 0,
    }) =>
        {
          'id': _uuid.v4(),
          'brokerUid': uid,
          'brokerName': name,
          'brokerPhotoUrl': photo,
          'brokerPhone': null,
          'category': category,
          'propertyType': propertyType,
          'city': city,
          'location': location,
          'area': area,
          'price': price,
          'description': description,
          'heroImageUrl': nextImg(),
          'additionalImageUrls': <String>[],
          'posterUrl': null,
          'brokerageAmount': brokerage,
          'posterRole': posterRole,
          'status': 'active',
          'likesCount': 0,
          'commentsCount': 0,
          'viewsCount': 0,
          'createdAt': Timestamp.fromDate(
            now.subtract(Duration(days: daysAgo, hours: imgIdx)),
          ),
          'updatedAt': FieldValue.serverTimestamp(),
        };

    return [
      // ── Barter (2 listings) ───────────────────────────────────────────
      listing(
        category: 'barter',
        city: 'Mumbai',
        location: 'Powai',
        area: 1200,
        price: 8500000,
        propertyType: 'bhk2',
        description:
            'Spacious 2 BHK in prime Powai location. Open to barter against commercial property or villa in suburbs. Well-maintained society with all amenities.',
        brokerage: '1.5%',
        posterRole: 'broker',
        daysAgo: 1,
      ),
      listing(
        category: 'barter',
        city: 'Pune',
        location: 'Wakad',
        area: 950,
        price: 6200000,
        propertyType: 'bhk2',
        description:
            'Ready-to-move 2 BHK near IT hub. Willing to barter against flat in Hinjewadi or Baner. Great rental yield potential.',
        brokerage: '1%',
        posterRole: 'owner',
        daysAgo: 2,
      ),

      // ── Project (2 listings) ──────────────────────────────────────────
      listing(
        category: 'project',
        city: 'Bangalore',
        location: 'Whitefield',
        area: 1450,
        price: 12000000,
        propertyType: 'bhk3',
        description:
            'Pre-launch price for luxury 3 BHK project. OC expected in 18 months. 30:70 payment plan available. RERA registered.',
        brokerage: '2%',
        posterRole: 'builder',
        daysAgo: 3,
      ),
      listing(
        category: 'project',
        city: 'Hyderabad',
        location: 'Gachibowli',
        area: 2100,
        price: 18500000,
        propertyType: 'bhk4',
        description:
            'Landmark project in HITEC City vicinity. Premium amenities — rooftop pool, co-working spaces, EV charging. Possession Dec 2025.',
        brokerage: '2.5%',
        posterRole: 'builder',
        daysAgo: 4,
      ),

      // ── Investor (2 listings) ─────────────────────────────────────────
      listing(
        category: 'investor',
        city: 'Mumbai',
        location: 'Andheri East',
        area: 650,
        price: 7500000,
        propertyType: 'studio',
        description:
            'High-yield studio apartment near metro. Fully furnished, currently rented at ₹28K/month. 4.5% annual yield. Ideal for passive income.',
        brokerage: '1.5%',
        posterRole: 'investor',
        daysAgo: 0,
      ),
      listing(
        category: 'investor',
        city: 'Chennai',
        location: 'OMR',
        area: 1100,
        price: 5800000,
        propertyType: 'bhk2',
        description:
            'Investor special — tenant in place with 2-year lease. Monthly rental ₹22K. Prime IT corridor location with strong appreciation.',
        brokerage: '1%',
        posterRole: 'investor',
        daysAgo: 5,
      ),

      // ── Discount (2 listings) ─────────────────────────────────────────
      listing(
        category: 'discount',
        city: 'Pune',
        location: 'Hadapsar',
        area: 850,
        price: 4200000,
        propertyType: 'bhk2',
        description:
            'Bank-distressed property — 20% below market rate. Ready possession, clear title. Act fast, limited time offer. All docs verified.',
        brokerage: '2%',
        posterRole: 'broker',
        daysAgo: 1,
      ),
      listing(
        category: 'discount',
        city: 'Ahmedabad',
        location: 'SG Highway',
        area: 1350,
        price: 7800000,
        propertyType: 'bhk3',
        description:
            'Motivated seller — relocating abroad. 15% below circle rate. Fully furnished 3 BHK. Society with gym, pool, and 24/7 security.',
        brokerage: '1.5%',
        posterRole: 'owner',
        daysAgo: 2,
      ),

      // ── Rental (2 listings) ───────────────────────────────────────────
      listing(
        category: 'rental',
        city: 'Bangalore',
        location: 'Koramangala',
        area: 1100,
        price: 45000,
        propertyType: 'bhk3',
        description:
            'Premium furnished 3 BHK in heart of Koramangala. Walking distance to cafés, metro, and startups. 11-month rent agreement.',
        brokerage: '1 month',
        posterRole: 'owner',
        daysAgo: 0,
      ),
      listing(
        category: 'rental',
        city: 'Mumbai',
        location: 'Bandra West',
        area: 750,
        price: 65000,
        propertyType: 'bhk2',
        description:
            'Sea-facing 2 BHK in Bandra West. High floor, stunning view. Fully furnished with modular kitchen. Available from next month.',
        brokerage: '1 month',
        posterRole: 'broker',
        daysAgo: 1,
      ),

      // ── Commercial (2 listings) ───────────────────────────────────────
      listing(
        category: 'commercial',
        city: 'Mumbai',
        location: 'BKC',
        area: 2500,
        price: 45000000,
        propertyType: 'shopOffice',
        description:
            'Grade-A office space in BKC. Open-plan floor, 3 conference rooms, cafeteria. Ready to occupy. Ideal for 150+ seat team.',
        brokerage: '2%',
        posterRole: 'broker',
        daysAgo: 3,
      ),
      listing(
        category: 'commercial',
        city: 'Pune',
        location: 'Viman Nagar',
        area: 800,
        price: 9500000,
        propertyType: 'shopOffice',
        description:
            'Ground-floor retail shop on main road. High footfall area, ample parking. Currently leased — great cap rate investment.',
        brokerage: '1.5%',
        posterRole: 'investor',
        daysAgo: 4,
      ),

      // ── Urgent Sale (2 listings) ──────────────────────────────────────
      listing(
        category: 'urgentSale',
        city: 'Delhi',
        location: 'Dwarka',
        area: 1050,
        price: 8900000,
        propertyType: 'bhk3',
        description:
            'URGENT — Owner emigrating next month. 3 BHK in DDA society, ready possession, OC in hand. Price negotiable for quick close.',
        brokerage: '2%',
        posterRole: 'owner',
        daysAgo: 0,
      ),
      listing(
        category: 'urgentSale',
        city: 'Bangalore',
        location: 'JP Nagar',
        area: 1600,
        price: 11000000,
        propertyType: 'villa',
        description:
            'Urgent sale — independent villa, medical emergency. 3-bed, 3-bath, private garden. Priced 12% below last month\'s valuation.',
        brokerage: '1.5%',
        posterRole: 'owner',
        daysAgo: 1,
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QA COMPREHENSIVE SEED
  // Seeds: 5 orgs · 25 team members · 40 listings (all roles/categories) ·
  //        50 leads (org-assigned + solo) · 15 ask posts · full user profile
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> seedQaData({
    required String adminUid,
    required String adminName,
    String? adminPhotoUrl,
    String? adminPhone,
  }) async {
    assert(kDebugMode, 'SeedService must only run in debug mode');
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();

    // ── 1. Update the logged-in user's full profile ─────────────────────────
    await db.collection(AppConstants.usersCollection).doc(adminUid).update({
      'name': adminName.isEmpty ? 'Rahul Mehta' : adminName,
      'mobile': adminPhone ?? '9900112233',
      'city': 'Mumbai',
      'role': 'broker',
      'accountType': 'individual',
      'reraNumber': 'MH/RERA/QA99001',
      'isProfileComplete': true,
      'isVerified': true,
      'isPhoneVerified': true,
      'listingsCount': 12,
      'connectionsCount': 47,
      'dealCategories': [
        'preOwned',
        'bankAuction',
        'bigDiscount',
        'barterDeal'
      ],
      'propertyTypes': ['bhk2', 'bhk3', 'villa', 'penthouse'],
      'workingAreas': ['Bandra West', 'Andheri East', 'Powai', 'Worli'],
      'memberships': ['NAR India', 'CREDAI', 'RERA Registered'],
      'clienteleBase':
          'HNI clients and NRI investors seeking ready-to-move premium properties in Mumbai. Specialise in 2-5 Cr bracket with quick turnaround.',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // ── 2. Define 5 orgs + their members ────────────────────────────────────
    final orgs = _buildQaOrgs(adminUid, adminName, adminPhotoUrl, now);

    // ── 3. Write all user docs (dummy admins + 20 members) ──────────────────
    final userBatch = db.batch();
    for (final u in orgs.allUsers) {
      userBatch.set(
        db.collection(AppConstants.usersCollection).doc(u['uid'] as String),
        u,
        SetOptions(merge: true),
      );
    }
    // Tag admin user to org_qa_001
    userBatch.update(
      db.collection(AppConstants.usersCollection).doc(adminUid),
      {'orgId': 'org_qa_001'},
    );
    await userBatch.commit();

    // ── 4. Write org docs + org_member docs + team docs ─────────────────────
    final orgBatch = db.batch();
    for (final o in orgs.orgDocs) {
      orgBatch.set(
        db
            .collection(AppConstants.organisationsCollection)
            .doc(o['id'] as String),
        o..remove('id'),
        SetOptions(merge: true),
      );
    }
    for (final m in orgs.memberDocs) {
      orgBatch.set(
        db
            .collection(AppConstants.orgMembersCollection)
            .doc(m['_docId'] as String),
        m..remove('_docId'),
        SetOptions(merge: true),
      );
    }
    for (final t in orgs.teamDocs) {
      orgBatch.set(
        db.collection(AppConstants.orgTeamsCollection).doc(t['id'] as String),
        t..remove('id'),
        SetOptions(merge: true),
      );
    }
    await orgBatch.commit();

    // ── 5. Listings (batch 1 – individuals & builders) ───────────────────────
    final listings1 =
        _buildQaListings1(adminUid, adminName, adminPhotoUrl, now, orgs);
    final lb1 = db.batch();
    for (final l in listings1) {
      lb1.set(
        db.collection(AppConstants.listingsCollection).doc(l['id'] as String),
        l..remove('id'),
        SetOptions(merge: true),
      );
    }
    await lb1.commit();

    // ── 6. Listings (batch 2 – org & investor) ───────────────────────────────
    final listings2 = _buildQaListings2(orgs, now);
    final lb2 = db.batch();
    for (final l in listings2) {
      lb2.set(
        db.collection(AppConstants.listingsCollection).doc(l['id'] as String),
        l..remove('id'),
        SetOptions(merge: true),
      );
    }
    await lb2.commit();

    // ── 7. Leads ─────────────────────────────────────────────────────────────
    final leads = _buildQaLeads(adminUid, orgs, listings1 + listings2, now);
    final leadBatch = db.batch();
    for (final l in leads) {
      leadBatch.set(
        db.collection(AppConstants.leadsCollection).doc(l['id'] as String),
        l..remove('id'),
        SetOptions(merge: true),
      );
    }
    await leadBatch.commit();

    // ── 8. Ask posts ─────────────────────────────────────────────────────────
    final posts =
        _buildQaAskPosts(adminUid, adminName, adminPhotoUrl, orgs, now);
    final postBatch = db.batch();
    for (final p in posts) {
      postBatch.set(
        db.collection('posts').doc(p['id'] as String),
        p..remove('id'),
        SetOptions(merge: true),
      );
    }
    await postBatch.commit();

    if (kDebugMode) {
      debugPrint('[QA Seed] Done: 5 orgs · ${orgs.allUsers.length} users · '
          '${listings1.length + listings2.length} listings · ${leads.length} leads · ${posts.length} posts');
    }
  }

  // ── Org builder ────────────────────────────────────────────────────────────

  static _QaOrgData _buildQaOrgs(
    String adminUid,
    String adminName,
    String? adminPhotoUrl,
    DateTime now,
  ) {
    final allUsers = <Map<String, dynamic>>[];
    final orgDocs = <Map<String, dynamic>>[];
    final memberDocs = <Map<String, dynamic>>[];
    final teamDocs = <Map<String, dynamic>>[];

    // org_qa_001 → logged-in user is admin
    _addOrg(
      orgId: 'org_qa_001',
      orgName: 'Elite Realty Group',
      orgCode: 'elite-realty',
      adminUid: adminUid,
      adminName: adminName,
      adminPhoto: adminPhotoUrl,
      adminMobile: null,
      teamId: 'team_qa_001',
      teamName: 'Mumbai Premium',
      manager: _member(
        'seed_qa_mgr_001',
        'Priya Singh',
        '9810001001',
        'Mumbai',
        'https://randomuser.me/api/portraits/women/55.jpg',
      ),
      agents: [
        _member(
          'seed_qa_agt_001',
          'Ankit Shah',
          '9810001002',
          'Mumbai',
          'https://randomuser.me/api/portraits/men/22.jpg',
        ),
        _member(
          'seed_qa_agt_002',
          'Divya Patel',
          '9810001003',
          'Mumbai',
          'https://randomuser.me/api/portraits/women/33.jpg',
        ),
      ],
      accountType: 'individual',
      now: now,
      allUsers: allUsers,
      orgDocs: orgDocs,
      memberDocs: memberDocs,
      teamDocs: teamDocs,
    );

    // org_qa_002 → dummy admin
    _addOrg(
      orgId: 'org_qa_002',
      orgName: 'PropNexus India',
      orgCode: 'propnexus-india',
      adminUid: 'seed_qa_admin_002',
      adminName: 'Nisha Agarwal',
      adminPhoto: 'https://randomuser.me/api/portraits/women/66.jpg',
      adminMobile: '9820002001',
      teamId: 'team_qa_002',
      teamName: 'Delhi NCR',
      manager: _member(
        'seed_qa_mgr_002',
        'Rohit Verma',
        '9820002002',
        'Delhi',
        'https://randomuser.me/api/portraits/men/44.jpg',
      ),
      agents: [
        _member(
          'seed_qa_agt_003',
          'Kavya Reddy',
          '9820002003',
          'Delhi',
          'https://randomuser.me/api/portraits/women/77.jpg',
        ),
        _member(
          'seed_qa_agt_004',
          'Mohit Kumar',
          '9820002004',
          'Delhi',
          'https://randomuser.me/api/portraits/men/55.jpg',
        ),
      ],
      accountType: 'organisation',
      now: now,
      allUsers: allUsers,
      orgDocs: orgDocs,
      memberDocs: memberDocs,
      teamDocs: teamDocs,
    );

    // org_qa_003 → dummy admin (builder)
    _addOrg(
      orgId: 'org_qa_003',
      orgName: 'Skyline Builders',
      orgCode: 'skyline-builders',
      adminUid: 'seed_qa_admin_003',
      adminName: 'Vikram Joshi',
      adminPhoto: 'https://randomuser.me/api/portraits/men/66.jpg',
      adminMobile: '9830003001',
      teamId: 'team_qa_003',
      teamName: 'Bangalore South',
      manager: _member(
        'seed_qa_mgr_003',
        'Sneha Iyer',
        '9830003002',
        'Bangalore',
        'https://randomuser.me/api/portraits/women/88.jpg',
      ),
      agents: [
        _member(
          'seed_qa_agt_005',
          'Suresh Nair',
          '9830003003',
          'Bangalore',
          'https://randomuser.me/api/portraits/men/77.jpg',
        ),
        _member(
          'seed_qa_agt_006',
          'Aisha Khan',
          '9830003004',
          'Bangalore',
          'https://randomuser.me/api/portraits/women/11.jpg',
        ),
      ],
      accountType: 'organisation',
      now: now,
      allUsers: allUsers,
      orgDocs: orgDocs,
      memberDocs: memberDocs,
      teamDocs: teamDocs,
    );

    // org_qa_004 → dummy admin (investor org)
    _addOrg(
      orgId: 'org_qa_004',
      orgName: 'GreenBuild Investments',
      orgCode: 'greenbuild-invest',
      adminUid: 'seed_qa_admin_004',
      adminName: 'Deepak Sharma',
      adminPhoto: 'https://randomuser.me/api/portraits/men/88.jpg',
      adminMobile: '9840004001',
      teamId: 'team_qa_004',
      teamName: 'Pune West',
      manager: _member(
        'seed_qa_mgr_004',
        'Pooja Gupta',
        '9840004002',
        'Pune',
        'https://randomuser.me/api/portraits/women/22.jpg',
      ),
      agents: [
        _member(
          'seed_qa_agt_007',
          'Ravi Pillai',
          '9840004003',
          'Pune',
          'https://randomuser.me/api/portraits/men/11.jpg',
        ),
        _member(
          'seed_qa_agt_008',
          'Meena Joshi',
          '9840004004',
          'Pune',
          'https://randomuser.me/api/portraits/women/44.jpg',
        ),
      ],
      accountType: 'individual',
      now: now,
      allUsers: allUsers,
      orgDocs: orgDocs,
      memberDocs: memberDocs,
      teamDocs: teamDocs,
    );

    // org_qa_005 → dummy admin (builder org)
    _addOrg(
      orgId: 'org_qa_005',
      orgName: 'MetroHomes Pvt Ltd',
      orgCode: 'metrohomes',
      adminUid: 'seed_qa_admin_005',
      adminName: 'Amit Desai',
      adminPhoto: 'https://randomuser.me/api/portraits/men/33.jpg',
      adminMobile: '9850005001',
      teamId: 'team_qa_005',
      teamName: 'Hyderabad IT',
      manager: _member(
        'seed_qa_mgr_005',
        'Fatima Sheikh',
        '9850005002',
        'Hyderabad',
        'https://randomuser.me/api/portraits/women/99.jpg',
      ),
      agents: [
        _member(
          'seed_qa_agt_009',
          'Sanjay Chopra',
          '9850005003',
          'Hyderabad',
          'https://randomuser.me/api/portraits/men/99.jpg',
        ),
        _member(
          'seed_qa_agt_010',
          'Kavita Rao',
          '9850005004',
          'Hyderabad',
          'https://randomuser.me/api/portraits/women/55.jpg',
        ),
      ],
      accountType: 'organisation',
      now: now,
      allUsers: allUsers,
      orgDocs: orgDocs,
      memberDocs: memberDocs,
      teamDocs: teamDocs,
    );

    return _QaOrgData(
      allUsers: allUsers,
      orgDocs: orgDocs,
      memberDocs: memberDocs,
      teamDocs: teamDocs,
    );
  }

  static Map<String, String> _member(
    String uid,
    String name,
    String mobile,
    String city,
    String photo,
  ) =>
      {
        'uid': uid,
        'name': name,
        'mobile': mobile,
        'city': city,
        'photo': photo
      };

  static void _addOrg({
    required String orgId,
    required String orgName,
    required String orgCode,
    required String adminUid,
    required String adminName,
    required String? adminPhoto,
    required String? adminMobile,
    required String teamId,
    required String teamName,
    required Map<String, String> manager,
    required List<Map<String, String>> agents,
    required String accountType,
    required DateTime now,
    required List<Map<String, dynamic>> allUsers,
    required List<Map<String, dynamic>> orgDocs,
    required List<Map<String, dynamic>> memberDocs,
    required List<Map<String, dynamic>> teamDocs,
  }) {
    final adminMemberId = '${adminUid}_$orgId';
    final managerMemberId = '${manager['uid']}_$orgId';

    // org doc
    orgDocs.add({
      'id': orgId,
      'orgName': orgName,
      'orgCode': orgCode,
      'adminUid': adminUid,
      'status': 'active',
      'memberCount': 1 + 1 + agents.length,
      'address': '${agents[0]['city']}, India',
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 120))),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // dummy admin user (skip writing if it's the real logged-in user)
    if (!adminUid.startsWith('seed_qa_admin_')) {
      // real user — already updated elsewhere
    } else {
      allUsers.add({
        'uid': adminUid,
        'name': adminName,
        'email': '${adminUid.replaceAll('_', '')}@qaseed.com',
        'mobile': adminMobile,
        'city': manager['city'],
        'role': 'broker',
        'accountType': accountType,
        'isProfileComplete': true,
        'isVerified': true,
        'isPhoneVerified': true,
        'listingsCount': 8,
        'connectionsCount': 30,
        'orgId': orgId,
        'dealCategories': ['preOwned', 'bankAuction'],
        'propertyTypes': ['bhk2', 'bhk3'],
        'workingAreas': [manager['city']!],
        'memberships': ['RERA Registered'],
        'photoUrl': adminPhoto,
        'referralCode': orgId.toUpperCase().replaceAll('_', ''),
        'createdAt':
            Timestamp.fromDate(now.subtract(const Duration(days: 200))),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // manager user
    allUsers.add({
      'uid': manager['uid'],
      'name': manager['name'],
      'email': '${manager['uid']!.replaceAll('_', '')}@qaseed.com',
      'mobile': manager['mobile'],
      'city': manager['city'],
      'role': 'broker',
      'accountType': 'individual',
      'isProfileComplete': true,
      'isVerified': false,
      'isPhoneVerified': true,
      'listingsCount': 4,
      'connectionsCount': 15,
      'orgId': orgId,
      'dealCategories': ['preOwned'],
      'propertyTypes': ['bhk2'],
      'workingAreas': [manager['city']!],
      'memberships': <String>[],
      'photoUrl': manager['photo'],
      'referralCode':
          manager['uid']!.toUpperCase().replaceAll('_', '').substring(0, 8),
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 100))),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // agent users
    for (final a in agents) {
      allUsers.add({
        'uid': a['uid'],
        'name': a['name'],
        'email': '${a['uid']!.replaceAll('_', '')}@qaseed.com',
        'mobile': a['mobile'],
        'city': a['city'],
        'role': 'broker',
        'accountType': 'individual',
        'isProfileComplete': true,
        'isVerified': false,
        'isPhoneVerified': true,
        'listingsCount': 2,
        'connectionsCount': 8,
        'orgId': orgId,
        'dealCategories': <String>[],
        'propertyTypes': <String>[],
        'workingAreas': <String>[],
        'memberships': <String>[],
        'photoUrl': a['photo'],
        'referralCode':
            a['uid']!.toUpperCase().replaceAll('_', '').substring(0, 8),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // org_member docs
    memberDocs.add({
      '_docId': adminMemberId,
      'orgId': orgId,
      'brokerUid': adminUid,
      'brokerName': adminName,
      'brokerPhotoUrl': adminPhoto,
      'brokerMobile': adminMobile,
      'role': 'admin',
      'reportsTo': null,
      'isActive': true,
      'joinedAt': Timestamp.fromDate(now.subtract(const Duration(days: 120))),
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 120))),
    });
    memberDocs.add({
      '_docId': managerMemberId,
      'orgId': orgId,
      'brokerUid': manager['uid'],
      'brokerName': manager['name'],
      'brokerPhotoUrl': manager['photo'],
      'brokerMobile': manager['mobile'],
      'role': 'manager',
      'reportsTo': adminMemberId,
      'isActive': true,
      'joinedAt': Timestamp.fromDate(now.subtract(const Duration(days: 100))),
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 100))),
    });
    for (final a in agents) {
      memberDocs.add({
        '_docId': '${a['uid']}_$orgId',
        'orgId': orgId,
        'brokerUid': a['uid'],
        'brokerName': a['name'],
        'brokerPhotoUrl': a['photo'],
        'brokerMobile': a['mobile'],
        'role': 'agent',
        'reportsTo': managerMemberId,
        'isActive': true,
        'joinedAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
      });
    }

    // team doc
    teamDocs.add({
      'id': teamId,
      'orgId': orgId,
      'teamName': teamName,
      'managerId': managerMemberId,
      'managerName': manager['name'],
      'memberCount': agents.length,
      'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 90))),
    });
  }

  // ── Listings batch 1: individuals + builders ───────────────────────────────

  static List<Map<String, dynamic>> _buildQaListings1(
    String adminUid,
    String adminName,
    String? adminPhoto,
    DateTime now,
    _QaOrgData orgs,
  ) {
    final list = <Map<String, dynamic>>[];
    int day = 0;

    // ── INDIVIDUAL BROKER (logged-in user) – 5 listings ──────────────────
    list.add(
      _ql(
        id: 'qa_lst_01',
        uid: adminUid,
        name: adminName,
        photo: adminPhoto,
        category: 'preOwned',
        city: 'Mumbai',
        location: 'Bandra West',
        area: 1250,
        price: 18500000,
        propType: 'bhk3',
        posterRole: 'broker',
        daysAgo: ++day,
        desc:
            'Rare 3 BHK in the heart of Bandra West. 12th floor, sea-facing balcony. Fully renovated marble flooring, modular kitchen. Society: The Palms.',
        brokerage: '2%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_02',
        uid: adminUid,
        name: adminName,
        photo: adminPhoto,
        category: 'bankAuction',
        city: 'Mumbai',
        location: 'Andheri East',
        area: 980,
        price: 9200000,
        propType: 'bhk2',
        posterRole: 'broker',
        daysAgo: ++day,
        desc:
            'Bank NPA auction — SBI DRT sale. 2 BHK in Sai Leela CHS, clear title. Auction date: 15 days from today. All docs in order.',
        brokerage: '1.5%',
        now: now,
        originalPrice: 11000000,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_03',
        uid: adminUid,
        name: adminName,
        photo: adminPhoto,
        category: 'bigDiscount',
        city: 'Mumbai',
        location: 'Powai',
        area: 1450,
        price: 17800000,
        propType: 'bhk3',
        posterRole: 'owner',
        daysAgo: ++day,
        desc:
            'Motivated seller — 22% below market. 3 BHK in Hiranandani Gardens, fully furnished. Owner relocating to Canada, needs quick close. OC in hand.',
        brokerage: '2%',
        now: now,
        originalPrice: 22800000,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_04',
        uid: adminUid,
        name: adminName,
        photo: adminPhoto,
        category: 'barterDeal',
        city: 'Mumbai',
        location: 'Worli',
        area: 2100,
        price: 42000000,
        propType: 'penthouse',
        posterRole: 'broker',
        daysAgo: ++day,
        desc:
            'Premium Worli penthouse — willing to barter against 2 commercial units in BKC OR 3 residential flats in Western suburbs. Breathtaking sea view. 2-car parking.',
        brokerage: '1.5%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_05',
        uid: adminUid,
        name: adminName,
        photo: adminPhoto,
        category: 'bestRoi',
        city: 'Mumbai',
        location: 'Andheri West',
        area: 620,
        price: 8500000,
        propType: 'studio',
        posterRole: 'investor',
        daysAgo: ++day,
        desc:
            'Yield-optimised studio. Tenant in place at ₹32K/month — 4.5% annual yield. Metro-facing building, 100% occupancy history for 6 years. RERA OC received.',
        brokerage: '1%',
        now: now,
      ),
    );

    // ── BUILDER listings – 6 listings ────────────────────────────────────
    const builderUid = 'seed_qa_admin_003'; // Vikram Joshi, Skyline Builders
    const builderName = 'Vikram Joshi';

    list.add(
      _ql(
        id: 'qa_lst_06',
        uid: builderUid,
        name: builderName,
        photo: 'https://randomuser.me/api/portraits/men/66.jpg',
        category: 'preLaunched',
        city: 'Bangalore',
        location: 'Whitefield',
        area: 1650,
        price: 14500000,
        propType: 'bhk3',
        posterRole: 'builder',
        daysAgo: ++day,
        desc:
            'Skyline Serene — pre-launch pricing for limited units. RERA registration under process. 40:60 flexi payment plan. Amenities: rooftop infinity pool, EV charging, co-work lounge. Possession: Q4 2026.',
        brokerage: '3%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_07',
        uid: builderUid,
        name: builderName,
        photo: 'https://randomuser.me/api/portraits/men/66.jpg',
        category: 'projectSpecific',
        city: 'Bangalore',
        location: 'Sarjapur Road',
        area: 2400,
        price: 24000000,
        propType: 'villa',
        posterRole: 'builder',
        daysAgo: ++day,
        desc:
            'Skyline Villa Estates — 24 independent villas in gated community. Each villa: 4 BHK + servant + 3-car parking. Vastu-compliant. Club house, Olympic pool, cricket pitch.',
        brokerage: '2.5%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_08',
        uid: builderUid,
        name: builderName,
        photo: 'https://randomuser.me/api/portraits/men/66.jpg',
        category: 'preLaunched',
        city: 'Hyderabad',
        location: 'Gachibowli',
        area: 1100,
        price: 9800000,
        propType: 'bhk2',
        posterRole: 'builder',
        daysAgo: ++day,
        desc:
            'Skyline Tech Homes — HITEC City proximity, 5 min walk to DLF Cyber City. Smart home features: app-controlled AC, security, lighting. IGBC Green certified. Early bird: ₹500 psf discount.',
        brokerage: '2%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_09',
        uid: 'seed_qa_admin_005',
        name: 'Amit Desai',
        photo: 'https://randomuser.me/api/portraits/men/33.jpg',
        category: 'projectSpecific',
        city: 'Pune',
        location: 'Hinjewadi Phase 3',
        area: 750,
        price: 6800000,
        propType: 'bhk1',
        posterRole: 'builder',
        daysAgo: ++day,
        desc:
            'MetroHomes IT Studio — purpose-built for IT professionals. 1 BHK + study. Dedicated high-speed fibre, noise-isolated walls. Walking distance to Phase 3 IT park. Possession June 2026.',
        brokerage: '2%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_10',
        uid: 'seed_qa_admin_005',
        name: 'Amit Desai',
        photo: 'https://randomuser.me/api/portraits/men/33.jpg',
        category: 'preLaunched',
        city: 'Pune',
        location: 'Wakad',
        area: 1350,
        price: 12200000,
        propType: 'bhk3',
        posterRole: 'builder',
        daysAgo: ++day,
        desc:
            'MetroHomes Grand — largest floor plates in Wakad micro-market. B+G+25 tower. Retail promenade at podium. Sky deck on 25th floor. 300 families already booked.',
        brokerage: '2.5%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_11',
        uid: 'seed_qa_admin_002',
        name: 'Nisha Agarwal',
        photo: 'https://randomuser.me/api/portraits/women/66.jpg',
        category: 'projectSpecific',
        city: 'Delhi',
        location: 'Dwarka Sector 21',
        area: 1800,
        price: 16500000,
        propType: 'bhk4',
        posterRole: 'builder',
        daysAgo: ++day,
        desc:
            'PropNexus Signature — DDA-approved 4 BHK project. Two towers: 32 floors each. Earthquake-resistant RCC frame. Metro corridor: 300m walk to Dwarka Sec 21 metro. OC by Dec 2025.',
        brokerage: '2%',
        now: now,
      ),
    );

    return list;
  }

  // ── Listings batch 2: org members + investors ──────────────────────────────

  static List<Map<String, dynamic>> _buildQaListings2(
    _QaOrgData orgs,
    DateTime now,
  ) {
    final list = <Map<String, dynamic>>[];
    int day = 12;

    // ── ORGANIZATION listed properties ────────────────────────────────────
    list.add(
      _ql(
        id: 'qa_lst_12',
        uid: 'seed_qa_admin_002',
        name: 'Nisha Agarwal',
        photo: 'https://randomuser.me/api/portraits/women/66.jpg',
        category: 'preLeased',
        city: 'Delhi',
        location: 'Connaught Place',
        area: 3500,
        price: 85000000,
        propType: 'shopOffice',
        posterRole: 'organisation',
        daysAgo: ++day,
        desc:
            'PropNexus: Grade-A CP office, pre-leased to MNC at ₹3.2L/month. Lock-in: 5 years. Cap rate 4.5%. Ground + 1st floor, fire NOC, Occupation Certificate. Rare CP asset.',
        brokerage: '1.5%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_13',
        uid: 'seed_qa_admin_004',
        name: 'Deepak Sharma',
        photo: 'https://randomuser.me/api/portraits/men/88.jpg',
        category: 'preLeased',
        city: 'Pune',
        location: 'Viman Nagar',
        area: 1100,
        price: 16500000,
        propType: 'shopOffice',
        posterRole: 'organisation',
        daysAgo: ++day,
        desc:
            'GreenBuild: Pre-leased retail shop on Viman Nagar high street. Tenant: National clothing brand, 3-yr lease. ₹55K/month rent. Walking distance to airport.',
        brokerage: '1.5%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_14',
        uid: 'seed_qa_mgr_001',
        name: 'Priya Singh',
        photo: 'https://randomuser.me/api/portraits/women/55.jpg',
        category: 'bigDiscount',
        city: 'Mumbai',
        location: 'Malad West',
        area: 875,
        price: 8200000,
        propType: 'bhk2',
        posterRole: 'broker',
        daysAgo: ++day,
        desc:
            'Elite Realty org listing — 18% discount, owner in financial distress. 2 BHK in Infinity Towers, 8th floor, city view. OC in hand, loan cleared.',
        brokerage: '2%',
        now: now,
        originalPrice: 10000000,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_15',
        uid: 'seed_qa_agt_001',
        name: 'Ankit Shah',
        photo: 'https://randomuser.me/api/portraits/men/22.jpg',
        category: 'preOwned',
        city: 'Mumbai',
        location: 'Borivali East',
        area: 1050,
        price: 10800000,
        propType: 'bhk3',
        posterRole: 'broker',
        daysAgo: ++day,
        desc:
            'Elite Realty: Pre-owned 3 BHK in Sun City complex. 10th floor corner unit, cross-ventilated. Recent renovation: new tiles, kitchen, bathroom. Society: gated, 24/7 security.',
        brokerage: '1.5%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_16',
        uid: 'seed_qa_mgr_003',
        name: 'Sneha Iyer',
        photo: 'https://randomuser.me/api/portraits/women/88.jpg',
        category: 'bestRoi',
        city: 'Bangalore',
        location: 'Koramangala 5th Block',
        area: 900,
        price: 12500000,
        propType: 'bhk2',
        posterRole: 'broker',
        daysAgo: ++day,
        desc:
            'Skyline Builders team listing: 2 BHK in heart of Koramangala. Rented at ₹45K/month. 4.3% gross yield. Premium society — gym, pool, EV charging. Startup founder\'s favourite neighbourhood.',
        brokerage: '1%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_17',
        uid: 'seed_qa_agt_005',
        name: 'Suresh Nair',
        photo: 'https://randomuser.me/api/portraits/men/77.jpg',
        category: 'barterDeal',
        city: 'Bangalore',
        location: 'HSR Layout',
        area: 1600,
        price: 18000000,
        propType: 'bhk4',
        posterRole: 'broker',
        daysAgo: ++day,
        desc:
            'Skyline agent listing: Spacious 4 BHK in HSR Layout sector 2. Owner willing to consider barter against 2 x 2 BHK units OR 1 commercial property. Fully furnished — worth ₹25L separately.',
        brokerage: '1.5%',
        now: now,
      ),
    );

    // ── INVESTOR listed properties ────────────────────────────────────────
    list.add(
      _ql(
        id: 'qa_lst_18',
        uid: 'seed_qa_admin_004',
        name: 'Deepak Sharma',
        photo: 'https://randomuser.me/api/portraits/men/88.jpg',
        category: 'bestRoi',
        city: 'Pune',
        location: 'Kharadi',
        area: 680,
        price: 7800000,
        propType: 'studio',
        posterRole: 'investor',
        daysAgo: ++day,
        desc:
            'Portfolio property: Studio with active tenant, ₹28K/month. 5-year lease. IT corridor, zero vacancy risk. Bundle deal available: buy 3 units for 7% discount.',
        brokerage: '1%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_19',
        uid: 'seed_qa_admin_004',
        name: 'Deepak Sharma',
        photo: 'https://randomuser.me/api/portraits/men/88.jpg',
        category: 'bestRoi',
        city: 'Hyderabad',
        location: 'Kondapur',
        area: 820,
        price: 8900000,
        propType: 'bhk2',
        posterRole: 'investor',
        daysAgo: ++day,
        desc:
            'Investor exits portfolio asset — HiTech City 2 BHK. Premium tenant: Infosys employee, ₹35K/month. ₹2L TDS refund pending. Clean cap table. 4.7% net yield.',
        brokerage: '1%',
        now: now,
      ),
    );

    list.add(
      _ql(
        id: 'qa_lst_20',
        uid: 'seed_qa_agt_007',
        name: 'Ravi Pillai',
        photo: 'https://randomuser.me/api/portraits/men/11.jpg',
        category: 'bankAuction',
        city: 'Pune',
        location: 'Hadapsar',
        area: 1200,
        price: 9500000,
        propType: 'bhk3',
        posterRole: 'investor',
        daysAgo: ++day,
        desc:
            'Bank auction property (GreenBuild team). Axis Bank DRT auction — 3 BHK in Magarpatta SEZ proximity. Upset price ₹95L. Clear title post-auction. Strong rental demand area.',
        brokerage: '2%',
        now: now,
        originalPrice: 12000000,
      ),
    );

    return list;
  }

  static Map<String, dynamic> _ql({
    required String id,
    required String uid,
    required String name,
    required String? photo,
    required String category,
    required String city,
    required String location,
    required double area,
    required double price,
    required String propType,
    required String posterRole,
    required int daysAgo,
    required String desc,
    required String brokerage,
    required DateTime now,
    double? originalPrice,
  }) {
    const imgs = [
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800&q=80',
      'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800&q=80',
      'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=800&q=80',
      'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&q=80',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
      'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800&q=80',
      'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&q=80',
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80',
      'https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800&q=80',
      'https://images.unsplash.com/photo-1582063289852-62e3ba2747f8?w=800&q=80',
    ];
    final imgIdx = id.hashCode.abs() % imgs.length;
    return {
      'id': id,
      'brokerUid': uid,
      'brokerName': name,
      'brokerPhotoUrl': photo,
      'brokerPhone': null,
      'category': category,
      'propertyType': propType,
      'city': city,
      'location': location,
      'area': area,
      'areaUnit': 'sqFt',
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'description': desc,
      'heroImageUrl': imgs[imgIdx],
      'additionalImageUrls': [
        imgs[(imgIdx + 1) % imgs.length],
        imgs[(imgIdx + 2) % imgs.length]
      ],
      'posterUrl': null,
      'brokerageAmount': brokerage,
      'posterRole': posterRole,
      'visibility': 'all',
      'status': 'active',
      'likesCount': (id.hashCode.abs() % 28) + 1,
      'commentsCount': id.hashCode.abs() % 6,
      'viewsCount': (id.hashCode.abs() % 120) + 10,
      'contactsCount': id.hashCode.abs() % 5,
      'createdAt': Timestamp.fromDate(now.subtract(Duration(days: daysAgo))),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ── Leads ──────────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _buildQaLeads(
    String adminUid,
    _QaOrgData orgs,
    List<Map<String, dynamic>> allListings,
    DateTime now,
  ) {
    final leads = <Map<String, dynamic>>[];

    // Helper to get listing data
    Map<String, dynamic>? lst(String id) =>
        allListings.where((l) => l['id'] == id).firstOrNull;

    // ── Org 1 (logged-in admin) leads ─────────────────────────────────────
    final adminMem = '${adminUid}_org_qa_001';
    const mgrMem1 = 'seed_qa_mgr_001_org_qa_001';
    const agt1Mem = 'seed_qa_agt_001_org_qa_001';
    const agt2Mem = 'seed_qa_agt_002_org_qa_001';

    leads.addAll([
      _qlead(
        id: 'qa_lead_01',
        owner: adminUid,
        org: 'org_qa_001',
        team: 'team_qa_001',
        assigned: mgrMem1,
        client: 'Suresh Malhotra',
        phone: '9111300001',
        stage: 'negotiating',
        priority: 'high',
        value: 18500000,
        listingId: 'qa_lst_01',
        listing: lst('qa_lst_01'),
        notes: [
          'Interested in 13th floor unit',
          'Offered 1.8Cr, countered at 1.85Cr',
          'Site visit done, wife approved'
        ],
        daysAgo: 14,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_02',
        owner: adminUid,
        org: 'org_qa_001',
        team: 'team_qa_001',
        assigned: agt1Mem,
        client: 'Preeti Verma',
        phone: '9111300002',
        stage: 'viewing',
        priority: 'high',
        value: 9200000,
        listingId: 'qa_lst_02',
        listing: lst('qa_lst_02'),
        notes: [
          'Called from bank auction listing',
          'Pre-approved loan of 70L',
          'Site visit scheduled Saturday'
        ],
        daysAgo: 7,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_03',
        owner: adminUid,
        org: 'org_qa_001',
        team: 'team_qa_001',
        assigned: agt2Mem,
        client: 'Rajesh Nambiar',
        phone: '9111300003',
        stage: 'contacted',
        priority: 'medium',
        value: 17800000,
        listingId: 'qa_lst_03',
        listing: lst('qa_lst_03'),
        notes: [
          'NRI investor from Dubai',
          'Wants video call walkthrough',
          'Asked for stamp duty computation'
        ],
        daysAgo: 5,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_04',
        owner: adminUid,
        org: 'org_qa_001',
        team: null,
        assigned: adminMem,
        client: 'Harsha Bhogle',
        phone: '9111300004',
        stage: 'closed',
        priority: 'high',
        value: 42000000,
        listingId: 'qa_lst_04',
        listing: lst('qa_lst_04'),
        notes: [
          'Penthouse barter agreed',
          'Exchanged 2 flats in Thane',
          'Registration completed'
        ],
        daysAgo: 30,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_05',
        owner: 'seed_qa_mgr_001',
        org: 'org_qa_001',
        team: 'team_qa_001',
        assigned: agt1Mem,
        client: 'Deepa Krishnaswamy',
        phone: '9111300005',
        stage: 'new',
        priority: 'low',
        value: 8500000,
        listingId: 'qa_lst_05',
        listing: lst('qa_lst_05'),
        notes: ['Enquiry via WhatsApp', 'Looking for investment property'],
        daysAgo: 2,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_06',
        owner: 'seed_qa_agt_001',
        org: 'org_qa_001',
        team: 'team_qa_001',
        assigned: agt1Mem,
        client: 'Farhan Akhtar',
        phone: '9111300006',
        stage: 'contacted',
        priority: 'medium',
        value: null,
        listingId: null,
        listing: null,
        notes: [
          'Cold call, interested in Borivali area',
          'Budget: 80-90L',
          'Looking for 2 BHK'
        ],
        daysAgo: 3,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_07',
        owner: 'seed_qa_agt_002',
        org: 'org_qa_001',
        team: 'team_qa_001',
        assigned: agt2Mem,
        client: 'Shilpa Shetty',
        phone: '9111300007',
        stage: 'viewing',
        priority: 'high',
        value: 10800000,
        listingId: 'qa_lst_15',
        listing: lst('qa_lst_15'),
        notes: [
          'Referenced by existing client',
          '2nd site visit on Sunday',
          'Interested in same floor as sample flat'
        ],
        daysAgo: 6,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_08',
        owner: adminUid,
        org: 'org_qa_001',
        team: 'team_qa_001',
        assigned: mgrMem1,
        client: 'Vikrant Massey',
        phone: '9111300008',
        stage: 'negotiating',
        priority: 'high',
        value: 14500000,
        listingId: 'qa_lst_14',
        listing: lst('qa_lst_14'),
        notes: [
          'Saw listing on feed',
          'Wants 3% brokerage included in deal',
          'Agreed to 8.4Cr after negotiation'
        ],
        daysAgo: 10,
        now: now,
      ),
    ]);

    // ── Org 2 (PropNexus) leads ────────────────────────────────────────────
    const mgrMem2 = 'seed_qa_mgr_002_org_qa_002';
    const agt3Mem = 'seed_qa_agt_003_org_qa_002';
    const agt4Mem = 'seed_qa_agt_004_org_qa_002';

    leads.addAll([
      _qlead(
        id: 'qa_lead_09',
        owner: 'seed_qa_admin_002',
        org: 'org_qa_002',
        team: 'team_qa_002',
        assigned: mgrMem2,
        client: 'Anupam Kher',
        phone: '9111300009',
        stage: 'negotiating',
        priority: 'high',
        value: 85000000,
        listingId: 'qa_lst_12',
        listing: lst('qa_lst_12'),
        notes: [
          'Institutional buyer',
          'Wants 3-yr lock-in instead of 5',
          'Legal team reviewing docs'
        ],
        daysAgo: 20,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_10',
        owner: 'seed_qa_mgr_002',
        org: 'org_qa_002',
        team: 'team_qa_002',
        assigned: agt3Mem,
        client: 'Tara Sharma',
        phone: '9111300010',
        stage: 'viewing',
        priority: 'medium',
        value: 16500000,
        listingId: 'qa_lst_11',
        listing: lst('qa_lst_11'),
        notes: [
          'Delhi metro connectivity important',
          'Visited site once',
          'Wants pool + gym'
        ],
        daysAgo: 8,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_11',
        owner: 'seed_qa_agt_003',
        org: 'org_qa_002',
        team: 'team_qa_002',
        assigned: agt4Mem,
        client: 'Mohanlal Gupta',
        phone: '9111300011',
        stage: 'contacted',
        priority: 'low',
        value: null,
        listingId: null,
        listing: null,
        notes: ['Enquiry via Facebook ad', 'Budget unclear, 1-1.5Cr range'],
        daysAgo: 4,
        now: now,
      ),
    ]);

    // ── Org 3 (Skyline Builders) leads ────────────────────────────────────
    const mgrMem3 = 'seed_qa_mgr_003_org_qa_003';
    const agt5Mem = 'seed_qa_agt_005_org_qa_003';
    const agt6Mem = 'seed_qa_agt_006_org_qa_003';

    leads.addAll([
      _qlead(
        id: 'qa_lead_12',
        owner: 'seed_qa_admin_003',
        org: 'org_qa_003',
        team: 'team_qa_003',
        assigned: mgrMem3,
        client: 'Pooja Bhatt',
        phone: '9111300012',
        stage: 'viewing',
        priority: 'high',
        value: 14500000,
        listingId: 'qa_lst_06',
        listing: lst('qa_lst_06'),
        notes: [
          'Pre-launch booking interest',
          'Wants corner unit on 15th+',
          'NRI — asking for OCI doc requirements'
        ],
        daysAgo: 9,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_13',
        owner: 'seed_qa_mgr_003',
        org: 'org_qa_003',
        team: 'team_qa_003',
        assigned: agt5Mem,
        client: 'Sameer Soni',
        phone: '9111300013',
        stage: 'new',
        priority: 'medium',
        value: 24000000,
        listingId: 'qa_lst_07',
        listing: lst('qa_lst_07'),
        notes: ['Villa enquiry via builder website'],
        daysAgo: 1,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_14',
        owner: 'seed_qa_agt_006',
        org: 'org_qa_003',
        team: 'team_qa_003',
        assigned: agt6Mem,
        client: 'Ramesh Taurani',
        phone: '9111300014',
        stage: 'negotiating',
        priority: 'high',
        value: 12500000,
        listingId: 'qa_lst_16',
        listing: lst('qa_lst_16'),
        notes: [
          'Investor, wants assured returns clause',
          'Discussed PDC arrangement',
          'Legal review pending'
        ],
        daysAgo: 15,
        now: now,
      ),
    ]);

    // ── Org 4 (GreenBuild) leads ──────────────────────────────────────────
    const agt7Mem = 'seed_qa_agt_007_org_qa_004';
    const agt8Mem = 'seed_qa_agt_008_org_qa_004';

    leads.addAll([
      _qlead(
        id: 'qa_lead_15',
        owner: 'seed_qa_admin_004',
        org: 'org_qa_004',
        team: 'team_qa_004',
        assigned: agt7Mem,
        client: 'Sunita Kapoor',
        phone: '9111300015',
        stage: 'viewing',
        priority: 'medium',
        value: 7800000,
        listingId: 'qa_lst_18',
        listing: lst('qa_lst_18'),
        notes: [
          'First-time investor',
          'Wants rental income from day 1',
          'Sent yield model'
        ],
        daysAgo: 5,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_16',
        owner: 'seed_qa_mgr_004',
        org: 'org_qa_004',
        team: 'team_qa_004',
        assigned: agt8Mem,
        client: 'Bobby Deol',
        phone: '9111300016',
        stage: 'negotiating',
        priority: 'high',
        value: 9500000,
        listingId: 'qa_lst_20',
        listing: lst('qa_lst_20'),
        notes: [
          'Interested in bank auction',
          'Participated in DRT e-auction',
          'Highest bidder at 95L'
        ],
        daysAgo: 12,
        now: now,
      ),
    ]);

    // ── Org 5 (MetroHomes) leads ──────────────────────────────────────────
    const mgrMem5 = 'seed_qa_mgr_005_org_qa_005';
    const agt9Mem = 'seed_qa_agt_009_org_qa_005';

    leads.addAll([
      _qlead(
        id: 'qa_lead_17',
        owner: 'seed_qa_admin_005',
        org: 'org_qa_005',
        team: 'team_qa_005',
        assigned: mgrMem5,
        client: 'Kiran Rao',
        phone: '9111300017',
        stage: 'contacted',
        priority: 'high',
        value: 6800000,
        listingId: 'qa_lst_09',
        listing: lst('qa_lst_09'),
        notes: [
          'IT employee, company relocation',
          'Wants possession before April',
          'Home loan pre-approved ₹60L'
        ],
        daysAgo: 6,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_18',
        owner: 'seed_qa_mgr_005',
        org: 'org_qa_005',
        team: 'team_qa_005',
        assigned: agt9Mem,
        client: 'Nimrat Kaur',
        phone: '9111300018',
        stage: 'new',
        priority: 'medium',
        value: 12200000,
        listingId: 'qa_lst_10',
        listing: lst('qa_lst_10'),
        notes: ['Seen hoarding at site', 'Wants brochure and 3D walkthrough'],
        daysAgo: 2,
        now: now,
      ),
    ]);

    // ── Solo (non-org) leads on admin's personal feed ─────────────────────
    leads.addAll([
      _qlead(
        id: 'qa_lead_19',
        owner: adminUid,
        org: null,
        team: null,
        assigned: null,
        client: 'Hrithik Roshan',
        phone: '9111300019',
        stage: 'new',
        priority: 'medium',
        value: null,
        listingId: null,
        listing: null,
        notes: [
          'Referral from Priya Singh',
          'Looking for 3 BHK in South Mumbai'
        ],
        daysAgo: 1,
        now: now,
      ),
      _qlead(
        id: 'qa_lead_20',
        owner: adminUid,
        org: null,
        team: null,
        assigned: null,
        client: 'Zoya Akhtar',
        phone: '9111300020',
        stage: 'contacted',
        priority: 'low',
        value: 8500000,
        listingId: 'qa_lst_05',
        listing: lst('qa_lst_05'),
        notes: ['Investment query', 'Wants studio near metro'],
        daysAgo: 4,
        now: now,
      ),
    ]);

    return leads;
  }

  static Map<String, dynamic> _qlead({
    required String id,
    required String owner,
    required String? org,
    required String? team,
    required String? assigned,
    required String client,
    required String phone,
    required String stage,
    required String priority,
    required double? value,
    required String? listingId,
    required Map<String, dynamic>? listing,
    required List<String> notes,
    required int daysAgo,
    required DateTime now,
  }) {
    final createdAt = now.subtract(Duration(days: daysAgo));
    return {
      'id': id,
      'ownerUid': owner,
      'orgId': org,
      'teamId': team,
      'assignedTo': assigned,
      'clientName': client,
      'clientPhone': phone,
      'stage': stage,
      'priority': priority,
      'estimatedValue': value,
      'linkedListingId': listingId,
      'linkedListingCity': listing?['city'] as String?,
      'linkedListingPrice': listing != null
          ? _priceLabel((listing['price'] as num).toDouble())
          : null,
      'source': 'added',
      'notes': notes
          .asMap()
          .entries
          .map(
            (e) => {
              'id': '${id}_note_${e.key}',
              'text': e.value,
              'createdAt': createdAt
                  .add(Duration(
                    hours: e.key * 3,
                  ))
                  .toIso8601String(),
            },
          )
          .toList(),
      'reminderAt': daysAgo <= 3 && stage == 'viewing'
          ? Timestamp.fromDate(now.add(const Duration(days: 2)))
          : null,
      'reminderNote': daysAgo <= 3 && stage == 'viewing'
          ? 'Follow up after site visit'
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(createdAt.add(Duration(
        hours: daysAgo * 2,
      ))),
    };
  }

  static String _priceLabel(double price) {
    if (price >= 10000000) return '₹${(price / 10000000).toStringAsFixed(1)}Cr';
    if (price >= 100000) return '₹${(price / 100000).toStringAsFixed(0)}L';
    return '₹${price.toStringAsFixed(0)}';
  }

  // ── Ask posts ──────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _buildQaAskPosts(
    String adminUid,
    String adminName,
    String? adminPhotoUrl,
    _QaOrgData orgs,
    DateTime now,
  ) {
    final posts = <Map<String, dynamic>>[];

    // image posts
    final imageUrls = [
      'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=800&q=80',
      'https://images.unsplash.com/photo-1582407947304-fd86f028f716?w=800&q=80',
      'https://images.unsplash.com/photo-1512918728675-ed5a9ecdebfd?w=800&q=80',
      'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=800&q=80',
      'https://images.unsplash.com/photo-1597347343908-2937e7dcc560?w=800&q=80',
    ];

    posts.add(
      _qpost(
        id: 'qa_post_01',
        uid: adminUid,
        name: adminName,
        photo: adminPhotoUrl,
        text:
            'Just closed a ₹4.2 Cr penthouse barter deal in Worli — exchanged for 2 Thane flats. If you have off-market barter requirements, DM me. Deals like these need creative structuring. 🏙️',
        imageUrl: null,
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 1,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_02',
        uid: adminUid,
        name: adminName,
        photo: adminPhotoUrl,
        text: '',
        imageUrl: imageUrls[0],
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 3,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_03',
        uid: 'seed_qa_admin_002',
        name: 'Nisha Agarwal',
        photo: 'https://randomuser.me/api/portraits/women/66.jpg',
        text:
            'MARKET INSIGHT 📊\n\nConnaught Place grade-A offices are now trading at ₹24,000–28,000 psf. If you have a CP asset, this is the time to exit. PropNexus closed 3 deals above ₹20Cr this quarter alone.',
        imageUrl: null,
        isBold: true,
        bg: '0xFF1A2744',
        fontSize: 'large',
        align: 'center',
        daysAgo: 2,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_04',
        uid: 'seed_qa_admin_003',
        name: 'Vikram Joshi',
        photo: 'https://randomuser.me/api/portraits/men/66.jpg',
        text: '',
        imageUrl: imageUrls[1],
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 5,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_05',
        uid: 'seed_qa_admin_003',
        name: 'Vikram Joshi',
        photo: 'https://randomuser.me/api/portraits/men/66.jpg',
        text:
            'Skyline Serene Whitefield — just 12 units left at pre-launch pricing. Price increases by ₹200 psf from next month. Book now with just ₹2L token. RERA number expected by 15th.',
        imageUrl: null,
        isBold: true,
        bg: '0xFF0A3D2B',
        fontSize: 'regular',
        align: 'left',
        daysAgo: 4,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_06',
        uid: 'seed_qa_mgr_001',
        name: 'Priya Singh',
        photo: 'https://randomuser.me/api/portraits/women/55.jpg',
        text:
            'Looking for a motivated buyer for a stunning sea-facing 2 BHK in Malad West. 18% below market, ready possession, loan cleared. Quick sale — buyer must be ready to execute in 30 days.',
        imageUrl: null,
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 6,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_07',
        uid: 'seed_qa_admin_004',
        name: 'Deepak Sharma',
        photo: 'https://randomuser.me/api/portraits/men/88.jpg',
        text: '',
        imageUrl: imageUrls[2],
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 7,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_08',
        uid: 'seed_qa_admin_004',
        name: 'Deepak Sharma',
        photo: 'https://randomuser.me/api/portraits/men/88.jpg',
        text:
            'YIELD COMPARISON 2025:\n\nMumbai studio: 4.2–4.8%\nPune Kharadi studio: 4.5–5.2%\nBangalore Koramangala 2BHK: 4.0–4.5%\nHyderabad Kondapur 2BHK: 4.6–5.0%\n\nPune and Hyderabad win on yield. Mumbai wins on capital appreciation. Where are you investing? 👇',
        imageUrl: null,
        isBold: false,
        bg: '0xFF2C1810',
        fontSize: 'regular',
        align: 'left',
        daysAgo: 8,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_09',
        uid: 'seed_qa_agt_001',
        name: 'Ankit Shah',
        photo: 'https://randomuser.me/api/portraits/men/22.jpg',
        text:
            'Bank auction tip of the day: Always check the DRT notice board on the court\'s website BEFORE bidding. Undisclosed prior charges on a property can wipe your gains. Learnt this the hard way 3 years ago. 💡',
        imageUrl: null,
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 9,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_10',
        uid: 'seed_qa_admin_005',
        name: 'Amit Desai',
        photo: 'https://randomuser.me/api/portraits/men/33.jpg',
        text: '',
        imageUrl: imageUrls[3],
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 10,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_11',
        uid: 'seed_qa_admin_005',
        name: 'Amit Desai',
        photo: 'https://randomuser.me/api/portraits/men/33.jpg',
        text:
            'MetroHomes Grand Wakad launch event this Saturday! 🚀\n\nFREE site visit bus from Shivaji Nagar at 10 AM. Lucky draw: ₹1L off on booking. 3 BHK show flat now ready. Seats limited — WhatsApp RSVP.',
        imageUrl: null,
        isBold: true,
        bg: '0xFF1F2937',
        fontSize: 'large',
        align: 'center',
        daysAgo: 11,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_12',
        uid: 'seed_qa_mgr_003',
        name: 'Sneha Iyer',
        photo: 'https://randomuser.me/api/portraits/women/88.jpg',
        text:
            'Koramangala 5th Block — 2 BHK yielding 4.3%. Asking ₹1.25Cr. Tenant already in place (Swiggy employee), ₹45K/month. Perfect for long-distance investor. DM if interested.',
        imageUrl: null,
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 12,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_13',
        uid: adminUid,
        name: adminName,
        photo: adminPhotoUrl,
        text: '',
        imageUrl: imageUrls[4],
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 15,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_14',
        uid: 'seed_qa_agt_005',
        name: 'Suresh Nair',
        photo: 'https://randomuser.me/api/portraits/men/77.jpg',
        text:
            'Barter Deal Alert! HSR Layout 4 BHK (1.8Cr) for 2 x 2BHK or 1 commercial property. Owners are flexible. If you have something that fits, let\'s connect and make this work.',
        imageUrl: null,
        isBold: false,
        bg: null,
        fontSize: 'regular',
        align: 'left',
        daysAgo: 16,
        now: now,
      ),
    );

    posts.add(
      _qpost(
        id: 'qa_post_15',
        uid: 'seed_qa_admin_002',
        name: 'Nisha Agarwal',
        photo: 'https://randomuser.me/api/portraits/women/66.jpg',
        text:
            'PropNexus Q1 2025 Report:\n✅ 14 deals closed\n💰 ₹47Cr total transaction value\n🏆 Top performer: Rohit Verma (5 deals)\n🔥 Fastest close: 9 days (Dwarka 4BHK)\n\nProud of my team! Keep pushing. 💪',
        imageUrl: null,
        isBold: true,
        bg: '0xFF0F172A',
        fontSize: 'regular',
        align: 'left',
        daysAgo: 18,
        now: now,
      ),
    );

    return posts;
  }

  static Map<String, dynamic> _qpost({
    required String id,
    required String uid,
    required String name,
    required String? photo,
    required String text,
    required String? imageUrl,
    required bool isBold,
    required String? bg,
    required String fontSize,
    required String align,
    required int daysAgo,
    required DateTime now,
  }) =>
      {
        'id': id,
        'authorUid': uid,
        'authorName': name,
        'authorPhotoUrl': photo,
        'text': text,
        'imageUrl': imageUrl,
        'isBold': isBold,
        'textAlign': align,
        'backgroundColorHex': bg,
        'fontSize': fontSize,
        'likesCount': (id.hashCode.abs() % 42) + 2,
        'commentsCount': id.hashCode.abs() % 8,
        'createdAt': Timestamp.fromDate(now.subtract(Duration(days: daysAgo))),
      };
}

// ── QA Org data holder ────────────────────────────────────────────────────────

class _QaOrgData {
  const _QaOrgData({
    required this.allUsers,
    required this.orgDocs,
    required this.memberDocs,
    required this.teamDocs,
  });

  final List<Map<String, dynamic>> allUsers;
  final List<Map<String, dynamic>> orgDocs;
  final List<Map<String, dynamic>> memberDocs;
  final List<Map<String, dynamic>> teamDocs;
}
