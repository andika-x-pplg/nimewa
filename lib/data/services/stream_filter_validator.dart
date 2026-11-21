/// Result of stream candidate title and source validation.
class StreamValidationResult {
  final bool isValid;
  final String reason;

  const StreamValidationResult(this.isValid, this.reason);

  static const StreamValidationResult valid = StreamValidationResult(true, 'Episode resmi terverifikasi');
}

/// Validates video stream titles and sources against non-episode content.
/// Rejects reactions, reviews, recaps, nobar, trailers, and untrusted sources.
class StreamFilterValidator {
  static final RegExp _reactionRegex = RegExp(
    r'\b(reaction|react|reaksi)\b',
    caseSensitive: false,
  );

  static final RegExp _reviewRegex = RegExp(
    r'\b(review|discussion|ulasan)\b',
    caseSensitive: false,
  );

  static final RegExp _explainRegex = RegExp(
    r'\b(explain|explained|penjelasan|teori|theory)\b',
    caseSensitive: false,
  );

  static final RegExp _nobarRegex = RegExp(
    r'\b(nonton\s*bareng|nobar)\b',
    caseSensitive: false,
  );

  static final RegExp _promoRegex = RegExp(
    r'\b(trailer|teaser|amv|clip|edit|recap|opening|ending|pv|cm)\b',
    caseSensitive: false,
  );

  static final RegExp _foreignDubRegex = RegExp(
    r'\b(1st\s*dubbing|dublado|audio\s*latino|latino|castellano|deutsch|german\s*dub|fandub|spain\s*dub|espanol\s*dub)\b',
    caseSensitive: false,
  );

  static final RegExp _foreignTitleRegex = RegExp(
    r'\b(der\s*st[äa]rkste|grausamkeit|flammens[äa]ule)\b',
    caseSensitive: false,
  );

  /// Validates a video candidate title and stream URL.
  static StreamValidationResult validate({
    required String candidateTitle,
    required String candidateUrl,
  }) {
    final cleanTitle = candidateTitle.trim();
    final cleanUrl = candidateUrl.trim().toLowerCase();

    // 1. Check URL scheme and protocol
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      return const StreamValidationResult(false, 'Sumber/uploader tidak terverifikasi (skema URL tidak valid)');
    }

    // 2. Filter reaction keywords
    if (_reactionRegex.hasMatch(cleanTitle)) {
      final match = _reactionRegex.firstMatch(cleanTitle)!.group(0);
      return StreamValidationResult(false, 'Judul mengandung kata reaksi: "$match"');
    }

    // 3. Filter review and discussion keywords
    if (_reviewRegex.hasMatch(cleanTitle)) {
      final match = _reviewRegex.firstMatch(cleanTitle)!.group(0);
      return StreamValidationResult(false, 'Judul mengandung kata review: "$match"');
    }

    // 4. Filter explain and theory keywords
    if (_explainRegex.hasMatch(cleanTitle)) {
      final match = _explainRegex.firstMatch(cleanTitle)!.group(0);
      return StreamValidationResult(false, 'Judul mengandung kata explain/teori: "$match"');
    }

    // 5. Filter nonton bareng / nobar
    if (_nobarRegex.hasMatch(cleanTitle)) {
      final match = _nobarRegex.firstMatch(cleanTitle)!.group(0);
      return StreamValidationResult(false, 'Judul mengandung kata nobar/nonton bareng: "$match"');
    }

    // 6. Filter trailers, AMVs, clips, and promo recaps
    if (_promoRegex.hasMatch(cleanTitle)) {
      final match = _promoRegex.firstMatch(cleanTitle)!.group(0);
      return StreamValidationResult(false, 'Judul mengandung kata trailer/AMV: "$match"');
    }

    // 7. Filter foreign dub signatures (German, Spanish, Portuguese, etc.)
    if (_foreignDubRegex.hasMatch(cleanTitle) || _foreignDubRegex.hasMatch(cleanUrl)) {
      final match = _foreignDubRegex.firstMatch(cleanTitle)?.group(0) ??
          _foreignDubRegex.firstMatch(cleanUrl)!.group(0);
      return StreamValidationResult(false, 'Stream terdeteksi dubbing bahasa asing: "$match"');
    }

    // 8. Filter foreign German/Spanish title keywords
    if (_foreignTitleRegex.hasMatch(cleanTitle) || _foreignTitleRegex.hasMatch(cleanUrl)) {
      final match = _foreignTitleRegex.firstMatch(cleanTitle)?.group(0) ??
          _foreignTitleRegex.firstMatch(cleanUrl)!.group(0);
      return StreamValidationResult(false, 'Stream terdeteksi judul bahasa Jerman/asing: "$match"');
    }

    // 9. Filter German dub archive packages (.Gemischt)
    if (cleanUrl.contains('.gemischt')) {
      return const StreamValidationResult(false, 'Stream berasal dari arsip paket dubbing asing (.Gemischt)');
    }

    return StreamValidationResult.valid;
  }
}

