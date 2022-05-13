#include <iostream>
#include <vector>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <bitset>
#include <string>

std::vector<std::string> split_string(std::string &cmdLine)
{
	std::vector<std::string> fields{};
	std::istringstream iss(cmdLine);
	for (std::string s; iss >> s;)
		fields.push_back(s);

	return fields;
}

std::string int_to_hex(unsigned int v, const std::string &header)
{
	std::stringstream stream;
	stream << header
		   << std::setfill('0') << std::setw(sizeof(int) * 2)
		   << std::hex << v;

	return stream.str();
}

std::string int_to_bin(int v, const std::string &header)
{
	std::stringstream stream;
	stream << std::bitset<32>(v);
	return stream.str();
}

std::string int_to_bin(int v)
{
	std::stringstream stream;
	stream << std::bitset<4>(v);
	return stream.str();
}

std::string int_to_string(int v)
{
	std::stringstream stream;
	stream << v;
	return stream.str();
}

int string_to_int(std::string &v)
{
	unsigned long int i;
	std::stringstream stream;
	stream << v;
	stream >> i;
	return i;
}

bool string_to_bool(std::string &v)
{
	return (v == "on" || v == "set" || v == "active") ? true : false;
}

int hex_string_to_int(std::string &v)
{
	unsigned int i;
	std::stringstream stream;
	stream << std::hex << v;
	stream >> i;
	return i;
}

int bin_string_to_int(std::string &v)
{
	int i = std::stoi(v, 0, 2);
	return i;
}
