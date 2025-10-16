package main

import "core:fmt"
import "core:math"
import "core:strings"
import sdl3 "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

Vector2 :: struct {
	x: f32,
	y: f32,
}

Node_Type :: enum {
	Client,
	Gateway,
	Region_Server,
	Matchmaker,
	Database,
}

Camera2D :: struct {
	position: Vector2,
	zoom:     f32,
}

Node :: struct {
	id:       u64,
	label:    string,
	kind:     Node_Type,
	position: Vector2,
	selected: bool,
	dragging: bool,
	region:   ^RegionZone,
}

Edge :: struct {
	id:        u64,
	source:    ^Node,
	target:    ^Node,
	latency:   f32,
	bandwidth: f32,
}

screen_to_app :: proc(cam: ^Camera2D, screen: Vector2) -> Vector2 {
	return Vector2 {
		x = (screen.x / cam.zoom) + cam.position.x,
		y = (screen.y / cam.zoom) + cam.position.y,
	}
}

app_to_screen :: proc(cam: ^Camera2D, app: Vector2) -> Vector2 {
	return Vector2 {
		x = (app.x - cam.position.x) * cam.zoom,
		y = (app.y - cam.position.y) * cam.zoom,
	}
}

draw_text :: proc(
	renderer: ^sdl3.Renderer,
	font: ^ttf.Font,
	text: string,
	x, y: f32,
	color: sdl3.Color,
) {
	t_string := strings.clone_to_cstring(text)
	surface := ttf.RenderText_Blended(font, t_string, len(t_string), color)
	if surface == nil {return}
	defer sdl3.DestroySurface(surface)

	texture := sdl3.CreateTextureFromSurface(renderer, surface)
	if texture == nil {return}
	defer sdl3.DestroyTexture(texture)

	dst := sdl3.FRect {
		x = x,
		y = y,
		w = f32(surface.w),
		h = f32(surface.h),
	}
	sdl3.RenderTexture(renderer, texture, nil, &dst)
}

draw_node :: proc(renderer: ^sdl3.Renderer, node: ^Node, cam: ^Camera2D, font: ^ttf.Font) {
	pos := app_to_screen(cam, node.position)
	size := Vector2{130, 60}

	r, g, b: u8
	switch node.kind {
	case .Client:
		r, g, b = 80, 200, 120
	case .Gateway:
		r, g, b = 120, 160, 255
	case .Region_Server:
		r, g, b = 200, 120, 255
	case .Matchmaker:
		r, g, b = 250, 200, 120
	case .Database:
		r, g, b = 255, 100, 100
	}

	if node.selected {
		r = min(r + 40, 255)
		g = min(g + 40, 255)
		b = min(b + 40, 255)
	}

	if node.region != nil {
		r = min(48, 255)
		g = min(72, 255)
		b = min(60, 255)
	}

	rect := sdl3.FRect {
		x = pos.x,
		y = pos.y,
		w = size.x * cam.zoom,
		h = size.y * cam.zoom,
	}

	sdl3.SetRenderDrawColor(renderer, r, g, b, 255)
	sdl3.RenderFillRect(renderer, &rect)
	// Outline
	sdl3.SetRenderDrawColor(renderer, 255, 255, 255, 50)
	sdl3.RenderRect(renderer, &rect)

	label_color := sdl3.Color{255, 255, 255, 255}
	text_x := rect.x + (rect.w / 2) - f32(len(node.label) * 4)
	text_y := rect.y + (rect.h / 2) - 6
	draw_text(renderer, font, node.label, text_x, text_y, label_color)
}


clamp :: proc(v, min_v, max_v: f32) -> f32 {
	if v < min_v do return min_v
	if v > max_v do return max_v
	return v
}

// Compute n-th degree Bézier point
// points: array of control points P0..Pn
// t: in [0,1]
bezier_point :: proc(points: []Vector2, t: f32) -> Vector2 {
	n := len(points) - 1
	result := Vector2{0, 0}

	for i in 0 ..< len(points) {
		coeff := binomial_coeff(n, i) * math.pow(1 - t, f32(n - i)) * math.pow(t, f32(i))
		result.x += coeff * points[i].x
		result.y += coeff * points[i].y
	}

	return result
}

// Binomial coefficient C(n,i) = n! / (i!(n-i)!)
binomial_coeff :: proc(n, k: int) -> f32 {
	if k < 0 || k > n do return 0
	// Efficient iterative form
	res: f32 = 1
	for i in 0 ..< k {
		res *= f32(n - i)
		res /= f32(i + 1)
	}
	return res
}

draw_edge :: proc(renderer: ^sdl3.Renderer, edge: ^Edge, cam: ^Camera2D, font: ^ttf.Font) {
	if edge.source == nil || edge.target == nil {
		return
	}

	s := edge.source.position
	t := edge.target.position

	edge_index_offset := ((edge.source.id + edge.target.id) % 3) - 1

	dx := t.x - s.x
	dy := t.y - s.y
	dist := math.sqrt(dx * dx + dy * dy)
	if dist < 1 do dist = 1

	control_offset := clamp(dist * 0.25, 40.0, 180.0)
	curve_y_offset := f32(edge_index_offset) * clamp(dist * 0.05, 20.0, 60.0)

	// Define control points (same as before)
	control_points := [4]Vector2 {
		s,
		{s.x + control_offset, s.y + curve_y_offset},
		{t.x - control_offset, t.y + curve_y_offset},
		t,
	}

	segments :: 24
	prev := bezier_point(control_points[:], 0.0)
	sdl3.SetRenderDrawColor(renderer, 160, 160, 160, 255)

	for i in 1 ..< segments {
		u := f32(i) / f32(segments)
		next := bezier_point(control_points[:], u)
		a := app_to_screen(cam, prev)
		b := app_to_screen(cam, next)
		sdl3.RenderLine(renderer, a.x, a.y, b.x, b.y)
		prev = next
	}

	// Midpoint text
	mid := bezier_point(control_points[:], 0.5)
	mid_screen := app_to_screen(cam, mid)

	txt := fmt.tprintf("%0.0f ms", edge.latency)
	color := sdl3.Color{255, 255, 255, 255}
	draw_text(renderer, font, txt, mid_screen.x + 5, mid_screen.y + 5, color)
}
