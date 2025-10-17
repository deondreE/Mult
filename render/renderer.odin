package render

import gl "vendor:OpenGL"
import "vendor:sdl3"

Color :: struct {
	r, g, b: f32,
}

Renderer :: struct {
	window:      ^sdl3.Window,
	ctx:         sdl3.GLContext,
	clear_color: Color,
}

init :: proc(window_title: string, width, height: i32) -> Renderer {
	if !sdl3.Init({.VIDEO}) {
		panic("Failed to initialize SDL3")
	}

	sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_MAJOR_VERSION, 3)
	sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_MINOR_VERSION, 3)
	sdl3.GL_SetAttribute(sdl3.GLAttr.CONTEXT_PROFILE_MASK, 0)

	flags := sdl3.WINDOW_OPENGL | sdl3.WINDOW_RESIZABLE
	window := sdl3.CreateWindow("Mult Engine", width, height, flags)
	if window == nil {
		panic("Failed to create SDL3 window")
	}

	ctx := sdl3.GL_CreateContext(window)
	if ctx == nil {
		panic("Failed to create SDL3 GL context")
	}
	// if !sdl3.GL_GetSwapInterval(c1) {
	// 	fmt.println("Warning: VSync wont work")
	// }
	gl.load_up_to(3, 3, sdl3.gl_set_proc_address)
	gl.Viewport(0, 0, width, height)

	init_quad_buffers()

	return Renderer{window = window, ctx = ctx, clear_color = Color{0.117, 0.117, 0.141}}
}

deinit :: proc(r: ^Renderer) {
	sdl3.GL_DestroyContext(r.ctx)
	sdl3.DestroyWindow(r.window)
	sdl3.Quit()
}

begin_frame :: proc(r: ^Renderer) {
	gl.ClearColor(r.clear_color.r, r.clear_color.g, r.clear_color.b, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

end_frame :: proc(r: ^Renderer) {
	sdl3.GL_SwapWindow(r.window)
}

shader_program: u32
vao: u32
vbo: u32
ebo: u32

init_quad_buffers :: proc() {
	vertex_source := "#version 330 core\nlayout(location=0) in vec2 aPos; \nvoid main(){ gl_Position = vec4(aPos,0.0,1.0); }"

	fragment_source := "#version 330 core\nout vec4 FragColor;\nuniform vec3 uColor;\nvoid main(){ FragColor = vec4(uColor,1.0); }"

	shader_program, ok := gl.load_shaders_source(vertex_source, fragment_source)
	if !ok do panic("Quad shader compile failed")

	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)
	gl.GenBuffers(1, &ebo)

	vertices := [8]f32{-0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5}
	indices := [6]u32{0, 1, 2, 2, 3, 0}

	gl.BindVertexArray(vao)

	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
	gl.BufferData(gl.ARRAY_BUFFER, size_of(vertices), rawptr(&vertices), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 2, gl.FLOAT, false, 2 * size_of(f32), 0)

	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(indices), rawptr(&indices), gl.STATIC_DRAW)

	gl.BindVertexArray(0)
}

render_quad :: proc(r: ^Renderer, pos: Vector2, size: Vector2, color: Color) {
	gl.UseProgram(shader_program)

	width, height: i32
	sdl3.GetWindowSize(r.window, &width, &height)

	// convert from window coordinates to normalized device coordinates
	x := (pos.x / f32(width / 2)) - 1.0
	y := 1.0 - (pos.y / f32(height / 2))
	sx := size.x / f32(width / 2)
	sy := size.y / f32(height / 2)

	// build a 4×4 transform manually
	transform := [16]f32{sx, 0, 0, 0, 0, sy, 0, 0, 0, 0, 1, 0, x, y, 0, 1}
	loc := gl.GetUniformLocation(shader_program, "uColor")
	gl.Uniform3f(loc, color.r, color.g, color.b)

	gl.BindVertexArray(vao)
	gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
	gl.BindVertexArray(0)
}
