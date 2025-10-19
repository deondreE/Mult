package render

import "core:math"

// Vector2 and Matrix4 are assumed to be defined elsewhere in your 'render' package
// For now, let's include basic definitions here for self-containment,
// but ideally, you'd have a separate `math_types.odin` or similar.

// --- Temporary Math Type Definitions (Ideally in a separate math_types.odin) ---
Vector2 :: struct {
	x, y: f32,
}

// Basic 4x4 matrix, column-major for OpenGL
Matrix4 :: [16]f32

// Basic matrix functions (for demonstration, you'd have a more robust math library)
mat4_identity :: proc() -> Matrix4 {
	return Matrix4{1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1}
}

mat4_ortho :: proc(left, right, bottom, top, near, far: f32) -> Matrix4 {
	tx := -(right + left) / (right - left)
	ty := -(top + bottom) / (top - bottom)
	tz := -(far + near) / (far - near)

	return Matrix4 {
		2.0 / (right - left),
		0,
		0,
		0,
		0,
		2.0 / (top - bottom),
		0,
		0,
		0,
		0,
		-2.0 / (far - near),
		0,
		tx,
		ty,
		tz,
		1,
	}
}

// Basic matrix multiplication (A * B)
mat4_mul :: proc(a, b: Matrix4) -> Matrix4 {
	result: Matrix4
	for y in 0 ..< 4 {
		for x in 0 ..< 4 {
			result[y * 4 + x] =
				a[y * 4 + 0] * b[0 * 4 + x] +
				a[y * 4 + 1] * b[1 * 4 + x] +
				a[y * 4 + 2] * b[2 * 4 + x] +
				a[y * 4 + 3] * b[3 * 4 + x]
		}
	}
	return result
}

// Translate matrix
mat4_translate :: proc(m: Matrix4, v: Vector2) -> Matrix4 {
	result := m
	result[12] += v.x // column 3, row 0 (x)
	result[13] += v.y // column 3, row 1 (y)
	return result
}

// Scale matrix
mat4_scale :: proc(m: Matrix4, sx, sy: f32) -> Matrix4 {
	result := mat4_identity()
	result[0] = sx // Scale X
	result[5] = sy // Scale Y
	return mat4_mul(m, result)
}

// Rotate matrix (around Z-axis for 2D)
mat4_rotate_z :: proc(m: Matrix4, angle_radians: f32) -> Matrix4 {
	c := math.cos(angle_radians)
	s := math.sin(angle_radians)

	rotation_matrix := mat4_identity()
	rotation_matrix[0] = c
	rotation_matrix[1] = s
	rotation_matrix[4] = -s
	rotation_matrix[5] = c
	return mat4_mul(m, rotation_matrix)
}

// --- End Temporary Math Type Definitions ---


Camera2D :: struct {
	position:          Vector2,
	zoom:              f32, // 1.0 is no zoom, <1.0 is zoomed out, >1.0 is zoomed in
	rotation:          f32, // Radians
	viewport_width:    i32,
	viewport_height:   i32,

	// Pre-calculated matrices
	projection_matrix: Matrix4,
	view_matrix:       Matrix4,
	combined_matrix:   Matrix4, // projection * view
}

// `init_camera` sets up an orthographic camera.
// `width` and `height` are the dimensions of the viewable area in game units/pixels.
// This sets up a projection where (0,0) is top-left and (width,height) is bottom-right.
init_camera :: proc(width, height: i32) -> Camera2D {
	camera: Camera2D
	camera.position = Vector2{0, 0}
	camera.zoom = 1.0
	camera.rotation = 0.0
	camera.viewport_width = width
	camera.viewport_height = height

	// Initialize the projection matrix
	// Assuming (0,0) top-left, (width,height) bottom-right
	camera.projection_matrix = mat4_ortho(
		0.0,
		f32(width),
		f32(height),
		0.0, // left, right, bottom, top
		-1.0,
		1.0, // near, far (standard for 2D)
	)

	// Initialize the view matrix to identity
	camera.view_matrix = mat4_identity()
	camera.combined_matrix = camera.projection_matrix

	return camera
}

// `update_camera` recalculates the view and combined matrices. Call this
// whenever the camera's position, zoom, or rotation changes.
update_camera :: proc(c: ^Camera2D) {
	// Identity matrix
	view := mat4_identity()

	view = mat4_scale(view, c.zoom, c.zoom)

	view = mat4_rotate_z(view, -c.rotation)
	view = mat4_translate(view, {-c.position.x, -c.position.y})


	c.view_matrix = view
	c.combined_matrix = mat4_mul(c.projection_matrix, c.view_matrix)
}

// Functions to manipulate the camera

// `set_position`
set_camera_position :: proc(c: ^Camera2D, new_pos: Vector2) {
	if c.position != new_pos {
		c.position = new_pos
		update_camera(c)
	}
}

// `move_camera`
move_camera :: proc(c: ^Camera2D, delta: Vector2) {
	c.position.x += delta.x
	c.position.y += delta.y
	update_camera(c)
}

// `set_zoom`
set_camera_zoom :: proc(c: ^Camera2D, new_zoom: f32) {
	if new_zoom <= 0 {
		// TODO: set new_zoom
	}
	if c.zoom != new_zoom {
		c.zoom = new_zoom
		update_camera(c)
	}
}

// `zoom_camera`
zoom_camera :: proc(c: ^Camera2D, delta_zoom: f32) {
	set_camera_zoom(c, c.zoom + delta_zoom)
}

// `set_rotation` in radians
set_camera_rotation :: proc(c: ^Camera2D, new_rotation_radians: f32) {
	if c.rotation != new_rotation_radians {
		c.rotation = new_rotation_radians
		update_camera(c)
	}
}

// `rotate_camera` in radians
rotate_camera :: proc(c: ^Camera2D, delta_rotation_radians: f32) {
	set_camera_rotation(c, c.rotation + delta_rotation_radians)
}
