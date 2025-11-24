package main

import sdl3 "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

RegionZone :: struct {
	name:  string,
	color: [4]u8,
	rect:  sdl3.FRect,
}

draw_region_zone :: proc(
	renderer: ^sdl3.Renderer,
	cam: ^Camera2D,
	font: ^ttf.Font,
	zone: ^RegionZone,
) {
	top_left := app_to_screen(cam, {zone.rect.x, zone.rect.y})
	size_w := zone.rect.w * cam.zoom
	size_h := zone.rect.h * cam.zoom

	color := zone.color

	sdl3.SetRenderDrawColor(renderer, color[0], color[1], color[2], color[3])
	rect := sdl3.FRect{top_left.x, top_left.y, size_w, size_h}
	sdl3.RenderFillRect(renderer, &rect)

	txt_color := sdl3.Color{255, 255, 255, 255}
	name_pos := Vector2{rect.x + 10, rect.y + 10}
	draw_text(renderer, font, zone.name, name_pos.x, name_pos.y, txt_color)
}

is_point_inside_region :: proc(region: ^RegionZone, p: Vector2) -> bool {
	return(
		p.x >= region.rect.x &&
		p.y >= region.rect.y &&
		p.x <= (region.rect.x + region.rect.w) &&
		p.y <= (region.rect.y + region.rect.h) \
	)
}
