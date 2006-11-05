#
# This file is part of Language::Befunge.
# See README in the archive for information on copyright & licensing.
#

use Language::Befunge::Ops;

use strict;
use warnings;

use Language::Befunge::Interpreter;
use Language::Befunge::IP;
use Language::Befunge::Ops;
use Test::More tests => 3;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$lbi->set_curip( $ip );

$ip->spush( 21, 42, 4 );
Language::Befunge::Ops::math_division( $lbi );
is( $ip->spop, 10,  'math_division pushes new value' );
is( $ip->spop, 21, 'math_division pops only two values' );

$ip->spush( 21, 10, 0 ); # division by zero
Language::Befunge::Ops::math_division( $lbi );
is( $ip->spop, 0, 'math_division deals with division by zero' );

