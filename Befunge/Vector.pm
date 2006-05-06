package Language::Befunge::Vector;
use strict;
use warnings;

use overload 
	'-'   => \&vector_subtract,
	'neg' => \&vector_invert,
	'+'   => \&vector_add,
	'+='  => \&vector_add_inplace,
	'='   => \&vector_copy,
	'=='  => \&vector_equality,
	'!='  => \&vector_inequality,
	'""'  => \&vector_as_string;

=head1 NAME

Language::Befunge::Vector - an opaque, N-dimensional vector class.


=head1 SYNOPSIS

	my $v1 = Language::Befunge::Vector->new($d, $x, $y, ...);
	my $v2 = Language::Befunge::Vector->new_zeroes($d);

=head1 DESCRIPTION

This class abstracts normal vector manipulation.  It lets you pass 
around one argument to your functions, rather than N arguments, one
per dimension.  This means much of your code doesn't have to care
how many dimensions you're working with.

You can do vector arithmetic, test for equality, or even stringify
the vector to a string like I<"(1,2,3)">.

=cut

use Carp;

=head1 CONSTRUCTORS

=head2 new( dimensions, x, [y, ...] )

Creates a new vector.  The first argument is an integer specifying
how many dimensions this vector operates in.  The remaining arguments
constitute the actual vector data; one integer per dimension.

=cut

sub new {
	my $package = shift;
	my $dimensions = shift;
	my $usage = "Usage: $package->new(\$dimensions, \$x, ...)";
	croak $usage unless defined $dimensions;
	croak $usage unless $dimensions > 0;
	croak $usage unless $dimensions == scalar @_;
	return bless({dims => $dimensions, v => [@_]}, $package);
}


=head2 new_zeroes( dimensions )

Creates a new vector, set to the origin (all zeroes).
->B<new_zeroes>(2) is exactly equivalent to ->B<new>(2, 0, 0).

=cut

sub new_zeroes {
	my $package = shift;
	my $dimensions = shift;
	my $usage = "Usage: $package->new_zeroes(\$dimensions)";
	croak $usage unless defined $dimensions;
	croak $usage unless $dimensions > 0;
    my @initial;
    push(@initial,0) for(1..$dimensions);
	return bless({dims => $dimensions, v => [@initial]}, $package);
}

=head1 PUBLIC METHODS

=head2 get_dims(  )

Returns the number of dimensions, an integer.

=cut

sub get_dims {
	my $self = shift;
	return $$self{dims};
}

=head2 vector_subtract( v2 )

	$v0 = $v1->vector_subtract($v2);
	$v0 = $v1 - $v2;

Returns a new Vector object, which is the result of I<v1> minus I<v2>.

=cut

sub vector_subtract {
	my ($v1, $v2) = @_;
	croak "uneven dimensions in vector subtraction!" unless $v1->get_dims == $v2->get_dims;
	my $vr = ref($v1)->new_zeroes($v1->get_dims);
	for(my $i = 0; $i < $v1->get_dims; $i++) {
		$$vr{v}[$i] = $$v1{v}[$i] - $$v2{v}[$i];
	}
	return $vr;
}

=head2 vector_invert( )

	$v1->vector_invert();
	$v2 = -$v1;

Subtracts I<v1> from the origin.  Effectively, gives the inverse of
the original vector.  The new vector is the same distance from the
origin, in the opposite direction.

=cut

sub vector_invert {
	my ($v1) = @_;
	my $rv = ref($v1)->new_zeroes($v1->get_dims);
	for(my $i = 0; $i < $v1->get_dims; $i++) {
		$$rv{v}[$i] = -$$v1{v}[$i];
	}
	return $rv;
}

=head2 vector_add( v2 )

	$v0 = $v1->vector_add($v2);
	$v0 = $v1 + $v2;

Returns a new Vector object, which is the result of I<v1> plus I<v2>.

=cut

sub vector_add {
	my ($v1, $v2) = @_;
	croak "uneven dimensions in vector addition!" unless $v1->get_dims == $v2->get_dims;
	my $rv = ref($v1)->new_zeroes($v1->get_dims);
	for(my $i = 0; $i < $v1->get_dims; $i++) {
		$$rv{v}[$i] = $$v1{v}[$i] + $$v2{v}[$i];
	}
	return $rv;
}

