#include "GLSLGenerator.hpp"
#include "../util/StringUtils.hpp"
#include <unordered_map>

std::string GLSLGenerator::generate(const ShaderIR& ir) 
{
    std::string result = ir.source;

    std::unordered_map<std::string, std::string> replacements{
        {"float4", "vec4"},
        {"float3", "vec3"},
        {"float2", "vec2"},
        {"Texture2D", "sampler2D"},
        {"SamplerState", "sampler2D"},
        {"mul", ""}
    };

    for (auto& [hlsl, glsl] : replacements)
    {
        result = StringUtils::replaceAll(result, hlsl, glsl);
    }

    return result;
}