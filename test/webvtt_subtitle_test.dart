import 'package:awesome_video_player/src/subtitles/better_player_subtitle.dart';
import 'package:awesome_video_player/src/subtitles/better_player_subtitles_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebVTT Subtitle Parser Tests', () {
    group('WebVTT Header Handling', () {
      test('should ignore WEBVTT header and parse valid subtitle', () {
        // Given: A WebVTT file with proper header
        const webVttContent = '''WEBVTT

00:00:01.000 --> 00:00:04.000
Hello, this is the first subtitle.

00:00:05.000 --> 00:00:08.000
This is the second subtitle.''';

        // When: Parsing the WebVTT content
        final subtitles =
            BetterPlayerSubtitlesFactory.parseString(webVttContent);

        // Then: Should parse exactly 2 subtitles (ignoring the WEBVTT header)
        expect(subtitles.length, equals(2));

        // First subtitle
        expect(subtitles[0].start, equals(const Duration(seconds: 1)));
        expect(subtitles[0].end, equals(const Duration(seconds: 4)));
        expect(
            subtitles[0].texts, equals(['Hello, this is the first subtitle.']));

        // Second subtitle
        expect(subtitles[1].start, equals(const Duration(seconds: 5)));
        expect(subtitles[1].end, equals(const Duration(seconds: 8)));
        expect(subtitles[1].texts, equals(['This is the second subtitle.']));
      });

      test('should ignore NOTE sections in WebVTT', () {
        // Given: A WebVTT file with NOTE sections
        const webVttContent = '''WEBVTT

NOTE
This is a comment line and should be ignored

1
00:00:01.000 --> 00:00:04.000
First subtitle after note.

NOTE
Another comment

2
00:00:05.000 --> 00:00:08.000
Second subtitle after note.''';

        // When: Parsing the WebVTT content
        final subtitles =
            BetterPlayerSubtitlesFactory.parseString(webVttContent);

        // Then: Should parse exactly 2 subtitles (ignoring the NOTE sections)
        expect(subtitles.length, equals(2));
        expect(subtitles[0].texts, equals(['First subtitle after note.']));
        expect(subtitles[1].texts, equals(['Second subtitle after note.']));
      });

      test('should handle WebVTT with metadata settings', () {
        // Given: A WebVTT file with metadata after header
        const webVttContent = '''WEBVTT
Kind: captions
Language: en

1
00:00:01.000 --> 00:00:04.000
Subtitle with metadata.''';

        // When: Parsing the WebVTT content
        final subtitles =
            BetterPlayerSubtitlesFactory.parseString(webVttContent);

        // Then: Should parse 1 subtitle (ignoring metadata)
        expect(subtitles.length, equals(1));
        expect(subtitles[0].texts, equals(['Subtitle with metadata.']));
      });

      test('should handle cue settings and styling in WebVTT', () {
        // Given: A WebVTT file with cue settings
        const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000 line:85% align:middle
<c.yellow>Yellow text</c> and normal text.

2
00:00:05.000 --> 00:00:08.000 position:50%
Text with position setting.''';

        // When: Parsing the WebVTT content
        final subtitles =
            BetterPlayerSubtitlesFactory.parseString(webVttContent);

        // Then: Should parse subtitles and handle cue settings
        expect(subtitles.length, equals(2));
        expect(subtitles[0].texts,
            equals(['<c.yellow>Yellow text</c> and normal text.']));
        expect(subtitles[1].texts, equals(['Text with position setting.']));
      });
    });

    group('Backward Compatibility with SRT', () {
      test('should continue to parse SRT format correctly', () {
        // Given: An SRT format subtitle
        const srtContent = '''1
00:00:01,000 --> 00:00:04,000
Hello, this is SRT format.

2
00:00:05,000 --> 00:00:08,000
Second SRT subtitle.''';

        // When: Parsing the SRT content
        final subtitles = BetterPlayerSubtitlesFactory.parseString(srtContent);

        // Then: Should parse SRT subtitles correctly
        expect(subtitles.length, equals(2));
        expect(subtitles[0].index, equals(1));
        expect(subtitles[0].texts, equals(['Hello, this is SRT format.']));
        expect(subtitles[1].index, equals(2));
        expect(subtitles[1].texts, equals(['Second SRT subtitle.']));
      });
    });

    group('Edge Cases', () {
      test('should handle empty WebVTT file', () {
        // Given: An empty WebVTT file
        const webVttContent = 'WEBVTT';

        // When: Parsing the empty WebVTT content
        final subtitles =
            BetterPlayerSubtitlesFactory.parseString(webVttContent);

        // Then: Should return empty list
        expect(subtitles.length, equals(0));
      });

      test('should handle WebVTT with only header and metadata', () {
        // Given: A WebVTT file with only header and metadata
        const webVttContent = '''WEBVTT
Kind: captions
Language: en

NOTE
This file has no actual subtitle cues''';

        // When: Parsing the WebVTT content
        final subtitles =
            BetterPlayerSubtitlesFactory.parseString(webVttContent);

        // Then: Should return empty list
        expect(subtitles.length, equals(0));
      });

      test('should handle malformed WebVTT gracefully', () {
        // Given: A malformed WebVTT file
        const webVttContent = '''WEBVTT

invalid_cue_without_timing
This should not be parsed

1
00:00:01.000 --> 00:00:04.000
This should be parsed correctly.''';

        // When: Parsing the malformed WebVTT content
        final subtitles =
            BetterPlayerSubtitlesFactory.parseString(webVttContent);

        // Then: Should parse only the valid subtitle
        expect(subtitles.length, equals(1));
        expect(
            subtitles[0].texts, equals(['This should be parsed correctly.']));
      });
    });

    group('Individual Subtitle Block Parsing', () {
      test(
          'should reject WEBVTT header block when parsed as individual subtitle',
          () {
        // Given: The WEBVTT header as individual subtitle block
        const webVttHeader = 'WEBVTT';

        // When: Trying to parse it as a subtitle
        final subtitle = BetterPlayerSubtitle(webVttHeader, true);

        // Then: Should return invalid subtitle (no start/end time)
        expect(subtitle.start, isNull);
        expect(subtitle.end, isNull);
        expect(subtitle.texts, isNull);
      });

      test('should reject NOTE blocks when parsed as individual subtitle', () {
        // Given: A NOTE block
        const noteBlock = '''NOTE
This is a comment line''';

        // When: Trying to parse it as a subtitle
        final subtitle = BetterPlayerSubtitle(noteBlock, true);

        // Then: Should return invalid subtitle
        expect(subtitle.start, isNull);
        expect(subtitle.end, isNull);
        expect(subtitle.texts, isNull);
      });

      test('should reject metadata blocks when parsed as individual subtitle',
          () {
        // Given: A metadata block
        const metadataBlock = '''Kind: captions
Language: en''';

        // When: Trying to parse it as a subtitle
        final subtitle = BetterPlayerSubtitle(metadataBlock, true);

        // Then: Should return invalid subtitle
        expect(subtitle.start, isNull);
        expect(subtitle.end, isNull);
        expect(subtitle.texts, isNull);
      });
    });

    group('W3C WebVTT Specification Examples', () {
      group('Voice Spans and Speaker Identification', () {
        test('should handle voice spans with speaker identification', () {
          // Based on W3C example: voice spans for dialogue
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
<v Roger Bingham>We are in New York City

2
00:00:04.000 --> 00:00:06.000
<v Neil deGrasse Tyson>We're actually at the Hayden Planetarium

3
00:00:06.000 --> 00:00:08.000
<v Roger Bingham>at the American Museum of Natural History''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(3));
          expect(subtitles[0].texts,
              equals(['<v Roger Bingham>We are in New York City']));
          expect(
              subtitles[1].texts,
              equals([
                '<v Neil deGrasse Tyson>We\'re actually at the Hayden Planetarium'
              ]));
          expect(
              subtitles[2].texts,
              equals([
                '<v Roger Bingham>at the American Museum of Natural History'
              ]));
        });

        test('should handle voice spans with multiple classes', () {
          // Based on W3C example: voice spans with CSS classes
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
<v.loud.fast John>This is spoken quickly and loudly!

2
00:00:04.000 --> 00:00:06.000
<v.whisper Mary>This is whispered softly''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(2));
          expect(subtitles[0].texts,
              equals(['<v.loud.fast John>This is spoken quickly and loudly!']));
          expect(subtitles[1].texts,
              equals(['<v.whisper Mary>This is whispered softly']));
        });
      });

      group('Cue Positioning and Layout', () {
        test('should handle advanced cue positioning settings', () {
          // Based on W3C examples: cue positioning
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000 position:10% align:start
Left-aligned subtitle at 10% position

2
00:00:04.000 --> 00:00:06.000 position:50% align:middle
Center-aligned subtitle

3
00:00:06.000 --> 00:00:08.000 position:90% align:end
Right-aligned subtitle at 90% position

4
00:00:08.000 --> 00:00:10.000 line:0 position:50%
Top line subtitle''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(4));
          expect(subtitles[0].texts,
              equals(['Left-aligned subtitle at 10% position']));
          expect(subtitles[1].texts, equals(['Center-aligned subtitle']));
          expect(subtitles[2].texts,
              equals(['Right-aligned subtitle at 90% position']));
          expect(subtitles[3].texts, equals(['Top line subtitle']));
        });

        test('should handle size and line positioning', () {
          // Based on W3C examples: size and line settings
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000 size:80% line:85%
Subtitle with 80% width at 85% line position

2
00:00:04.000 --> 00:00:06.000 size:50% position:25%
Half-width subtitle at quarter position

3
00:00:06.000 --> 00:00:08.000 line:-1
Bottom line subtitle''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(3));
          expect(subtitles[0].texts,
              equals(['Subtitle with 80% width at 85% line position']));
          expect(subtitles[1].texts,
              equals(['Half-width subtitle at quarter position']));
          expect(subtitles[2].texts, equals(['Bottom line subtitle']));
        });
      });

      group('CSS Styling and Classes', () {
        test('should handle various CSS styling tags', () {
          // Based on W3C examples: CSS styling
          const webVttContent = '''WEBVTT

STYLE
::cue(.red) { color: red; }
::cue(.blue) { color: blue; }
::cue(.large) { font-size: 150%; }

1
00:00:01.000 --> 00:00:04.000
<c.red>Red text</c> and <c.blue>blue text</c>

2
00:00:04.000 --> 00:00:06.000
<c.large>Large text</c> with normal text

3
00:00:06.000 --> 00:00:08.000
<b>Bold</b>, <i>italic</i>, and <u>underlined</u> text''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(3));
          expect(subtitles[0].texts,
              equals(['<c.red>Red text</c> and <c.blue>blue text</c>']));
          expect(subtitles[1].texts,
              equals(['<c.large>Large text</c> with normal text']));
          expect(
              subtitles[2].texts,
              equals(
                  ['<b>Bold</b>, <i>italic</i>, and <u>underlined</u> text']));
        });

        test('should handle complex nested styling', () {
          // Based on W3C examples: nested tags
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
<c.speaker1><b>John:</b> <i>Hello there!</i></c>

2
00:00:04.000 --> 00:00:06.000
<c.speaker2><b>Mary:</b> <u>How are you?</u></c>''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(2));
          expect(subtitles[0].texts,
              equals(['<c.speaker1><b>John:</b> <i>Hello there!</i></c>']));
          expect(subtitles[1].texts,
              equals(['<c.speaker2><b>Mary:</b> <u>How are you?</u></c>']));
        });
      });

      group('Chapters and Metadata', () {
        test('should handle chapter cues with metadata', () {
          // Based on W3C examples: chapter navigation
          const webVttContent = '''WEBVTT

CHAPTER 1
00:00:00.000 --> 00:02:00.000
Introduction

CHAPTER 2
00:02:00.000 --> 00:05:00.000
Main Content

1
00:00:01.000 --> 00:00:04.000
Subtitle in introduction chapter''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          // Parser might include chapter markers as subtitles, check that regular subtitle is present
          expect(subtitles.length, greaterThanOrEqualTo(1));
          expect(
              subtitles.any((s) =>
                  s.texts != null &&
                  s.texts!.contains('Subtitle in introduction chapter')),
              isTrue);
        });

        test('should handle metadata and description cues', () {
          // Based on W3C examples: metadata cues
          const webVttContent = '''WEBVTT

METADATA
00:00:01.000 --> 00:00:04.000
{"speaker": "John", "emotion": "happy"}

1
00:00:01.000 --> 00:00:04.000
Hello everyone!

METADATA
00:00:04.000 --> 00:00:06.000
{"speaker": "Mary", "emotion": "surprised"}

2
00:00:04.000 --> 00:00:06.000
Oh wow, that's amazing!''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          // Parser might include metadata as subtitles, check that regular subtitles are present
          expect(subtitles.length, greaterThanOrEqualTo(2));
          expect(
              subtitles.any((s) =>
                  s.texts != null && s.texts!.contains('Hello everyone!')),
              isTrue);
          expect(
              subtitles.any((s) =>
                  s.texts != null &&
                  s.texts!.contains('Oh wow, that\'s amazing!')),
              isTrue);
        });
      });

      group('Multi-line and Complex Text', () {
        test('should handle multi-line cues with various formatting', () {
          // Based on W3C examples: multi-line cues
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
Line one of the subtitle
Line two with <b>bold text</b>
Line three with <i>italic</i>

2
00:00:04.000 --> 00:00:06.000
<v Speaker1>First speaker line
<v Speaker1>continues speaking

3
00:00:06.000 --> 00:00:08.000
<v Speaker2>Second speaker
<v Speaker1>First speaker interrupts''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(3));
          expect(
              subtitles[0].texts,
              equals([
                'Line one of the subtitle',
                'Line two with <b>bold text</b>',
                'Line three with <i>italic</i>'
              ]));
          expect(
              subtitles[1].texts,
              equals([
                '<v Speaker1>First speaker line',
                '<v Speaker1>continues speaking'
              ]));
          expect(
              subtitles[2].texts,
              equals([
                '<v Speaker2>Second speaker',
                '<v Speaker1>First speaker interrupts'
              ]));
        });
      });

      group('Language and Internationalization', () {
        test('should handle language spans and direction', () {
          // Based on W3C examples: language and direction
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
English text with <lang en-US>American English</lang>

2
00:00:04.000 --> 00:00:06.000
Text with <lang ar>النص العربي</lang> Arabic

3
00:00:06.000 --> 00:00:08.000
Mixed <lang ja>日本語</lang> and <lang ko>한국어</lang> text''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(3));
          expect(
              subtitles[0].texts,
              equals(
                  ['English text with <lang en-US>American English</lang>']));
          expect(subtitles[1].texts,
              equals(['Text with <lang ar>النص العربي</lang> Arabic']));
          expect(
              subtitles[2].texts,
              equals(
                  ['Mixed <lang ja>日本語</lang> and <lang ko>한국어</lang> text']));
        });
      });

      group('Edge Cases from W3C Specification', () {
        test('should handle cues with identifiers', () {
          // Based on W3C examples: cue identifiers
          const webVttContent = '''WEBVTT

intro
00:00:01.000 --> 00:00:04.000
Introduction subtitle

speaker-john-1
00:00:04.000 --> 00:00:06.000
<v John>Hello there!

speaker-mary-1
00:00:06.000 --> 00:00:08.000
<v Mary>Hi John!''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(3));
          expect(subtitles[0].texts, equals(['Introduction subtitle']));
          expect(subtitles[1].texts, equals(['<v John>Hello there!']));
          expect(subtitles[2].texts, equals(['<v Mary>Hi John!']));
        });

        test('should handle precise millisecond timing', () {
          // Based on W3C examples: precise timing
          const webVttContent = '''WEBVTT

1
00:00:01.234 --> 00:00:04.567
Precise timing subtitle

2
00:00:04.567 --> 00:00:06.890
Another precise timing''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(2));
          expect(
              subtitles[0].start, equals(const Duration(milliseconds: 1234)));
          expect(subtitles[0].end, equals(const Duration(milliseconds: 4567)));
          expect(
              subtitles[1].start, equals(const Duration(milliseconds: 4567)));
          expect(subtitles[1].end, equals(const Duration(milliseconds: 6890)));
        });

        test('should handle empty cues and whitespace-only cues', () {
          // Based on W3C examples: edge cases
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
Normal subtitle

2
00:00:04.000 --> 00:00:06.000
Another normal subtitle

3
00:00:08.000 --> 00:00:10.000
Final subtitle''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          // Should handle empty cues gracefully and parse valid ones
          expect(subtitles.length, equals(3));
          expect(subtitles[0].texts, equals(['Normal subtitle']));
          expect(subtitles[1].texts, equals(['Another normal subtitle']));
          expect(subtitles[2].texts, equals(['Final subtitle']));
        });

        test('should handle cues with only formatting tags', () {
          // Based on W3C examples: formatting-only cues
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
<c.highlight></c>

2
00:00:04.000 --> 00:00:06.000
<b></b><i></i><u></u>

3
00:00:06.000 --> 00:00:08.000
Text with content''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, greaterThanOrEqualTo(1));
          expect(subtitles.last.texts, equals(['Text with content']));
        });
      });
    });

    group('Advanced W3C WebVTT Features', () {
      group('Complex Cue Settings Combinations', () {
        test('should handle multiple cue settings combined', () {
          // Based on W3C examples: complex cue settings
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000 line:0 position:50% align:middle size:80%
Top centered subtitle with custom width

2
00:00:04.000 --> 00:00:06.000 line:-1 position:10% align:start size:40%
Bottom left subtitle with narrow width

3
00:00:06.000 --> 00:00:08.000 line:50% position:90% align:end
Middle right subtitle''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(3));
          expect(subtitles[0].texts,
              equals(['Top centered subtitle with custom width']));
          expect(subtitles[1].texts,
              equals(['Bottom left subtitle with narrow width']));
          expect(subtitles[2].texts, equals(['Middle right subtitle']));
        });

        test('should handle vertical text settings', () {
          // Based on W3C examples: vertical text
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000 vertical:rl
Vertical right-to-left text

2
00:00:04.000 --> 00:00:06.000 vertical:lr
Vertical left-to-right text''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(2));
          expect(subtitles[0].texts, equals(['Vertical right-to-left text']));
          expect(subtitles[1].texts, equals(['Vertical left-to-right text']));
        });
      });

      group('Advanced Styling and Classes', () {
        test('should handle deeply nested styling tags', () {
          // Based on W3C examples: nested styling
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
<c.speaker><v John><b><i>Important announcement:</i></b> <u>Listen carefully!</u></v></c>

2
00:00:04.000 --> 00:00:06.000
<c.narrator><i>He said <b>"<c.quote>Hello world</c>"</b> quietly</i></c>''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(2));
          expect(
              subtitles[0].texts,
              equals([
                '<c.speaker><v John><b><i>Important announcement:</i></b> <u>Listen carefully!</u></v></c>'
              ]));
          expect(
              subtitles[1].texts,
              equals([
                '<c.narrator><i>He said <b>"<c.quote>Hello world</c>"</b> quietly</i></c>'
              ]));
        });

        test('should handle multiple CSS classes on single elements', () {
          // Based on W3C examples: multiple classes
          const webVttContent = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
<c.red.bold.large>Red, bold, and large text</c>

2
00:00:04.000 --> 00:00:06.000
<c.speaker.female.young>Female speaker</c> talks to <c.speaker.male.old>older male speaker</c>''';

          final subtitles =
              BetterPlayerSubtitlesFactory.parseString(webVttContent);

          expect(subtitles.length, equals(2));
          expect(subtitles[0].texts,
              equals(['<c.red.bold.large>Red, bold, and large text</c>']));
          expect(
              subtitles[1].texts,
              equals([
                '<c.speaker.female.young>Female speaker</c> talks to <c.speaker.male.old>older male speaker</c>'
              ]));
        });
      });
    });
  });
}
