import 'dart:math';

enum DiffOp { equal, insert, delete }

class DiffSegment {
  final DiffOp op;
  final String text;
  const DiffSegment(this.op, this.text);

  @override
  bool operator ==(Object other) =>
      other is DiffSegment && other.op == op && other.text == text;

  @override
  int get hashCode => Object.hash(op, text);

  @override
  String toString() => 'DiffSegment($op, "$text")';
}

/// Word-level diff between [oldText] and [newText] using a longest-common-
/// subsequence, coalescing consecutive segments of the same kind. Words are
/// split on single spaces. Pure (no Flutter) so it can be unit tested.
List<DiffSegment> diffWords(String oldText, String newText) {
  final a = oldText.split(' ');
  final b = newText.split(' ');
  final m = a.length, n = b.length;

  final lcs = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = m - 1; i >= 0; i--) {
    for (var j = n - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : max(lcs[i + 1][j], lcs[i][j + 1]);
    }
  }

  final raw = <DiffSegment>[];
  var i = 0, j = 0;
  while (i < m && j < n) {
    if (a[i] == b[j]) {
      raw.add(DiffSegment(DiffOp.equal, a[i]));
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      raw.add(DiffSegment(DiffOp.delete, a[i]));
      i++;
    } else {
      raw.add(DiffSegment(DiffOp.insert, b[j]));
      j++;
    }
  }
  while (i < m) {
    raw.add(DiffSegment(DiffOp.delete, a[i]));
    i++;
  }
  while (j < n) {
    raw.add(DiffSegment(DiffOp.insert, b[j]));
    j++;
  }

  final out = <DiffSegment>[];
  for (final seg in raw) {
    if (out.isNotEmpty && out.last.op == seg.op) {
      out[out.length - 1] = DiffSegment(seg.op, '${out.last.text} ${seg.text}');
    } else {
      out.add(seg);
    }
  }
  return out;
}
