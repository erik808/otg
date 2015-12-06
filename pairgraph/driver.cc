#include <iostream>
#include <fstream>
#include "pairgraph.h"

int main(int argc, char **argv)
{
    if (argc < 5)
    {
        std::cerr << "Syntax: " << argv[0] << " [input file] [repeat length] [adjacency out] [mapping out]\n";
        return 1;
    }
	
    std::ifstream infile(argv[1]);
    if (!infile)
    {
        std::cerr << "Could not open input file " << argv[1] << '\n';
        return 1;
    }

    int repeatLength = std::stoi(argv[2]);
    CipherPairMatrix pairMatrix = makeCipherPairMatrix(infile, repeatLength);
    CipherPairMap pairMap = makeCipherPairMap(pairMatrix);
    AdjacencyMatrix adj = makeAdjacencyMatrix(pairMatrix, pairMap);

    std::ofstream adjOut(argv[3]);
    for (auto const &row: adj)
    {
        for (auto const &element: row)
            adjOut << element << ' ';
        adjOut << '\n';
    }

    std::ofstream mapOut(argv[4]);
    for (auto const &pr: pairMap)
    {
        mapOut << pr.first << ' ' << pr.second << '\n';
    }
}
