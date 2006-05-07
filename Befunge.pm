# $Id: Befunge.pm 52 2006-05-07 10:13:42Z jquelin $
#
# Copyright (c) 2002 Jerome Quelin <jquelin@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#

package Language::Befunge;
require 5.006;

=head1 NAME

Language::Befunge - a Befunge-98 interpreter


=head1 SYNOPSIS

    use Language::Befunge;
    my $interp = Language::Befunge->new( "program.bf" );
    $interp->run_code( "param", 7, "foo" );

    Or, one can write directly:
    my $interp = Language::Befunge->new;
    $interp->store_code( <<'END_OF_CODE' );
    < @,,,,"foo"a
    END_OF_CODE
    $interp->run_code;


=head1 DESCRIPTION

Enter the realm of topological languages!

This module implements the Funge-98 specifications on a 2D field (also
called Befunge). In particular, be aware that this is not a Trefunge
implementation (3D).

This Befunge-98 interpreters assumes the stack and Funge-Space cells
of this implementation are 32 bits signed integers (I hope your os
understand those integers). This means that the torus (or Cartesian
Lahey-Space topology to be more precise) looks like the following:

              32-bit Befunge-98
              =================
                      ^
                      |-2,147,483,648
                      |
                      |         x
          <-----------+----------->
  -2,147,483,648      |      2,147,483,647
                      |
                     y|2,147,483,647
                      v

This implementation is meant to work on unix-like systems, because
this interpreters only handle the character which ordinal value is 10
(also known as \n) as an End-Of-Line chars. In particular, no warranty
is made neither for Microsoft systems (\r\n) nor for Macs (\r).

This module also implements the Concurrent Funge semantics.

=cut
use strict;
use warnings;

# Modules we rely upon.
use Carp;     # This module can't explode :o)
use Config;   # For the 'y' instruction.
use Language::Befunge::Interpreter;

# Public variables of the module.
our $VERSION = '2.06';
$| = 1;

sub new {
    shift;
    return Language::Befunge::Interpreter->new(@_);
}

1;
__END__


=head1 TODO

=over 4

=item o

Write standard libraries.

=back


=head1 BUGS

Although this module comes with a full set of tests, maybe there are
subtle bugs - or maybe even I misinterpreted the Funge-98
specs. Please report them to me.

There are some bugs anyway, but they come from the specs:

=over 4

=item o

About the 18th cell pushed by the C<y> instruction: Funge specs just
tell to push onto the stack the size of the stacks, but nothing is
said about how user will retrieve the number of stacks.

=item o

About the load semantics. Once a library is loaded, the interpreter is
to put onto the TOSS the fingerprint of the just-loaded library. But
nothing is said if the fingerprint is bigger than the maximum cell
width (here, 4 bytes). This means that libraries can't have a name
bigger than C<0x80000000>, ie, more than four letters with the first
one smaller than C<P> (C<chr(80)>).

Since perl is not so rigid, one can build libraries with more than
four letters, but perl will issue a warning about non-portability of
numbers greater than C<0xffffffff>.

=back


=head1 AUTHOR

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

Development is discussed on E<lt>language-befunge@mongueurs.netE<gt>


=head1 ACKNOWLEDGEMENTS

I would like to thank Chris Pressey, creator of Befunge, who gave a
whole new dimension to both coding and obfuscating.


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

=over 4

=item L<perl>

=item L<http://www.catseye.mb.ca/esoteric/befunge/>

=item L<http://dufflebunk.iwarp.com/JSFunge/spec98.html>

=back

=cut
