use strict;
use warnings;

package Language::Befunge::Wrapping;
# ABSTRACT: base wrapping class


# -- CONSTRUCTOR

use Class::XSAccessor constructor => 'new';


# -- PUBLIC METHODS

#
# $wrapping->wrap( $storage, $ip );
#
# Wrap $ip in $storage according to this module wrapping algorithm. Note
# that $ip is already out of bounds, ie, it has been moved once by LBI.
# As a side effect, $ip will have its position changed.
#
# LBW implements a wrapping that dies. It's meant to be overridden by
# other wrapping classes.
#
sub wrap { die 'wrapping not implemented in LBW'; }

1;
__END__

=head1 DESCRIPTION

C<LBW> implements a wrapping that dies. It's meant to be overridden by
other wrapping classes.



=head1 CONSTRUCTOR

=head2 LBW->new;

Creates a new wrapping object.


=head1 PUBLIC METHODS

=head2 $wrapping->wrap( $storage, $ip )

Wrap C<$ip> in C<$storage> according to this module wrapping algorithm.
See L<DESCRIPTION> for an overview of the algorithm used.

Note that C<$ip> is already out of bounds, ie, it has been moved once by
LBI.

As a side effect, $ip will have its position changed.

