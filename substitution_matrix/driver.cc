#include <iostream>
#include <fstream>
#include <map>
#include <vector>
#include <array>
#include <algorithm>
#include "../pairgraph/cipherpair.h"

using SubstitutionMatrix = std::vector<std::array<double, 26>>;
using IndexMap = std::map<CipherPair, int>;

std::pair<SubstitutionMatrix, IndexMap> makeSubstitutionMatrix(std::ifstream &cipher, std::ifstream &plain)
{
    SubstitutionMatrix result;
    IndexMap index;

    Direction dir = HORIZONTAL;
    std::string pair;
    char plainChar;
    while (cipher >> pair)
    {
        while (plain.get(plainChar) && !std::isalpha(std::tolower(plainChar)))
        {} 

        CipherPair cp(pair, dir);
        if (index.find(cp) == index.end())
        {
            index[cp] = result.size(); // add new index to the list
            result.push_back({}); // push empty array to the back
        }
        
        int id = index[cp];
        result[id][std::tolower(plainChar) - 'a'] += 1;
        dir = (dir == HORIZONTAL) ? VERTICAL : HORIZONTAL; 
    }

    // Normalize rows
    for (auto &row: result)
    {
        double sum = std::accumulate(row.begin(), row.end(), 0);
        std::transform(row.begin(), row.end(), row.begin(), [&](double x) { return x / sum; });
    }
    
    return {result, index};
}

int main(int argc, char **argv)
{
    if (argc < 5)
    {
        std::cerr << "Syntax: " << argv[0] << " [ciphertext] [plaintext] [matrix (out)] [mapping (out)]\n";
        return 1;
    }

    std::ifstream cipher(argv[1]);
    std::ifstream plain(argv[2]);
    if (!cipher || !plain)
    {
        std::cerr << "Error: could not read from " << (!cipher ? argv[1] : argv[2]) << '\n';
        return 1;
    }

    auto result = makeSubstitutionMatrix(cipher, plain);
    
    std::ofstream matrix(argv[3]);
    std::ofstream mapping(argv[4]);

    for (auto const &arr: result.first)
    {
        for (auto const &val: arr)
            matrix << val << ' ';
        matrix << '\n';
    }

    for (auto const &pr: result.second)
        mapping << pr.first << ' ' << pr.second << '\n';
}
