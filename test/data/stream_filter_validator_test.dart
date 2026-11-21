import 'package:flutter_test/flutter_test.dart';
import 'package:nimeva/data/services/stream_filter_validator.dart';

void main() {
  group('StreamFilterValidator Tests', () {
    test('accepts authentic episode stream titles', () {
      final res1 = StreamFilterValidator.validate(
        candidateTitle: 'Tokyo Revengers Episode 1 Sub Indo',
        candidateUrl: 'https://archive.org/download/tokyo-revengers/S01E01.mp4',
      );
      expect(res1.isValid, isTrue);

      final res2 = StreamFilterValidator.validate(
        candidateTitle: 'Demon Slayer S01E01 - Cruelty',
        candidateUrl: 'https://archive.org/download/rai-demon-slayer/ep1.mp4',
      );
      expect(res2.isValid, isTrue);

      final res3 = StreamFilterValidator.validate(
        candidateTitle: 'Attack on Titan 1 Cap 01.mp4',
        candidateUrl: 'https://archive.org/download/Shingeki_no_Kyojin/Cap01.mp4',
      );
      expect(res3.isValid, isTrue);
    });

    test('rejects titles with forbidden reaction keywords', () {
      final res1 = StreamFilterValidator.validate(
        candidateTitle: 'Tokyo Revengers Episode 1 Reaction & Live Commentary!',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(res1.isValid, isFalse);
      expect(res1.reason.toLowerCase(), contains('reaction'));

      final res2 = StreamFilterValidator.validate(
        candidateTitle: 'Reaksi Nonton Jujutsu Kaisen Episode 2',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(res2.isValid, isFalse);
      expect(res2.reason.toLowerCase(), contains('reaksi'));
    });

    test('rejects titles with review, explain, or theory keywords', () {
      final reviewRes = StreamFilterValidator.validate(
        candidateTitle: 'Jujutsu Kaisen Season 1 Full Review & Discussion',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(reviewRes.isValid, isFalse);
      expect(reviewRes.reason.toLowerCase(), contains('review'));

      final explainRes = StreamFilterValidator.validate(
        candidateTitle: 'Attack on Titan Ending Explained in Detail',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(explainRes.isValid, isFalse);
      expect(explainRes.reason.toLowerCase(), contains('explain'));

      final theoryRes = StreamFilterValidator.validate(
        candidateTitle: 'Teori Identitas Rahasia Izana Tokyo Revengers',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(theoryRes.isValid, isFalse);
      expect(theoryRes.reason.toLowerCase(), contains('teori'));
    });

    test('rejects nonton bareng / nobar videos', () {
      final nobarRes = StreamFilterValidator.validate(
        candidateTitle: 'Nonton Bareng Dan Da Dan Episode 1 Seru',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(nobarRes.isValid, isFalse);
      expect(nobarRes.reason.toLowerCase(), contains('nonton bareng'));

      final nobarRes2 = StreamFilterValidator.validate(
        candidateTitle: 'Nobar Tokyo Revengers Malam Minggu',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(nobarRes2.isValid, isFalse);
      expect(nobarRes2.reason.toLowerCase(), contains('nobar'));
    });

    test('rejects trailers, amv, clips, and recaps', () {
      final trailerRes = StreamFilterValidator.validate(
        candidateTitle: 'Chainsaw Man Official Teaser Trailer PV',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(trailerRes.isValid, isFalse);
      expect(trailerRes.reason.toLowerCase(), contains('trailer'));

      final amvRes = StreamFilterValidator.validate(
        candidateTitle: 'Solo Leveling Best AMV Edit 4K',
        candidateUrl: 'https://archive.org/download/video.mp4',
      );
      expect(amvRes.isValid, isFalse);
      expect(amvRes.reason.toLowerCase(), contains('amv'));
    });

    test('rejects untrusted or invalid streaming URLs', () {
      final invalidUrlRes = StreamFilterValidator.validate(
        candidateTitle: 'Solo Leveling Episode 1',
        candidateUrl: 'ftp://suspicious-unknown-server.com/malicious.exe',
      );
      expect(invalidUrlRes.isValid, isFalse);
      expect(invalidUrlRes.reason.toLowerCase(), contains('sumber'));
    });

    test('rejects foreign dub signatures in title or URL', () {
      final claroRes = StreamFilterValidator.validate(
        candidateTitle: 'Fullmetal Alchemist Brotherhood [1st Dubbing] S01E01',
        candidateUrl: 'https://archive.org/download/claro-video/ep1.mp4',
      );
      expect(claroRes.isValid, isFalse);
      expect(claroRes.reason.toLowerCase(), contains('dubbing bahasa asing'));

      final latinoRes = StreamFilterValidator.validate(
        candidateTitle: 'Tokyo Revengers Episode 1 Audio Latino',
        candidateUrl: 'https://archive.org/download/tr/ep1.mp4',
      );
      expect(latinoRes.isValid, isFalse);
      expect(latinoRes.reason.toLowerCase(), contains('dubbing bahasa asing'));

      final germanRes = StreamFilterValidator.validate(
        candidateTitle: 'One Punch Man S01E01 - Der Stärkste',
        candidateUrl: 'https://archive.org/download/opm.Gemischt/S01E01.mp4',
      );
      expect(germanRes.isValid, isFalse);

      final gemischtRes = StreamFilterValidator.validate(
        candidateTitle: 'Demon Slayer Episode 1',
        candidateUrl: 'https://archive.org/download/anicolldemonslayer.Gemischt/ep1.mp4',
      );
      expect(gemischtRes.isValid, isFalse);
    });

    test('accepts Japanese audio streams with Sub Indo or Eng Sub', () {
      final subIndo = StreamFilterValidator.validate(
        candidateTitle: 'One Punch Man Episode 1 Sub Indo',
        candidateUrl: 'https://archive.org/download/opm-s1/OPM-BD-01.mp4',
      );
      expect(subIndo.isValid, isTrue);

      final engSub = StreamFilterValidator.validate(
        candidateTitle: 'Demon Slayer S01E01 Eng Sub Japanese Audio',
        candidateUrl: 'https://archive.org/download/knys1/KNYS1-E1.mp4',
      );
      expect(engSub.isValid, isTrue);
    });
  });
}

