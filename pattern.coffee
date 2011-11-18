Math.seedrandom('foo')

COL_BACKGROUND = '#eee'
COL_EMPTY = '#fff'
COL_FULL = '#000'
COL_TEXT = '#000'
COL_UNKNOWN = '#dce'
COL_GRID = '#ccc'
COL_CURSOR = 'yellow'

UNKNOWN = 0
BLOCK = 1
DOT = 2
STILL_UNKNOWN = 3

GRID_UNKNOWN = 2
GRID_FULL = 1
GRID_EMPTY = 0

PREFERRED_TILE_SIZE = 24
TILE_SIZE = 20
BORDER = 3 * TILE_SIZE / 4
TLBORDER = (d) -> d / 5 + 2
GUTTER = TILE_SIZE / 2
FROMCOORD = (d, x) -> 
	(x - (BORDER + GUTTER + TILE_SIZE * TLBORDER(d))) / TILE_SIZE
SIZE = (d) ->
	2 * BORDER + GUTTER + TILE_SIZE * (TLBORDER(d) + d)
GETTILESIZE = (d, w) ->
	w / (2.0 + TLBORDER(d) + d)
TOCOORD = (d, x) ->
	BORDER + GUTTER + TILE_SIZE * (TLBORDER(d) + x)

class GameParams
	constructor: (@w, @h) ->
		if @w <= 0 or @h <= 0
			throw 'Width and height must both be greater than zero'

class Cell
	constructor: (@v) ->
		null

class game_state
	constructor: (params) ->
		@w = params.w
		@h = params.h
		@grid =
			for y in [0 .. @h - 1]
				for x in [0 .. @w - 1]
					new Cell(GRID_UNKNOWN)
		@completed = false
		@cheated = false
		#
		@grid = solution_grid = generate_soluble(@w, @h)
		console.log 'solution', solution_grid
		@rowdata = []
		for x in [0 .. params.w - 1]
			@rowdata.push( compute_rowdata(solution_grid.column(x)) )
		for y in [0 .. params.h - 1]
			@rowdata.push( compute_rowdata(solution_grid[y]) )
		console.log 'rowdatas:', @rowdata

	clone: ->
		throw 'TODO'

# ----------------------------------------------------------------------
# Puzzle generation code.
# 
# For this particular puzzle, it seemed important to me to ensure
# a unique solution. I do this the brute-force way, by having a
# solver algorithm alongside the generator, and repeatedly
# generating a random grid until I find one whose solution is
# unique. It turns out that this isn't too onerous on a modern PC
# provided you keep grid size below around 30. Any offers of
# better algorithms, however, will be very gratefully received.
# 
# Another annoyance of this approach is that it limits the
# available puzzles to those solvable by the algorithm I've used.
# My algorithm only ever considers a single row or column at any
# one time, which means it's incapable of solving the following
# difficult example (found by Bella Image around 1995/6, when she
# and I were both doing maths degrees):
# 
#       2  1  2  1 
#      +--+--+--+--+
# 1 1  |  |  |  |  |
#      +--+--+--+--+
#   2  |  |  |  |  |
#      +--+--+--+--+
#   1  |  |  |  |  |
#      +--+--+--+--+
#   1  |  |  |  |  |
#      +--+--+--+--+
# 
# Obviously this cannot be solved by a one-row-or-column-at-a-time
# algorithm (it would require at least one row or column reading
# `2 1', `1 2', `3' or `4' to get started). However, it can be
# proved to have a unique solution: if the top left square were
# empty, then the only option for the top row would be to fill the
# two squares in the 1 columns, which would imply the squares
# below those were empty, leaving no place for the 2 in the second
# row. Contradiction. Hence the top left square is full, and the
# unique solution follows easily from that starting point.
# 
# (The game ID for this puzzle is 4x4:2/1/2/1/1.1/2/1/1 , in case
# it's useful to anyone.)

