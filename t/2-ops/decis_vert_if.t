#!perl

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
$v   = Language::Befunge::Vector->new(4,4);
$ip->set_delta( $v );
$lbi->set_curip( $ip );

$ip->spush( 12, 42 );
Language::Befunge::Ops::decis_vert_if( $lbi );
is( $ip->get_delta, '(0,-1)',
    'decis_vert_if sets delta to north if popped value is true' );
is( $ip->spop, 12, 'decis_vert_if pops only one value' );

$ip->spush( 0 );
Language::Befunge::Ops::decis_vert_if( $lbi );
is( $ip->get_delta, '(0,1)',
    'decis_vert_if sets delta to south if popped value is true' );

