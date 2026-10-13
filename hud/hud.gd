class_name Hud
extends CanvasLayer
## Affichage du score, des vies et des messages (lancer, gagné, perdu).

@onready var _score: Label = $ScoreLabel
@onready var _lives: Label = $LivesLabel
@onready var _title: Label = $MessageTitle
@onready var _subtitle: Label = $MessageSubtitle


func set_score(value: int) -> void:
	_score.text = "Score : %d" % value


func set_lives(value: int) -> void:
	_lives.text = "Vies : %d" % value


func show_message(title: String, subtitle := "") -> void:
	_title.text = title
	_subtitle.text = subtitle
	_title.show()
	_subtitle.show()


func hide_message() -> void:
	_title.hide()
	_subtitle.hide()
