package main

import "core:fmt"
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

draw_edge :: proc(renderer: ^sdl3.Renderer, edge: ^Edge, cam: ^Camera2D, font: ^ttf.Font) {
	if edge.source == nil || edge.target == nil {
		return
	}

	s := app_to_screen(cam, edge.source.position)
	t := app_to_screen(cam, edge.target.position)

	sdl3.SetRenderDrawColor(renderer, 160, 160, 160, 255)
	sdl3.RenderLine(renderer, s.x+10, s.y+10, t.x+10, t.y+10)

	mid_x := (s.x + t.x) * 0.5
	mid_y := (s.y + t.y) * 0.5
	txt := fmt.tprintf("%0.0f ms", edge.latency)
	color := sdl3.Color{255, 255, 255, 255}
	draw_text(renderer, font, txt, mid_x + 5, mid_y + 5, color)
}
