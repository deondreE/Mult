package main
import "core:fmt"

log_info :: proc(msg: string) {
    fmt.printf("[INFO] %s\n", msg)
}