generate = (w, h) ->
	fgrid =
		for y in [0 .. h - 1]
			for x in [0 .. w - 1]
				Math.random()
	# The above gives a completely random splattering of black and
	# white cells. We want to gently bias this in favour of _some_
	# reasonably thick areas of white and black, while retaining
	# some randomness and fine detail.
	# 
	# So we evolve the starting grid using a cellular automaton.
	# Currently, I'm doing something very simple indeed, which is
	# to set each square to the average of the surrounding nine
	# cells (or the average of fewer, if we're on a corner).
	for step in [1]
		fgrid =
			for y in [0 .. h - 1]
				for x in [0 .. w - 1]
					# Compute the average of the surrounding cells.
					n = 0
					sx = 0.0
					for dy in [-1 .. +1] when 0 <= y + dy < h
						for dx in [-1 .. +1] when 0 <= x + dx < h
							# An additional special case not mentioned
							# above: if a grid dimension is 2xn then
							# we do not average across that dimension
							# at all. Otherwise a 2x2 grid would
							# contain four identical squares.
							continue if (h == 2 and dy != 0) or (w == 2 and dx != 0)
							n++
							sx += fgrid[y + dy][x + dx]
					sx / n
	# binary grid
	threshold = fgrid.median()
	for y in [0 .. h - 1]
		for x in [0 .. w - 1]
			if fgrid[y][x] >= threshold
				new Cell(GRID_FULL)
			else
				new Cell(GRID_EMPTY)

# run length encoding
compute_rowdata = (run) ->
	ret = []
	current = 0
	for cell in run
		switch cell.v
			when GRID_FULL
				current++
			when GRID_EMPTY
				if current > 0
					ret.push(current)
					current = 0
			when GRID_UNKNOWN
				throw 'unknown'
	if current > 0
		ret.push(current)
	ret


do_recurse = (known, deduced, row, data, freespace, ndone = 0, lowest = 0) ->
	run_length = data[ndone]
	if run_length
		for i in [0 .. freespace]
			j = lowest
			for k in [0 .. i - 1] by 1
				row[j++].v = DOT
			for k in [0 .. run_length - 1] by 1
				row[j++].v = BLOCK
			if j < row.length
				row[j++].v = DOT
			do_recurse(known, deduced, row, data, freespace - i, ndone + 1, j)
	else
		for i in [lowest .. row.length - 1] by 1
			row[i].v = DOT
		for i in [0 .. row.length - 1]
			if known[i].v and known[i].v != row[i].v
				return
		for i in [0 .. row.length - 1]
			deduced[i].v |= row[i].v
	null

do_row = (start, data) ->
	known =
		for x in start
			x
	deduced =
		for x in start
			new Cell(0)

	freespace = start.length + 1
	for d in data
		freespace -= d + 1

	row =
		for x in start
			new Cell(0)
	do_recurse(known, deduced, row, data, freespace)
	done_any = false
	for i in [0 .. start.length - 1]
		if deduced[i] and deduced[i] != STILL_UNKNOWN and not known[i].v
			start[i] = deduced[i]
			done_any = true
	done_any

generate_soluble = (w, h) ->
	ok = false
	while not ok
		console.log 'generate_new'
		grid = generate(w, h)

		# The game is a bit too easy if any row or column is
		# completely black or completely white. An exception is
		# made for rows/columns that are under 3 squares,
		# otherwise nothing will ever be successfully generated.
		ok = true
		if w > 2
			for i in [0 .. h - 1]
				colours = 0
				for j in [0 .. w - 1]
					colours |= if grid[i][j].v == GRID_FULL then 2 else 1
				if colours != 3
					ok = false
		if h > 2
			for j in [0 .. w - 1]
				colours = 0
				for i in [0 .. h - 1]
					colours |= if grid[i][j].v == GRID_FULL then 2 else 1
				if colours != 3
					ok = false
		console.log 'too easy?', ok
		continue if not ok

		matrix =
			for y in [0 .. h - 1]
				for x in [0 .. w - 10]
					new Cell(0)

		done_any = true
		while done_any
			done_any = false
			for i in [0 .. h - 1]
				rowdata = compute_rowdata(grid[i])
				done_any |= do_row(matrix[i], rowdata)
			for i in [0 .. w - 1]
				rowdata = compute_rowdata(grid.column(i))
				done_any |= do_row(matrix.column(i), rowdata)
		console.log matrix, grid
		ok = true
		for row in matrix
			for cell in row
				if cell.v == UNKNOWN
					ok = false
	grid

class game_ui
	constructor: ->
		@dragging = false
		@cur_x = @cur_y = 0
		@cur_visible = false
		@drag_start_x = @drag_start_y = 0
		@drag_end_x = @drag_end_y = 0
		@drag = @release = @state = null

class game_drawstate
	constructor: (state) ->
		@started = false
		@w = state.w
		@h = state.h
		@visible =
			for y in [0 .. @h - 1]
				for x in [0 .. @w - 1]
					255
		@tilesize = 0
		@cur_x = @cur_y = 0

