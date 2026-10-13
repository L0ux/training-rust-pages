class_name Paddle
extends AnimatableBody2D
## Raquette : suit la souris / le doigt, ou le clavier (flèches, A/Q/D).
## Sa taille vient de la CollisionShape2D de la scène.

@export var speed := 600.0

var half_width: float
var half_height: float


func _ready() -> void:
	var size := ($CollisionShape2D.shape as RectangleShape2D).size
	half_width = size.x / 2.0
	half_height = size.y / 2.0


func _unhandled_input(event: InputEvent) -> void:
	# Le toucher est émulé en souris par défaut : ça couvre aussi le mobile.
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_move_to(get_global_mouse_position().x)


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("ui_left", "ui_right")
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_Q):
		dir -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		dir += 1.0
	if dir != 0.0:
		_move_to(position.x + clampf(dir, -1.0, 1.0) * speed * delta)


func _move_to(x: float) -> void:
	position.x = clampf(x, half_width, get_viewport_rect().size.x - half_width)
