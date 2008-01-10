#!perl
#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
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
$v   = Language::Befunge::Vector->new(4,4);
$ip->spush( 12, 42 );
$ip->set_delta( $v );
$lbi->set_curip( $ip );

Language::Befunge::Ops::flow_no_op( $lbi );
is( $ip->get_delta, '(4,4)', 'flow_no_op does not alter delta' );
is( $ip->spop, 42, 'flow_no_op does not pop any value' );
