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
use Test::More tests => 2;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$v   = Language::Befunge::Vector->new(2,1,0);
$ip->set_delta( $v );
$lbi->set_curip( $ip );
$lbi->store_code('1234567');

Language::Befunge::Ops::block_close( $lbi );
is( $ip->get_delta, '(-1,0)', 'block_close reverses delta when no blocks are opened' );
#is( scalar(@{$ip->get_ss}), 1, 'block_close pushes current stack on stack-of-stacks' );

