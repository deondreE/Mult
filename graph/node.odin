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
		// coeff = C(n, i) * (1-t)^(n-i) * t^i
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

draw_thick_lines :: proc(
	renderer: ^sdl3.Renderer,
	a, b: Vector2,
	thickness: f32,
	color: sdl3.FColor,
) {
	dx := b.x - a.x
	dy := b.y - a.y
	len := math.sqrt(dx * dx + dy * dy)

	nx := -dy / len
	ny := dx / len
	half := thickness * 0.5
	inner := color; inner.a = 255 // center opaque
	outer := color; outer.a = 40

	p1 := sdl3.FPoint{a.x + nx * half, a.y + ny * half}
	p2 := sdl3.FPoint{a.x - nx * half, a.y - ny * half}
	p3 := sdl3.FPoint{b.x - nx * half, b.y - ny * half}
	p4 := sdl3.FPoint{b.x + nx * half, b.y + ny * half}

	verts := [4]sdl3.Vertex {
		{p1, inner, {0, 0}},
		{p2, outer, {0, 0}},
		{p3, outer, {0, 0}},
		{p4, inner, {0, 0}},
	}
	indicies := [6]i32{0, 1, 2, 2, 3, 0}
	_ = sdl3.RenderGeometry(renderer, nil, &verts[0], 4, &indicies[0], 6)
}

draw_edge :: proc(renderer: ^sdl3.Renderer, edge: ^Edge, cam: ^Camera2D, font: ^ttf.Font) {
	if edge.source == nil || edge.target == nil {
		return
	}

	s := edge.source.position
	t := edge.target.position

	edge_index_offset := ((cast(int)(edge.source.id + edge.target.id)) % 3) - 1

	dx_st := t.x - s.x
	dy_st := t.y - s.y
	dist_st := math.sqrt(dx_st * dx_st + dy_st * dy_st)
	MIN_NORMALIZED_DIST :: 1e-6
	if dist_st < MIN_NORMALIZED_DIST {
		a_screen := app_to_screen(cam, s)
		b_screen := app_to_screen(cam, t)
		line_color := sdl3.FColor{160.0 / 255.0, 160.0 / 255.0, 160.0 / 255.0, 255.0 / 255.0}
		draw_thick_lines(renderer, a_screen, b_screen, 3.0, line_color)
		return
	}

	MIN_EFFECTED_DIST :: 20.0
	_ = math.max(dist_st, MIN_EFFECTED_DIST)

	// dir_st_x := dx_st / dist_st
	// dir_st_y := dy_st / dist_st

	perp_x := -dx_st / dist_st
	perp_y := dx_st / dist_st

	ARC_TENSION_FACTOR :: 0.2
	MAX_ARC_HEIGHT :: 150.0
	SEPARATION_TENSION_FACTOR :: 0.05
	MAX_SEPARATION_HEIGHT :: 60.0

	arc_strength := clamp(dist_st * ARC_TENSION_FACTOR, 0.0, MAX_ARC_HEIGHT) // How much it bends off the straight line
	arc_separation :=
		f32(edge_index_offset) *
		clamp(dist_st * SEPARATION_TENSION_FACTOR, 0.0, MAX_SEPARATION_HEIGHT) // How much it shifts for parallel lines


	mid_s_t := Vector2{(s.x + t.x) * 0.5, (s.y + t.y) * 0.5}
	p1_control_point := Vector2 {
		mid_s_t.x + (perp_x * (arc_strength + arc_separation)),
		mid_s_t.y + (perp_y * (arc_strength + arc_separation)),
	}
	control_points := [3]Vector2{s, p1_control_point, t}

	// --- DEBUG: Print control point coordinates ---
	// fmt.eprintf("DEBUG: Edge %d->%d\n", edge.source.id, edge.target.id)
	// fmt.eprintf("       P0: (%.1f, %.1f)\n", s.x, s.y)
	// fmt.eprintf(
	// 	"       P1: (%.1f, %.1f) [Arc:%.1f, Sep:%.1f]\n",
	// 	p1_control_point.x,
	// 	p1_control_point.y,
	// 	arc_strength,
	// 	arc_separation,
	// )
	// fmt.eprintf("       P2: (%.1f, %.1f)\n", t.x, t.y)
	// --- END DEBUG ---

	segments :: 100
	prev := bezier_point(control_points[:], 0.0)
	line_color := sdl3.FColor{160.0 / 255.0, 160.0 / 255.0, 160.0 / 255.0, 255.0 / 255.0}

	for i in 1 ..= segments {
		u := f32(i) / f32(segments)

		next := bezier_point(control_points[:], u)
		if math.is_nan(next.x) || math.is_nan(next.y) {
			fmt.eprintf(
				"ERROR: NaN in bezier_point output at u=%.2f for edge %d->%d\n",
				u,
				edge.source.id,
				edge.target.id,
			)
			break // Stop drawing this corrupted line
		}
		a := app_to_screen(cam, prev)
		b := app_to_screen(cam, next)
		// sdl3.RenderLine(renderer, a.x, a.y, b.x, b.y)
		draw_thick_lines(renderer, a, b, 3.0, line_color)
		prev = next
	}

	// Midpoint text
	mid := bezier_point(control_points[:], 0.5)
	mid_screen := app_to_screen(cam, mid)

	txt := fmt.tprintf("%0.0f ms", edge.latency)
	color := sdl3.Color{255, 255, 255, 255}
	draw_text(renderer, font, txt, mid_screen.x + 5, mid_screen.y + 5, color)
}
