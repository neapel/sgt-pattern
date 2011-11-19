COL_TEXT = '#000'
COL_EMPTY = '#fff'
COL_UNKNOWN = '#9e9b7d'
COL_FULL = '#38372c'
COL_GRID = '#6b6955'
ALPHA_GRID = 0.2

GRID_UNKNOWN = 2
GRID_FULL = 1
GRID_EMPTY = 0

LEFT_BUTTON = 1
MIDDLE_BUTTON = 2
RIGHT_BUTTON = 3
LEFT_DRAG = 4
MIDDLE_DRAG = 5
RIGHT_DRAG = 6
LEFT_RELEASE = 7
MIDDLE_RELEASE = 8
RIGHT_RELEASE = 9
CURSOR_UP = 10
CURSOR_DOWN = 11
CURSOR_LEFT = 12
CURSOR_RIGHT = 13
CURSOR_SELECT = 14
CURSOR_SELECT2 = 15

IS_MOUSE_DOWN = (m) ->
	m - LEFT_BUTTON <= RIGHT_BUTTON - LEFT_BUTTON
IS_MOUSE_DRAG = (m) ->
	m - LEFT_DRAG <= RIGHT_DRAG - LEFT_DRAG
IS_MOUSE_RELEASE = (m) ->
	m - LEFT_RELEASE <= RIGHT_RELEASE - LEFT_RELEASE
IS_CURSOR_MOVE = (m) ->
	m == CURSOR_UP || m == CURSOR_DOWN || m == CURSOR_RIGHT || m == CURSOR_LEFT
IS_CURSOR_SELECT = (m) ->
	m == CURSOR_SELECT || m == CURSOR_SELECT2


class Cell
	constructor: (@v = GRID_EMPTY) ->
		null
	clone: ->
		new Cell(@v)

class GameState
	constructor: (@w, @h, generate = true) ->
		if @w <= 0 or @h <= 0
			throw 'Width and height must both be greater than zero'
		@grid =
			for y in [0 .. @h - 1]
				for x in [0 .. @w - 1]
					new Cell(GRID_UNKNOWN)
		@completed = false
		if generate
			solution_grid = generate_soluble(@w, @h)
			@coldata = for x in [0 .. @w - 1]
				compute_rowdata(solution_grid.column(x))
			@rowdata = for y in [0 .. @h - 1]
				compute_rowdata(solution_grid[y])

	clone: ->
		r = new GameState(@w, @h, false)
		r.grid =
			for row in @grid
				for cell in row
					cell.clone()
		r.completed = @completed
		r.rowdata = @rowdata
		r.coldata = @coldata
		r

	execute_move: (val, x1, y1, x2 = x1, y2 = y1) ->
		ret = @clone()
		for y in [y1 .. y2] by 1
			for x in [x1 .. x2] by 1
				ret.grid[y][x].v = val
		# An actual change, so check to see if we've completed the game
		if not ret.completed
			ret.completed = true
			for x in [0 .. ret.w - 1]
				coldata = compute_rowdata(ret.grid.column(x))
				if not ret.coldata[x].equals(coldata)
					ret.completed = false
					break
			for y in [0 .. ret.h - 1]
				rowdata = compute_rowdata(ret.grid[y])
				if not ret.rowdata[y].equals(rowdata)
					ret.completed = false
					break
		ret

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
						for dx in [-1 .. +1] when 0 <= x + dx < w
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
				return null
	if current > 0
		ret.push(current)
	ret

