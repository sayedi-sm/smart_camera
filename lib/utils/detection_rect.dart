import 'dart:ui' as ui;

extension DetectionRect on ui.Rect {
  ui.Rect operator /(double operand) {
    return ui.Rect.fromLTRB(left / operand, top / operand, right / operand, bottom / operand);
  }
}
