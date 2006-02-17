#-*- cperl -*-
# $Id: 03ip.t 25 2006-02-17 14:53:49Z jquelin $
#

#----------------------------------#
#          The IP module.          #
#----------------------------------#

use strict;
use Test;
use Language::Befunge::IP;

my $tests;
BEGIN { $tests = 0 };

# Constructor.
my $ip = new Language::Befunge::IP;
ok( ref($ip), "Language::Befunge::IP");
BEGIN { $tests += 1 };

# Unique ids.
ok( $ip->get_id, 0 );
$ip = new Language::Befunge::IP;
ok( $ip->get_id, 1 );
$ip = new Language::Befunge::IP;
ok( $ip->get_id, 2 );
ok( Language::Befunge::IP::get_new_id, 3 );
BEGIN { $tests += 4 };

# Test accessors.
$ip->set_curx(36);
ok( $ip->get_curx, 36 );
$ip->set_cury(27);
ok( $ip->get_cury, 27 );
$ip->set_pos(4, 6);
ok( $ip->get_curx, 4 );
ok( $ip->get_cury, 6 );
$ip->set_dx(15);
ok( $ip->get_dx, 15 );
$ip->set_dy(-4);
ok( $ip->get_dy, -4 );
$ip->set_storx( -5 );
ok( $ip->get_storx, -5 );
$ip->set_storx( 16 );
ok( $ip->get_storx, 16 );
$ip->set_string_mode( 1 );
ok( $ip->get_string_mode, 1 );
$ip->set_end( 1 );
ok( $ip->get_end, 1 );
$ip->set_input( "gnirts" );
ok( $ip->get_input, "gnirts" );
BEGIN { $tests += 11 };

# Test stack operations.
ok( $ip->spop, 0); # empty stack should return a 0.
ok( $ip->svalue(5), 0); # empty stack should return a 0.
$ip->spush( 45 );
ok( $ip->spop, 45);
$ip->spush( 65, 32, 78, 14, 0, 103, 110, 105, 114, 116, 83 );
ok( $ip->svalue(2),  116 );
ok( $ip->svalue(-2), 116 );
ok( $ip->svalue(1),  83 );
ok( $ip->svalue(-1), 83 );
ok( $ip->scount, 11 );
ok( $ip->spop_gnirts, "String" );
ok( $ip->scount, 4 );
$ip->spush_vec( 4, 5);
ok( $ip->scount, 6);
ok( $ip->spop, 5 );
ok( $ip->spop, 4 );
my ($x, $y) = $ip->spop_vec;
ok( $x, 78 );
ok( $y, 14 );
$ip->spush_args( "foo", 7, "bar" );
ok( $ip->scount, 11 );
ok( $ip->spop, 98 );
ok( $ip->spop, 97 );
ok( $ip->spop, 114 );
ok( $ip->spop, 0 );
ok( $ip->spop, 7 );
ok( $ip->spop_gnirts, "foo" );
$ip->sclear;
ok( $ip->scount, 0 );
BEGIN { $tests += 23 };