=head2 vector_add_inplace( v2 )

	$v1->vector_add_inplace($v2);
	$v1 += $v2;

Adds I<v2> to I<v1>, and stores the result back into I<v1>.

=cut

sub vector_add_inplace {
	my ($v1, $v2) = @_;
	croak "uneven dimensions in vector addition!" unless $v1->get_dims == $v2->get_dims;
	for(my $i = 0; $i < $v1->get_dims; $i++) {
		$$v1{v}[$i] += $$v2{v}[$i];
	}
	return $v1;
}

=head2 vector_copy( )

	$v0 = $v1->vector_copy();
	$v0 = $v1;

Returns a new Vector object, which has the same dimensions and
coordinates as I<v1>.

=cut

sub vector_copy {
	my $v = shift;
	return bless {dims => $$v{dims}, v => [@{$$v{v}}]}, ref $v;
}

=head2 set_component( dimension, data )

	$v->set_component(0, 1); # set X to 1

Sets the value for dimension I<dimension> to the value I<data>.

=cut

sub set_component {
	my ($self, $d, $data) = @_;
	croak "No such dimension $d!" unless ($d >= 0 && $self->get_dims > $d);
	$$self{v}[$d] = $data;
}

=head2 get_component( dimension )

	my $x = $v->get_component(0);

Gets the value for dimension I<dimension>.

=cut

sub get_component {
	my ($self, $d) = @_;
	croak "No such dimension $d!" unless ($d >= 0 && $self->get_dims > $d);
	return $$self{v}[$d];
}

=head2 get_all_components( )

	my $v = Language::Befunge::Vector->new(3, 1, 2, 3);
	# $v now holds a 3-dimensional vector, <1,2,3>
	my @list = $v->get_all_components(); # returns (1, 2, 3)

Gets the value for all dimensions, in order from 0..N.

=cut

sub get_all_components {
	my ($self) = @_;
	return @{$$self{v}};
}

=head2 zero( )

Sets the vector back to the origin, all 0's.  See also the
constructor, B<new_from_origin>, above.

=cut

sub zero {
	my ($self) = @_;
	@{$$self{v}} = map { 0 } (1..$self->get_dims);
}

=head2 bounds_check( begin, end )

	die "out of bounds"
		unless $vector->bounds_check($begin, $end);

Checks whether the given I<vector> is within the box defined by
I<begin> and I<end>.  Returns I<1> if I<vector> is contained within
the box, and I<0> otherwise.

=cut

sub bounds_check {
	my ($vchk, $begin, $end) = @_;
	croak "uneven dimensions in bounds check!" unless $vchk->get_dims == $begin->get_dims;
	croak "uneven dimensions in bounds check!" unless $vchk->get_dims == $end->get_dims;
	for(my $d = 0; $d < $vchk->get_dims; $d++) {
		return 0 if $vchk->get_component($d) < $begin->get_component($d);
		return 0 if $vchk->get_component($d) >   $end->get_component($d);
	}
	return 1;
}

=head2 vector_as_string( )

Returns the stringified form of the vector.  For instance, a Befunge
vector might look like I<"(1,2)">.

=cut

sub vector_as_string {
	my $self = shift;
	return "(" . join(",",@{$$self{v}}) . ")";
}

=head2 vector_equality( v2 )

	print("Equal!\n") if $v1->vector_equality($v2);
	print("Equal!\n") if $v1 == $v2;

Checks whether the vectors both point at the same spot.  Returns
I<1> if they do, I<0> if they don't.

=cut

sub vector_equality {
	my ($v1, $v2) = @_;
	croak "uneven dimensions in bounds check!" unless $v1->get_dims == $v2->get_dims;
	for(my $d = 0; $d < $v1->get_dims; $d++) {
		return 0 unless $v1->get_component($d) == $v2->get_component($d);
	}
	return 1;
}

=head2 vector_inequality( v2 )

	print("Equal!\n") unless $v1->vector_inequality($v2);
	print("Equal!\n") unless $v1 != $v2;

Checks whether the vectors point to different spots.  Returns
I<1> if they don't, I<0> if they do.  Compare B<vector_equality>,
above.

=cut

sub vector_inequality {
	return !vector_equality(@_);
}

1;
