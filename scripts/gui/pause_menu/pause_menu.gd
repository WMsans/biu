extends Control

# References the button node. Adjust the path if your scene hierarchy differs.
@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton

func _ready() -> void:
	# 1. Setup Initial State
	visible = false
	
	# CRITICAL: This node must run even when the tree is paused.
	# Standard nodes inherit 'PROCESS_MODE_PAUSABLE' and stop running when paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 2. Connect Signal (can also be done via the Editor node tab)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)

func _unhandled_input(event: InputEvent) -> void:
	# 3. Handle Input ("ui_cancel" maps to ESCAPE by default in Godot)
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

func _toggle_pause() -> void:
	# Flip the current pause state
	var should_be_paused = not get_tree().paused
	
	# Apply state to the Tree and Visibility
	get_tree().paused = should_be_paused
	visible = should_be_paused
	
	# UI Focus Logic (Important for keyboard/controller support)
	if should_be_paused and resume_button:
		resume_button.grab_focus()

func _on_resume_pressed() -> void:
	_toggle_pause()
