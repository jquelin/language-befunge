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
$v   = Language::Befunge::Vector->new(4,4);
$ip->spush( 12, 42 );
$ip->set_delta( $v );
$lbi->set_curip( $ip );

Language::Befunge::Ops::flow_kill_thread( $lbi );
is( $ip->get_end, '@', 'flow_kill_thread sets end of thread' );

