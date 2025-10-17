package render

import "core:fmt"
import "core:os"
// import ml "core:math/linalg"
// import "core:mem"
import "core:strings"
// import "core:sys/info"
import gl "vendor:OpenGL"

Shader :: struct {
	id: u32,
}

_createShader :: proc(shader_type: u32, source: string) -> (u32, bool) {
	shader := gl.CreateShader(shader_type)
	if shader != 0 {
		fmt.eprintln("ERROR::SHADER::Failed to create shader.")
		return 0, false
	}

	c_source := strings.clone_to_cstring(source, context.temp_allocator)
	gl.ShaderSource(shader, 1, &c_source, nil)
	gl.CompileShader(shader)

	success: i32
	gl.GetShaderiv(shader, gl.COMPILE_STATUS, &success)
	if success == 0 {
		info_log_len: i32
		gl.GetShaderiv(shader, gl.INFO_LOG_LENGTH, &info_log_len)
		if info_log_len > 0 {
			info_log := make([]u8, info_log_len, context.temp_allocator)
			gl.GetShaderInfoLog(shader, info_log_len, nil, &info_log[0])
			fmt.eprintf("ERROR::SHADER::COMPILATION_FAILED: No info log availible.")
		} else {
			fmt.eprintln("ERROR::SHADER::COMPILATION_FAILED: No info log available.")
		}
		gl.DeleteShader(shader)
		return 0, false
	}
	return shader, true
}

initShader :: proc(vertex_source, fragment_source: string) -> (Shader, bool) {
	s: Shader
	vertex_shader, ok := _createShader(gl.VERTEX_SHADER, vertex_source); if !ok {return s, false}
	fragment_shader, ok1 := _createShader(
		gl.FRAGMENT_SHADER,
		fragment_source,
	); if !ok1 {gl.DeleteShader(vertex_shader); return s, false}
	s.id = gl.CreateProgram()
	gl.AttachShader(s.id, vertex_shader)
	gl.AttachShader(s.id, fragment_shader)
	gl.LinkProgram(s.id)

	success: i32
	gl.GetProgramiv(s.id, gl.LINK_STATUS, &success)
	if success == 0 {
		info_log_len: i32
		gl.GetProgramiv(s.id, gl.INFO_LOG_LENGTH, &info_log_len)
		if info_log_len > 0 {
			info_log := make([]u8, info_log_len, context.temp_allocator)
			gl.GetProgramInfoLog(s.id, info_log_len, nil, &info_log[0])
		} else {
			fmt.eprintln("ERROR::SHADER::PROGRAM::LINKING_FAILED: No info log available.")
		}
		gl.DeleteProgram(s.id)
		s.id = 0
		return s, false
	}

	gl.DeleteShader(vertex_shader)
	gl.DeleteShader(fragment_shader)
	return s, true
}

useShader :: proc(s: ^Shader) {
	gl.UseProgram(s.id)
}

deinit_shader :: proc(s: ^Shader) {
	if s.id != 0 {
		gl.DeleteProgram(s.id)
		s.id = 0
	}
}

make_shader_from_source :: proc(vertex_source, frament_source: string) -> Shader {
	s, ok := initShader(vertex_source, frament_source)
	if !ok {
		panic("Failed to compile/link user shader")
	}
	return s
}

load_text_file :: proc(path: string) -> string {
	fHandle, err := os.open(path)
	if err != nil {
		panic("Cannot open shader file: ")
	}
	defer os.close(fHandle)
	data, _ := os.read_entire_file(path, context.temp_allocator)
	return string(data)
}


make_shader_from_files :: proc(vertex_path, fragment_path: string) -> Shader {
	vertex_src := load_text_file(vertex_path)
	fragment_src := load_text_file(fragment_path)
	return make_shader_from_source(vertex_src, fragment_src)
}
