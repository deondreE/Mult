package main

import "core:encoding/json"
import "core:fmt"
import "core:os"

InfraSpec :: struct {
	name:    string,
	version: string,
	regions: []RegionData,
	nodes:   []NodeData,
	edges:   []EdgeData,
}

RegionData :: struct {
	name:  string,
	color: [4]u8,
	rect:  [4]f32,
}

NodeData :: struct {
	id:       u64,
	label:    string,
	kind:     string,
	region:   string,
	position: [2]f32,
}

EdgeData :: struct {
	id:        u64,
	from:      string,
	to:        string,
	latency:   f32,
	bandwidth: f32,
}

make_infra_spec :: proc(
	name: string,
	regions: []RegionZone,
	nodes: []Node,
	edges: []Edge,
) -> InfraSpec {
	return InfraSpec{}
}

save_infra_json :: proc(spec: InfraSpec, path: string) -> bool {
	encoded, _ := json.marshal(spec)
	if !os.write_entire_file(path, encoded) {
		fmt.printf("Failed to write JSON file: %s\n", path)
		return false
	}
	fmt.printf("✅ Infra JSON exported to %s\n", path)
	return true
}
