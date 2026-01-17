extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	# Start transparent
	if not color_rect:
		color_rect = ColorRect.new()
		color_rect.color = Color.BLACK
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		add_child(color_rect)
	
	color_rect.modulate.a = 0.0
	visible = false

func fade_out(duration: float = 0.3) -> void:
	visible = true
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func fade_in(duration: float = 0.3) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false
