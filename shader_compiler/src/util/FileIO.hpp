#pragma once
#include <string>

namespace FileIO 
{
    std::string readFile (const std::string& path);
    void writeFile(const std::string& path, const std::string& content);
}