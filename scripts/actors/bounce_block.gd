extends "res://scripts/actors/box.gd"

@export var bounce_range: int = 5

var is_overloaded: bool = false
var _last_overload_state: bool = false
var _overload_buffer_timer: float = 0.0 # [NEW] Timer for sustained overload

func _ready() -> void:
	super._ready()
	add_to_group("bounce_block")

func _physics_process(delta: float) -> void: # [Updated arg to include delta]
	# Optimization: Don't run logic if we are moving (being pushed/bounced ourselves)
	if move_tween and move_tween.is_running():
		return
	
	# [NEW] Tick down the buffer timer
	if _overload_buffer_timer > 0:
		_overload_buffer_timer -= delta
		
	_update_overload_state()
	_update_collision_layer()
	
	if not is_overloaded:
		_handle_bounce()

func _update_overload_state() -> void:
	var space_state = get_world_2d().direct_space_state
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	var found_chain = false
	
	for dir in directions:
		# Check Neighbor 1 (Adjacent)
		var pos1 = global_position + (dir * tile_size)
		var obj1 = _get_overload_entity_at(space_state, pos1)
		
		if obj1:
			# Check Neighbor 2 (Behind Neighbor 1)
			var pos2 = pos1 + (dir * tile_size)
			var obj2 = _get_overload_entity_at(space_state, pos2)
			
			if obj2:
				found_chain = true
				break
	
	# [NEW] Apply Coyote Time logic to overload state
	if found_chain:
		is_overloaded = true
		_overload_buffer_timer = 0.2 # Reset buffer (0.2s is enough for player swap)
	else:
		# Stay overloaded if the timer is still running
		if _overload_buffer_timer > 0:
			is_overloaded = true
		else:
			is_overloaded = false
	
	# Visual Feedback
	if is_overloaded != _last_overload_state:
		_last_overload_state = is_overloaded
		if is_overloaded:
			print("BounceBlock Overloaded!")
			modulate = Color(0.5, 0.5, 0.5) # Dim when overloaded
		else:
			print("BounceBlock Active!")
			# Restore modulate (handling water tint)
			if is_floating:
				modulate = Color(0.7, 0.7, 0.8)
			else:
				modulate = Color.WHITE

func _update_collision_layer() -> void:
	if is_floating:
		return
		
	# Land Logic
	if is_overloaded:
		# Overloaded: Acts like a normal box (Pushable Layer 4)
		if not (collision_layer & 4):
			collision_layer |= 4
	else:
		# Active: Acts like a bumper (Wall Layer 2 Only)
		# We remove Layer 4 so the Player's push raycast sees it as a static wall
		if collision_layer & 4:
			collision_layer &= ~4

func _handle_bounce() -> void:
	var space_state = get_world_2d().direct_space_state
	
	# Neighbor Check (Side Bouncing)
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	
	for dir in directions:
		var check_pos = global_position + (dir * tile_size)
		var query = PhysicsPointQueryParameters2D.new()
		query.position = check_pos
		query.collide_with_bodies = true
		query.collision_mask = 0xFFFFFFFF 
		
		var results = space_state.intersect_point(query)
		for result in results:
			var collider = result.collider
			if collider == self: continue
			
			# Filter: Floating blocks only bounce floating things
			if is_floating:
				if not (collider.has_method("is_floating_object") and collider.is_floating_object()):
					# Player is an exception: they are valid on both land and water bridges
					if not collider.is_in_group("player"):
						continue
			
			# Filter: Don't bounce moving things
			if collider.get("is_moving"): continue
			
			if collider.has_method("apply_knockback"):
				# Bounce AWAY from the block
				collider.apply_knockback(dir, bounce_range)

func _get_overload_entity_at(space_state, pos: Vector2) -> Node:
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_bodies = true
	
	# Context Aware Masking:
	# If we are floating, we look for entities valid on the "water plane" (Player + Floating Boxes)
	# If we are on land, we look for entities valid on the "land plane" (Player + Land Boxes)
	if is_floating:
		query.collision_mask = 1 + 32 # Player (1) + Floating Box (32)
	else:
		query.collision_mask = 1 + 4  # Player (1) + Land Box (4)
	
	var results = space_state.intersect_point(query)
	for result in results:
		var collider = result.collider
		if collider == self: continue
		
		# Return if it is a Box (any type) or Player
		if collider.is_in_group("box") or collider.is_in_group("player"):
			
			# Double check floating status for boxes to be safe
			if collider.is_in_group("box"):
				if is_floating:
					if collider.has_method("is_floating_object") and collider.is_floating_object():
						return collider
				else:
					if not (collider.has_method("is_floating_object") and collider.is_floating_object()):
						return collider
			else:
				# Player is always valid
				return collider
				
	return null
