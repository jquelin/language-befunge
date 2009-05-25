#!perl
#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

# -- numbers

use strict;
use warnings;

use Test::More tests => 34;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# empty stack
$bef->store_code( <<'END_OF_CODE' );
,q
END_OF_CODE
stdout_is { $bef->run_code } chr(0), 'empty stack, string output';
$bef->store_code( <<'END_OF_CODE' );
.q
END_OF_CODE
stdout_is { $bef->run_code } '0 ', 'empty stack, numeral output';


# zero
$bef->store_code( <<'END_OF_CODE' );
0,q
END_OF_CODE
stdout_is { $bef->run_code } chr(0), 'zero, string output';
$bef->store_code( <<'END_OF_CODE' );
0.q
END_OF_CODE
stdout_is { $bef->run_code } '0 ', 'zero, numeral output';


# one
$bef->store_code( <<'END_OF_CODE' );
1,q
END_OF_CODE
stdout_is { $bef->run_code } chr(1), 'one, string output';
$bef->store_code( <<'END_OF_CODE' );
1.q
END_OF_CODE
stdout_is { $bef->run_code } '1 ', 'one, numeral output';


# two
$bef->store_code( <<'END_OF_CODE' );
2,q
END_OF_CODE
stdout_is { $bef->run_code } chr(2), 'two, string output';
$bef->store_code( <<'END_OF_CODE' );
2.q
END_OF_CODE
stdout_is { $bef->run_code } '2 ', 'two, numeral output';


# three
$bef->store_code( <<'END_OF_CODE' );
3,q
END_OF_CODE
stdout_is { $bef->run_code } chr(3), 'three, string output';
$bef->store_code( <<'END_OF_CODE' );
3.q
END_OF_CODE
stdout_is { $bef->run_code } '3 ', 'three, numeral output';


# four
$bef->store_code( <<'END_OF_CODE' );
4,q
END_OF_CODE
stdout_is { $bef->run_code } chr(4), 'four, string output';
$bef->store_code( <<'END_OF_CODE' );
4.q
END_OF_CODE
stdout_is { $bef->run_code } '4 ', 'four, numeral output';


# five
$bef->store_code( <<'END_OF_CODE' );
5,q
END_OF_CODE
stdout_is { $bef->run_code } chr(5), 'five, string output';
$bef->store_code( <<'END_OF_CODE' );
5.q
END_OF_CODE
stdout_is { $bef->run_code } '5 ', 'five, numeral output';


# six
$bef->store_code( <<'END_OF_CODE' );
6,q
END_OF_CODE
stdout_is { $bef->run_code } chr(6), 'six, string output';
$bef->store_code( <<'END_OF_CODE' );
6.q
END_OF_CODE
stdout_is { $bef->run_code } '6 ', 'six, numeral output';


# seven
$bef->store_code( <<'END_OF_CODE' );
7,q
END_OF_CODE
stdout_is { $bef->run_code } chr(7), 'seven, string output';
$bef->store_code( <<'END_OF_CODE' );
7.q
END_OF_CODE
stdout_is { $bef->run_code } '7 ', 'seven, numeral output';


# eight
$bef->store_code( <<'END_OF_CODE' );
8,q
END_OF_CODE
stdout_is { $bef->run_code } chr(8), 'eight, string output';
$bef->store_code( <<'END_OF_CODE' );
8.q
END_OF_CODE
stdout_is { $bef->run_code } '8 ', 'eight, numeral output';


# nine
$bef->store_code( <<'END_OF_CODE' );
9,q
END_OF_CODE
stdout_is { $bef->run_code } chr(9), 'nine, string output';
$bef->store_code( <<'END_OF_CODE' );
9.q
END_OF_CODE
stdout_is { $bef->run_code } '9 ', 'nine, numeral output';


# ten
$bef->store_code( <<'END_OF_CODE' );
a,q
END_OF_CODE
stdout_is { $bef->run_code } chr(10), 'ten, string output';
$bef->store_code( <<'END_OF_CODE' );
a.q
END_OF_CODE
stdout_is { $bef->run_code } '10 ', 'ten, numeral output';


# eleven
$bef->store_code( <<'END_OF_CODE' );
b,q
END_OF_CODE
stdout_is { $bef->run_code } chr(11), 'eleven, string output';
$bef->store_code( <<'END_OF_CODE' );
b.q
END_OF_CODE
stdout_is { $bef->run_code } '11 ', 'eleven, numeral output';


# twelve
$bef->store_code( <<'END_OF_CODE' );
c,q
END_OF_CODE
stdout_is { $bef->run_code } chr(12), 'twelve, string output';
$bef->store_code( <<'END_OF_CODE' );
c.q
END_OF_CODE
stdout_is { $bef->run_code } '12 ', 'twelve, numeral output';


# thirteen
$bef->store_code( <<'END_OF_CODE' );
d,q
END_OF_CODE
stdout_is { $bef->run_code } chr(13), 'thirteen, string output';
$bef->store_code( <<'END_OF_CODE' );
d.q
END_OF_CODE
stdout_is { $bef->run_code } '13 ', 'thirteen, numeral output';


# fourteen
$bef->store_code( <<'END_OF_CODE' );
e,q
END_OF_CODE
stdout_is { $bef->run_code } chr(14), 'fourteen, string output';
$bef->store_code( <<'END_OF_CODE' );
e.q
END_OF_CODE
stdout_is { $bef->run_code } '14 ', 'fourteen, numeral output';


# fifteen
$bef->store_code( <<'END_OF_CODE' );
f,q
END_OF_CODE
stdout_is { $bef->run_code } chr(15), 'fifteen, string output';
$bef->store_code( <<'END_OF_CODE' );
f.q
END_OF_CODE
stdout_is { $bef->run_code } '15 ', 'fifteen, numeral output';


