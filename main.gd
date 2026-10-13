extends Node2D
## Casse-briques minimal : tout est dessiné via _draw(), sans moteur physique.

const W := 540.0  # format portrait 9:16
const H := 960.0
const TOP_WALL := 56.0

const PADDLE_SIZE := Vector2(96, 16)
const PADDLE_Y := H - 90.0  # marge en bas pour le pouce sur mobile
const PADDLE_SPEED := 600.0

const BALL_RADIUS := 8.0
const BALL_SPEED_START := 420.0
const BALL_SPEED_MAX := 820.0
const BALL_SPEED_STEP := 8.0
const MAX_BOUNCE_ANGLE := PI / 3.0  # 60°

const BRICK_COLS := 7
const BRICK_ROWS := 8
const BRICK_SIZE := Vector2(64, 24)
const BRICK_GAP := 6.0
const BRICK_TOP := 110.0
const ROW_COLORS := [
	Color("ef476f"), Color("f78c6b"), Color("ffd166"),
	Color("06d6a0"), Color("118ab2"), Color("8338ec"),
	Color("ff5d8f"), Color("4cc9f0"),
]

const TEXT_COLOR := Color("e8e8f0")
const PADDLE_COLOR := Color("e8e8f0")
const BALL_COLOR := Color("ffffff")
const WALL_COLOR := Color(1, 1, 1, 0.15)

enum State { READY, PLAYING, WON, LOST }

var state := State.READY
var paddle_x := W / 2.0
var ball_pos := Vector2.ZERO
var ball_vel := Vector2.ZERO
var bricks: Array[Dictionary] = []  # { rect: Rect2, color: Color, points: int }
var score := 0
var lives := 3


func _ready() -> void:
	randomize()
	_new_game()


func _new_game() -> void:
	score = 0
	lives = 3
	_build_bricks()
	_reset_ball()


func _build_bricks() -> void:
	bricks.clear()
	var total_w := BRICK_COLS * BRICK_SIZE.x + (BRICK_COLS - 1) * BRICK_GAP
	var left := (W - total_w) / 2.0
	for row in BRICK_ROWS:
		for col in BRICK_COLS:
			var pos := Vector2(left + col * (BRICK_SIZE.x + BRICK_GAP), BRICK_TOP + row * (BRICK_SIZE.y + BRICK_GAP))
			bricks.append({
				"rect": Rect2(pos, BRICK_SIZE),
				"color": ROW_COLORS[row % ROW_COLORS.size()],
				"points": (BRICK_ROWS - row) * 10,
			})


func _reset_ball() -> void:
	state = State.READY
	ball_vel = Vector2.ZERO
	_stick_ball_to_paddle()


func _stick_ball_to_paddle() -> void:
	ball_pos = Vector2(paddle_x, PADDLE_Y - BALL_RADIUS - 1.0)


func _action() -> void:
	match state:
		State.READY:
			ball_vel = Vector2.UP.rotated(randf_range(-0.5, 0.5)) * BALL_SPEED_START
			state = State.PLAYING
		State.WON, State.LOST:
			_new_game()


func _unhandled_input(event: InputEvent) -> void:
	# Le toucher est émulé en souris par défaut : ça couvre aussi le mobile.
	if event is InputEventMouseMotion:
		paddle_x = make_input_local(event).position.x
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		paddle_x = make_input_local(event).position.x
		_action()
	elif event.is_action_pressed("ui_accept"):
		_action()


func _process(delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_Q):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	paddle_x += clampf(dir, -1.0, 1.0) * PADDLE_SPEED * delta
	paddle_x = clampf(paddle_x, PADDLE_SIZE.x / 2.0, W - PADDLE_SIZE.x / 2.0)

	match state:
		State.READY:
			_stick_ball_to_paddle()
		State.PLAYING:
			# Sous-pas pour éviter que la balle traverse une brique à grande vitesse.
			var steps := maxi(1, ceili(ball_vel.length() * delta / BALL_RADIUS))
			for i in steps:
				if state != State.PLAYING:
					break
				_step_ball(delta / steps)

	queue_redraw()


