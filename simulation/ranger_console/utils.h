#pragma once

#include <vector>
#include <sstream>

std::vector<std::string> split_string(std::string& cmdLine);
int string_to_int(std::string& v);
std::string int_to_hex(unsigned int v, const std::string& header);
std::string int_to_bin(int v);

bool string_to_bool(std::string& v);
int hex_string_to_int(std::string& v);
std::string int_to_bin(int v, const std::string& header);
std::string int_to_string(int v);
int bin_string_to_int(std::string &v);

int word_to_byte_addr(int wa);
int byte_to_word_addr(int ba);
