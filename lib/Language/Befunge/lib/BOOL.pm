use strict;
use warnings;

package Language::Befunge::lib::BOOL;
# ABSTRACT: Boolean operations extension

sub new { return bless {}, shift; }


# -- bit operations

#
# $v = A( $a, $b )
#
# push $a and $b back onto the stack (logical AND)
#
sub A {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a and $b );
}


#
# $v = N( $a )
#
# push not $a back onto the stack (logical NOT)
#
sub N {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( not $a );
}


#
# $v = O( $a, $b )
#
# push $a or $b back onto the stack (logical OR)
#
sub O {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a or $b );
}



#
# $v = X( $a, $b )
#
# push $a xor $b back onto the stack (logical XOR)
#
sub X {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip();

    # pop the values
    my $b = $ip->spop;
    my $a = $ip->spop;
	
	# push the result
	$ip->spush( $a xor $b );
}



1;

__END__

=head1 DESCRIPTION

The BOOL fingerprint (0x424F4F4C) allows to do Boole logical operations.



=head1 FUNCTIONS

=head2 new

Create a new BOOL instance.


=head2 Bit operations

=over 4

=item A( $a, $b )

Push back C<$a AND $b> (logical AND).


=item O( $a, $b )

Push back C<$a OR $b> (logical OR).


=item N( $a )

Push back C<NOT $ab> (logical NOT).


=item X( $a, $b )

Push back C<$a XOR $b> (logical XOR).


=back



=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#BOOL>.
