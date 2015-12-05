#include <iostream>
#include <fstream>

class CypherPair
{
	char d_first;
	char d_second;

public:
	CypherPair(char f, char s):
		first(f),
		second(s)
		{}

	char first() { return d_first; }
	char second() { return d_second; }
};

using PairMatrix = std::vector<std::vector<CypherPair>>;


PairMatrix makePairMatrix(std::ifstream &infile, int repeatLength)
{
	PairMatrix result;

}

int main(int argc, char **argv)
{
	if (argc < 3)
	{
		std::cerr << "Syntax: " << argv[0] << " [input file] [repeat length]\n";
		return 1;
	}
	
	std::ifstream infile(argv[1]);
	int repeatLength = std::stoi(argv[2]);

	PairMatrix pm = makePairMatrix(infile, repeatLength);
}