# Test stack stack.
# The following table gives the line number where the
# corresponding test is done.
#
# create = $ip->ss_create
# remove = $ip->ss_remove
# transfer = $ip->ss_transfer
#
# enough means there's enough values in the start stack to perform the
# action. not enough means there's not enough values in the start
# stack to perform the action (filled with zeroes).
#
#                   enough   not enough
# create   (<0)      106         X
# create   (=0)      136         X
# create   (>0)       96        141
# remove   (<0)      121         X
# remove   (=0)      156         X
# remove   (>0)      164        127
# transfer (<0)      161        110
# transfer (=0)      153         X
# transfer (>0)      102        146
$ip->sclear;
$ip->spush( 11, 12, 13, 14, 15, 16, 17, 18, 19 );
ok( $ip->scount, 9 );             # toss = (11,12,13,14,15,16,17,18,19)
ok( $ip->ss_count, 0 );
$ip->ss_create( 2 );              # create new toss, filled with values (enough).
ok( $ip->scount, 2 );             # toss = (18,19)
ok( $ip->soss_count, 7 );         # soss = (11,12,13,14,15,16,17)
ok( $ip->ss_count, 1 );
ok( $ip->spop, 19 );              # toss = (18)
ok( $ip->soss_pop, 17 );          # soss = (11,12,13,14,15,16)
$ip->ss_transfer( 2 );            # move elems from soss to toss (enough).
ok( $ip->scount, 3 );             # toss = (18,16,15)
ok( $ip->soss_count, 4 );         # soss = (11,12,13,14)
ok( $ip->spop, 15 );              # toss = (18,16)
$ip->ss_create( -3 );             # create new toss, filled with zeroes.
ok( $ip->scount, 3 );             # toss = (0,0,0)
ok( $ip->soss_count, 2 );         # soss = (18,16)
ok( $ip->ss_count, 2 );
ok( join("",$ip->ss_sizes), "324" );
ok( $ip->spop, 0 );               # toss = (0,0)
$ip->ss_transfer( -10 );          # move elems from toss to soss (not enough).
ok( $ip->scount, 0 );             # toss = ()
ok( $ip->soss_count, 12 );        # soss = (18,17,0,0,0,0,0,0,0,0,0,0)
$ip->soss_push( 15 );             # soss = (18,17,0,0,0,0,0,0,0,0,0,0,15)
ok( $ip->soss_pop, 15 );          # soss = (18,17,0,0,0,0,0,0,0,0,0,0)
$ip->soss_clear;                  # soss = ()
ok( $ip->soss_count, 0 );
$ip->spush( 16, 17 );             # toss = (16, 17)
$ip->soss_push( 13, 14, 15, 16 ); # soss = (13,14,15,16)
$ip->ss_remove( -1 );             # destroy toss, remove elems.
ok( $ip->ss_count, 1 );
ok( $ip->scount, 3 );             # toss = (13,14,15)
ok( $ip->spop, 15 );              # toss = (13,14)
ok( $ip->spop, 14 );              # toss = (13)
$ip->spush( 14, 15 );
$ip->ss_remove( 5 );              # destroy toss, push values (not enough).
ok( $ip->ss_count, 0 );
ok( $ip->scount, 9 );             # toss = (11,12,13,14,0,0,13,14,15)
ok( $ip->spop, 15 );              # toss = (11,12,13,14,0,0,13,14)
ok( $ip->spop, 14 );              # toss = (11,12,13,14,0,0,13)
ok( $ip->spop, 13 );              # toss = (11,12,13,14,0,0)
ok( $ip->spop, 0 );               # toss = (11,12,13,14,0)
ok( $ip->spop, 0 );               # toss = (11,12,13,14)
ok( $ip->spop, 14 );              # toss = (11,12,13)
$ip->ss_create( 0 );              # create new toss, no values filled.
ok( $ip->scount, 0 );             # toss = ()
ok( $ip->soss_count, 3 );         # soss = (11,12,13)
ok( $ip->ss_count, 1 );
$ip->spush( 78 );                 # toss = (78)
$ip->ss_create( 3 );              # create new toss, filled with values (not enough).
ok( $ip->scount, 3 );             # toss = (0,0,78)
ok( $ip->soss_count, 0 );         # soss = ()
ok( $ip->ss_count, 2 );
$ip->soss_push( 45 );             # soss = (45)
$ip->ss_transfer( 3 );            # move elems from soss to toss (not enough).
ok( $ip->scount, 6 );             # toss = (0,0,78,45,0,0)
ok( $ip->soss_count, 0 );         # soss = ()
ok( $ip->spop, 0 );               # toss = (0,0,78,45,0)
ok( $ip->spop, 0 );               # toss = (0,0,78,45)
ok( $ip->spop, 45 );              # toss = (0,0,78)
$ip->soss_push( 12 );             # soss = (12)
$ip->ss_transfer( 0 );            # move 0 elems.
ok( $ip->scount, 3 );
ok( $ip->soss_count, 1 );
$ip->ss_remove( 0 );              # destroy toss, no values moved.
ok( $ip->scount, 1 );             # toss = (12)
ok( $ip->soss_count, 3 );         # soss = (11,12,13)
ok( $ip->ss_count, 1 );
$ip->spush( 18 );                 # toss = (12,18)
$ip->ss_transfer( -1 );           # move elems from toss to soss (enough).
ok( $ip->scount, 1 );             # toss = (12)
ok( $ip->soss_count, 4 );         # soss = (11,12,13,18)
$ip->ss_remove( 1 );              # destroy toss, values filled (enough).
ok( $ip->scount, 5 );             # toss = (11,12,13,18,12)
ok( $ip->ss_count, 0 );
ok( $ip->spop, 12 );              # toss = (11,12,13,18)
ok( $ip->spop, 18 );              # toss = (11,12,13)
ok( $ip->spop, 13 );              # toss = (11,12)
ok( $ip->spop, 12 );              # toss = (11)
BEGIN { $tests += 55 };

