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

    CypherPair(std::string const &pr)
    {
        if (pr.size() != 2)
            throw std::string("Error: cypherpair not of length 2: ") + pr;

        d_first = pr[0];
        d_second = pr[1];
    }

    char first() { return d_first; }
    char second() { return d_second; }
};

using PairMatrix = std::vector<std::vector<CypherPair>>;
using AdjacencyMatrix = std::vector<std::vector<bool>>;

PairMatrix makePairMatrix(std::ifstream &infile, int repeatLength)
{
    PairMatrix result(1);
    result[0].reserve(repeatLength);
    
    int iteration = 0;
    while (checkForLoopCondition())
    {
        std::string pair; 
        inFile >> pair;
        
        result[iteration].push_back(CypherPair(pair));
        if (result[iteration].size() == repeatLength)
        {
            result.push_back({});
            ++iteration;
        }
    }
    
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
