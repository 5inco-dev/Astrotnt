extends "res://scripts/projectile_behavior.gd"

# A bounded subsurface burst. The extra swept segment still hits players/walls.
func impact(shell: Node2D, hit: Dictionary) -> Dictionary:
	if not hit.collider is DestructibleTerrain:
		return hit
	var end: Vector2 = hit.position + shell.flight_velocity.normalized() * shell.profile.penetration
	var query := PhysicsRayQueryParameters2D.create(hit.position, end, 3,
		[shell.shooter_rid, hit.collider.get_rid()])
	query.hit_from_inside = true
	var obstruction: Dictionary = shell.get_world_2d().direct_space_state.intersect_ray(query)
	if not obstruction.is_empty():
		return obstruction
	return {"collider": hit.collider, "position": end}
