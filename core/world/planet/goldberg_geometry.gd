extends RefCounted
class_name GoldbergGeometry

static func generate_goldberg_sphere_correct(subdivisions: int, radius: float) -> Dictionary:
	Logger.info("GoldbergGeometryV2", "Generating Goldberg sphere...")

	var icosahedron_vertices = generate_icosahedron()
	var icosahedron_faces = generate_icosahedron_faces()

	var current_vertices = icosahedron_vertices.duplicate()
	var current_faces = icosahedron_faces.duplicate()

	for i in range(subdivisions):
		var result = subdivide_mesh(current_vertices, current_faces)
		current_vertices = result.vertices
		current_faces = result.faces

	for i in range(current_vertices.size()):
		current_vertices[i] = current_vertices[i].normalized() * radius

	var tiles_data = create_tiles_from_triangle_centers(current_vertices, current_faces, radius)

	Logger.info("GoldbergGeometryV2", "Created %d hexagonal tiles" % tiles_data.hex_centers.size())

	return {
		"vertices": current_vertices,
		"faces": current_faces,
		"hex_centers": tiles_data.hex_centers,
		"hex_neighbors": tiles_data.hex_neighbors,
		"hex_boundaries": tiles_data.hex_boundaries,
		"vertex_to_hex": tiles_data.vertex_to_hex,
		"triangle_to_hex": {}
	}

static func create_tiles_from_triangle_centers(vertices: PackedVector3Array, faces: Array, radius: float) -> Dictionary:
	var hex_centers := PackedVector3Array()
	var hex_neighbors := {}
	var hex_boundaries := {}
	var vertex_to_hex := {}

	var vertex_triangles := {}
	for i in vertices.size():
		vertex_triangles[i] = []
	for triangle_id in faces.size():
		var face = faces[triangle_id]
		for vertex_id in face:
			vertex_triangles[vertex_id].append(triangle_id)

	var hex_id := 0
	for vertex_id in vertices.size():
		var triangles: Array = vertex_triangles[vertex_id]
		if triangles.size() >= 5:
			var center := vertices[vertex_id]
			hex_centers.append(center)
			var boundary := PackedVector3Array()
			for tri_id in triangles:
				boundary.append(get_triangle_center(faces[tri_id], vertices, radius))
			if boundary.size() > 2:
				boundary = sort_boundary_vertices(boundary, center)
			hex_boundaries[hex_id] = boundary
			vertex_to_hex[vertex_id] = hex_id
			hex_neighbors[hex_id] = []
			hex_id += 1

	calculate_hex_neighbors(hex_boundaries, hex_neighbors)

	return {
		"hex_centers": hex_centers,
		"hex_neighbors": hex_neighbors,
		"hex_boundaries": hex_boundaries,
		"vertex_to_hex": vertex_to_hex,
		"triangle_to_hex": {}
	}

static func calculate_hex_neighbors(hex_boundaries: Dictionary, hex_neighbors: Dictionary) -> void:
	var edge_to_hexes := {}
	for hex_id in hex_boundaries:
		var boundary: PackedVector3Array = hex_boundaries[hex_id]
		var count: int = boundary.size()
		for i in count:
			var a = boundary[i]
			var b = boundary[(i + 1) % count]
			var edge_key = get_edge_key(a, b)
			if not edge_to_hexes.has(edge_key):
				edge_to_hexes[edge_key] = []
			edge_to_hexes[edge_key].append(hex_id)
	for edge_key in edge_to_hexes:
		var hex_list = edge_to_hexes[edge_key]
		if hex_list.size() == 2:
			var a = hex_list[0]
			var b = hex_list[1]
			if not hex_neighbors[a].has(b):
				hex_neighbors[a].append(b)
			if not hex_neighbors[b].has(a):
				hex_neighbors[b].append(a)

static func get_edge_key(a: Vector3, b: Vector3) -> String:
	var rounded_a = round_vector(a, 5)
	var rounded_b = round_vector(b, 5)
	var key_a = str(rounded_a)
	var key_b = str(rounded_b)
	return key_a + "|" + key_b if key_a < key_b else key_b + "|" + key_a

static func round_vector(v: Vector3, decimals: int) -> Vector3:
	var f = pow(10, decimals)
	return Vector3(
		round(v.x * f) / f,
		round(v.y * f) / f,
		round(v.z * f) / f
	)

static func get_triangle_center(face: Array, vertices: PackedVector3Array, radius: float) -> Vector3:
	var v0 = vertices[face[0]]
	var v1 = vertices[face[1]]
	var v2 = vertices[face[2]]
	var center = (v0 + v1 + v2) / 3.0
	return center.normalized() * radius

static func sort_boundary_vertices(boundary_vertices: PackedVector3Array, center: Vector3) -> PackedVector3Array:
	if boundary_vertices.size() <= 2:
		return boundary_vertices

	var up = center.normalized()
	var ref_vec = boundary_vertices[0] - center
	var right = ref_vec.normalized()
	var forward = up.cross(right).normalized()
	right = forward.cross(up).normalized()

	var vertices_with_angles = []
	for i in range(boundary_vertices.size()):
		var vec = boundary_vertices[i] - center
		var angle = atan2(vec.dot(forward), vec.dot(right))
		vertices_with_angles.append({"index": i, "angle": angle})

	vertices_with_angles.sort_custom(func(a, b): return a["angle"] < b["angle"])

	var sorted_vertices = PackedVector3Array()
	for item in vertices_with_angles:
		sorted_vertices.append(boundary_vertices[item["index"]])

	return sorted_vertices

static func generate_icosahedron() -> PackedVector3Array:
	var t = (1.0 + sqrt(5.0)) / 2.0
	return PackedVector3Array([
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)
	])

static func generate_icosahedron_faces() -> Array:
	return [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
		[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
		[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
	]

static func subdivide_mesh(verts: PackedVector3Array, faces: Array) -> Dictionary:
	var new_vertices = verts.duplicate()
	var new_faces = []
	var edge_midpoints = {}

	for face in faces:
		var v0 = face[0]
		var v1 = face[1]
		var v2 = face[2]

		var mid01 = get_or_create_midpoint(v0, v1, new_vertices, edge_midpoints)
		var mid12 = get_or_create_midpoint(v1, v2, new_vertices, edge_midpoints)
		var mid20 = get_or_create_midpoint(v2, v0, new_vertices, edge_midpoints)

		new_faces.append([v0, mid01, mid20])
		new_faces.append([v1, mid12, mid01])
		new_faces.append([v2, mid20, mid12])
		new_faces.append([mid01, mid12, mid20])

	return {"vertices": new_vertices, "faces": new_faces}

static func get_or_create_midpoint(v0: int, v1: int, vertices: PackedVector3Array, edge_midpoints: Dictionary) -> int:
	var edge_key = str(min(v0, v1)) + "_" + str(max(v0, v1))
	if edge_midpoints.has(edge_key):
		return edge_midpoints[edge_key]

	var midpoint = (vertices[v0] + vertices[v1]) * 0.5
	vertices.append(midpoint)
	var new_index = vertices.size() - 1
	edge_midpoints[edge_key] = new_index
	return new_index
