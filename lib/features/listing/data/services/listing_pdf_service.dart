import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cpapp/features/listing/domain/entities/listing.dart';

/// 9 × 16 single-page property poster.
/// Uses explicit heights throughout — NO pw.Spacer / pw.Expanded —
/// to avoid pdf-layout-engine constraint ambiguities.
abstract final class ListingPdfService {
  // ── Page dimensions (9:16) ───────────────────────────────────────────────
  static const double _w       = 540;
  static const double _h       = 960;
  static const double _heroH   = 490;   // tall hero image section
  static const double _footerH =  32;
  static const double _bodyH   = _h - _heroH - _footerH; // 438

  static const _page = PdfPageFormat(_w, _h, marginAll: 0);

  // ── Palette ──────────────────────────────────────────────────────────────
  static const _navy     = PdfColor(0.039, 0.086, 0.157);
  static const _navyMid  = PdfColor(0.086, 0.141, 0.251);
  static const _navyLt   = PdfColor(0.118, 0.196, 0.333);
  static const _gold     = PdfColor(0.788, 0.659, 0.298);
  static const _goldBd   = PdfColor(0.788, 0.659, 0.298, 0.40);
  static const _goldBg   = PdfColor(0.788, 0.659, 0.298, 0.12);
  static const _white    = PdfColors.white;
  static const _white90  = PdfColor(1, 1, 1, 0.90);
  static const _white65  = PdfColor(1, 1, 1, 0.65);
  static const _white40  = PdfColor(1, 1, 1, 0.40);
  static const _offWhite = PdfColor(0.973, 0.973, 0.965);
  static const _textSec  = PdfColor(0.400, 0.435, 0.510);
  static const _border   = PdfColor(0.878, 0.898, 0.929);
  static const _transpt  = PdfColor(0, 0, 0, 0);
  static const _scrim    = PdfColor(0.039, 0.086, 0.157, 0.85);
  static const _green    = PdfColor(0.18, 0.80, 0.44);

  // ── Public entry ─────────────────────────────────────────────────────────

