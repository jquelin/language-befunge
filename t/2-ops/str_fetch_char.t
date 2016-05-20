#!perl

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
$v   = Language::Befunge::Vector->new(1,0);
$ip->set_delta( $v );
$lbi->set_curip( $ip );
$lbi->get_storage->set_value( $v, ord('A') );
Language::Befunge::Ops::str_fetch_char( $lbi );
is( $ip->get_position, '(1,0)', 'str_fetch_char moves ip' );
is( $ip->spop, 65, 'str_fetch_char pushes value on ip' );
