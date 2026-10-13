extends Node2D
## Orchestration de la partie : état, score, vies et génération des briques.
## La physique (rebonds, collisions) est gérée par Ball, Paddle et les Brick.

enum State { READY, PLAYING, WON, LOST }

const BrickScene := preload("res://brick/brick.tscn")

@export var start_lives := 3

@export_group("Briques")
@export var brick_cols := 7
@export var brick_rows := 8
@export var brick_size := Vector2(64, 24)
@export var brick_gap := 6.0
@export var brick_top := 110.0
@export var row_colors: Array[Color] = [
	Color("ef476f"), Color("f78c6b"), Color("ffd166"), Color("06d6a0"),
	Color("118ab2"), Color("8338ec"), Color("ff5d8f"), Color("4cc9f0"),
]

var state := State.READY
var score := 0
var lives := 0
var bricks_left := 0

@onready var paddle: Paddle = $Paddle
@onready var ball: Ball = $Ball
@onready var bricks: Node2D = $Bricks
@onready var hud: Hud = $HUD


func _ready() -> void:
	_new_game()


func _new_game() -> void:
	score = 0
	lives = start_lives
	hud.set_score(score)
	hud.set_lives(lives)
	_build_bricks()
	_reset_ball()


func _build_bricks() -> void:
	for child in bricks.get_children():
		child.queue_free()

	var total_w := brick_cols * brick_size.x + (brick_cols - 1) * brick_gap
	var left := (get_viewport_rect().size.x - total_w) / 2.0
	for row in brick_rows:
		for col in brick_cols:
			var brick: Brick = BrickScene.instantiate()
			var top_left := Vector2(left + col * (brick_size.x + brick_gap), brick_top + row * (brick_size.y + brick_gap))
			brick.position = top_left + brick_size / 2.0
			brick.color = row_colors[row % row_colors.size()]
			brick.points = (brick_rows - row) * 10
			brick.destroyed.connect(_on_brick_destroyed)
			bricks.add_child(brick)
	bricks_left = brick_rows * brick_cols


func _reset_ball() -> void:
	state = State.READY
	ball.stop()
	ball.show()
	hud.show_message("", "Touche ou Espace pour lancer")


func _physics_process(_delta: float) -> void:
	if state == State.READY:
		# La balle reste posée sur la raquette jusqu'au lancement
		ball.position = paddle.position + Vector2(0, -(paddle.half_height + ball.radius + 1.0))


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	var clicked := mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT
	if not (clicked or event.is_action_pressed("ui_accept")):
		return
	match state:
		State.READY:
			state = State.PLAYING
			ball.launch()
			hud.hide_message()
		State.WON, State.LOST:
			_new_game()


func _end_game(won: bool) -> void:
	state = State.WON if won else State.LOST
	ball.stop()
	ball.hide()
	var title := "Gagné ! Score : %d" if won else "Perdu… Score : %d"
	hud.show_message(title % score, "Touche pour rejouer")


func _on_brick_destroyed(brick: Brick) -> void:
	score += brick.points
	hud.set_score(score)
	bricks_left -= 1
	if bricks_left == 0:
		_end_game(true)


func _on_death_zone_body_entered(body: Node2D) -> void:
	if body != ball or state != State.PLAYING:
		return
	lives -= 1
	hud.set_lives(lives)
	if lives <= 0:
		_end_game(false)
	else:
		_reset_ball()
