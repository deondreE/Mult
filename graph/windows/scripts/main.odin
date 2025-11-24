package main

import "core:fmt"
import "core:os"
import sdl3 "vendor:sdl3"
import ttf "vendor:sdl3/ttf"

main :: proc() {
	if !sdl3.Init({.VIDEO}) {
		panic("This is not init")
	}

	if !ttf.Init() {
		panic("TTf")
	}
	defer ttf.Quit()

	window := sdl3.CreateWindow("Mult infra Tool", 1280, 600, nil)
	renderer := sdl3.CreateRenderer(window, nil)

	font := ttf.OpenFont("./graph/assets/fonts/Roboto-Regular.ttf", 16)
	if font == nil {
		wd := os.get_current_directory(context.allocator)
		fmt.printf("Working dir: %s\n", wd)
		panic("The font failed to load")
	}
	defer ttf.CloseFont(font)

	running := true
	event: sdl3.Event
	selected_node: ^Node
	mouse_down := false
	panning_camera: bool
	last_mouse: Vector2

	// ---------------------------------------
	// Setup example nodes
	// ---------------------------------------
	camera := Camera2D {
		position = {x = 0, y = 0},
		zoom = 1.0,
	}

	regions := []RegionZone {
		{
			name = "US-East",
			color = {80, 150, 255, 80},
			rect = sdl3.FRect{x = 0, y = 0, w = 700, h = 500},
		},
		{
			name = "EU-Central",
			color = {255, 120, 90, 80},
			rect = sdl3.FRect{x = 750, y = 0, w = 700, h = 500},
		},
		{
			name = "Asia-Pacific",
			color = {255, 200, 100, 80},
			rect = sdl3.FRect{x = 1500, y = 0, w = 700, h = 500},
		},
	}

	nodes := []Node {
		// Clients
		{1, "Client_US_East", .Client, {120, 180}, false, false, nil},
		{2, "Client_EU", .Client, {830, 160}, false, false, nil},
		{3, "Client_APAC", .Client, {1580, 180}, false, false, nil},

		// Regional Gateways
		{4, "Gateway_US_East", .Gateway, {340, 220}, false, false, nil},
		{5, "Gateway_EU", .Gateway, {1060, 220}, false, false, nil},
		{6, "Gateway_APAC", .Gateway, {1810, 230}, false, false, nil},

		// Regional Servers
		{7, "Server_US_East", .Region_Server, {520, 250}, false, false, nil},
		{8, "Server_EU", .Region_Server, {1240, 240}, false, false, nil},
		{9, "Server_APAC", .Region_Server, {1990, 250}, false, false, nil},

		// Global Layer
		{10, "Global_Matchmaker", .Matchmaker, {950, 400}, false, false, nil},
		{11, "Central_Database", .Database, {970, 440}, false, false, nil},
	}

	edges := []Edge {
		// Clients → Gateway
		{1, &nodes[0], &nodes[3], 20, 0},
		{2, &nodes[1], &nodes[4], 25, 0},
		{3, &nodes[2], &nodes[5], 30, 0},

		// Gateway → Server
		{4, &nodes[3], &nodes[6], 5, 0},
		{5, &nodes[4], &nodes[7], 6, 0},
		{6, &nodes[5], &nodes[8], 7, 0},

		// Gateways → Global Matchmaker
		{7, &nodes[3], &nodes[9], 45, 0},
		{8, &nodes[4], &nodes[9], 55, 0},
		{9, &nodes[5], &nodes[9], 65, 0},

		// Matchmaker → Database
		{10, &nodes[9], &nodes[10], 5, 0},

		// Regional Servers → Database (stats uplink)
		{11, &nodes[6], &nodes[10], 15, 0},
		{12, &nodes[7], &nodes[10], 17, 0},
		{13, &nodes[8], &nodes[10], 20, 0},
	}

	for running {
		for sdl3.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
			case .KEY_DOWN:
				sym := event.key.key
				if sym == sdl3.K_ESCAPE {
					running = false
				}
				// Zoom using + or - keys
				if sym == sdl3.K_EQUALS {
					camera.zoom *= 1.1
				} else if sym == sdl3.K_MINUS {
					camera.zoom /= 1.1
				}
			case .MOUSE_WHEEL:
				if event.wheel.y > 0 {
					camera.zoom *= 1.1
				} else if event.wheel.y < 0 {
					camera.zoom /= 1.1
				}
			case .MOUSE_BUTTON_DOWN:
				mouse_down = true
				mx, my: f32
				_ = sdl3.GetMouseState(&mx, &my)
				mouse_app := screen_to_app(&camera, {mx, my})
				if event.button.button == sdl3.BUTTON_LEFT {
					for &node in nodes {
						if mouse_app.x > node.position.x &&
						   mouse_app.x < node.position.x + 130 &&
						   mouse_app.y > node.position.y &&
						   mouse_app.y < node.position.y + 60 {
							node.selected = true
							node.dragging = true
							selected_node = &node
						} else {
							node.selected = false
						}
					}
				}

				if event.button.button == sdl3.BUTTON_MIDDLE {
					panning_camera = true
				}
				last_mouse = mouse_app
			case .MOUSE_BUTTON_UP:
				if event.button.button == sdl3.BUTTON_LEFT {
					mouse_down = false
					if selected_node != nil {
						selected_node.dragging = false
					}
					selected_node = nil
				}
				if event.button.button == sdl3.BUTTON_MIDDLE {
					panning_camera = false
				}
			}
		}

		if panning_camera {
			mx, my: f32
			_ = sdl3.GetMouseState(&mx, &my)
			mouse_app := screen_to_app(&camera, {mx, my})
			delta := Vector2 {
				x = mouse_app.x - last_mouse.x,
				y = mouse_app.y - last_mouse.y,
			}
			camera.position.x -= delta.x
			camera.position.y -= delta.y
			last_mouse = screen_to_app(&camera, {mx, my})
		}

		if mouse_down && selected_node != nil && selected_node.dragging {
			mx, my: f32
			_ = sdl3.GetMouseState(&mx, &my)
			mouse_app := screen_to_app(&camera, {mx, my})
			delta := Vector2 {
				x = mouse_app.x - last_mouse.x,
				y = mouse_app.y - last_mouse.y,
			}
			selected_node.position.x += delta.x
			selected_node.position.y += delta.y
			last_mouse = mouse_app

			inside_any := false
			for &region in regions {
				if is_point_inside_region(&region, selected_node.position) {
					selected_node.region = &region
					inside_any = true
					break
				}
			}
			if !inside_any {
				selected_node.region = nil
			}
		}


		w, h: i32
		sdl3.GetRenderOutputSize(renderer, &w, &h)

		sdl3.SetRenderDrawColor(renderer, 25, 25, 30, 255)
		sdl3.RenderClear(renderer)

		for &region in regions {
			draw_region_zone(renderer, &camera, font, &region)
		}

		draw_grid(renderer, &camera, f32(w), f32(h))

		for &edge in edges {
			draw_edge(renderer, &edge, &camera, font)
		}

		for &node in nodes {
			draw_node(renderer, &node, &camera, font)
		}

		sdl3.RenderPresent(renderer)
	}

	sdl3.DestroyRenderer(renderer)
	sdl3.DestroyWindow(window)
	sdl3.Quit()
}
