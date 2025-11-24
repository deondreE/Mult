#include "compiler/ShaderCompiler.hpp"
#include <iostream>
#include <string>


int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: scompile -glsl <input_file>\n";
        return 1;
    }

    std::string option = argv[1];
    std::string inputPath = argv[2];

    try {
        ShaderCompiler compiler;
        if (option == "-glsl") {
            compiler.compileToGLSL(inputPath);
        } else {
            std::cerr << "Unknown option: " << option << "\n";
            return 1;
        }
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
