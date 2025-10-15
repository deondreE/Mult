package main

import sdl3 "vendor:sdl3"

draw_grid :: proc(renderer: ^sdl3.Renderer, cam: ^Camera2D, width, height: f32) {
	base_step: f32 = 100.0
	step := base_step * cam.zoom

	// avoid clutter being zoomed out.
	if step < 10 {
		step = 10
	}

	offset_x := int(-cam.position.x * cam.zoom) % int(step)
	offset_y := int(-cam.position.y * cam.zoom) % int(step)

	cols := int(width / step) + 2
	rows := int(height / step) + 2

	for i in 0 ..< cols {
		x := offset_x + int(step) * i
		if i % 5 == 0 {
			sdl3.SetRenderDrawColor(renderer, 70, 70, 80, 255)
		} else {
			sdl3.SetRenderDrawColor(renderer, 45, 45, 55, 255)
		}
		sdl3.RenderLine(renderer, f32(x), 0, f32(x), height)
	}

	for j in 0 ..< rows {
		y := offset_y + int(step) * j
		if j % 5 == 0 {
			if j % 5 == 0 {
				sdl3.SetRenderDrawColor(renderer, 70, 70, 80, 255)
			} else {
				sdl3.SetRenderDrawColor(renderer, 45, 45, 55, 255)
			}
		}
		sdl3.RenderLine(renderer, 0, f32(y), width, f32(y))
	}
}
