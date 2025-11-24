package main 

import "vendor:glfw"
import "vendor:OpenGL"
import "core:fmt"
import "core:c"

window: glfw.WindowHandle


GL_MAJOR_VERSION : c.int : 4
GL_MINOR_VERSION :: 6

init_window :: proc() -> bool {
    if !glfw.Init() {
        fmt.println("Failed to init GLFW")
        return false
    }

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, glfw.TRUE)

    window = glfw.CreateWindow(800, 600, "Mult Opengl Window", nil, nil)
    if window == nil {
        fmt.println("Faield to create GLFW window.")
        glfw.Terminate()
        return false
    }

    glfw.MakeContextCurrent(window)

    OpenGL.load_up_to(int(GL_MAJOR_VERSION), GL_MINOR_VERSION, glfw.gl_set_proc_address) 

    fmt.println("OpenGL initialized successfully.")
    return true
}

run_loop :: proc() {
    for !glfw.WindowShouldClose(window) {
        glfw.PollEvents()

        // Clear screen with a bluish color
        OpenGL.Viewport(0, 0, 800, 600)
        OpenGL.ClearColor(0.1, 0.3, 0.8, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

        glfw.SwapBuffers(window)
    }
}

shutdown_window :: proc() {
    glfw.DestroyWindow(window)
    glfw.Terminate()
    fmt.println("Renderer closed.")
}