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
use Language::Befunge::Vector;
use Test::More tests => 3;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$v   = Language::Befunge::Vector->new(2,1,0);
$ip->set_delta( $v );
$ip->spush( ord('A') );
$lbi->set_curip( $ip );
$lbi->get_torus->set_value( $v, ord('B') ); # to enlarge torus
Language::Befunge::Ops::str_store_char( $lbi );
is( $ip->get_position, '(1,0)', 'str_store_char moves ip' );
is( $ip->spop, 0, 'str_store_char pops value from ip' );
is( $lbi->get_torus->get_value( $v ), ord('A'),
    'str_store_char oversrites next instruction from the char on the stack' );
