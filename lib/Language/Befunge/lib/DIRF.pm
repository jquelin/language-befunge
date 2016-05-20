use strict;
use warnings;

package Language::Befunge::lib::DIRF;
# ABSTRACT: directory operations

sub new { return bless {}, shift; }


#
# C( $directory )
#
# chdir $directory
#
sub C {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $dir = $ip->spop_gnirts;

    chdir $dir or $ip->dir_reverse;
}

#
# M( $directory )
#
# mkdir $directory
#
sub M {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $dir = $ip->spop_gnirts;

    mkdir $dir or $ip->dir_reverse;
}


#
# R( $directory )
#
# rmdir $directory
#
sub R {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $dir = $ip->spop_gnirts;

    rmdir $dir or $ip->dir_reverse;
}


1;

__END__

=head1 DESCRIPTION

The DIRF fingerprint (0x44495246) allows to do directory operations.



=head1 FUNCTIONS

=head2 new

Create a new DIRF instance.


=head2 directory operations

=over 4

=item * C( $directory )

chdir C<$directory>.

=item * M( $directory )

mkdir C<$directory>.

=item * R( $directory )

rmdir C<$directory>.


=back



=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#DIRF>.
