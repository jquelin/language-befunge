#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Befunge::lib::ORTH;

use strict;
use warnings;

use Language::Befunge::Vector;

sub new { return bless {}, shift; }

# -- bit operations

sub A {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a&$b );
}

sub E {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a^$b );
}

sub O {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a|$b );
}


# -- push / get

sub G {
	my ($self, $lbi) = @_;
	my $ip = $lbi->get_curip;

    my $x = $ip->spop;
    my $y = $ip->spop;
	my $v = Language::Befunge::Vector->new($x,$y);
    my $val = $lbi->storage->get_value( $v );
    $ip->spush( $val );
}

sub P {
	my ($self, $lbi) = @_;
	my $ip = $lbi->get_curip;

    my $x = $ip->spop;
    my $y = $ip->spop;
	my $v = Language::Befunge::Vector->new($x,$y);
	my $val = $ip->spop;
    $lbi->storage->set_value( $v, $val );
}


# -- output

sub S {
    my ($self, $lbi) = @_;
    print $lbi->get_curip->spop_gnirts;
}


# -- coordinates & velocity changes

sub X {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v = $ip->get_position;
    my $x = $ip->spop;
	$v->set_component(0,$x);
}

sub Y {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v = $ip->get_position;
    my $y = $ip->spop;
	$v->set_component(1,$y);
}

sub V {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v  = $ip->get_delta;
    my $dx = $ip->spop;
	$v->set_component(0,$dx);
}

sub W {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v  = $ip->get_delta;
    my $dy = $ip->spop;
	$v->set_component(1,$dy);
}


# -- misc

sub Z {
	my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $v  = $ip->spop;
	$lbi->_move_ip_once($ip) if $v == 0;
}


1;

__END__


=head1 NAME

Language::Befunge::IP::lib::ORTH - Orthogonal Easement Library



=head1 DESCRIPTION

The ORTH fingerprint (0x4f525448) is designed to ease transition between the
Orthogonal programming language and Befunge-98 (or higher dimension Funges).

Even if transition from Orthogonal is not an issue, the ORTH library contains
some potentially interesting instructions not in standard Funge-98.



=head1 FUNCTIONS

=head2 new

Create a new ORTH instance.


=head2 Bit operations

=over 4

=item A( $a, $b )

Push back C<$a & $b> (bitwise AND).


=item O( $a, $b )

Push back C<$a | $b> (bitwise OR).


=item E( $a, $b )

Push back C<$a ^ $b> (bitwise XOR).


=back



=head2 Push & get

=over 4

=item G( $y, $x )

Push back value stored at coords ($x, $y). Note that Befunge get is C<g($x,$y)>
(ie, the arguments are reversed).


=item P( $v, $y, $x )

Store value C<$v> at coords ($x, $y). Note that Befunge put is C<p($v,$x,$y)> (ie,
the coordinates are reversed).


=back



=head2 Output

=over 4

=item S( 0gnirts )

Print popped 0gnirts on STDOUT.

=back



=head2 Coordinates & velocity changes

=over 4

=item X( $x )

Change X coordinate of IP to C<$x>.


=item Y( $y )

Change Y coordinate of IP to C<$y>.


=item V( $dx )

Change X coordinate of IP velocity to C<$dx>.


=item W( $dy )

Change Y coordinate of IP velocity to C<$dy>.


=back



=head1 SEE ALSO

L<Language::Befunge>, L<http://www.muppetlabs.com/~breadbox/orth/orth.html>
and L<http://catseye.tc/projects/funge98/library/ORTH.html>


=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>


=head1 COPYRIGHT & LICENSE

Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
