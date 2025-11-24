#include "FileIO.hpp"
#include <fstream>
#include <stdexcept>

namespace FileIO 
{

std::string readFile(const std::string& path) 
{
    std::ifstream file(path);
    if (!file.is_open()) throw std::runtime_error("Could not open " + path);

    return std::string((std::istreambuf_iterator<char>(file)),
                       std::istreambuf_iterator<char>());
}

void writeFile(const std::string& path, const std::string& content)
{
    std::ofstream file(path);
    if (!file.is_open()) throw std::runtime_error("Could not write to " + path);
    file << content;
}

}