#include <iostream>
#include <vector>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <bitset>

std::vector<std::string> split_string(std::string &cmdLine)
{
	std::vector<std::string> fields{};
	std::istringstream iss(cmdLine);
	for (std::string s; iss >> s;)
		fields.push_back(s);

	return fields;
}

std::string int_to_hex(unsigned long int v, const std::string &header)
{
	std::stringstream stream;
	stream << header
		   << std::setfill('0') << std::setw(sizeof(int) * 2)
		   << std::hex << v;

	// Not sure why I need to do this because setw() should handle it.
	// The stream doesn't seem to understand that v is unsigned
	// which means I end up with ffffffffdeadbeaf instead of deadbeaf.
	int size = stream.str().size();
	std::string sub = stream.str();
	if (size > 8)
		sub = sub.substr(8, 16);
	return sub;
}

std::string int_to_bin(long int v, const std::string &header)
{
	std::stringstream stream;
	stream << std::bitset<32>(v);
	return stream.str();
}

std::string int_to_bin(long int v)
{
	std::stringstream stream;
	stream << std::bitset<4>(v);
	return stream.str();
}

std::string int_to_string(long int v)
{
	std::stringstream stream;
	stream << v;
	return stream.str();
}

long int string_to_int(std::string &v)
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
