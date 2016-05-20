#!perl

use strict;
use warnings;

# -- TEST library

# this test is not like the others, where we check whether the output matches
# what is expected. indeed, since we're testing a test library, we're just
# running the befunge snippets, which should output some regular tap.

use Language::Befunge;
my $bef = Language::Befunge->new;

# TEST.pm and this test script share the same plan.

# plan (no_plan)
$bef->store_code( <<'END_OF_CODE' );
0"TSET"4(#@0P)@
END_OF_CODE
$bef->run_code;

# ok
$bef->store_code( <<'END_OF_CODE' );
0"TSET"4(0"dnammoc O"1O)@
END_OF_CODE
$bef->run_code;

# is
$bef->store_code( <<'END_OF_CODE' );
0"TSET"4(0"dnammoc I"44I)@
END_OF_CODE
$bef->run_code;

