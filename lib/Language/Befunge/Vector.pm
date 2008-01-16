#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Befunge::Vector;

use strict;
use warnings;
use integer;
use Carp;

use overload
	'='   => \&copy,
	'+'   => \&_add,
	'-'   => \&_substract,
	'neg' => \&_invert,
	'+='  => \&_add_inplace,
    '-='  => \&_substract_inplace,
	'<=>' => \&_compare,
	'""'  => \&as_string;

# try to load speed-up LBV
eval 'use Language::Befunge::Vector::XS';
if ( defined $Language::Befunge::Vector::XS::VERSION ) {
    my @subs = qw[
        new new_zeroes copy
        as_string get_dims get_component get_all_components
        clear set_component
        bounds_check
        _add _substract _invert
        _add_inplace _substract_inplace
        _compare
    ];
    foreach my $sub ( @subs ) {
        no strict 'refs';
        no warnings 'redefine';
        my $lbvxs_sub = "Language::Befunge::Vector::XS::$sub";
        *$sub = \&$lbvxs_sub;
    }
}


# -- CONSTRUCTORS

#
# my $vec = LB::Vector->new( $x [, $y, ...] );
#
# Create a new vector. The arguments are the actual vector data; one
# integer per dimension.
#
sub new {
	my $pkg = shift;

    # sanity checks
	my $usage = "Usage: $pkg->new(\$x, ...)";
	croak $usage unless scalar(@_) > 0;

    # regular LBV object
    my $self = [@_];
    bless $self, $pkg;
	return $self;
}


#
# my $vec = LB::Vector->new_zeroes($dims);
#
# Create a new vector of dimension $dims, set to the origin (all
# zeroes). LBV->new_zeroes(2) is exactly equivalent to LBV->new(0, 0).
#
sub new_zeroes {
    my ($pkg, $dims) = @_;

    # sanity checks
	my $usage = "Usage: $pkg->new_zeroes(\$dimensions)";
	croak $usage unless defined $dims;
	croak $usage unless $dims > 0;

    # regular LBV object
    my $self = [ (0) x $dims ];
    bless $self, $pkg;
	return $self;
}


#
# my $vec = $v->copy;
#
# Return a new LBV object, which has the same dimensions and coordinates
# as $v.
#
sub copy {
    my $vec = shift;
    return bless [@$vec], ref $vec;
}


# -- PUBLIC METHODS

#- accessors


#
# my $str = $vec->as_string;
# my $str = "$vec";
#
# Return the stringified form of $vec. For instance, a Befunge vector
# might look like "(1,2)".
#
sub as_string {
	my $self = shift;
	return "(" . join(",",@$self) . ")";
}


#
# my $dims = $vec->get_dims;
#
# Return the number of dimensions, an integer.
#
sub get_dims {
	my $self = shift;
	return scalar(@$self);
}


#
# my $val = $vec->get_component($dim);
#
# Get the value for dimension $dim.
#
sub get_component {
    my ($self, $dim) = @_;
    croak "No such dimension $dim!" unless $dim >= 0 && $self->get_dims > $dim;
    return $self->[$dim];
}


#
# my @vals = $vec->get_all_components;
#
# Get the values for all dimensions, in order from 0..N.
#
sub get_all_components {
    my ($self) = @_;
    return @$self;
}


# - mutators

#
# $vec->clear;
#
# Set the vector back to the origin, all 0's.
#
sub clear {
    my ($self) = @_;
    @$self = (0) x $self->get_dims;
}


#
# $vec->set_component($dim, $value);
#
# Set the value for dimension $dim to $value.
#
sub set_component {
    my ($self, $dim, $val) = @_;
    croak "No such dimension $dim!" unless $dim >= 0 && $self->get_dims > $dim;
    $self->[$dim] = $val;
}


#- other methods

#
# my $is_within = $vec->bounds_check($begin, $end);
#
# Check whether $vec is within the box defined by $begin and $end.
# Return 1 if vector is contained within the box, and 0 otherwise.
#
sub bounds_check {
	my ($vchk, $begin, $end) = @_;
	croak "uneven dimensions in bounds check!" unless $vchk->get_dims == $begin->get_dims;
	croak "uneven dimensions in bounds check!" unless $vchk->get_dims == $end->get_dims;
	for (my $d = 0; $d < $vchk->get_dims; $d++) {
		return 0 if $vchk->get_component($d) < $begin->get_component($d);
		return 0 if $vchk->get_component($d) >   $end->get_component($d);
	}
	return 1;
}


# -- PRIVATE METHODS

#- math ops

#
# my $vec = $v1->_add($v2);
# my $vec = $v1 + $v2;
#
# Return a new LBV object, which is the result of $v1 plus $v2.
#
sub _add {
	my ($v1, $v2) = @_;
	croak "uneven dimensions in vector addition!" unless $v1->get_dims == $v2->get_dims;
	my $rv = ref($v1)->new_zeroes($v1->get_dims);
	for (my $i = 0; $i < $v1->get_dims; $i++) {
		$rv->[$i] = $v1->[$i] + $v2->[$i];
	}
	return $rv;
}


