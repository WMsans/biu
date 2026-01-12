@tool
extends Node

# Define your mapping here: "LDtkIdentifier" : "Path/To/Scene.tscn"
const SCENE_MAPPING = {
	"Box": "res://scenes/prefabs/box.tscn"
}

func post_import(entity_layer: LDTKEntityLayer) -> LDTKEntityLayer:
	var entities: Array = entity_layer.entities
	
	# The owner is usually the root node of the imported scene
	# We need this to ensure new nodes are saved to the PackedScene
	var scene_root = entity_layer.owner

	for entity in entities:
		# 1. Check if the entity has a mapping
		if entity.identifier in SCENE_MAPPING:
			var scene_path = SCENE_MAPPING[entity.identifier]
			var packed_scene = load(scene_path)
			
			if packed_scene:
				var new_node = packed_scene.instantiate()
				
				# 2. Position the new node matching the LDtk entity
				new_node.position = entity.position
				
				# 3. Add the new node to the layer (sibling of the current entity for now)
				entity_layer.add_child(new_node)
				new_node.owner = scene_root
				
				# 4. Reparent the LDTKEntity to be a child of the new prefab
				# Remove from layer
				# entity.get_parent().remove_child(entity)
				
				# Add to the new prefab
				# new_node.add_child(entity)
				
				# 5. Reset entity position to (0,0) relative to the parent
				# Since the parent (new_node) is already at the correct world position
				 #entity.position = Vector2.ZERO
				
				# Ensure the entity is still owned by the scene root so it gets saved
				# entity.owner = scene_root
				
				# Optional: Print for debugging
				print("Mapped %s to %s" % [entity.identifier, new_node.name])
			else:
				push_warning("Could not load scene at path: %s" % scene_path)

	return entity_layer
