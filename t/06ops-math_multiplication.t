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
use Test::More tests => 4;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$lbi->set_curip( $ip );

$ip->spush( 21, 42, 63 );
Language::Befunge::Ops::math_multiplication( $lbi );
is( $ip->spop, 2646, 'math_multiplication pushes new value' );
is( $ip->spop, 21,   'math_multiplication pops only two values' );

SKIP: {
    eval { require Test::Exception; Test::Exception->import; };
    skip 'need Test::Exception', 2 unless defined $Test::Exception::VERSION;
    # overflow
    $ip->spush( 2**31-2, 3 );
    throws_ok( sub { Language::Befunge::Ops::math_multiplication($lbi) },
        qr/overflow/, 'math_multiplication barfs on overflow' );
    # underflow
    $ip->spush( -2**31+2, 3 );
    throws_ok( sub { Language::Befunge::Ops::math_multiplication($lbi) },
        qr/under/, 'math_multiplication barfs on underflow' );
}