interpret_move = (state, ui, ds, x, y, button) ->
	x = FROMCOORD(state.w, x)
	y = FROMCOORD(state.h, y)
	if x >= 0 and x < state.w and y >= 0 and y < state.h and (button == LEFT_BUTTON or button == RIGHT_BUTTON or button == MIDDLE_BUTTON)
		ui.dragging = true
		if button == LEFT_BUTTON
			ui.drag = LEFT_DRAG
			ui.release = LEFT_RELEASE
			ui.state = GRID_FULL
		else if button == RIGHT_BUTTON
			ui.drag = RIGHT_DRAG
			ui.release = RIGHT_RELEASE
			ui.state = GRID_EMPTY
		else
			ui.drag = MIDDLE_DRAG
			ui.release = MIDDLE_RELEASE
			ui.state = GRID_UNKNOWN
		ui.drag_start_x = ui.drag_end_x = x
		ui.drag_start_y = ui.drag_end_y = x
		ui.cur_visible = false
		null
	else if ui.dragging and button == ui.drag
		# There doesn't seem much point in allowing a rectangle
		# drag; people will generally only want to drag a single
		# horizontal or vertical line, so we make that easy by
		# snapping to it.
		# 
		# Exception: if we're _middle_-button dragging to tag
		# things as UNKNOWN, we may well want to trash an entire
		# area and start over!
		if ui.state != GRID_UNKNOWN
			if Math.abs(x - ui.drag_start_x) > Math.abs(y - ui.drag_start_y)
				y = ui.drag_start_y
			else
				x = ui.drag_start_x
		x = Math.max(x, 0)
		y = Math.max(y, 0)
		x = Math.min(x, state.w - 1)
		y = Math.min(y, state.h - 1)
		ui.drag_end_x = x
		ui.drag_end_y = y
		null
	else if ui.dragging and button == ui.release
		move_needed = false
		x1 = Math.min(ui.drag_start_x, ui.drag_end_x)
		x2 = Math.max(ui.drag_start_x, ui.drag_end_x)
		y1 = Math.min(ui.drag_start_y, ui.drag_end_y)
		y2 = Math.max(ui.drag_start_y, ui.drag_end_y)
		for yy in [y1 .. y2]
			for xx in [x1 .. x2]
				if state.grid[yy][xx].v != ui.state
					move_needed = true
					break
		ui.dragging = false
		if move_needed
			[ui.state, x1, y1, x2 - x1 + 1, y2 - y1 + 1]
		else
			null
	else if IS_CURSOR_MOVE(button)
		ui.cur_visible = true
		switch button
			when CURSOR_UP
				ui.cur_y = (ui.cur_y - 1 + state.h) % state.h
			when CURSOR_DOWN
				ui.cur_y = (ui.cur_y + 1) % state.h
			when CURSOR_LEFT
				ui.cur_x = (ui.cur_x - 1 + state.w) % state.w
			when CURSOR_RIGHT
				ui.cur_x = (ui.cur_x + 1) % state.w
		null
	else if IS_CURSOR_SELECT(button)
		currstate = state.grid[ui.cur_y][ui.cur_x]
		if not ui.cur_visible
			ui.cur_visible = true
			null
		else
			newstate = 
				if button == CURSOR_SELECT2
					if currstate == GRID_UNKNOWN
						GRID_EMPTY
					else if currstate == GRID_EMPTY
						GRID_FULL
					else
						GRID_UNKNOWN
				else
					if currstate == GRID_UNKNOWN
						GRID_FULL
					else if currstate == GRID_FULL
						GRID_EMPTY
					else
						GRID_UNKNOWN
			[newstate, ui.cur_x, ui.cur_y, 1, 1]
	else
		null

execute_move = (from, move) ->
	[val, x1, y1, x2, y2] = move
	return null unless x1 >= 0 and x2 >= 0 and x1 + x2 <= from.w
	return null unless y1 >= 0 and y2 >= 0 and y1 + y2 <= from.h
	x2 += x1
	y2 += y1
	ret = from.clone()
	for y in [y1 .. y2 - 1] by 1
		for x in [x1 .. x2 - 1] by 1
			ret.grid[yy][xx] = val
	# An actual change, so check to see if we've completed the game
	if not ret.completed
		ret.completed = true
		for x in [0 .. ret.w - 1]
			rowdata = compute_rowdata(ret.grid.column(i))
			if not ret.rowdata[i].equals(rowdata)
				ret.completed = false
				break
		for y in [0 .. ret.h - 1]
			rowdata = compute_rowdata(ret.grid[i])
			if not ret.rowdata[i + ret.w].equals(rowdata)
				ret.completed = false
				break
	ret

