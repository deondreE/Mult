package main

import "core:time"
import render "render"
import sdl3 "vendor:sdl3"

main :: proc() {
	r := render.init("OpenGL Renderer", 800, 600)
	defer render.deinit(&r)

	running := true
	event: sdl3.Event

	for running {
		for sdl3.PollEvent(&event) {
			if event.type == .QUIT {
				running = false
			}
		}

		render.begin_frame(&r)
		render.render_quad(&r, {100, 100}, {200, 200}, {1, 0, 0})
		render.end_frame(&r)
		time.sleep(16 * time.Millisecond)
	}
}
