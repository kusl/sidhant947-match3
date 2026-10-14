import 'dart:math';

import 'package:match3/domain/models/level_goal.dart';
import 'package:match3/domain/models/tile_model.dart';

class _Cell {
  _Cell(this.id, this.emoji, this.type, this.frozen, this.crateHp);

  final String id;
  String? emoji;
  TileType type;
  bool frozen;
  int crateHp;

  bool get canSwap => !frozen && type != TileType.crate;

  _Cell clone() => _Cell(id, emoji, type, frozen, crateHp);
}

class _Scan {
  _Scan(this.matched, this.specials);

  final List<int> matched;
  final Map<int, TileType> specials;
}

class _Outcome {
  int points = 0;
  int targetFruit = 0;
  int specials = 0;
  int specialValue = 0;
  int combos = 0;
  int jelly = 0;
  int obstacles = 0;
}

class BestMoveFinder {
  BestMoveFinder({
    required this.rows,
    required this.cols,
    required this.goal,
    required this.jellyTiles,
    required this.colorBombEmoji,
  });

  final int rows;
  final int cols;
  final LevelGoal goal;
  final Set<String> jellyTiles;
  final String colorBombEmoji;

  int get _size => rows * cols;

  List<TileModel>? findBestSwap(List<TileModel> tiles) {
    final origin = List<TileModel?>.filled(_size, null);
    final base = _buildGrid(tiles, origin);
    List<TileModel>? best;
    var bestValue = double.negativeInfinity;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final a = r * cols + c;
        if (origin[a] == null || !base[a]!.canSwap) continue;
        for (final next in [(r, c + 1), (r + 1, c)]) {
          if (next.$1 >= rows || next.$2 >= cols) continue;
          final b = next.$1 * cols + next.$2;
          if (origin[b] == null || !base[b]!.canSwap) continue;

          final double value;
          if (_isSpecialCombo(base[a]!, base[b]!)) {
            value = (_evaluate(_simulateSwap(base, a, b)!) + _evaluate(_simulateSwap(base, b, a)!)) / 2;
          } else {
            final outcome = _simulateSwap(base, a, b);
            if (outcome == null) continue;
            value = _evaluate(outcome);
          }

          if (value > bestValue) {
            bestValue = value;
            best = [origin[a]!, origin[b]!];
          }
        }
      }
    }
    return best;
  }

  List<TileModel>? findBestTwist(List<TileModel> tiles) {
    final origin = List<TileModel?>.filled(_size, null);
    final base = _buildGrid(tiles, origin);
    List<TileModel>? best;
    var bestValue = double.negativeInfinity;

    for (var r = 0; r < rows - 1; r++) {
      for (var c = 0; c < cols - 1; c++) {
        final tl = r * cols + c;
        final tr = r * cols + c + 1;
        final br = (r + 1) * cols + c + 1;
        final bl = (r + 1) * cols + c;
        final cluster = [tl, tr, br, bl];
        if (cluster.any((i) => origin[i] == null || !base[i]!.canSwap)) continue;

        final g = _clone(base);
        g[tr] = base[tl]!.clone();
        g[br] = base[tr]!.clone();
        g[bl] = base[br]!.clone();
        g[tl] = base[bl]!.clone();

        final prio = {for (final i in cluster) base[i]!.id};
        if (_scan(g, prio).matched.isEmpty) continue;

        final outcome = _Outcome();
        _resolve(g, prio, outcome, Set<String>.of(jellyTiles), 0);
        final value = _evaluate(outcome);
        if (value > bestValue) {
          bestValue = value;
          best = [for (final i in cluster) origin[i]!];
        }
      }
    }
    return best;
  }

  List<_Cell?> _buildGrid(List<TileModel> tiles, List<TileModel?> origin) {
    final g = List<_Cell?>.filled(_size, null);
    for (final t in tiles) {
      if (t.row < 0 || t.row >= rows || t.col < 0 || t.col >= cols) continue;
      final i = t.row * cols + t.col;
      g[i] = _Cell(t.id, t.emoji, t.type, t.isFrozen, t.crateHealth);
      origin[i] = t;
    }
    for (var i = 0; i < _size; i++) {
      g[i] ??= _unknown();
    }
    return g;
  }

  _Cell _unknown() => _Cell('', null, TileType.normal, false, 0);

  List<_Cell?> _clone(List<_Cell?> g) => List<_Cell?>.generate(_size, (i) => g[i]!.clone());

  String _key(int i) => '${i ~/ cols}_${i % cols}';

  bool _isSpecialCombo(_Cell a, _Cell b) {
    if (a.type == TileType.colorBomb || b.type == TileType.colorBomb) return true;
    return a.type != TileType.normal && b.type != TileType.normal;
  }

  _Outcome? _simulateSwap(List<_Cell?> base, int a, int b) {
    final g = _clone(base);
    final first = g[a]!;
    final second = g[b]!;
    g[a] = second;
    g[b] = first;

    final outcome = _Outcome();
    final jelly = Set<String>.of(jellyTiles);

    if (_isSpecialCombo(first, second)) {
      _applySpecialCombo(g, b, a, outcome, jelly);
      _resolve(g, const {}, outcome, jelly, 1);
      return outcome;
    }

    final prio = {first.id, second.id};
    if (_scan(g, prio).matched.isEmpty) return null;
    _resolve(g, prio, outcome, jelly, 0);
    return outcome;
  }

  void _applySpecialCombo(List<_Cell?> g, int p1, int p2, _Outcome outcome, Set<String> jelly) {
    final t1 = g[p1]!;
    final t2 = g[p2]!;
    final b1 = t1.type == TileType.colorBomb;
    final b2 = t2.type == TileType.colorBomb;
    final s1 = t1.type == TileType.stripedHorizontal || t1.type == TileType.stripedVertical;
    final s2 = t2.type == TileType.stripedHorizontal || t2.type == TileType.stripedVertical;
    final w1 = t1.type == TileType.wrapped;
    final w2 = t2.type == TileType.wrapped;
    final tr = p1 ~/ cols;
    final tc = p1 % cols;
    final all = List<int>.generate(_size, (i) => i);
    final destroy = <int>{p1, p2};

    List<int> sameColor(_Cell other) =>
        other.emoji == null ? const [] : all.where((i) => g[i]!.emoji == other.emoji).toList();

    if (b1 && b2) {
      destroy.addAll(all);
    } else if ((b1 && s2) || (b2 && s1)) {
      final matching = sameColor(b1 ? t2 : t1);
      destroy.addAll(matching);
      for (final m in matching) {
        destroy.addAll(all.where((i) => i ~/ cols == m ~/ cols || i % cols == m % cols));
      }
    } else if ((b1 && w2) || (b2 && w1)) {
      final matching = sameColor(b1 ? t2 : t1);
      destroy.addAll(matching);
      for (final m in matching) {
        destroy.addAll(all.where((i) => (i ~/ cols - m ~/ cols).abs() <= 1 && (i % cols - m % cols).abs() <= 1));
      }
    } else if (b1 || b2) {
      destroy.addAll(sameColor(b1 ? t2 : t1));
    } else if (s1 && s2) {
      destroy.addAll(all.where((i) => i ~/ cols == tr || i % cols == tc));
    } else if ((s1 && w2) || (s2 && w1)) {
      destroy.addAll(all.where((i) => (i ~/ cols - tr).abs() <= 1 || (i % cols - tc).abs() <= 1));
    } else if (w1 && w2) {
      destroy.addAll(all.where((i) => (i ~/ cols - tr).abs() <= 2 && (i % cols - tc).abs() <= 2));
    }

    outcome.points += destroy.length * 60;
    for (final i in destroy) {
      if (jelly.remove(_key(i))) outcome.jelly++;
      if (goal.targetFruitEmoji != null && g[i]!.emoji == goal.targetFruitEmoji) outcome.targetFruit++;
    }
    for (final i in destroy) {
      g[i] = null;
    }
    _cascade(g);
  }

  void _resolve(List<_Cell?> g, Set<String> prio, _Outcome outcome, Set<String> jelly, int combo) {
    var first = true;
    for (var guard = 0; guard < 200; guard++) {
      final scan = _scan(g, first ? prio : const {});
      first = false;
      if (scan.matched.isEmpty) return;

      final exploded = _explode(g, scan.matched);
      final finalExploded = exploded.difference(scan.specials.keys.toSet());

      outcome.points += finalExploded.length * 50;
      for (final i in exploded) {
        if (jelly.remove(_key(i))) outcome.jelly++;
      }
      for (final i in finalExploded) {
        if (goal.targetFruitEmoji != null && g[i]!.emoji == goal.targetFruitEmoji) outcome.targetFruit++;
      }
      outcome.specials += scan.specials.length;
      for (final type in scan.specials.values) {
        outcome.specialValue += _specialWorth(type);
      }
      if (combo > 0) outcome.combos++;
      combo++;

      scan.specials.forEach((i, type) {
        g[i]!.type = type;
        if (type == TileType.colorBomb) g[i]!.emoji = colorBombEmoji;
      });

      for (var i = 0; i < _size; i++) {
        if (finalExploded.contains(i) || !_isAdjacent(i, finalExploded)) continue;
        final cell = g[i]!;
        if (cell.frozen) {
          cell.frozen = false;
          outcome.obstacles++;
        } else if (cell.type == TileType.crate) {
          cell.crateHp--;
          outcome.obstacles++;
          if (cell.crateHp <= 0) {
            cell.type = TileType.normal;
            cell.crateHp = 0;
            cell.emoji = null;
          }
        }
      }

      for (final i in finalExploded) {
        g[i] = null;
      }
      _cascade(g);
    }
  }

  bool _isAdjacent(int i, Set<int> targets) {
    final r = i ~/ cols;
    final c = i % cols;
    return (c > 0 && targets.contains(i - 1)) ||
        (c < cols - 1 && targets.contains(i + 1)) ||
        (r > 0 && targets.contains(i - cols)) ||
        (r < rows - 1 && targets.contains(i + cols));
  }

  int _specialWorth(TileType type) {
    switch (type) {
      case TileType.stripedHorizontal:
      case TileType.stripedVertical:
        return 150;
      case TileType.wrapped:
        return 200;
      case TileType.colorBomb:
        return 300;
      default:
        return 0;
    }
  }

  bool _same(_Cell a, _Cell b) => a.emoji != null && a.emoji == b.emoji;

  int _pick(List<_Cell?> g, List<int> line, Set<String> prio, int fallback) {
    for (final i in line) {
      if (prio.contains(g[i]!.id)) return i;
    }
    return line[fallback];
  }

  _Scan _scan(List<_Cell?> g, Set<String> prio) {
    final matched = <int>{};
    final specials = <int, TileType>{};
    final horizontal = <Set<int>>[];
    final vertical = <Set<int>>[];

    for (var r = 0; r < rows; r++) {
      var start = 0;
      for (var c = 1; c <= cols; c++) {
        final current = c < cols ? g[r * cols + c] : null;
        final startCell = g[r * cols + start]!;
        if (current != null && _same(current, startCell) && current.type != TileType.colorBomb) continue;
        final length = c - start;
        if (length >= 3) {
          final line = [for (var i = start; i < c; i++) r * cols + i];
          matched.addAll(line);
          horizontal.add(line.toSet());
          if (length == 4) {
            specials[_pick(g, line, prio, 1)] = TileType.stripedHorizontal;
          } else if (length >= 5) {
            specials[_pick(g, line, prio, 2)] = TileType.colorBomb;
          }
        }
        start = c;
      }
    }

    for (var c = 0; c < cols; c++) {
      var start = 0;
      for (var r = 1; r <= rows; r++) {
        final current = r < rows ? g[r * cols + c] : null;
        final startCell = g[start * cols + c]!;
        if (current != null && _same(current, startCell) && current.type != TileType.colorBomb) continue;
        final length = r - start;
        if (length >= 3) {
          final line = [for (var i = start; i < r; i++) i * cols + c];
          matched.addAll(line);
          vertical.add(line.toSet());
          if (length == 4) {
            specials[_pick(g, line, prio, 1)] = TileType.stripedVertical;
          } else if (length >= 5) {
            specials[_pick(g, line, prio, 2)] = TileType.colorBomb;
          }
        }
        start = r;
      }
    }

    for (final h in horizontal) {
      for (final v in vertical) {
        final intersection = h.intersection(v);
        if (intersection.isNotEmpty && specials[intersection.first] != TileType.colorBomb) {
          specials[intersection.first] = TileType.wrapped;
        }
      }
    }

    return _Scan(matched.toList(), specials);
  }

  Set<int> _explode(List<_Cell?> g, List<int> initial) {
    final exploded = <int>{...initial};
    final queue = List<int>.of(initial);
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final r = current ~/ cols;
      final c = current % cols;
      final type = g[current]!.type;
      Iterable<int> targets;
      if (type == TileType.stripedHorizontal) {
        targets = [for (var cc = 0; cc < cols; cc++) r * cols + cc];
      } else if (type == TileType.stripedVertical) {
        targets = [for (var rr = 0; rr < rows; rr++) rr * cols + c];
      } else if (type == TileType.wrapped) {
        targets = [
          for (var rr = max(0, r - 1); rr <= min(rows - 1, r + 1); rr++)
            for (var cc = max(0, c - 1); cc <= min(cols - 1, c + 1); cc++) rr * cols + cc
        ];
      } else {
        continue;
      }
      for (final t in targets) {
        if (exploded.add(t)) queue.add(t);
      }
    }
    return exploded;
  }

  void _cascade(List<_Cell?> g) {
    for (var c = 0; c < cols; c++) {
      var target = rows - 1;
      for (var r = rows - 1; r >= 0; r--) {
        final cell = g[r * cols + c];
        if (cell == null) continue;
        g[r * cols + c] = null;
        g[target * cols + c] = cell;
        target--;
      }
      while (target >= 0) {
        g[target * cols + c] = _unknown();
        target--;
      }
    }
  }

  double _evaluate(_Outcome o) {
    final remaining = max(0, goal.targetValue - goal.currentValue);
    final progress = switch (goal.type) {
      LevelGoalType.score => o.points,
      LevelGoalType.targetFruit => o.targetFruit,
      LevelGoalType.createSpecials => o.specials,
      LevelGoalType.comboMaster => o.combos,
      LevelGoalType.clearJelly => o.jelly,
    };
    var value = (o.points + o.specialValue + o.obstacles * 40).toDouble();
    if (goal.type != LevelGoalType.score) value += min(progress, remaining) * 1000;
    if (remaining > 0 && progress >= remaining) value += 1e9;
    return value;
  }
}