# Solve one row or column
do_row = (start, data) ->
	# Things we have deduced so far.
	deduced = (0 for x in start)
	# The row to be operated on: initially empty
	row = (GRID_EMPTY for x in start)
	# Recursive function
	do_recurse = (freespace, ndone = 0, lowest = 0) ->
		run_length = data[ndone]
		if run_length
			for i in [0 .. freespace]
				j = lowest
				for k in [0 .. i - 1] by 1
					row[j++] = GRID_UNKNOWN
				for k in [0 .. run_length - 1] by 1
					row[j++] = GRID_FULL
				if j < row.length
					row[j++] = GRID_UNKNOWN
				do_recurse(freespace - i, ndone + 1, j)
		else
			for i in [lowest .. row.length - 1] by 1
				row[i] = GRID_UNKNOWN
			for i in [0 .. row.length - 1]
				if start[i].v and start[i].v != row[i]
					return
			for i in [0 .. row.length - 1]
				deduced[i] |= row[i]
		null
	# Free space to fill
	freespace = start.length + 1
	for d in data
		freespace -= d + 1
	# Check all possible ways to fill
	do_recurse(freespace)
	# Deduce things from this
	done_any = false
	for i in [0 .. start.length - 1]
		if (deduced[i] == GRID_FULL or deduced[i] == GRID_UNKNOWN) and not start[i].v
			start[i].v = deduced[i]
			done_any = true
	done_any

generate_soluble = (w, h) ->
	ok = false
	while not ok
		grid = generate(w, h)
		# The game is a bit too easy if any row or column is
		# completely black or completely white. An exception is
		# made for rows/columns that are under 3 squares,
		# otherwise nothing will ever be successfully generated.
		again = do ->
			if w > 2
				for row in grid
					colours = 0
					for cell in row
						colours |= if cell.v == GRID_FULL then 2 else 1
					if colours != 3
						return true
			if h > 2
				for x in [0 .. w - 1]
					colours = 0
					for cell in grid.column(x)
						colours |= if cell.v == GRID_FULL then 2 else 1
					if colours != 3
						return true
		continue if again
		# Solve game a bit
		matrix =
			for row in grid
				for cell in row
					new Cell()
		done_any = true
		while done_any
			done_any = false
			for y in [0 .. h - 1]
				done_any |= do_row(matrix[y], compute_rowdata(grid[y]))
			for x in [0 .. w - 1]
				done_any |= do_row(matrix.column(x), compute_rowdata(grid.column(x)))
		ok = true
		for row in matrix
			for cell in row
				if cell.v == GRID_EMPTY
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

interpret_move = (state, ui, ds, x, y, button) ->
	[x, y] = ds.cell_at(x, y)
	x = Math.min(state.w - 1, Math.max(0, x))
	y = Math.min(state.h - 1, Math.max(0, y))

	if button == LEFT_BUTTON or button == RIGHT_BUTTON or button == MIDDLE_BUTTON
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
		ui.drag_start_y = ui.drag_end_y = y
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
			[ui.state, x1, y1, x2, y2]
		else
			null
	else if IS_CURSOR_MOVE(button)
		ui.cur_visible = true
		switch button
			when CURSOR_UP
				ui.cur_y = 0|((ui.cur_y - 1 + state.h) % state.h)
			when CURSOR_DOWN
				ui.cur_y = 0|((ui.cur_y + 1) % state.h)
			when CURSOR_LEFT
				ui.cur_x = 0|((ui.cur_x - 1 + state.w) % state.w)
			when CURSOR_RIGHT
				ui.cur_x = 0|((ui.cur_x + 1) % state.w)
		null
	else if IS_CURSOR_SELECT(button)
		currstate = state.grid[ui.cur_y][ui.cur_x].v
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
			[newstate, ui.cur_x, ui.cur_y]
	else
		null



# ----------------------------------------------------------------------
# Drawing routines.

