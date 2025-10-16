package core

import "core:fmt"
import "core:log"

@(private)
Event_Type :: enum {
	None,
	Window_Close,
	Key_Press,
	Mouse_Move,
}

@(private)
Event :: struct {
	type:    Event_Type,
	handled: bool, // To stop propagation of events
}

Layer_ID :: u32

Layer :: struct {
	id:        Layer_ID,
	name:      string,
	on_attach: proc(l: ^Layer),
	on_detach: proc(l: ^Layer),
	on_update: proc(l: ^Layer, delta_time: f32),
	on_render: proc(l: ^Layer),
	on_event:  proc(l: ^Layer, e: ^Event),
}

create_layer :: proc(
	name: string,
	on_attach: proc(l: ^Layer),
	on_detach: proc(l: ^Layer),
	on_update: proc(l: ^Layer, dt: f32),
	on_render: proc(l: ^Layer),
	on_event: proc(l: ^Layer, e: ^Event),
) -> Layer {
	layer_id_counter: u32 = 0
	layer_id_counter += 1
	return Layer {
		id = layer_id_counter,
		name = name,
		on_attach = on_attach,
		on_detach = on_detach,
		on_update = on_update,
		on_render = on_render,
		on_event = on_event,
	}
}
