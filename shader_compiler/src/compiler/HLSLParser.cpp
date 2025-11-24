#include "HLSLParser.hpp"
#include "../util/StringUtils.hpp"

ShaderIR HLSLParser::parse(const std::string& src)
{
    ShaderIR ir;
    ir.source = src;
    return ir;
}