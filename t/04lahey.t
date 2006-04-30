#-*- cperl -*-
# $Id: 04lahey.t 33 2006-04-30 13:54:21Z jquelin $
#

#------------------------------------------#
#          The LaheySpace module.          #
#------------------------------------------#

use strict;
use Test::More;
use Language::Befunge::IP;
use Language::Befunge::LaheySpace;

my $tests;
my $ip = Language::Befunge::IP->new;
my $href;
BEGIN { $tests = 0 };


# constructor.
my $ls = Language::Befunge::LaheySpace->new;
isa_ok( $ls, "Language::Befunge::LaheySpace");
BEGIN { $tests += 1 };


# clear method.
$ls->clear;
is( $ls->{xmin}, 0, "clear resets xmin" );
is( $ls->{ymin}, 0, "clear resets ymin" );
is( $ls->{xmax}, 0, "clear resets xmax" );
is( $ls->{ymax}, 0, "clear resets ymax" );
BEGIN { $tests += 4; }


# _set_min/_set_max methods.
$ls->clear;
$ls->_set_min( -2, -3 ); # _set_min
is( $ls->{xmin}, -2, "_set_min sets xmin" );
is( $ls->{ymin}, -3, "_set_min sets ymin" );
$ls->_set_min( -1, -1 ); # can't shrink
is( $ls->{xmin}, -2, "_set_min can't shrink xmin" );
is( $ls->{ymin}, -3, "_set_min can't shrink ymin" );
$ls->_set_max( 4, 5 );   # _set_max
is( $ls->{xmax}, 4, "_set_max sets xmax" );
is( $ls->{ymax}, 5, "_set_max sets ymax" );
$ls->_set_max( 2, 3 );   # can't shrink
is( $ls->{xmax}, 4, "_set_max can't shrink xmax" );
is( $ls->{ymax}, 5, "_set_max can't shrink ymax" );
BEGIN{ $tests += 8; }


# _out_of_bounds method.
is( $ls->_out_of_bounds(-6,  0), 1, "_out_of_bounds < xmin" );
is( $ls->_out_of_bounds( 0, -6), 1, "_out_of_bounds < ymin" );
is( $ls->_out_of_bounds( 0,  6), 1, "_out_of_bounds > xmax" );
is( $ls->_out_of_bounds( 6,  0), 1, "_out_of_bounds > ymax" );
is( $ls->_out_of_bounds( 0,  0), 0, "_out_of_bounds in torus" );
BEGIN{ $tests += 5; }


# enlarge torus.
$ls->clear;
$ls->_enlarge_y( 3 );
is( $ls->{xmin}, 0, "_enlarge_y >0 does not grow xmin" );
is( $ls->{ymin}, 0, "_enlarge_y >0 does not grow ymin" );
is( $ls->{xmax}, 0, "_enlarge_y >0 does not grow xmax" );
is( $ls->{ymax}, 3, "_enlarge_y >0 does grow ymax" );
$ls->_enlarge_x( 2 );
is( $ls->{xmin}, 0, "_enlarge_x >0 does not grow xmin" );
is( $ls->{ymin}, 0, "_enlarge_x >0 does not grow ymin" );
is( $ls->{xmax}, 2, "_enlarge_x >0 does grow xmax" );
is( $ls->{ymax}, 3, "_enlarge_x >0 does not grow ymax" );
$ls->_enlarge_y( -5 );
is( $ls->{xmin}, 0,  "_enlarge_y <0 does not grow xmin" );
is( $ls->{ymin}, -5, "_enlarge_y <0 does grow ymin" );
is( $ls->{xmax}, 2,  "_enlarge_y <0 does not grow xmax" );
is( $ls->{ymax}, 3,  "_enlarge_y <0 does not grow ymax" );
$ls->_enlarge_x( -4 );
is( $ls->{xmin}, -4, "_enlarge_x <0 does grow xmin" );
is( $ls->{ymin}, -5, "_enlarge_x <0 does not grow ymin" );
is( $ls->{xmax}, 2,  "_enlarge_x <0 does not grow xmax" );
is( $ls->{ymax}, 3,  "_enlarge_x <0 does not grow ymax" );
BEGIN { $tests += 16; }


