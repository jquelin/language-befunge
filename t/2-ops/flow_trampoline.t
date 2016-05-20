#!perl

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
$v   = Language::Befunge::Vector->new(2,0);
$ip->set_delta( $v );
$lbi->set_curip( $ip );
$lbi->store_code( '     q' );

Language::Befunge::Ops::flow_trampoline( $lbi );
is( $ip->get_position, '(2,0)', 'flow_trampoline moves ip' );
