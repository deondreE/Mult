package core

import "core:fmt"
import "core:log"
import "core:slice"

Layer_Stack :: struct {
	layers:           [dynamic]^Layer,
	layer_insert_idx: int,
}

create_layer_stack :: proc() -> Layer_Stack {
	return Layer_Stack{layers = make([dynamic]^Layer, 0, 16), layer_insert_idx = 0}
}

destroy_layer_stack :: proc(ls: ^Layer_Stack) {
	for l in ls.layers {
		l.on_detach(l)
	}
	delete(ls.layers)
}
