package main

import "core:fmt"
import "vendor:vulkan"
import "core:strings"

init_vulkan :: proc() -> vulkan.Result {
    app_info := vulkan.ApplicationInfo{
        sType = .APPLICATION_INFO,
        pApplicationName = "SCompile Renderer",
        applicationVersion = vulkan.MAKE_VERSION(1, 0, 0),
        pEngineName = "SCompile Engine",
        engineVersion = vulkan.MAKE_VERSION(1, 0, 0),
        apiVersion = vulkan.API_VERSION_1_2,
    }

    extensions: [2]cstring
    extensions = [2]cstring{
        "VK_KHR_surface",
        "VK_KHR_xcb_surface",
    }
    
    create_info := vulkan.InstanceCreateInfo{
        sType = .INSTANCE_CREATE_INFO,
        pApplicationInfo = &app_info,
        enabledExtensionCount = cast(u32)len(extensions),
        ppEnabledExtensionNames = &extensions[0],
    }

    instance: vulkan.Instance
    res := vulkan.CreateInstance(&create_info, nil, &instance)
    if res != .SUCCESS {
        fmt.printf("Failed to create vulkan instance: %v\n", res)
        return res
    }

    fmt.println("Vulkan instance created suvvessfully")
    vulkan.DestroyInstance(instance, nil)
    fmt.println("Vulkan instance destoryed. Clean exit")
    return vulkan.Result.SUCCESS;
}