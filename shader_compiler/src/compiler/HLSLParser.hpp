#pragma once
#include <string>
#include <unordered_map>

struct ShaderIR 
{
    std::string source;
};  

class HLSLParser 
{
public:
    ShaderIR parse(const std::string& src);
};
