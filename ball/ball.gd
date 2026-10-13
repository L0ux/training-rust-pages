class_name Ball
extends CharacterBody2D
## Balle : rebondit sur les murs et les briques. Sur la raquette, l'angle de
## rebond dépend du point d'impact (bord = angle max, centre = tout droit).

@export var radius := 8.0
@export var color := Color.WHITE
@export var start_speed := 420.0
@export var max_speed := 820.0
@export var speed_step := 8.0  ## Gain de vitesse par brique cassée
@export_range(0.0, 89.0) var max_bounce_angle_deg := 60.0

var active := false


func _ready() -> void:
	($CollisionShape2D.shape as CircleShape2D).radius = radius


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)


func launch() -> void:
	velocity = Vector2.UP.rotated(randf_range(-0.5, 0.5)) * start_speed
	active = true


func stop() -> void:
	velocity = Vector2.ZERO
	active = false


func _physics_process(delta: float) -> void:
	if not active:
		return
	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return

	var paddle := collision.get_collider() as Paddle
	if paddle:
		var offset := clampf((global_position.x - paddle.global_position.x) / paddle.half_width, -1.0, 1.0)
		velocity = Vector2.UP.rotated(offset * deg_to_rad(max_bounce_angle_deg)) * velocity.length()
		return

	velocity = velocity.bounce(collision.get_normal())
	var brick := collision.get_collider() as Brick
	if brick:
		brick.hit()
		velocity = velocity.normalized() * minf(velocity.length() + speed_step, max_speed)