# Test cardinal directions.
$ip->dir_go_east();
ok( $ip->get_dx, 1 );
ok( $ip->get_dy, 0 );
$ip->dir_go_west();
ok( $ip->get_dx, -1 );
ok( $ip->get_dy, 0 );
$ip->dir_go_north();
ok( $ip->get_dx, 0 );
ok( $ip->get_dy, -1 );
$ip->dir_go_south();
ok( $ip->get_dx, 0 );
ok( $ip->get_dy, 1 );
BEGIN { $tests += 8 };

# Test random direction.
$ip->dir_go_away();
ok( abs($ip->get_dx + $ip->get_dy), 1);
BEGIN { $tests += 1 };

# Test turn left.
$ip->dir_go_east();
$ip->dir_turn_left();
ok( $ip->get_dx, 0);
ok( $ip->get_dy, -1);
$ip->dir_turn_left();
ok( $ip->get_dx, -1);
ok( $ip->get_dy, 0);
$ip->dir_turn_left();
ok( $ip->get_dx, 0);
ok( $ip->get_dy, 1);
$ip->dir_turn_left();
ok( $ip->get_dx, 1);
ok( $ip->get_dy, 0);
BEGIN { $tests += 8 };
$ip->set_delta(3,2);
$ip->dir_turn_left();
ok( $ip->get_dx, 2);
ok( $ip->get_dy, -3);
$ip->dir_turn_left();
ok( $ip->get_dx, -3);
ok( $ip->get_dy, -2);
$ip->dir_turn_left();
ok( $ip->get_dx, -2);
ok( $ip->get_dy, 3);
$ip->dir_turn_left();
ok( $ip->get_dx, 3);
ok( $ip->get_dy, 2);
BEGIN { $tests += 8 };

# Test turn right.
$ip->dir_go_east();
$ip->dir_turn_right();
ok( $ip->get_dx, 0);
ok( $ip->get_dy, 1);
$ip->dir_turn_right();
ok( $ip->get_dx, -1);
ok( $ip->get_dy, 0);
$ip->dir_turn_right();
ok( $ip->get_dx, 0);
ok( $ip->get_dy, -1);
$ip->dir_turn_right();
ok( $ip->get_dx, 1);
ok( $ip->get_dy, 0);
BEGIN { $tests += 8 };
$ip->set_delta(3,2);
$ip->dir_turn_right();
ok( $ip->get_dx, -2);
ok( $ip->get_dy, 3);
$ip->dir_turn_right();
ok( $ip->get_dx, -3);
ok( $ip->get_dy, -2);
$ip->dir_turn_right();
ok( $ip->get_dx, 2);
ok( $ip->get_dy, -3);
$ip->dir_turn_right();
ok( $ip->get_dx, 3);
ok( $ip->get_dy, 2);
BEGIN { $tests += 8 };

# Test reverse.
$ip->dir_go_east();
$ip->dir_reverse();
ok( $ip->get_dx, -1 );
ok( $ip->get_dy, 0 );
$ip->dir_reverse();
ok( $ip->get_dx, 1 );
ok( $ip->get_dy, 0 );
$ip->set_delta( 2, -3);
$ip->dir_reverse();
ok( $ip->get_dx, -2 );
ok( $ip->get_dy, 3 );
$ip->dir_reverse();
ok( $ip->get_dx, 2 );
ok( $ip->get_dy, -3 );
BEGIN { $tests += 8 };

# Test cloning.
$ip = new Language::Befunge::IP;
$ip->spush( 1, 5, 6 );
my $clone = $ip->clone;
ok( $ip->get_id != $clone->get_id, 1 );
ok( $ip->spop, 6 );
ok( $clone->spop, 6 );
ok( $clone->spop, 5 );
BEGIN { $tests += 4 };

BEGIN { plan tests => $tests };


