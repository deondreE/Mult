package render

import "core:math"
import ml "core:math/linalg"

Vertex :: struct {
	position:   ml.Vector3f32,
	color:      ml.Vector4f32,
	normal:     ml.Vector3f32,
	text_coord: ml.Vector2f32,
}

Camera :: struct {
	position:     ml.Vector3f32,
	front:        ml.Vector3f32,
	up:           ml.Vector3f32,
	fov_degrees:  f32,
	aspect_ratio: f32,
	near_plane:   f32,
	far_plane:    f32,
}

getViewMatrix :: proc(c: ^Camera) -> ml.Matrix4f32 {
	return ml.matrix4_look_at_f32(c.position, c.position + c.front, c.up)
}

// equivalent to glm::perspective(fov_radians, aspect_ratio, near, far)
getProjectionMatrix :: proc(c: ^Camera) -> ml.Matrix4f32 {
	fov_radians := c.fov_degrees * (math.PI / 180.0)
	return ml.matrix4_perspective_f32(fov_radians, c.aspect_ratio, c.near_plane, c.far_plane)
}