func _step_ball(dt: float) -> void:
	ball_pos += ball_vel * dt

	# Murs
	if ball_pos.x < BALL_RADIUS:
		ball_pos.x = BALL_RADIUS
		ball_vel.x = absf(ball_vel.x)
	elif ball_pos.x > W - BALL_RADIUS:
		ball_pos.x = W - BALL_RADIUS
		ball_vel.x = -absf(ball_vel.x)
	if ball_pos.y < TOP_WALL + BALL_RADIUS:
		ball_pos.y = TOP_WALL + BALL_RADIUS
		ball_vel.y = absf(ball_vel.y)

	# Balle perdue
	if ball_pos.y > H + BALL_RADIUS:
		lives -= 1
		if lives <= 0:
			state = State.LOST
		else:
			_reset_ball()
		return

	# Raquette : l'angle de rebond dépend du point d'impact
	if ball_vel.y > 0.0 and _ball_hits(_paddle_rect()):
		var offset := clampf((ball_pos.x - paddle_x) / (PADDLE_SIZE.x / 2.0), -1.0, 1.0)
		ball_vel = Vector2.UP.rotated(offset * MAX_BOUNCE_ANGLE) * ball_vel.length()
		ball_pos.y = PADDLE_Y - BALL_RADIUS
		return

	# Briques (une seule par sous-pas)
	for i in bricks.size():
		var rect: Rect2 = bricks[i].rect
		if not _ball_hits(rect):
			continue
		var closest := ball_pos.clamp(rect.position, rect.end)
		var diff := ball_pos - closest
		if absf(diff.x) > absf(diff.y):
			ball_vel.x = signf(diff.x) * absf(ball_vel.x)
		elif diff.y != 0.0:
			ball_vel.y = signf(diff.y) * absf(ball_vel.y)
		else:
			ball_vel.y = -ball_vel.y
		score += bricks[i].points
		bricks.remove_at(i)
		ball_vel = ball_vel.normalized() * minf(ball_vel.length() + BALL_SPEED_STEP, BALL_SPEED_MAX)
		if bricks.is_empty():
			state = State.WON
		break


func _paddle_rect() -> Rect2:
	return Rect2(Vector2(paddle_x - PADDLE_SIZE.x / 2.0, PADDLE_Y), PADDLE_SIZE)


func _ball_hits(rect: Rect2) -> bool:
	var closest := ball_pos.clamp(rect.position, rect.end)
	return ball_pos.distance_squared_to(closest) <= BALL_RADIUS * BALL_RADIUS


func _draw() -> void:
	var font := ThemeDB.fallback_font

	# HUD
	draw_string(font, Vector2(20, 38), "Score : %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, TEXT_COLOR)
	draw_string(font, Vector2(0, 38), "Vies : %d" % lives, HORIZONTAL_ALIGNMENT_RIGHT, W - 20.0, 24, TEXT_COLOR)
	draw_line(Vector2(0, TOP_WALL), Vector2(W, TOP_WALL), WALL_COLOR, 2.0)

	for brick in bricks:
		var rect: Rect2 = brick.rect
		draw_rect(rect, brick.color)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), Color(1, 1, 1, 0.25))

	draw_rect(_paddle_rect(), PADDLE_COLOR)
	if state != State.LOST:
		draw_circle(ball_pos, BALL_RADIUS, BALL_COLOR)

	match state:
		State.READY:
			_draw_centered(font, "Touche ou Espace pour lancer", H * 0.62, 24)
		State.WON:
			_draw_centered(font, "Gagné ! Score : %d" % score, H * 0.55, 36)
			_draw_centered(font, "Touche pour rejouer", H * 0.62, 22)
		State.LOST:
			_draw_centered(font, "Perdu… Score : %d" % score, H * 0.55, 36)
			_draw_centered(font, "Touche pour rejouer", H * 0.62, 22)


func _draw_centered(font: Font, text: String, y: float, size: int) -> void:
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, W, size, TEXT_COLOR)