class game_drawstate
	constructor: (@dr) ->
		null

	cell_at: (mx, my) ->
		[
			0|((mx - @center_x) / @tile_size) - @offset_x
			0|((my) / @tile_size) - @offset_y
		]

	game_redraw: (state, ui) ->
		longest_coldata = 0
		for x in [0 .. state.w - 1]
			longest_coldata = Math.max(longest_coldata, state.coldata[x].length)
		longest_rowdata = 0
		for y in [0 .. state.h - 1]
			longest_rowdata = Math.max(longest_rowdata, state.rowdata[y].length)
		total_w = 2 * longest_rowdata + state.w
		total_h = 2 * longest_coldata + state.h
		@tile_size = Math.min(40, Math.min(
			0|(@dr.canvas.width / total_w),
			0|(@dr.canvas.height / total_h)
		))
		@offset_x = longest_rowdata
		@offset_y = longest_coldata
		@center_x = 0|((@dr.canvas.width - total_w * @tile_size) / 2)


		@dr.canvas.width = @dr.canvas.width
		@dr.save()
		@dr.translate(@offset_x * @tile_size + @center_x, @offset_y * @tile_size)
		# Draw the numbers.
		@dr.fillStyle = COL_TEXT
		@dr.font = "bold #{@tile_size/2}px sans-serif"
		@dr.textAlign = 'center'
		@dr.textBaseline = 'middle'
		for cols, i in state.coldata
			for run_length, j in cols
				x = (i ) * @tile_size
				y = (j - cols.length) * @tile_size
				@dr.fillText("#{run_length}", x + @tile_size/2, y + @tile_size/2)
		for rows, i in state.rowdata
			for run_length, j in rows
				x = (j - rows.length) * @tile_size
				y = i * @tile_size
				@dr.fillText("#{run_length}", x + @tile_size/2, y + @tile_size/2)
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
		for y in [0 .. state.h - 1]
			for x in [0 .. state.w - 1]
				@dr.save()
				@dr.translate(x * @tile_size, y * @tile_size)
				# Work out what state this square should be drawn in,
				# taking any current drag operation into account.
				val =
					if ui.dragging and x1 <= x <= x2 and y1 <= y <= y2
						ui.state
					else
						state.grid[y][x].v
				xl = +(0|(x % 5) == 0)
				yt = +(0|(y % 5) == 0)
				xr = +(0|(x % 5) == 4 or x == state.w - 1)
				yb = +(0|(y % 5) == 4 or y == state.h - 1)
				dx =  1 + xl
				dy = 1 + yt
				@dr.translate(dx, dy)
				dw = @tile_size - xl - xr - 1
				dh = @tile_size - yt - yb - 1
				@dr.strokeStyle = COL_GRID
				@dr.strokeRect(-1 + 0.5, -1+0.5, dw + 1, dh + 1)
				switch val
					when GRID_FULL
						@dr.fillStyle = COL_FULL
						@dr.fillRect(0, 0, dw, dh)
					when GRID_UNKNOWN
						@dr.fillStyle = COL_UNKNOWN
						@dr.fillRect(0, 0, dw, dh)
					when GRID_EMPTY
						@dr.fillStyle = COL_EMPTY
						@dr.fillRect(0, 0, dw, dh)
						@dr.strokeStyle = COL_GRID
						@dr.beginPath()
						@dr.save()
						@dr.translate(0.5, 0.5)
						m = @tile_size/6
						@dr.moveTo(m/2, m/2)
						@dr.lineTo(@tile_size - m, @tile_size - m)
						@dr.moveTo(m/2, @tile_size - m)
						@dr.lineTo(@tile_size - m, m/2)
						@dr.stroke()
						@dr.restore()
				if x == cx and y == cy
					@dr.beginPath()
					@dr.arc(dw/2, dw/2, @tile_size * 0.25, 0, Math.PI * 2, false)
					@dr.strokeStyle = '#000'
					@dr.lineWidth = 2.5
					@dr.stroke()
					@dr.strokeStyle = '#fff'
					@dr.lineWidth = 1.5
					@dr.stroke()

				@dr.restore()

		@dr.restore()

