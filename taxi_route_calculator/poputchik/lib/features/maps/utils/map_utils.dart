import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart' hide TextStyle;
import 'package:yandex_maps_mapkit/mapkit.dart' hide TextStyle;
import 'package:flutter/painting.dart' show TextStyle;

extension VisibleRegionToBoundingBox on VisibleRegion {
  BoundingBox toBoundingBox() => BoundingBox(bottomLeft, topRight);
}

extension ToTextSpans on SpannableString {
  List<TextSpan> toTextSpans({
    required Color defaultColor,
    required Color spanColor,
  }) {
    var spannableTexts = <TextSpan>[];

    if (spans.isNotEmpty) {
      spannableTexts.add(
        TextSpan(
          text: text.substring(0, spans.first.begin),
          style: TextStyle(
            color: defaultColor,
          ),
        ),
      );

      spans.forEachIndexed((index, span) {
        spannableTexts.add(
          TextSpan(
            text: text.substring(span.begin, span.end),
            style: TextStyle(
              color: spanColor,
            ),
          ),
        );
      });

      if (spans.last.end != text.length) {
        spannableTexts.add(
          TextSpan(
            text: text.substring(spans.last.end),
            style: TextStyle(
              color: defaultColor,
            ),
          ),
        );
      }
    } else {
      spannableTexts.add(
        TextSpan(
          text: text,
          style: TextStyle(
            color: defaultColor,
          ),
        ),
      );
    }
    return spannableTexts;
  }
}