#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Befunge::lib::MODU;

use strict;
use warnings;

use POSIX qw{ floor };

sub new { return bless {}, shift; }


# -- modulus

#
# $mod = M( $x, $y )
#
# signed-result modulo: x MOD y = x - FLOOR(x / y) * y
#
sub M {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $y = $ip->spop;
    my $x = $ip->spop;
    my $mod = $y == 0
        ? 0
        : $x - floor($x/$y)*$y;
    $ip->spush($mod);
}


#
# $mod = U( $x, $y );
#
# Sam Holden's unsigned-result modulo... No idea who this Sam Holden is
# or if he has a special algorithm for this, therefore always returning
# absolute value of standard modulo.
#
sub U {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $y = $ip->spop;
    my $x = $ip->spop;
    if ( $y == 0 ) {
        $ip->push(0);
        return;
    }
    my $mod = $x % $y;
    $ip->spush(abs($mod));
}


#
# $mod = R( $x, $y );
#
# C-language integer remainder: old C leaves negative modulo undefined
# but C99 defines it as the same sign as the dividend so that's what we're
# going with.
#
sub R {
    my ($self, $lbi) = @_;
    my $ip = $lbi->get_curip;
    my $y = $ip->spop;
    my $x = $ip->spop;
    if ( $y == 0 ) {
        $ip->push(0);
        return;
    }

    my $mod = $x % $y;
    if ( ($x <= 0 && $mod <= 0) || ($x >= 0 && $mod >= 0)) {
        $ip->spush( $mod );
    } else {
        $ip->spush( -$mod );
    }    
}


1;

__END__


=head1 NAME

Language::Befunge::IP::lib::MODU - Modulo Arithmetic extension



=head1 DESCRIPTION

The MODU fingerprint (0x4d4f4455) implements some of the finer, less-well-
agreed-upon points of modulo arithmetic. With positive arguments, these
instructions work exactly the same as C<%> does. However, when negative
values are involved, they all work differently.


=head1 FUNCTIONS

=head2 new

Create a new MODU instance.



=head2 Module information

=over 4

=item S

C<Shelled> pushes a 0 on the stack, meaning that the Perl language is already
loaded (e.g. the interpreter is written in Perl).

=back


=head2 Perl embedding

=over 4

=item 0gnirts = E( 0gnirts )

C<Eval> pops a 0gnirts string and performs a Perl C<eval()> on it. The
result of the call is pushed as a 0gnirts string back onto the stack.


=item val = I( 0gnirts )

C<Int Eval> acts the same as C<E>, except that the result of the call
is converted to an integer and pushed as a single cell onto the stack. 


=back



=head1 SEE ALSO

L<Language::Befunge>, L<http://catseye.tc/projects/funge98/library/PERL.html>.



=head1 AUTHOR

Jerome Quelin, C<< <jquelin@cpan.org> >>



=head1 COPYRIGHT & LICENSE

Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
