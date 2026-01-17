extends Node2D

func _ready() -> void:
	# 1. Create the Burst Particles (The 8 circles)
	var burst = CPUParticles2D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.amount = 8
	burst.explosiveness = 1.0
	burst.lifetime = 0.6
	burst.direction = Vector2.UP
	burst.spread = 180.0
	burst.gravity = Vector2(0, 0)
	burst.initial_velocity_min = 60.0
	burst.initial_velocity_max = 80.0
	
	# Create a simple circular texture on the fly
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0)) # Transparent
	# Draw a white circle in the center
	for x in range(8):
		for y in range(8):
			if Vector2(x-3.5, y-3.5).length() <= 3.0:
				img.set_pixel(x, y, Color.WHITE)
	
	burst.texture = ImageTexture.create_from_image(img)
	burst.scale_amount_min = 1.0
	burst.scale_amount_max = 1.0
	
	# Add curves for fading out
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	burst.color_ramp = grad
	
	add_child(burst)
	
	# 2. Emit and Cleanup
	burst.emitting = true
	
	# Destroy self after particles finish
	get_tree().create_timer(1.0).timeout.connect(queue_free)
