#ifndef SHADER_COMPILER_HPP
#define SHADER_COMPILER_HPP

#include <string>
#include <vector>
#include <map>
#include <optional> 
#include <sstream>

namespace ShaderCompiler {
  struct CompilationError 
  { 
    std::string message;
    int line; 
    int column;

    std::string toString() const {
      std::stringstream ss;
      ss << "Error (Line " << line << "): " << message;
      if (column != 1) {
        ss << "(Column " << column << ")";
      }
      return ss.str();
    }
  };
} // Namespace ShaderCompiler

#endif