# get/set value.
$ls->clear;
$ls->set_value( 10, 5, 65 );
is( $ls->{xmax}, 10, "set_value grows xmax if needed" );
is( $ls->{ymax}, 5,  "set_value grows ymax if needed" );
is( $ls->get_value( 10, 5 ), 65, "get_value returns correct value" );
$ls->set_value( -10, -5, 65 );
is( $ls->{xmin}, -10, "set_value grows xmin if needed" );
is( $ls->{ymin}, -5,  "set_value grows ymin if needed" );
is( $ls->get_value( -10, -5 ), 65, "get_value returns correct value" );

is( $ls->get_value( 1, 1),   32, "get_value defaults to space" );
is( $ls->get_value( 20, 20), 32, "get_value out of bounds defaults to space" );
BEGIN { $tests += 8; }

# input checking: make sure get_char() returns ASCII.
$ls->set_value(0,0, -1);
$ls->set_value(1,0,  0);
$ls->set_value(2,0,255);
$ls->set_value(3,0,256);
is( $ls->get_char(0,0), sprintf("<np-0x%x>", -1), "get_char always returns ascii" );
is( $ls->get_char(1,0), chr(0),       "get_chars always returns ascii" );
is( $ls->get_char(2,0), chr(0xff),    "get_chars always returns ascii" );
is( $ls->get_char(3,0), '<np-0x100>', "get_chars always returns ascii" );
BEGIN { $tests += 4 };


# store method.
$ls->clear;
$ls->store( <<'EOF' );
Foo bar baz
camel llama buffy
EOF
#   5432101234567890123456789012345678
#  2
#  1
#  0     Foo bar baz
#  1     camel llama buffy
#  2
#  3
#  4
is( $ls->{xmin}, 0,  "store does not grow xmin if not needed" );
is( $ls->{ymin}, 0,  "store does not grow ymax if not needed" );
is( $ls->{xmax}, 16, "store grows xmax if needed" );
is( $ls->{ymax}, 1,  "store grows ymax if needed" );
is( $ls->get_value( 0, 0),  70, "store stores everything" );
is( $ls->get_value( 12, 0), 32, "store defaults to space" );
is( $ls->get_value( 1, 5),  32, "store does not store outside of its bounds" );
BEGIN { $tests += 7; }
$ls->store( <<'EOF', 4, 1 );
Foo bar baz
camel llama buffy
EOF
#   5432101234567890123456789012345678
#  2
#  1
#  0     Foo bar baz
#  1     cameFoo bar baz      
#  2         camel llama buffy
#  3
#  4
is( $ls->{xmin}, 0,  "store does not grow xmin if not needed" );
is( $ls->{ymin}, 0,  "store does not grow ymin if not needed" );
is( $ls->{xmax}, 20, "store grows xmax if needed" );
is( $ls->{ymax}, 2,  "store grows ymax if needed" );
is( $ls->get_value( 0, 0),  70,  "store respects specified origin" ); # old values.
is( $ls->get_value( 4, 1),  70,  "store overwrites if needed" );
is( $ls->get_value( 20, 2), 121, "store stores everything" ); # last value.
BEGIN { $tests += 7; }
my ($w, $h) = $ls->store( <<'EOF', -2, -1 );
Foo bar baz
camel llama buffy
EOF
#   5432101234567890123456789012345678
#  2
#  1   Foo bar baz
#  0   camel llama buffy
#  1     cameFoo bar baz      
#  2         camel llama buffy
#  3
#  4
is( $w, 17, "store returns correct inserted width" );
is( $h, 2,  "store returns correct inserted height" );
is( $ls->{xmin}, -2, "store grows xmin if needed" );
is( $ls->{ymin}, -1, "store grows ymin if needed" );
is( $ls->{xmax}, 20, "store does not grow xmax if not needed" );
is( $ls->{ymax}, 2,  "store does not grow ymax if not needed" );
is( $ls->get_value( -2, -1), 70,  "store stores value in negative indices" );
is( $ls->get_value( 0, 0 ),  109, "store overwrites if needed" );
is( $ls->get_value( 4, 1 ),  70,  "store does not overwrite outside its rectangle" );
BEGIN { $tests += 9; }
$ls->store( <<'EOF', -2, 0 );
Foo bar baz
camel llama buffy
EOF
#   5432101234567890123456789012345678
#  2
#  1   Foo bar baz
#  0   Foo bar baz       
#  1   camel llama buffy      
#  2         camel llama buffy
#  3
#  4
is( $ls->{xmin}, -2, "store does not grow xmin if not needed" );
is( $ls->{ymin}, -1, "store does not grow ymin if not needed" );
is( $ls->{xmax}, 20, "store does not grow xmax if not needed" );
is( $ls->{ymax}, 2,  "store does not grow ymax if not needed" );
is( $ls->get_value( -2, 0), 70,  "store overwrites if needed" );
is( $ls->get_value( 12, 0 ), 32, "store overwrites with spaces if needed" );
BEGIN { $tests += 6; }


