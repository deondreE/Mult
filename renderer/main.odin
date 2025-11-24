package main

import "core:fmt"
import "core:os"

main :: proc() {
    fmt.println("=== Odin OpenGL Renderer ===")

    if !init_window() {
        os.exit(1)
    }

    run_loop()
    shutdown_window()
}