#ifndef CIPHERPAIR_H
#define CIPHERPAIR_H

#include <string>

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

std::ostream &operator<<(std::ostream &out, CipherPair const &pr);

#endif // CIPHERPAIR_H


