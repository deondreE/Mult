#pragma once
#include <string>
#include "HLSLParser.hpp"

class GLSLGenerator
{
public:
    std::string generate(const ShaderIR& ir);
};