#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <unordered_map>
#include <map>

enum Direction
{
    HORIZONTAL,
    VERTICAL
};

class CipherPair
{
    char d_first;
    char d_second;
    Direction d_direction;

public:
    CipherPair(char f, char s, Direction d):
        d_first(f),
        d_second(s),
        d_direction(d)
    {}

    CipherPair(std::string const &pr, Direction d):
        d_direction(d)
    {
        if (pr.size() != 2)
            throw std::string("Error: cipherpair not of length 2: ") + pr;

        d_first = pr[0];
        d_second = pr[1];
    }

    char first() const { return d_first; }
    char second() const { return d_second; }
    Direction direction() const { return d_direction; }

    bool operator==(CipherPair const &other) const
    {
        return d_first == other.d_first &&
            d_second == other.d_second &&
            d_direction == other.d_direction;
    }

    bool operator<(CipherPair const &other) const
    {
        static std::string const appender("01");
        std::string s1({d_first, d_second, appender[d_direction]});
        std::string s2({other.d_first, other.d_second, appender[other.d_direction]});

        return s1 < s2;
    }
};

std::ostream &operator<<(std::ostream &out, CipherPair const &pr)
{
    return (out << pr.first() << pr.second() << pr.direction());
}

using CipherPairMatrix = std::vector<std::vector<CipherPair>>;
using AdjacencyMatrix = std::vector<std::vector<bool>>;
using CipherPairMap = std::map<CipherPair, int>;


bool checkForLoopCondition(CipherPairMatrix const &pm, int iteration, int current)
{
    static std::vector<int> counts;
    static int const countLimit = 3;
    
    if (iteration == 0)
        return false;

    counts.resize(iteration);
    for (int i = 0; i != iteration; ++i)
    {
        if (pm[i][current] == pm[iteration][current])
            ++counts[i];
        else
            counts[i] = 0;
    }

    return std::any_of(counts.begin(), counts.end(), [&](int c) 
                       { 
                           return c >= countLimit; 
                       });
}

CipherPairMatrix makeCipherPairMatrix(std::ifstream &infile, size_t repeatLength)
{
    CipherPairMatrix result(1);
    result[0].reserve(repeatLength);
    
    int iteration = 0;
    int current = 0;
    std::string pair; 

    Direction dir = HORIZONTAL;
    while (infile >> pair)
    {
        result[iteration].push_back(CipherPair(pair, dir));
        if (checkForLoopCondition(result, iteration, current))
            break;

        ++current;
        if (result[iteration].size() == repeatLength)
        {
            result.push_back({});
            current = 0;
            ++iteration;
        }
        
        dir = (dir == HORIZONTAL) ? VERTICAL : HORIZONTAL;
    }

    return result;
}

CipherPairMap makeCipherPairMap(CipherPairMatrix const &pairMatrix)
{
    CipherPairMap pairMap;
    int id = 0;
    
    for (auto const &col: pairMatrix)
        for (CipherPair pair: col)
        {
            if (pairMap.find(pair) == pairMap.end())
                pairMap[pair] = id++;
        }

    return pairMap;
}

AdjacencyMatrix makeAdjacencyMatrix(CipherPairMatrix const &matrix, CipherPairMap const &mapping)
{
    int n = mapping.size();

    // initialize matrix
    AdjacencyMatrix result(n);
    for (auto &row: result)
        row.resize(n);

    // fill according to matrix
    for (size_t i = 0; i != matrix[0].size(); ++i)
    {
        std::vector<int> connected;
        for (size_t j = 0; j != matrix.size(); ++j)
        {
            if (i >= matrix[j].size())
                continue;
            
            connected.push_back(mapping.find(matrix[j][i])->second);
        }

        for (size_t j = 0; j != connected.size(); ++j)
            for (size_t k = 0; k != connected.size(); ++k)
                result[connected[j]][connected[k]] = true;
    }

    return result;
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

    CipherPairMatrix pairMatrix = makeCipherPairMatrix(infile, repeatLength);
    CipherPairMap pairMap = makeCipherPairMap(pairMatrix);
    AdjacencyMatrix adj = makeAdjacencyMatrix(pairMatrix, pairMap);

    for (auto const &row: adj)
    {
        for (auto const &element: row)
            std::cout << element << ' ';
        std::cout << '\n';
    }

}
