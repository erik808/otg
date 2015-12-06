#ifndef PAIRGRAPH_UTILITIES_H
#define PAIRGRAPH_UTILITIES_H

#include "cipherpair.h"

#include <iostream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <map>

using CipherPairMatrix = std::vector<std::vector<CipherPair>>;
using AdjacencyMatrix = std::vector<std::vector<bool>>;
using CipherPairMap = std::map<CipherPair, int>;

bool checkForLoopCondition(CipherPairMatrix const &pm, int iteration, int current);
CipherPairMatrix makeCipherPairMatrix(std::ifstream &infile, size_t repeatLength);
CipherPairMap makeCipherPairMap(CipherPairMatrix const &pairMatrix);
AdjacencyMatrix makeAdjacencyMatrix(CipherPairMatrix const &matrix, CipherPairMap const &mapping);

#endif // PAIRGRAPH_UTILITIES_H