window.onload = ->
	canvas = document.getElementById 'game'
	canvas.style.display = 'block'
	canvas.width = window.innerWidth
	canvas.height = window.innerHeight
	ctx = canvas.getContext '2d'
	ui = new game_ui()
	ds = new game_drawstate(ctx)
	console.log canvas, ctx, ui, ds

	setup = document.getElementById 'setup'
	setup_width = document.getElementById 'width'
	setup_height = document.getElementById 'height'
	play_button = document.getElementById 'play'
	won = document.getElementById 'won'
	again_button = document.getElementById 'again'
	fail = document.getElementById 'fail'
	fail.style.display = 'none'

	again_button.onclick = ->
		won.style.display = 'none'
		setup.style.display = 'block'

	setup.style.display = 'block'

	states = []
	current_state = 0

	draw = ->
		console.log 'draw', current_state, states
		if 0 <= current_state < states.length
			console.log 'draw'
			ds.game_redraw(states[current_state], ui)

	start_game = ->
		w = 0| +setup_width.value
		h = 0| +setup_height.value
		if 2 <= w <= 50 and 2 <= h <= 50
			states = [new GameState(w, h)]
			current_state = 0
			draw()

	play_button.onclick = ->
		start_game()
		setup.style.display = 'none'

	make_move = (button, x, y) ->
		if 0 <= current_state < states.length and not states[current_state].completed
			mov = interpret_move(states[current_state], ui, ds, x, y, button)
			if mov
				new_state = states[current_state].execute_move(mov...)
				states = states[..current_state]
				states.push(new_state)
				current_state++
			draw()
			if states[current_state].completed
				won.style.display = 'block'
		console.log states

	undo_move = ->
		if current_state > 0
			current_state--
			draw()
			true
		else
			false

	redo_move = ->
		if current_state < states.length - 1
			current_state++
			draw()
			true
		else
			false

	window.onkeydown = (event) ->
		switch event.keyCode
			when 37, 65 # left, a: move cursor
				make_move(CURSOR_LEFT)
				event.preventDefault()
			when 38, 87 # up, w: move cursor
				make_move(CURSOR_UP)
				event.preventDefault()
			when 39, 68 # right, d: move cursor
				make_move(CURSOR_RIGHT)
				event.preventDefault()
			when 40, 83 # down, s: move cursor
				make_move(CURSOR_DOWN)
				event.preventDefault()
			when 32 # space: forward select
				make_move(CURSOR_SELECT)
				event.preventDefault()
			when 13 # enter: reverse select
				make_move(CURSOR_SELECT2)
				event.preventDefault()
			when 85 # u: undo
				if undo_move()
					event.preventDefault()
			when 82 # r: redo
				if redo_move()
					event.preventDefault()
	
	canvas.oncontextmenu = (event) ->
		event.stopImmediatePropagation()
		event.preventDefault()

	mouse_is_down = false
	x = y = 0

	canvas.onmousedown = (event) ->
		mouse_is_down = true
		event.stopImmediatePropagation()
		event.preventDefault()
		x = event.clientX
		y = event.clientY
		switch event.button
			when 0
				make_move(LEFT_BUTTON, x, y)
			when 1
				make_move(MIDDLE_BUTTON, x, y)
			when 2
				make_move(RIGHT_BUTTON, x, y)
	
	handle_mouseup = ->
		switch event.button
			when 0
				make_move(LEFT_RELEASE, x, y)
			when 1
				make_move(MIDDLE_RELEASE, x, y)
			when 2
				make_move(RIGHT_RELEASE, x, y)

	canvas.onmouseup = (event) ->
		mouse_is_down = false
		event.stopImmediatePropagation()
		event.preventDefault()
		x = event.clientX
		y = event.clientY
		handle_mouseup()

	window.onmouseup = ->
		mouse_is_down = false
		handle_mouseup()

	canvas.onmousemove = (event) ->
		if mouse_is_down
			event.preventDefault()
			x = event.clientX
			y = event.clientY
			switch event.button
				when 0
					make_move(LEFT_DRAG, x, y)
				when 1
					make_move(MIDDLE_DRAG, x, y)
				when 2
					make_move(RIGHT_DRAG, x, y)

	window.onresize = (event) ->
		canvas.width = window.innerWidth
		canvas.height = window.innerHeight
		draw()

	draw()