  static Future<Uint8List> generate(Listing listing) async {
    final heroBytes   = await _fetchImage(listing.heroImageUrl);
    final brokerBytes = listing.brokerPhotoUrl != null
        ? await _fetchImage(listing.brokerPhotoUrl!)
        : null;

    final heroImage   = heroBytes   != null ? pw.MemoryImage(heroBytes)   : null;
    final brokerImage = brokerBytes != null ? pw.MemoryImage(brokerBytes) : null;

    final doc = pw.Document(
      title : listing.title?.isNotEmpty == true
          ? listing.title!
          : '${listing.category.label} – ${listing.location}',
      author: listing.brokerName,
    );

    doc.addPage(
      pw.Page(
        pageFormat: _page,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Column(
          children: [
            // 1. Hero (490 pt) — Stack-based, explicit height
            _hero(listing, heroImage),
            // 2. Body (438 pt) — Stack-based, explicit height
            _body(listing, brokerImage),
            // 3. Footer (32 pt)
            _footer(),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ── 1. Hero (Stack — no Expanded, no Spacer) ─────────────────────────────

  static pw.Widget _hero(Listing listing, pw.ImageProvider? heroImage) =>
      pw.Stack(
        children: [
          // ① Full-size background
          pw.Container(
            width: _w,
            height: _heroH,
            child: heroImage != null
                ? pw.Image(heroImage,
                    width: _w, height: _heroH, fit: pw.BoxFit.cover,)
                : pw.Container(width: _w, height: _heroH, color: _navyMid),
          ),

          // ② Top dark fade (badge readability)
          pw.Positioned(
            top: 0, left: 0, right: 0,
            child: pw.Container(
              height: 100,
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                  colors: [_navy, _transpt],
                ),
              ),
            ),
          ),

          // ③ Bottom scrim for price legibility
          pw.Positioned(
            bottom: 0, left: 0, right: 0,
            child: pw.Container(
              height: 280,
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  begin: pw.Alignment.topCenter,
                  end: pw.Alignment.bottomCenter,
                  colors: [_transpt, _scrim],
                ),
              ),
            ),
          ),

          // ④ Category badge — top left
          pw.Positioned(
            top: 18, left: 18,
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _navy,
                borderRadius: pw.BorderRadius.circular(20),
                border: pw.Border.all(color: _goldBd, width: 1),
              ),
              child: pw.Text(
                listing.category.label.toUpperCase(),
                style: pw.TextStyle(
                  color: _gold,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          // ⑤ CPApp badge — top right
          pw.Positioned(
            top: 18, right: 18,
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: _gold,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'CPApp',
                style: pw.TextStyle(
                  color: _navy,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),

          // ⑥ Price / info overlay — bottom
          pw.Positioned(
            bottom: 18, left: 18, right: 18,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Left: title + price + location
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (listing.title?.isNotEmpty == true) ...[
                        pw.Text(
                          listing.title!.toUpperCase(),
                          style: pw.TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      // Price row
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            listing.priceLabel,
                            style: pw.TextStyle(
                              color: _white,
                              fontSize: 30,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (listing.originalPriceLabel != null) ...[
                            pw.SizedBox(width: 8),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  listing.originalPriceLabel!,
                                  style: const pw.TextStyle(
                                    color: _white65,
                                    fontSize: 10,
                                    decoration: pw.TextDecoration.lineThrough,
                                  ),
                                ),
                                if (listing.discountPercent != null)
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 2,),
                                    decoration: pw.BoxDecoration(
                                      color: _green,
                                      borderRadius:
                                          pw.BorderRadius.circular(4),
                                    ),
                                    child: pw.Text(
                                      'SAVE ${listing.discountPercent}%',
                                      style: pw.TextStyle(
                                        color: _white,
                                        fontSize: 7,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${listing.location}, ${listing.city}',
                        style: const pw.TextStyle(
                            color: _white90, fontSize: 11,),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                // Right: property type pill + area
                if (listing.propertyType != null) ...[
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6,),
                        decoration: pw.BoxDecoration(
                          color: _goldBg,
                          borderRadius: pw.BorderRadius.circular(8),
                          border: pw.Border.all(color: _goldBd),
                        ),
                        child: pw.Text(
                          listing.propertyType!.label.toUpperCase(),
                          style: pw.TextStyle(
                            color: _gold,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      if (listing.area > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          listing.areaLabel,
                          style: const pw.TextStyle(
                              color: _white65, fontSize: 10,),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );

  // ── 2. Body (Stack — top content + bottom broker) ─────────────────────────

  static pw.Widget _body(Listing listing, pw.ImageProvider? brokerImage) =>
      pw.Stack(
      children: [
        // Background
        pw.Container(width: _w, height: _bodyH, color: _offWhite),

        // ── Top group: gold border + specs + divider + description + brokerage
        pw.Positioned(
          top: 0, left: 0, right: 0,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Gold top accent
              pw.Container(height: 3, width: _w, color: _gold),

              // Specs strip (white bg)
              _specsStrip(listing),

              // Hairline divider
              pw.Container(
                margin:
                    const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                height: 0.5,
                color: _border,
              ),

              // Description (optional)
              if (listing.description?.isNotEmpty == true)
                _descriptionBlock(listing),

              // Brokerage row (optional)
              if (listing.brokerageAmount?.isNotEmpty == true)
                _brokerageRow(listing),
            ],
          ),
        ),

        // ── Bottom group: exclusive header + broker card — pinned to bottom
        pw.Positioned(
          bottom: 0, left: 0, right: 0,
          child: pw.Column(
            children: [
              _exclusiveHeader(),
              _brokerCard(listing, brokerImage),
            ],
          ),
        ),
      ],
    );

  // ── Specs strip ───────────────────────────────────────────────────────────

  static pw.Widget _specsStrip(Listing listing) {
    final specs = <_Spec>[
      if (listing.area > 0) _Spec('AREA', listing.areaLabel),
      if (listing.propertyType != null)
        _Spec('TYPE', listing.propertyType!.label),
      _Spec('CITY', listing.city),
      _Spec('DEAL', listing.category.label),
    ];

    return pw.Container(
      width: _w,
      color: _white,
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: pw.Row(
        children: [
          for (int i = 0; i < specs.length; i++) ...[
            pw.Expanded(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    specs[i].value,
                    style: pw.TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    specs[i].label,
                    style: const pw.TextStyle(
                      color: _textSec,
                      fontSize: 7,
                      letterSpacing: 0.8,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            if (i < specs.length - 1)
              pw.Container(width: 1, height: 28, color: _border),
          ],
        ],
      ),
    );
  }

  // ── Description ───────────────────────────────────────────────────────────

  static pw.Widget _descriptionBlock(Listing listing) => pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(20, 10, 20, 0),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(width: 3, height: 28, color: _gold),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Text(
                listing.description!,
                style: const pw.TextStyle(
                  color: _textSec,
                  fontSize: 9,
                  lineSpacing: 2.5,
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      );

  // ── Brokerage ─────────────────────────────────────────────────────────────

  static pw.Widget _brokerageRow(Listing listing) => pw.Container(
        margin: const pw.EdgeInsets.fromLTRB(20, 10, 20, 0),
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(
          color: _white,
          borderRadius: pw.BorderRadius.circular(8),
          border: const pw.Border(
            left: pw.BorderSide(color: _gold, width: 3),
          ),
        ),
        child: pw.Row(
          children: [
            pw.Text(
              'Brokerage',
              style: const pw.TextStyle(color: _textSec, fontSize: 9),
            ),
            pw.SizedBox(width: 10),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: pw.BoxDecoration(
                color: _navy,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                listing.brokerageAmount!,
                style: pw.TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              'Negotiable on request',
              style: const pw.TextStyle(color: _textSec, fontSize: 8),
            ),
          ],
        ),
      );

  // ── "Exclusive deal with" header ──────────────────────────────────────────

  static pw.Widget _exclusiveHeader() => pw.Container(
        width: _w,
        color: _navy,
        padding:
            const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(width: 36, height: 1, color: _goldBd),
            pw.SizedBox(width: 12),
            pw.Text(
              'EXCLUSIVE DEAL WITH',
              style: pw.TextStyle(
                color: _white65,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Container(width: 36, height: 1, color: _goldBd),
          ],
        ),
      );

  // ── Broker card ───────────────────────────────────────────────────────────

  static pw.Widget _brokerCard(
      Listing listing, pw.ImageProvider? photo,) =>
      pw.Container(
        width: _w,
        color: _navyMid,
        padding: const pw.EdgeInsets.fromLTRB(20, 14, 20, 16),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            // Avatar with gold ring
            pw.Container(
              width: 54,
              height: 54,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: _navyLt,
                border: pw.Border.all(color: _gold, width: 2.5),
                image: photo != null
                    ? pw.DecorationImage(
                        image: photo, fit: pw.BoxFit.cover,)
                    : null,
              ),
              child: photo == null
                  ? pw.Center(
                      child: pw.Text(
                        listing.brokerName.isNotEmpty
                            ? listing.brokerName[0].toUpperCase()
                            : 'B',
                        style: pw.TextStyle(
                          color: _gold,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            pw.SizedBox(width: 14),

            // Name + role + phone
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    listing.brokerName.toUpperCase(),
                    style: pw.TextStyle(
                      color: _white,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                  ),
                  if (listing.posterRole != null) ...[
                    pw.SizedBox(height: 3),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2,),
                      decoration: pw.BoxDecoration(
                        color: _goldBg,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: _goldBd),
                      ),
                      child: pw.Text(
                        _roleLabel(listing.posterRole!).toUpperCase(),
                        style: pw.TextStyle(
                          color: _gold,
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                  if (listing.brokerPhone != null) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      listing.brokerPhone!,
                      style: pw.TextStyle(
                        color: _gold,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.SizedBox(width: 12),

            // QR code
            pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: listing.brokerPhone != null
                      ? 'tel:${listing.brokerPhone!.replaceAll(' ', '')}'
                      : 'https://cpapp.in',
                  width: 52,
                  height: 52,
                  color: _white,
                  backgroundColor: _navyMid,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'SCAN TO CALL',
                  style: const pw.TextStyle(
                    color: _white40,
                    fontSize: 6,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ── 3. Footer ─────────────────────────────────────────────────────────────

  static pw.Widget _footer() => pw.Container(
        width: _w,
        height: _footerH,
        color: _navy,
        alignment: pw.Alignment.center,
        child: pw.Text(
          'CPApp  ·  ${DateFormat('d MMM yyyy').format(DateTime.now())}  ·  For informational purposes only',
          style: const pw.TextStyle(
            color: _white40,
            fontSize: 7,
            letterSpacing: 0.4,
          ),
        ),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _roleLabel(String role) => switch (role) {
        'broker'   => 'Broker',
        'investor' => 'Investor',
        'owner'    => 'Owner / Not a Broker',
        'builder'  => 'Builder',
        _          => role,
      };

  static Future<Uint8List?> _fetchImage(String url) async {
    try {
      final resp = await Dio().get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return resp.data != null ? Uint8List.fromList(resp.data!) : null;
    } catch (_) {
      return null;
    }
  }
}

class _Spec {
  const _Spec(this.label, this.value);
  final String label;
  final String value;
}
