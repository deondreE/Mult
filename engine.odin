package main

import "core:fmt"
import "core:time"
import sdl3 "vendor:sdl3"

Engine_State :: enum {
	STOPPED,
	PAUSED,
	PLAYING,
}

engine_state: Engine_State = .STOPPED
window_width :: 800
window_height :: 600
window: ^sdl3.Window = nil
renderer: ^sdl3.Renderer = nil

Button_Rect :: struct {
	x, y, w, h: f32,
	text:       string,
}

play_button: Button_Rect = {10, 10, 100, 40, "Play"}
pause_button: Button_Rect = {120, 10, 100, 40, "Pause"}
stop_button: Button_Rect = {230, 10, 100, 40, "Stop"}

draw_button :: proc(button: Button_Rect, current_state: Engine_State, active_state: Engine_State) {
	if renderer == nil {return}

	// Set color based on whether it's the active state
	if current_state == active_state {
		sdl3.SetRenderDrawColor(renderer, 0, 200, 0, 255)
	} else {
		sdl3.SetRenderDrawColor(renderer, 100, 100, 100, 255) // Grey otherwise
	}
	sdl3.RenderFillRect(renderer, &sdl3.FRect{button.x, button.y, button.w, button.h})

	// Draw a border
	sdl3.SetRenderDrawColor(renderer, 255, 255, 255, 255) // White border
	sdl3.RenderRect(renderer, &sdl3.FRect{button.x, button.y, button.w, button.h})
}

init_sdl :: proc() -> bool {
	if !sdl3.Init(sdl3.INIT_VIDEO) {
		fmt.eprintf("SDL could not initialize! SDL_Error: %s\n", sdl3.GetError())
		return false
	}

	window = sdl3.CreateWindow(
		"T3 Chat Engine Viewport",
		window_width,
		window_height,
		sdl3.WINDOW_RESIZABLE,
	)
	if window == nil {
		fmt.eprintf("Window could not be created! SDL_Error: %s\n", sdl3.GetError())
		sdl3.Quit()
		return false
	}

	renderer = sdl3.CreateRenderer(window, nil) // nil for default driver
	if renderer == nil {
		fmt.eprintf("Renderer could not be created! SDL_Error: %s\n", sdl3.GetError())
		sdl3.DestroyWindow(window)
		sdl3.Quit()
		return false
	}

	// Initialize SDL_ttf if you plan to add text
	// if sdl3_ttf.Init() < 0 {
	//     fmt.eprintf("SDL_ttf could not initialize! SDL_ttf Error: %s\n", sdl3_ttf.GetError())
	//     return false
	// }

	return true
}

quit_sdl :: proc() {
	if renderer != nil {
		sdl3.DestroyRenderer(renderer)
	}
	if window != nil {
		sdl3.DestroyWindow(window)
	}
	// if sdl3_ttf.WasInit() {
	//     sdl3_ttf.Quit()
	// }
	sdl3.Quit()
}

engine_loop :: proc() {
	if !init_sdl() {
		return
	}
	defer quit_sdl() // Ensure cleanup happens when engine_loop exits

	running := true
	event: sdl3.Event
	for running {
		// Handle Events
		for sdl3.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
			case .MOUSE_BUTTON_DOWN:
				mouse_event := event.button
				handle_button_click(mouse_event.x, mouse_event.y)
			case:
			// Handle other events like key presses, window resize, etc.
			}
		}

		// Update Game State (only if playing)
		if engine_state == .PLAYING {
			update_game_logic()
		}

		// Render
		sdl3.SetRenderDrawColor(renderer, 30, 30, 30, 255) // Dark background
		sdl3.RenderClear(renderer)

		render_viewport_content()
		render_ui_buttons()

		sdl3.RenderPresent(renderer) // Present the rendered frame to the window
	}
}

update_game_logic :: proc() {
	// This is where your game simulation happens
	// e.g., move_player(), update_physics(), run_animations()
	// For now, let's just print and simulate a bit of work.
	// fmt.printf("Updating game logic...\n")
	time.sleep(16)
}

render_viewport_content :: proc() {
	// This is where you'd draw your game world/scene
	// For now, let's draw a simple spinning rectangle to show activity
	if renderer == nil {return}

	rotation_speed := 0.05 // Radians per frame (adjust for actual time)
	// The actual rotation should be based on delta time for consistent speed
	rotation_angle := f32(120.0)

	rect_w, rect_h := 100, 100.0
	rect_x := f32(window_width / 2) - f32(rect_w / 2)
	rect_y := f32(window_height / 2) - f32(rect_h / 2)

	sdl3.SetRenderDrawColor(renderer, 200, 0, 0, 255) // Red rectangle
	// SDL3's RenderGeometry or similar might be needed for rotation directly.
	// For a simple RenderRect, it won't rotate. Let's just draw a fixed one for now
	// and acknowledge that full rotation requires more advanced rendering.
	sdl3.RenderFillRect(renderer, &sdl3.FRect{rect_x, rect_y, f32(rect_w), f32(rect_h)})
}

render_ui_buttons :: proc() {
	// Draw the play, pause, stop buttons
	draw_button(play_button, engine_state, .PLAYING)
	draw_button(pause_button, engine_state, .PAUSED)
	draw_button(stop_button, engine_state, .STOPPED)
}

is_point_in_rect :: proc(x, y: f32, rect: Button_Rect) -> bool {
	return x >= rect.x && x < rect.x + rect.w && y >= rect.y && y < rect.y + rect.h
}

handle_button_click :: proc(mouse_x: f32, mouse_y: f32) {
	if is_point_in_rect(mouse_x, mouse_y, play_button) {
		fmt.printf("Play button clicked! Setting state to PLAYING.\n")
		engine_state = .PLAYING
	} else if is_point_in_rect(mouse_x, mouse_y, pause_button) {
		fmt.printf("Pause button clicked! Setting state to PAUSED.\n")
		engine_state = .PAUSED
	} else if is_point_in_rect(mouse_x, mouse_y, stop_button) {
		fmt.printf("Stop button clicked! Setting state to STOPPED.\n")
		engine_state = .STOPPED
	}
}

main :: proc() {
	engine_loop()
}