# rectangle.
is( $ls->rectangle(-3,4,1,1), " \n", "rectangle returns lines ending with \\n" );
is( $ls->rectangle(-2,-1,3,2), "Foo\nFoo\n", "rectangle works with multiple lines" );
is( $ls->rectangle(19,-2,2,6), "  \n  \n  \n  \nfy\n  \n", "rectangle works accross origin" );
BEGIN { $tests += 3; }


# move ip.
$ls->clear;   # "positive" playfield.
$ls->_set_max(5, 10);
$ip->set_pos( 4, 3 );
$ip->set_dx( 1 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 5, "move_ip_forward respects dx" );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 0, "move_ip_forward wraps xmax" );
$ip->set_pos( 4, 3 );
$ip->set_dx( 7 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 4, "move_ip_forward deals with delta overflowing torus width" );
$ls->move_ip_forward( $ip ); # wrap xmax harder
is( $ip->get_curx, 4, "move_ip_forward deals with delta overflowing torus width" );
$ip->set_pos( 0, 4 );
$ip->set_dx( -1 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 5, "move_ip_forward wraps xmin" );

$ip->set_pos( 2, 9 );
$ip->set_dx( 0 );
$ip->set_dy( 1 );
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 10, "move_ip_forward respects dy" );
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 0,  "move_ip_forward wraps ymax" );
$ip->set_pos( 2, 9 );
$ip->set_dx( 0 );
$ip->set_dy( 12 );               # apply delta that overflows torus height
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 9, "move_ip_forward deals with delta overflowing torus heigth" );
$ls->move_ip_forward( $ip ); # wrap ymax harder
is( $ip->get_cury, 9, "move_ip_forward deals with delta overflowing torus heigth" );
$ip->set_pos( 1, 0 );
$ip->set_dx( 0 );
$ip->set_dy( -1 );
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 10, "move_ip_forward wraps ymin" );
BEGIN { $tests += 10 }

$ls->clear;   # "negative" playfield.
$ls->_set_min(-1, -3);
$ls->_set_max(5, 10);
$ip->set_pos( 4, 3 );
$ip->set_dx( 1 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 5, "move_ip_forward respects dx" );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, -1, "move_ip_forward wraps xmax" );
$ip->set_pos( -1, 4 );
$ip->set_dx( -1 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 5, "move_ip_forward wraps xmin" );
$ip->set_pos( 2, 9 );
$ip->set_dx( 0 );
$ip->set_dy( 1 );
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 10, "move_ip_forward respects dy" );
$ls->move_ip_forward( $ip );
is( $ip->get_cury, -3, "move_ip_forward wraps ymax" );
$ip->set_pos( 1, -3 );
$ip->set_dx( 0 );
$ip->set_dy( -1 );
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 10, "move_ip_forward wraps ymin" );
BEGIN { $tests += 6; }

$ls->clear;   # diagonals.
$ls->_set_min(-1, -2);
$ls->_set_max(6, 5);
$ip->set_pos(0, 0);
$ip->set_dx(-2);
$ip->set_dy(-3);
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 2, "move_ip_forward deals with diagonals" );
is( $ip->get_cury, 3, "move_ip_forward deals with diagonals" );
BEGIN { $tests += 2; }


# label lookup
# four directions.
$ls->clear;
$ls->store( <<'EOF', -2, -1 );
      3
      ;
      z
      a
      b
      :
2;rab:;:foo;1
      :
      b
      l
      a
      h
      ;
      4
