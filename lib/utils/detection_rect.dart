import 'dart:ui' as ui;

extension DetectionRect on ui.Rect {
  ui.Rect operator /(double value) {
    return ui.Rect.fromLTRB(left / value, top / value, right / value, bottom / value);
  }
}
