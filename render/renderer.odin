package render

import "vendor:sdl3"

Color :: struct {
	r, g, b: u8,
}

Vector2 :: struct {
	x, y: f32,
}

Renderer :: struct {
	window:      ^sdl3.Window,
	renderer:    ^sdl3.Renderer,
	clear_color: Color,
}

init :: proc(window_title: string, width, height: i32) -> Renderer {
	if sdl3.Init({.VIDEO}) {
		panic("Failed to initialize SDL3")
	}

	window := sdl3.CreateWindow("test string", width, height, sdl3.WINDOW_RESIZABLE)

	if window == nil {
		panic("Failed to create SDL3 window")
	}

	sdl_renderer := sdl3.CreateRenderer(window, nil)
	if sdl_renderer == nil {
		panic("Failed to create SDL3 renderer")
	}

	return Renderer{window = window, renderer = sdl_renderer, clear_color = Color{30, 30, 36}}
}

deinit :: proc(r: ^Renderer) {
	sdl3.DestroyRenderer(r.renderer)
	sdl3.DestroyWindow(r.window)
	sdl3.Quit()
}

begin_frame :: proc(r: ^Renderer) {
	sdl3.SetRenderDrawColor(r.renderer, r.clear_color.r, r.clear_color.g, r.clear_color.b, 255)
	sdl3.RenderClear(r.renderer)
}

end_frame :: proc(r: ^Renderer) {
	sdl3.RenderPresent(r.renderer)
}

render_quad :: proc(r: ^Renderer, pos: Vector2, size: Vector2, color: Color) {
	rect := sdl3.FRect {
		x = pos.x,
		y = pos.y,
		w = size.x,
		h = size.y,
	}

	sdl3.SetRenderDrawColor(r.renderer, color.r, color.g, color.b, 255)
	sdl3.RenderFillRect(r.renderer, &rect)
}
