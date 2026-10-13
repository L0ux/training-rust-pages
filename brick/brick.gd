class_name Brick
extends StaticBody2D
## Brique : disparaît au premier contact et prévient la partie via `destroyed`.

signal destroyed(brick: Brick)

@export var color := Color("ef476f")
@export var points := 10


func _ready() -> void:
	$ColorRect.color = color


func hit() -> void:
	# Désactivée tout de suite pour ne pas être touchée deux fois avant le queue_free
	$CollisionShape2D.set_deferred("disabled", true)
	destroyed.emit(self)
	queue_free()
