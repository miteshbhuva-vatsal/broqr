import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cpapp/core/constants/app_constants.dart';

/// Debug-only service that seeds Firestore with one dummy listing per
/// ListingCategory so every category section in the feed has content.
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
    debugPrint('[Seed] ${seeds.length} listings written to Firestore');
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
              now.subtract(Duration(days: daysAgo, hours: imgIdx)),),
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
}
