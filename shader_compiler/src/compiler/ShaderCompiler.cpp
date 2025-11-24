#include "ShaderCompiler.hpp"
#include "HLSLParser.hpp"
#include "GLSLGenerator.hpp"
#include "../util/FileIO.hpp"
#include <iostream>

void ShaderCompiler::compileToGLSL(const std::string &inputFile)
{
    std::string hlslSource = FileIO::readFile(inputFile);

    HLSLParser parser;
    auto ir = parser.parse(hlslSource);

    GLSLGenerator generator;
    std::string glslSource = generator.generate(ir);

    std::string outputFile = inputFile.substr(0, inputFile.find_last_of('.')) + ".glsl";
    FileIO::writeFile(outputFile, glslSource);

    std::cout << "Compiled: " << inputFile << " → " << outputFile << std::endl;
}