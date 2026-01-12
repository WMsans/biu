extends Node2D

@export var bomb_scene: PackedScene
@export var tile_size: int = 16

# We need a dedicated raycast for placing to avoid messing with the player's movement ray
var ray: RayCast2D
var facing_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	# Create a RayCast2D dynamically for this component
	ray = RayCast2D.new()
	ray.enabled = false # We only force update it
	add_child(ray)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Z:
		try_place_bomb()

func update_direction(new_dir: Vector2) -> void:
	facing_direction = new_dir
	queue_redraw() # Redraw the indicator

func try_place_bomb() -> void:
	var player = get_parent()
	
	# Safety check: Don't place if player is moving or scene isn't set
	if not bomb_scene or (player.get("is_moving") and player.is_moving):
		return

	# Configure Raycast to check the tile in front
	# We assume the parent (Player) is centered on the tile
	ray.position = Vector2.ZERO
	ray.target_position = facing_direction * tile_size
	
	# Check against Walls (2) and Boxes/Bombs (4)
	# (These values match the Player's exported flags)
	ray.collision_mask = 2 + 4 
	ray.force_raycast_update()
	
	if not ray.is_colliding():
		spawn_bomb()
	else:
		print("Blocked! Cannot place bomb.")

func spawn_bomb() -> void:
	var new_bomb = bomb_scene.instantiate()
	
	# Calculate global position for the bomb
	# We use the parent's position + offset
	var target_pos = global_position + (facing_direction * tile_size)
	new_bomb.global_position = target_pos
	
	# Add to the Level (Player's parent) so it doesn't move attached to the player
	get_parent().get_parent().add_child(new_bomb)

func _draw() -> void:
	# Draw the red indicator square
	var color = Color(1, 0, 0, 0.4)
	var size = Vector2(tile_size, tile_size)
	
	# Offset to draw centered relative to the direction
	# (Assuming this node is at 0,0 relative to player center)
	var draw_pos = (facing_direction * tile_size) - (size / 2.0)
	
	draw_rect(Rect2(draw_pos, size), color, false, 2.0)
