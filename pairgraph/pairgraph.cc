#include "pairgraph.h"

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

std::ostream &operator<<(std::ostream &out, CipherPair const &pr)
{
    return (out << pr.first() << pr.second() << pr.direction());
}
