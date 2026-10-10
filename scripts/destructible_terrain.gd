class_name DestructibleTerrain
extends StaticBody2D

# A circle is wider than a chunk, so subtraction cannot produce an enclosed
# hole contour. Every returned contour is a standalone solid polygon.
const CHUNK_SIZE: float = 64.0
const MIN_AREA: float = 0.25
var chunks: Dictionary = {}
var tint := Color.WHITE
var revision: int = 0
var last_changed_chunks: int = 0

func build(outline: PackedVector2Array, color: Color) -> void:
	collision_layer = 1
	collision_mask = 0
	tint = color
	var boundary := clean_polygon(outline)
	var triangles := Geometry2D.triangulate_polygon(boundary)
	if triangles.is_empty():
		push_error("Terrain initialization failed: outline cannot be triangulated")
		return
	var bounds := Rect2(boundary[0], Vector2.ZERO)
	for point in boundary:
		bounds = bounds.expand(point)
	# Initial geometry uses triangle/half-plane clipping, not boolean intersection
	# or convex decomposition. All resulting pieces are already convex.
	for y in range(floori(bounds.position.y / CHUNK_SIZE), ceili(bounds.end.y / CHUNK_SIZE)):
		for x in range(floori(bounds.position.x / CHUNK_SIZE), ceili(bounds.end.x / CHUNK_SIZE)):
			var key := Vector2i(x, y)
			var rect := Rect2(Vector2(key) * CHUNK_SIZE, Vector2.ONE * CHUNK_SIZE)
			var solids: Array[PackedVector2Array] = []
			for index in range(0, triangles.size(), 3):
				var piece := PackedVector2Array([boundary[triangles[index]],
					boundary[triangles[index + 1]], boundary[triangles[index + 2]]])
				piece = clip_axis(piece, 0, rect.position.x, true)
				piece = clip_axis(piece, 0, rect.end.x, false)
				piece = clip_axis(piece, 1, rect.position.y, true)
				piece = clip_axis(piece, 1, rect.end.y, false)
				piece = clean_polygon(piece)
				if piece.size() >= 3 and polygon_area(piece) >= MIN_AREA:
					solids.append(piece)
			if solids.is_empty():
				continue
			var owner_id := create_shape_owner(self)
			chunks[key] = {"polygons": solids, "owner_id": owner_id}
			rebuild_shapes(key)
	var expected := polygon_area(boundary)
	if chunks.is_empty() or absf(solid_area() - expected) > maxf(1.0, expected * 0.001):
		push_error("Terrain initialization lost geometry: expected %s, got %s; engine %s" %
			[expected, solid_area(), Engine.get_version_info().string])
	queue_redraw()

func _ready() -> void:
	# build() runs before entering the tree. Request first draw after attachment.
	queue_redraw()

static func clean_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		if not point.is_finite():
			return PackedVector2Array()
		if result.is_empty() or result[result.size() - 1].distance_squared_to(point) > 0.000001:
			result.append(point)
	if result.size() > 1 and result[0].distance_squared_to(result[result.size() - 1]) <= 0.000001:
		result.remove_at(result.size() - 1)
	if result.size() >= 3 and Geometry2D.is_polygon_clockwise(result):
		result.reverse()
	return result

static func clip_axis(points: PackedVector2Array, axis: int, limit: float,
		keep_greater: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.is_empty():
		return result
	var previous := points[points.size() - 1]
	var previous_inside: bool = previous[axis] >= limit if keep_greater else previous[axis] <= limit
	for point in points:
		var inside: bool = point[axis] >= limit if keep_greater else point[axis] <= limit
		if inside != previous_inside:
			var weight: float = (limit - previous[axis]) / (point[axis] - previous[axis])
			var intersection := previous.lerp(point, weight)
			intersection[axis] = limit
			result.append(intersection)
		if inside:
			result.append(point)
		previous = point
		previous_inside = inside
	return result

func carve(global_center: Vector2, radius: float = CombatConfig.CRATER_RADIUS) -> void:
	# Called by the map's deferred explosion queue, never inside a physics query.
	assert(radius * 2.0 > CHUNK_SIZE, "Crater diameter must exceed chunk width")
	var center := to_local(global_center)
	var cutter := PackedVector2Array()
	for i in range(CombatConfig.CRATER_SEGMENTS):
		cutter.append(center + Vector2.from_angle(TAU * i / CombatConfig.CRATER_SEGMENTS) * radius)
	last_changed_chunks = 0
	for y in range(floori((center.y - radius) / CHUNK_SIZE), floori((center.y + radius) / CHUNK_SIZE) + 1):
		for x in range(floori((center.x - radius) / CHUNK_SIZE), floori((center.x + radius) / CHUNK_SIZE) + 1):
			var key := Vector2i(x, y)
			if not chunks.has(key):
				continue
			var old: Array = chunks[key].polygons
			var replacement: Array[PackedVector2Array] = []
			for polygon: PackedVector2Array in old:
				replacement.append_array(validated_solids(Geometry2D.clip_polygons(polygon, cutter)))
			if total_area(old) - total_area(replacement) < MIN_AREA:
				continue
			chunks[key].polygons = replacement
			rebuild_shapes(key)
			if replacement.is_empty():
				remove_shape_owner(chunks[key].owner_id)
				chunks.erase(key)
			last_changed_chunks += 1
	if last_changed_chunks > 0:
		revision += 1
		queue_redraw()

static func polygon_area(polygon: PackedVector2Array) -> float:
	var area := 0.0
	for i in range(polygon.size()):
		area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
	return absf(area) * 0.5

static func total_area(polygons: Array) -> float:
	var area := 0.0
	for polygon: PackedVector2Array in polygons:
		area += polygon_area(polygon)
	return area

static func validated_solids(polygons: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for polygon in polygons:
		# Remove numerical slivers from BOTH physics and rendering.
		if polygon.size() < 3 or polygon_area(polygon) < MIN_AREA:
			continue
		var convex := Geometry2D.decompose_polygon_in_convex(polygon)
		for piece in convex:
			if piece.size() >= 3 and polygon_area(piece) >= MIN_AREA:
				result.append(piece)
	return result

func rebuild_shapes(key: Vector2i) -> void:
	var owner_id: int = chunks[key].owner_id
	shape_owner_clear_shapes(owner_id)
	for polygon: PackedVector2Array in chunks[key].polygons:
		var shape := ConvexPolygonShape2D.new()
		shape.points = polygon
		shape_owner_add_shape(owner_id, shape)

func solid_area() -> float:
	var area := 0.0
	for chunk: Dictionary in chunks.values():
		area += total_area(chunk.polygons)
	return area

func _draw() -> void:
	for chunk: Dictionary in chunks.values():
		for polygon: PackedVector2Array in chunk.polygons:
			draw_colored_polygon(polygon, tint)
