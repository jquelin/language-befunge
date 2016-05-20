use strict;
use warnings;

package Language::Befunge::lib::ROMA;
#ABSTRACT: Roman numerals extension

use Language::Befunge::Vector;

sub new { return bless {}, shift; }

# -- roman numbers

#
# push the corresponding value onto the stack:
#  - M: 1000
#  - D: 500
#  - C: 100
#  - L: 50
#  - X: 10
#  - V: 5
#  - I: 1
#
sub C { $_[1]->get_curip->spush(100); }
sub D { $_[1]->get_curip->spush(500); }
sub I { $_[1]->get_curip->spush(1); }
sub L { $_[1]->get_curip->spush(50); }
sub M { $_[1]->get_curip->spush(1000); }
sub V { $_[1]->get_curip->spush(5); }
sub X { $_[1]->get_curip->spush(10); }


1;

__END__

=head1 DESCRIPTION

The ROMA fingerprint (0x524f4d41) allows to get standard values of roman
numbers. Note that the new instructions will just push digits, you still
have to do the arithmetic yourself. Executing MCMLXXXIV will not leave 1984
on the stack. But executing C<MCM\-+LXXX+++IV\-++> should.



=head1 FUNCTIONS

=head2 new

Create a new ROMA instance.


=head2 Roman numbers

=over 4

=item C D I L M V X

Push the corresponding roman value (M=1000, D=500, etc.) onto the stack.

=back



=head1 SEE ALSO

L<http://catseye.tc/projects/funge98/library/ROMA.html>.