#
# my $vec = $v1->_substract($v2);
# my $vec = $v1 - $v2;
#
# Return a new LBV object, which is the result of $v1 minus $v2.
#
sub _substract {
    my ($v1, $v2) = @_;
    croak "uneven dimensions in vector subtraction!" unless $v1->get_dims == $v2->get_dims;
    my $rv = ref($v1)->new_zeroes($v1->get_dims);
    for (my $i=0; $i<$v1->get_dims; $i++) {
        $rv->[$i] = $v1->[$i] - $v2->[$i];
    }
    return $rv;
}


 
#
# my $v2 = $v1->_invert;
# my $v2 = -$v1;
#
# Subtract $v1 from the origin. Effectively, gives the inverse of the
# original vector. The new vector is the same distance from the origin,
# in the opposite direction.
#
sub _invert {
    my ($v1) = @_;
    my $rv = ref($v1)->new_zeroes($v1->get_dims);
    for (my $i = 0; $i < $v1->get_dims; $i++) {
        $rv->[$i] = -$v1->[$i];
    }
    return $rv;
}


#- inplace math ops

#
# $v1->_add_inplace($v2);
# $v1 += $v2;
#
#
sub _add_inplace {
    my ($v1, $v2) = @_;
    croak "uneven dimensions in vector addition!" unless $v1->get_dims == $v2->get_dims;
    for (my $i = 0; $i < $v1->get_dims; $i++) {
        $v1->[$i] += $v2->[$i];
    }
    return $v1;
}


#
# $v1->_substract_inplace($v2);
# $v1 -= $v2;
#
# Substract $v2 to $v1, and stores the result back into $v1.
#
sub _substract_inplace {
	my ($v1, $v2) = @_;
	croak "uneven dimensions in vector substraction!" unless $v1->get_dims == $v2->get_dims;
	for (my $i = 0; $i < $v1->get_dims; $i++) {
		$v1->[$i] -= $v2->[$i];
	}
	return $v1;
}


#- comparison

#
# my $bool = $v1->_compare($v2);
# my $bool = $v1 <=> $v2;
#
# Check whether the vectors both point at the same spot. Return 0 if they
# do, 1 if they don't.
#
sub _compare {
 	my ($v1, $v2) = @_;
 	croak "uneven dimensions in bounds check!" unless $v1->get_dims == $v2->get_dims;
	for (my $d = 0; $d < $v1->get_dims; $d++) {
		return 1 if $v1->get_component($d) != $v2->get_component($d);
 	}
	return 0;
}


1;
__END__

=head1 NAME

Language::Befunge::Vector - an opaque, N-dimensional vector class.



=head1 SYNOPSIS

    my $v1 = Language::Befunge::Vector->new($x, $y, ...);
    my $v2 = Language::Befunge::Vector->new_zeroes($dims);



=head1 DESCRIPTION

This class abstracts normal vector manipulation. It lets you pass
around one argument to your functions, rather than N arguments, one
per dimension.  This means much of your code doesn't have to care
how many dimensions you're working with.

You can do vector arithmetic, test for equality, or even stringify
the vector to a string like I<"(1,2,3)">.



=head1 CONSTRUCTORS

=head2 my $vec = LB::Vector->new( $x [, $y, ...] )

Create a new vector. The arguments are the actual vector data; one
integer per dimension.


=head2 my $vec = LB::Vector->new_zeroes($dims);

Create a new vector of dimension C<$dims>, set to the origin (all zeroes). C<<
LBV->new_zeroes(2) >> is exactly equivalent to B<< LBV->new(0,0) >>.


=head2 my $vec = $v->copy;

Return a new LBV object, which has the same dimensions and coordinates
as $v.



=head1 PUBLIC METHODS

=head2 my $str = $vec->as_string;

Return the stringified form of C<$vec>. For instance, a Befunge vector
might look like C<(1,2)>.

This method is also applied to stringification, ie when one forces
string context (C<"$vec">).


=head2 my $dims = $vec->get_dims;

Return the number of dimensions, an integer.


=head2 my $val = $vec->get_component($dim);

Get the value for dimension C<$dim>.


=head2 my @vals = $vec->get_all_components;

Get the values for all dimensions, in order from 0..N.


=head2 $vec->clear;

Set the vector back to the origin, all 0's.


=head2 $vec->set_component($dim, $value);

Set the value for dimension C<$dim> to C<$value>.


=head2 my $is_within = $vec->bounds_check($begin, $end);

Check whether C<$vec> is within the box defined by C<$begin> and C<$end>.
Return 1 if vector is contained within the box, and 0 otherwise.



=head1 MATHEMATICAL OPERATIONS

=head2 Standard operations

One can do some maths on the vectors. Addition and substraction work as
expected:

    my $v = $v1 + $v2;
    my $v = $v1 - $v2;

Either operation return a new LBV object, which is the result of C<$v1>
plus / minus C<$v2>.

The inversion is also supported:
    my $v2 = -$v1;

will subtracts C<$v1> from the origin, and effectively, gives the
inverse of the original vector. The new vector is the same distance from
the origin, in the opposite direction.


=head2 Inplace operations

LBV objects also supports inplace mathematical operations:

    $v1 += $v2;
    $v1 -= $v2;

effectively adds / substracts C<$v2> to / from C<$v1>, and stores the
result back into C<$v1>.


=head2 Comparison

Finally, LBV objects can be tested for equality, ie whether two vectors
both point at the same spot.

    print "same"   if $v1 == $v2;
    print "differ" if $v1 != $v2;


=head1 SEE ALSO

L<Language::Befunge>


=head1 AUTHOR

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

Development is discussed on E<lt>language-befunge@mongueurs.netE<gt>


=head1 COPYRIGHT & LICENSE

Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