# ----------------------------------------------------------------------
# Drawing routines.

grid_square = (dr, ds, y, x, state, cur) ->
	dr.fillStyle = COL_GRID
	dr.fillRect(TOCOORD(ds.w, x), TOCOORD(ds.h, y), TILE_SIZE, TILE_SIZE)
	xl = if 0|(x % 5) == 0 then 1 else 0
	yt = if 0|(y % 5) == 0 then 1 else 0
	xr = if 0|(x % 5) == 4 or x == ds.w - 1 then 1 else 0
	yb = if 0|(y % 5) == 4 or y == ds.h - 1 then 1 else 0
	dx = TOCOORD(ds.w, x) + 1 + xl
	dy = TOCOORD(ds.h, y) + 1 + yt
	dw = TILE_SIZE - xl - xr - 1
	dh = TILE_SIZE - yt - yb - 1
	dr.fillStyle =
		if state == GRID_FULL
			COL_FULL
		else if state == GRID_EMPTY
			COL_EMPTY
		else
			COL_UNKNOWN
	dr.fillRect(dx, dy, dw, dh)
	if cur
		dr.strokeStyle = COL_CURSOR
		dr.strokeRect(dx, dy, dw, dh)

draw_numbers = (dr, ds, state) ->
	# Draw the numbers.
	for rowdata, i in state.rowdata
		# Normally I space the numbers out by the same
		# distance as the tile size. However, if there are
		# more numbers than available spaces, I have to squash
		# them up a bit.
		nfit = Math.max(rowdata.length, TLBORDER(state.h)) - 1
		for run_length, j in rowdata
			if i < state.w
				x = TOCOORD(state.w, i)
				y = BORDER + TILE_SIZE * (TLBORDER(state.h) - 1)
				y -= ((rowdata.length-j-1)*TILE_SIZE) * (TLBORDER(state.h)-1) / nfit
			else
				y = TOCOORD(state.h, i - state.w)
				x = BORDER + TILE_SIZE * (TLBORDER(state.w) - 1)
				x -= ((rowdata.length-j-1)*TILE_SIZE) * (TLBORDER(state.h)-1) / nfit
			dr.fillStyle = COL_TEXT
			dr.fillText("#{run_length}", x + TILE_SIZE/2, y + TILE_SIZE/2)

game_redraw = (dr, ds, state, ui) ->
	# The initial contents of the window are not guaranteed
	# and can vary with front ends. To be on the safe side,
	# all games should start by drawing a big background-
	# colour rectangle covering the whole window.
	dr.fillStyle = COL_BACKGROUND
	dr.fillRect(0, 0, SIZE(ds.w), SIZE(ds.h))
	draw_numbers(dr, ds, state)
	dr.strokeStyle = COL_GRID
	dr.strokeRect(TOCOORD(ds.w, 0) - 1, TOCOORD(ds.h, 0) - 1, ds.w * TILE_SIZE + 3, ds.h * TILE_SIZE + 3)
	# Dynamic things
	if ui.dragging
		x1 = Math.min(ui.drag_start_x, ui.drag_end_x)
		x2 = Math.max(ui.drag_start_x, ui.drag_end_x)
		y1 = Math.min(ui.drag_start_y, ui.drag_end_y)
		y2 = Math.max(ui.drag_start_y, ui.drag_end_y)
	if ui.cur_visible
		cx = ui.cur_x
		cy = ui.cur_y
	else
		cx = cy = -1
	# Draw everything.
	for i in [0 .. ds.h - 1]
		for j in [0 .. ds.w - 1]
			# Work out what state this square should be drawn in,
			# taking any current drag operation into account.
			val =
				if ui.dragging and x1 <= j and j <= x2 and y1 <= i and i <= y2
					ui.state
				else
					state.grid[i][j].v
			grid_square(dr, ds, i, j, val, (j == cx && i == cy))
	ds.cur_x = cx
	ds.cur_y = cy

window.onclick = ->
	canvas = document.createElement 'canvas'
	document.body.appendChild canvas
	canvas.width = 300
	canvas.height = 300
	ctx = canvas.getContext '2d'

	params = new GameParams(5, 5)
	state = new game_state(params)
	ui = new game_ui()
	ds = new game_drawstate(state)
	game_redraw(ctx, ds, state, ui)

