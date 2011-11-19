var ALPHA_GRID, COL_EMPTY, COL_FULL, COL_GRID, COL_TEXT, COL_UNKNOWN, CURSOR_DOWN, CURSOR_LEFT, CURSOR_RIGHT, CURSOR_SELECT, CURSOR_SELECT2, CURSOR_UP, Cell, GRID_EMPTY, GRID_FULL, GRID_UNKNOWN, GameState, IS_CURSOR_MOVE, IS_CURSOR_SELECT, IS_MOUSE_DOWN, IS_MOUSE_DRAG, IS_MOUSE_RELEASE, LEFT_BUTTON, LEFT_DRAG, LEFT_RELEASE, MIDDLE_BUTTON, MIDDLE_DRAG, MIDDLE_RELEASE, RIGHT_BUTTON, RIGHT_DRAG, RIGHT_RELEASE, compute_rowdata, do_row, game_drawstate, game_ui, generate, generate_soluble, interpret_move;
COL_TEXT = '#000';
COL_EMPTY = '#fff';
COL_UNKNOWN = '#9e9b7d';
COL_FULL = '#38372c';
COL_GRID = '#6b6955';
ALPHA_GRID = 0.2;
GRID_UNKNOWN = 2;
GRID_FULL = 1;
GRID_EMPTY = 0;
LEFT_BUTTON = 1;
MIDDLE_BUTTON = 2;
RIGHT_BUTTON = 3;
LEFT_DRAG = 4;
MIDDLE_DRAG = 5;
RIGHT_DRAG = 6;
LEFT_RELEASE = 7;
MIDDLE_RELEASE = 8;
RIGHT_RELEASE = 9;
CURSOR_UP = 10;
CURSOR_DOWN = 11;
CURSOR_LEFT = 12;
CURSOR_RIGHT = 13;
CURSOR_SELECT = 14;
CURSOR_SELECT2 = 15;
IS_MOUSE_DOWN = function(m) {
  return m - LEFT_BUTTON <= RIGHT_BUTTON - LEFT_BUTTON;
};
IS_MOUSE_DRAG = function(m) {
  return m - LEFT_DRAG <= RIGHT_DRAG - LEFT_DRAG;
};
IS_MOUSE_RELEASE = function(m) {
  return m - LEFT_RELEASE <= RIGHT_RELEASE - LEFT_RELEASE;
};
IS_CURSOR_MOVE = function(m) {
  return m === CURSOR_UP || m === CURSOR_DOWN || m === CURSOR_RIGHT || m === CURSOR_LEFT;
};
IS_CURSOR_SELECT = function(m) {
  return m === CURSOR_SELECT || m === CURSOR_SELECT2;
};
Cell = (function() {
  function Cell(v) {
    this.v = v != null ? v : GRID_EMPTY;
    null;
  }
  Cell.prototype.clone = function() {
    return new Cell(this.v);
  };
  return Cell;
})();
GameState = (function() {
  function GameState(w, h, generate) {
    var solution_grid, x, y;
    this.w = w;
    this.h = h;
    if (generate == null) {
      generate = true;
    }
    if (this.w <= 0 || this.h <= 0) {
      throw 'Width and height must both be greater than zero';
    }
    this.grid = (function() {
      var _ref, _results;
      _results = [];
      for (y = 0, _ref = this.h - 1; 0 <= _ref ? y <= _ref : y >= _ref; 0 <= _ref ? y++ : y--) {
        _results.push((function() {
          var _ref2, _results2;
          _results2 = [];
          for (x = 0, _ref2 = this.w - 1; 0 <= _ref2 ? x <= _ref2 : x >= _ref2; 0 <= _ref2 ? x++ : x--) {
            _results2.push(new Cell(GRID_UNKNOWN));
          }
          return _results2;
        }).call(this));
      }
      return _results;
    }).call(this);
    this.completed = false;
    if (generate) {
      solution_grid = generate_soluble(this.w, this.h);
      this.coldata = (function() {
        var _ref, _results;
        _results = [];
        for (x = 0, _ref = this.w - 1; 0 <= _ref ? x <= _ref : x >= _ref; 0 <= _ref ? x++ : x--) {
          _results.push(compute_rowdata(solution_grid.column(x)));
        }
        return _results;
      }).call(this);
      this.rowdata = (function() {
        var _ref, _results;
        _results = [];
        for (y = 0, _ref = this.h - 1; 0 <= _ref ? y <= _ref : y >= _ref; 0 <= _ref ? y++ : y--) {
          _results.push(compute_rowdata(solution_grid[y]));
        }
        return _results;
      }).call(this);
    }
  }
  GameState.prototype.clone = function() {
    var cell, r, row;
    r = new GameState(this.w, this.h, false);
    r.grid = (function() {
      var _i, _len, _ref, _results;
      _ref = this.grid;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _results.push((function() {
          var _j, _len2, _results2;
          _results2 = [];
          for (_j = 0, _len2 = row.length; _j < _len2; _j++) {
            cell = row[_j];
            _results2.push(cell.clone());
          }
          return _results2;
        })());
      }
      return _results;
    }).call(this);
    r.completed = this.completed;
    r.rowdata = this.rowdata;
    r.coldata = this.coldata;
    return r;
  };
  GameState.prototype.execute_move = function(val, x1, y1, x2, y2) {
    var coldata, ret, rowdata, x, y, _ref, _ref2;
    if (x2 == null) {
      x2 = x1;
    }
    if (y2 == null) {
      y2 = y1;
    }
    ret = this.clone();
    for (y = y1; y <= y2; y += 1) {
      for (x = x1; x <= x2; x += 1) {
        ret.grid[y][x].v = val;
      }
    }
    if (!ret.completed) {
      ret.completed = true;
      for (x = 0, _ref = ret.w - 1; 0 <= _ref ? x <= _ref : x >= _ref; 0 <= _ref ? x++ : x--) {
        coldata = compute_rowdata(ret.grid.column(x));
        if (!ret.coldata[x].equals(coldata)) {
          ret.completed = false;
          break;
        }
      }
      for (y = 0, _ref2 = ret.h - 1; 0 <= _ref2 ? y <= _ref2 : y >= _ref2; 0 <= _ref2 ? y++ : y--) {
        rowdata = compute_rowdata(ret.grid[y]);
        if (!ret.rowdata[y].equals(rowdata)) {
          ret.completed = false;
          break;
        }
      }
    }
    return ret;
  };
  return GameState;
})();
generate = function(w, h) {
  var dx, dy, fgrid, n, step, sx, threshold, x, y, _i, _len, _ref, _ref2, _results;
  fgrid = (function() {
    var _ref, _results;
    _results = [];
    for (y = 0, _ref = h - 1; 0 <= _ref ? y <= _ref : y >= _ref; 0 <= _ref ? y++ : y--) {
      _results.push((function() {
        var _ref2, _results2;
        _results2 = [];
        for (x = 0, _ref2 = w - 1; 0 <= _ref2 ? x <= _ref2 : x >= _ref2; 0 <= _ref2 ? x++ : x--) {
          _results2.push(Math.random());
        }
        return _results2;
      })());
    }
    return _results;
  })();
  _ref = [1];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    step = _ref[_i];
    fgrid = (function() {
      var _ref2, _results;
      _results = [];
      for (y = 0, _ref2 = h - 1; 0 <= _ref2 ? y <= _ref2 : y >= _ref2; 0 <= _ref2 ? y++ : y--) {
        _results.push((function() {
          var _ref3, _ref4, _ref5, _results2;
          _results2 = [];
          for (x = 0, _ref3 = w - 1; 0 <= _ref3 ? x <= _ref3 : x >= _ref3; 0 <= _ref3 ? x++ : x--) {
            n = 0;
            sx = 0.0;
            for (dy = -1; dy <= 1; dy++) {
              if ((0 <= (_ref4 = y + dy) && _ref4 < h)) {
                for (dx = -1; dx <= 1; dx++) {
                  if ((0 <= (_ref5 = x + dx) && _ref5 < w)) {
                    if ((h === 2 && dy !== 0) || (w === 2 && dx !== 0)) {
                      continue;
                    }
                    n++;
                    sx += fgrid[y + dy][x + dx];
                  }
                }
              }
            }
            _results2.push(sx / n);
          }
          return _results2;
        })());
      }
      return _results;
    })();
  }
  threshold = fgrid.median();
  _results = [];
  for (y = 0, _ref2 = h - 1; 0 <= _ref2 ? y <= _ref2 : y >= _ref2; 0 <= _ref2 ? y++ : y--) {
    _results.push((function() {
      var _ref3, _results2;
      _results2 = [];
      for (x = 0, _ref3 = w - 1; 0 <= _ref3 ? x <= _ref3 : x >= _ref3; 0 <= _ref3 ? x++ : x--) {
        _results2.push(fgrid[y][x] >= threshold ? new Cell(GRID_FULL) : new Cell(GRID_EMPTY));
      }
      return _results2;
    })());
  }
  return _results;
};
compute_rowdata = function(run) {
  var cell, current, ret, _i, _len;
  ret = [];
  current = 0;
  for (_i = 0, _len = run.length; _i < _len; _i++) {
    cell = run[_i];
    switch (cell.v) {
      case GRID_FULL:
        current++;
        break;
      case GRID_EMPTY:
        if (current > 0) {
          ret.push(current);
          current = 0;
        }
        break;
      case GRID_UNKNOWN:
        return null;
    }
  }
  if (current > 0) {
    ret.push(current);
  }
  return ret;
};
do_row = function(start, data) {
  var d, deduced, do_recurse, done_any, freespace, i, row, x, _i, _len, _ref;
  deduced = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = start.length; _i < _len; _i++) {
      x = start[_i];
      _results.push(0);
    }
    return _results;
  })();
  row = (function() {
    var _i, _len, _results;
    _results = [];
    for (_i = 0, _len = start.length; _i < _len; _i++) {
      x = start[_i];
      _results.push(GRID_EMPTY);
    }
    return _results;
  })();
  do_recurse = function(freespace, ndone, lowest) {
    var i, j, k, run_length, _ref, _ref2, _ref3, _ref4, _ref5;
    if (ndone == null) {
      ndone = 0;
    }
    if (lowest == null) {
      lowest = 0;
    }
    run_length = data[ndone];
    if (run_length) {
      for (i = 0; 0 <= freespace ? i <= freespace : i >= freespace; 0 <= freespace ? i++ : i--) {
        j = lowest;
        for (k = 0, _ref = i - 1; k <= _ref; k += 1) {
          row[j++] = GRID_UNKNOWN;
        }
        for (k = 0, _ref2 = run_length - 1; k <= _ref2; k += 1) {
          row[j++] = GRID_FULL;
        }
        if (j < row.length) {
          row[j++] = GRID_UNKNOWN;
        }
        do_recurse(freespace - i, ndone + 1, j);
      }
    } else {
      for (i = lowest, _ref3 = row.length - 1; i <= _ref3; i += 1) {
        row[i] = GRID_UNKNOWN;
      }
      for (i = 0, _ref4 = row.length - 1; 0 <= _ref4 ? i <= _ref4 : i >= _ref4; 0 <= _ref4 ? i++ : i--) {
        if (start[i].v && start[i].v !== row[i]) {
          return;
        }
      }
      for (i = 0, _ref5 = row.length - 1; 0 <= _ref5 ? i <= _ref5 : i >= _ref5; 0 <= _ref5 ? i++ : i--) {
        deduced[i] |= row[i];
      }
    }
    return null;
  };
  freespace = start.length + 1;
  for (_i = 0, _len = data.length; _i < _len; _i++) {
    d = data[_i];
    freespace -= d + 1;
  }
  do_recurse(freespace);
  done_any = false;
  for (i = 0, _ref = start.length - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
    if ((deduced[i] === GRID_FULL || deduced[i] === GRID_UNKNOWN) && !start[i].v) {
      start[i].v = deduced[i];
      done_any = true;
    }
  }
  return done_any;
};
generate_soluble = function(w, h) {
  var again, cell, done_any, grid, matrix, ok, row, x, y, _i, _j, _len, _len2, _ref, _ref2;
  ok = false;
  while (!ok) {
    grid = generate(w, h);
    again = (function() {
      var cell, colours, row, x, _i, _j, _k, _len, _len2, _len3, _ref, _ref2;
      if (w > 2) {
        for (_i = 0, _len = grid.length; _i < _len; _i++) {
          row = grid[_i];
          colours = 0;
          for (_j = 0, _len2 = row.length; _j < _len2; _j++) {
            cell = row[_j];
            colours |= cell.v === GRID_FULL ? 2 : 1;
          }
          if (colours !== 3) {
            return true;
          }
        }
      }
      if (h > 2) {
        for (x = 0, _ref = w - 1; 0 <= _ref ? x <= _ref : x >= _ref; 0 <= _ref ? x++ : x--) {
          colours = 0;
          _ref2 = grid.column(x);
          for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
            cell = _ref2[_k];
            colours |= cell.v === GRID_FULL ? 2 : 1;
          }
          if (colours !== 3) {
            return true;
          }
        }
      }
    })();
    if (again) {
      continue;
    }
    matrix = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = grid.length; _i < _len; _i++) {
        row = grid[_i];
        _results.push((function() {
          var _j, _len2, _results2;
          _results2 = [];
          for (_j = 0, _len2 = row.length; _j < _len2; _j++) {
            cell = row[_j];
            _results2.push(new Cell());
          }
          return _results2;
        })());
      }
      return _results;
    })();
    done_any = true;
    while (done_any) {
      done_any = false;
      for (y = 0, _ref = h - 1; 0 <= _ref ? y <= _ref : y >= _ref; 0 <= _ref ? y++ : y--) {
        done_any |= do_row(matrix[y], compute_rowdata(grid[y]));
      }
      for (x = 0, _ref2 = w - 1; 0 <= _ref2 ? x <= _ref2 : x >= _ref2; 0 <= _ref2 ? x++ : x--) {
        done_any |= do_row(matrix.column(x), compute_rowdata(grid.column(x)));
      }
    }
    ok = true;
    for (_i = 0, _len = matrix.length; _i < _len; _i++) {
      row = matrix[_i];
      for (_j = 0, _len2 = row.length; _j < _len2; _j++) {
        cell = row[_j];
        if (cell.v === GRID_EMPTY) {
          ok = false;
        }
      }
    }
  }
  return grid;
};
game_ui = (function() {
  function game_ui() {
    this.dragging = false;
    this.cur_x = this.cur_y = 0;
    this.cur_visible = false;
    this.drag_start_x = this.drag_start_y = 0;
    this.drag_end_x = this.drag_end_y = 0;
    this.drag = this.release = this.state = null;
  }
  return game_ui;
})();
interpret_move = function(state, ui, ds, x, y, button) {
  var currstate, move_needed, newstate, x1, x2, xx, y1, y2, yy, _ref;
  _ref = ds.cell_at(x, y), x = _ref[0], y = _ref[1];
  x = Math.min(state.w - 1, Math.max(0, x));
  y = Math.min(state.h - 1, Math.max(0, y));
  if (button === LEFT_BUTTON || button === RIGHT_BUTTON || button === MIDDLE_BUTTON) {
    ui.dragging = true;
    if (button === LEFT_BUTTON) {
      ui.drag = LEFT_DRAG;
      ui.release = LEFT_RELEASE;
      ui.state = GRID_FULL;
    } else if (button === RIGHT_BUTTON) {
      ui.drag = RIGHT_DRAG;
      ui.release = RIGHT_RELEASE;
      ui.state = GRID_EMPTY;
    } else {
      ui.drag = MIDDLE_DRAG;
      ui.release = MIDDLE_RELEASE;
      ui.state = GRID_UNKNOWN;
    }
    ui.drag_start_x = ui.drag_end_x = x;
    ui.drag_start_y = ui.drag_end_y = y;
    ui.cur_visible = false;
    return null;
  } else if (ui.dragging && button === ui.drag) {
    if (ui.state !== GRID_UNKNOWN) {
      if (Math.abs(x - ui.drag_start_x) > Math.abs(y - ui.drag_start_y)) {
        y = ui.drag_start_y;
      } else {
        x = ui.drag_start_x;
      }
    }
    x = Math.max(x, 0);
    y = Math.max(y, 0);
    x = Math.min(x, state.w - 1);
    y = Math.min(y, state.h - 1);
    ui.drag_end_x = x;
    ui.drag_end_y = y;
    return null;
  } else if (ui.dragging && button === ui.release) {
    move_needed = false;
    x1 = Math.min(ui.drag_start_x, ui.drag_end_x);
    x2 = Math.max(ui.drag_start_x, ui.drag_end_x);
    y1 = Math.min(ui.drag_start_y, ui.drag_end_y);
    y2 = Math.max(ui.drag_start_y, ui.drag_end_y);
    for (yy = y1; y1 <= y2 ? yy <= y2 : yy >= y2; y1 <= y2 ? yy++ : yy--) {
      for (xx = x1; x1 <= x2 ? xx <= x2 : xx >= x2; x1 <= x2 ? xx++ : xx--) {
        if (state.grid[yy][xx].v !== ui.state) {
          move_needed = true;
          break;
        }
      }
    }
    ui.dragging = false;
    if (move_needed) {
      return [ui.state, x1, y1, x2, y2];
    } else {
      return null;
    }
  } else if (IS_CURSOR_MOVE(button)) {
    ui.cur_visible = true;
    switch (button) {
      case CURSOR_UP:
        ui.cur_y = 0 | ((ui.cur_y - 1 + state.h) % state.h);
        break;
      case CURSOR_DOWN:
        ui.cur_y = 0 | ((ui.cur_y + 1) % state.h);
        break;
      case CURSOR_LEFT:
        ui.cur_x = 0 | ((ui.cur_x - 1 + state.w) % state.w);
        break;
      case CURSOR_RIGHT:
        ui.cur_x = 0 | ((ui.cur_x + 1) % state.w);
    }
    return null;
  } else if (IS_CURSOR_SELECT(button)) {
    currstate = state.grid[ui.cur_y][ui.cur_x].v;
    if (!ui.cur_visible) {
      ui.cur_visible = true;
      return null;
    } else {
      newstate = button === CURSOR_SELECT2 ? currstate === GRID_UNKNOWN ? GRID_EMPTY : currstate === GRID_EMPTY ? GRID_FULL : GRID_UNKNOWN : currstate === GRID_UNKNOWN ? GRID_FULL : currstate === GRID_FULL ? GRID_EMPTY : GRID_UNKNOWN;
      return [newstate, ui.cur_x, ui.cur_y];
    }
  } else {
    return null;
  }
};
game_drawstate = (function() {
  function game_drawstate(dr) {
    this.dr = dr;
    null;
  }
  game_drawstate.prototype.cell_at = function(mx, my) {
    return [0 | ((mx - this.center_x) / this.tile_size) - this.offset_x, 0 | (my / this.tile_size) - this.offset_y];
  };
  game_drawstate.prototype.game_redraw = function(state, ui) {
    var cols, cx, cy, dh, dw, dx, dy, i, j, longest_coldata, longest_rowdata, m, rows, run_length, total_h, total_w, val, x, x1, x2, xl, xr, y, y1, y2, yb, yt, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
    longest_coldata = 0;
    for (x = 0, _ref = state.w - 1; 0 <= _ref ? x <= _ref : x >= _ref; 0 <= _ref ? x++ : x--) {
      longest_coldata = Math.max(longest_coldata, state.coldata[x].length);
    }
    longest_rowdata = 0;
    for (y = 0, _ref2 = state.h - 1; 0 <= _ref2 ? y <= _ref2 : y >= _ref2; 0 <= _ref2 ? y++ : y--) {
      longest_rowdata = Math.max(longest_rowdata, state.rowdata[y].length);
    }
    total_w = 2 * longest_rowdata + state.w;
    total_h = 2 * longest_coldata + state.h;
    this.tile_size = Math.min(40, Math.min(0 | (this.dr.canvas.width / total_w), 0 | (this.dr.canvas.height / total_h)));
    this.offset_x = longest_rowdata;
    this.offset_y = longest_coldata;
    this.center_x = 0 | ((this.dr.canvas.width - total_w * this.tile_size) / 2);
    this.dr.canvas.width = this.dr.canvas.width;
    this.dr.save();
    this.dr.translate(this.offset_x * this.tile_size + this.center_x, this.offset_y * this.tile_size);
    this.dr.fillStyle = COL_TEXT;
    this.dr.font = "bold " + (this.tile_size / 2) + "px sans-serif";
    this.dr.textAlign = 'center';
    this.dr.textBaseline = 'middle';
    _ref3 = state.coldata;
    for (i = 0, _len = _ref3.length; i < _len; i++) {
      cols = _ref3[i];
      for (j = 0, _len2 = cols.length; j < _len2; j++) {
        run_length = cols[j];
        x = i * this.tile_size;
        y = (j - cols.length) * this.tile_size;
        this.dr.fillText("" + run_length, x + this.tile_size / 2, y + this.tile_size / 2);
      }
    }
    _ref4 = state.rowdata;
    for (i = 0, _len3 = _ref4.length; i < _len3; i++) {
      rows = _ref4[i];
      for (j = 0, _len4 = rows.length; j < _len4; j++) {
        run_length = rows[j];
        x = (j - rows.length) * this.tile_size;
        y = i * this.tile_size;
        this.dr.fillText("" + run_length, x + this.tile_size / 2, y + this.tile_size / 2);
      }
    }
    if (ui.dragging) {
      x1 = Math.min(ui.drag_start_x, ui.drag_end_x);
      x2 = Math.max(ui.drag_start_x, ui.drag_end_x);
      y1 = Math.min(ui.drag_start_y, ui.drag_end_y);
      y2 = Math.max(ui.drag_start_y, ui.drag_end_y);
    }
    if (ui.cur_visible) {
      cx = ui.cur_x;
      cy = ui.cur_y;
    } else {
      cx = cy = -1;
    }
    for (y = 0, _ref5 = state.h - 1; 0 <= _ref5 ? y <= _ref5 : y >= _ref5; 0 <= _ref5 ? y++ : y--) {
      for (x = 0, _ref6 = state.w - 1; 0 <= _ref6 ? x <= _ref6 : x >= _ref6; 0 <= _ref6 ? x++ : x--) {
        this.dr.save();
        this.dr.translate(x * this.tile_size, y * this.tile_size);
        val = ui.dragging && (x1 <= x && x <= x2) && (y1 <= y && y <= y2) ? ui.state : state.grid[y][x].v;
        xl = +(0 | (x % 5) === 0);
        yt = +(0 | (y % 5) === 0);
        xr = +(0 | (x % 5) === 4 || x === state.w - 1);
        yb = +(0 | (y % 5) === 4 || y === state.h - 1);
        dx = 1 + xl;
        dy = 1 + yt;
        this.dr.translate(dx, dy);
        dw = this.tile_size - xl - xr - 1;
        dh = this.tile_size - yt - yb - 1;
        this.dr.strokeStyle = COL_GRID;
        this.dr.strokeRect(-1 + 0.5, -1 + 0.5, dw + 1, dh + 1);
        switch (val) {
          case GRID_FULL:
            this.dr.fillStyle = COL_FULL;
            this.dr.fillRect(0, 0, dw, dh);
            break;
          case GRID_UNKNOWN:
            this.dr.fillStyle = COL_UNKNOWN;
            this.dr.fillRect(0, 0, dw, dh);
            break;
          case GRID_EMPTY:
            this.dr.fillStyle = COL_EMPTY;
            this.dr.fillRect(0, 0, dw, dh);
            this.dr.strokeStyle = COL_GRID;
            this.dr.beginPath();
            this.dr.save();
            this.dr.translate(0.5, 0.5);
            m = this.tile_size / 6;
            this.dr.moveTo(m / 2, m / 2);
            this.dr.lineTo(this.tile_size - m, this.tile_size - m);
            this.dr.moveTo(m / 2, this.tile_size - m);
            this.dr.lineTo(this.tile_size - m, m / 2);
            this.dr.stroke();
            this.dr.restore();
        }
        if (x === cx && y === cy) {
          this.dr.beginPath();
          this.dr.arc(dw / 2, dw / 2, this.tile_size * 0.25, 0, Math.PI * 2, false);
          this.dr.strokeStyle = '#000';
          this.dr.lineWidth = 2.5;
          this.dr.stroke();
          this.dr.strokeStyle = '#fff';
          this.dr.lineWidth = 1.5;
          this.dr.stroke();
        }
        this.dr.restore();
      }
    }
    return this.dr.restore();
  };
  return game_drawstate;
})();
window.onload = function() {
  var again_button, canvas, ctx, current_state, draw, ds, fail, handle_mouseup, make_move, mouse_is_down, play_button, redo_move, setup, setup_height, setup_width, start_game, states, ui, undo_move, won, x, y;
  canvas = document.getElementById('game');
  canvas.style.display = 'block';
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  ctx = canvas.getContext('2d');
  ui = new game_ui();
  ds = new game_drawstate(ctx);
  setup = document.getElementById('setup');
  setup_width = document.getElementById('width');
  setup_height = document.getElementById('height');
  play_button = document.getElementById('play');
  won = document.getElementById('won');
  again_button = document.getElementById('again');
  fail = document.getElementById('fail');
  fail.style.display = 'none';
  again_button.onclick = function() {
    won.style.display = 'none';
    return setup.style.display = 'block';
  };
  setup.style.display = 'block';
  states = [];
  current_state = 0;
  draw = function() {
    if ((0 <= current_state && current_state < states.length)) {
      return ds.game_redraw(states[current_state], ui);
    }
  };
  start_game = function() {
    var h, w;
    w = 0 | +setup_width.value;
    h = 0 | +setup_height.value;
    if ((2 <= w && w <= 50) && (2 <= h && h <= 50)) {
      states = [new GameState(w, h)];
      current_state = 0;
      return draw();
    }
  };
  play_button.onclick = function() {
    start_game();
    return setup.style.display = 'none';
  };
  make_move = function(button, x, y) {
    var mov, new_state, _ref;
    if ((0 <= current_state && current_state < states.length) && !states[current_state].completed) {
      mov = interpret_move(states[current_state], ui, ds, x, y, button);
      if (mov) {
        new_state = (_ref = states[current_state]).execute_move.apply(_ref, mov);
        states = states.slice(0, (current_state + 1) || 9e9);
        states.push(new_state);
        current_state++;
      }
      draw();
      if (states[current_state].completed) {
        return won.style.display = 'block';
      }
    }
  };
  undo_move = function() {
    if (current_state > 0) {
      current_state--;
      draw();
      return true;
    } else {
      return false;
    }
  };
  redo_move = function() {
    if (current_state < states.length - 1) {
      current_state++;
      draw();
      return true;
    } else {
      return false;
    }
  };
  window.onkeydown = function(event) {
    switch (event.keyCode) {
      case 37:
      case 65:
        make_move(CURSOR_LEFT);
        return event.preventDefault();
      case 38:
      case 87:
        make_move(CURSOR_UP);
        return event.preventDefault();
      case 39:
      case 68:
        make_move(CURSOR_RIGHT);
        return event.preventDefault();
      case 40:
      case 83:
        make_move(CURSOR_DOWN);
        return event.preventDefault();
      case 32:
        make_move(CURSOR_SELECT);
        return event.preventDefault();
      case 13:
        make_move(CURSOR_SELECT2);
        return event.preventDefault();
      case 85:
        if (undo_move()) {
          return event.preventDefault();
        }
        break;
      case 82:
        if (redo_move()) {
          return event.preventDefault();
        }
    }
  };
  canvas.oncontextmenu = function(event) {
    event.stopImmediatePropagation();
    return event.preventDefault();
  };
  mouse_is_down = false;
  x = y = 0;
  canvas.onmousedown = function(event) {
    mouse_is_down = true;
    event.stopImmediatePropagation();
    event.preventDefault();
    x = event.clientX;
    y = event.clientY;
    switch (event.button) {
      case 0:
        return make_move(LEFT_BUTTON, x, y);
      case 1:
        return make_move(MIDDLE_BUTTON, x, y);
      case 2:
        return make_move(RIGHT_BUTTON, x, y);
    }
  };
  handle_mouseup = function() {
    switch (event.button) {
      case 0:
        return make_move(LEFT_RELEASE, x, y);
      case 1:
        return make_move(MIDDLE_RELEASE, x, y);
      case 2:
        return make_move(RIGHT_RELEASE, x, y);
    }
  };
  canvas.onmouseup = function(event) {
    mouse_is_down = false;
    event.stopImmediatePropagation();
    event.preventDefault();
    x = event.clientX;
    y = event.clientY;
    return handle_mouseup();
  };
  window.onmouseup = function() {
    mouse_is_down = false;
    return handle_mouseup();
  };
  canvas.onmousemove = function(event) {
    if (mouse_is_down) {
      event.preventDefault();
      x = event.clientX;
      y = event.clientY;
      switch (event.button) {
        case 0:
          return make_move(LEFT_DRAG, x, y);
        case 1:
          return make_move(MIDDLE_DRAG, x, y);
        case 2:
          return make_move(RIGHT_DRAG, x, y);
      }
    }
  };
  window.onresize = function(event) {
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    return draw();
  };
  return draw();
};