EOF
$href = $ls->labels_lookup;
isa_ok( $href, "HASH" );
is( scalar(keys(%$href)), 4, "labels_lookup finds everything" );
is( $href->{foo}[0], 10,  "labels_lookup finds left-right" );
is( $href->{foo}[1], 5,   "labels_lookup finds left-right" );
is( $href->{foo}[2], 1,   "labels_lookup deals with left-right" );
is( $href->{foo}[3], 0,   "labels_lookup deals with left-right" );
is( $href->{bar}[0], -2,  "labels_lookup finds right-left" );
is( $href->{bar}[1], 5,   "labels_lookup finds right-left" );
is( $href->{bar}[2], -1,  "labels_lookup deals with right-left" );
is( $href->{bar}[3], 0,   "labels_lookup deals with right-left" );
is( $href->{baz}[0], 4,   "labels_lookup finds bottom-top" );
is( $href->{baz}[1], -1,  "labels_lookup finds bottom-top" );
is( $href->{baz}[2], 0,   "labels_lookup deals with bottom-top" );
is( $href->{baz}[3], -1,  "labels_lookup deals with bottom-top" );
is( $href->{blah}[0], 4,  "labels_lookup finds top-bottom" );
is( $href->{blah}[1], 12, "labels_lookup finds top-bottom" );
is( $href->{blah}[2], 0,  "labels_lookup deals with top-bottom" );
is( $href->{blah}[3], 1,  "labels_lookup deals with top-bottom" );
BEGIN { $tests += 18};

# wrapping...
$ls->clear;
$ls->store( <<'EOF', -2, -1 );
;1      z  ;   ;:foo
rab:;   a  4      2;
        b
        :  ;
        ;  :
           b
           l
        3  a
        ;  h
EOF
$href = $ls->labels_lookup;
is( scalar(keys(%$href)), 4, "labels_lookup finds everything, even wrapping" );
is( $href->{foo}[0], -1, "labels_lookup finds left-right" );
is( $href->{foo}[1], -1, "labels_lookup finds left-right" );
is( $href->{foo}[2], 1,  "labels_lookup deals with left-right" );
is( $href->{foo}[3], 0,  "labels_lookup deals with left-right" );
is( $href->{bar}[0], 16, "labels_lookup finds right-left" );
is( $href->{bar}[1], 0,  "labels_lookup finds right-left" );
is( $href->{bar}[2], -1, "labels_lookup deals with right-left" );
is( $href->{bar}[3], 0,  "labels_lookup deals with right-left" );
is( $href->{baz}[0], 6,  "labels_lookup finds bottom-top" );
is( $href->{baz}[1], 6,  "labels_lookup finds bottom-top" );
is( $href->{baz}[2], 0,  "labels_lookup deals with bottom-top" );
is( $href->{baz}[3], -1, "labels_lookup deals with bottom-top" );
is( $href->{blah}[0], 9, "labels_lookup finds top-bottom" );
is( $href->{blah}[1], 0, "labels_lookup finds top-bottom" );
is( $href->{blah}[2], 0, "labels_lookup deals with top-bottom" );
is( $href->{blah}[3], 1, "labels_lookup deals with top-bottom" );
BEGIN { $tests += 17 };

# garbage...
$ls->clear;
$ls->store( <<'EOF', -2, -1 );
   ;:foo is foo;1  
     ;not a label;
EOF
$href = $ls->labels_lookup;
is( scalar(keys(%$href)), 1, "labels_lookup does not looks-alike non-labels" );
is( $href->{foo}[0], 14, "labels_lookup discards comments" );
is( $href->{foo}[1], -1, "labels_lookup discards comments" );
is( $href->{foo}[2], 1,  "labels_lookup discards comments" );
is( $href->{foo}[3], 0,  "labels_lookup discards comments" );
BEGIN { $tests += 5 };

# double define...
$ls->clear;
$ls->store( <<'EOF', -2, -1 );
   ;:foo is foo;1  
   2;another oof:;
EOF
eval { $href = $ls->labels_lookup; };
like( $@, qr/^Help! I found two labels 'foo' in the funge space/,
      "labels_lookup chokes on double-defined labels" );
BEGIN { $tests += 1 };



BEGIN { plan tests => $tests };
