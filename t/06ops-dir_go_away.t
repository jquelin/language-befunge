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
$v   = Language::Befunge::Vector->new(2,4,4);
$ip->set_delta( $v );
$lbi->set_curip( $ip );
Language::Befunge::Ops::dir_go_away( $lbi );
like( $ip->get_delta, qr/^\((-?1|0),(-?1|0)\)$/,
      'dir_go_away forces a cardinal direction as new direction' );
