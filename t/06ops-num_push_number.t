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
use Test::More tests => 1;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$v   = Language::Befunge::Vector->new(2,0,0);
$lbi->set_curip( $ip );
$lbi->get_torus->set_value( $v, ord('e') );
Language::Befunge::Ops::num_push_number( $lbi );
is( $ip->spop, 14, 'num_push_number pushes current instruction on the stack as number' );
