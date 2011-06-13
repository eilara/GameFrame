package GameFrame::Types;

use strict;
use warnings;
use MooseX::Types -declare => [qw(
    Vector2D
)];
use MooseX::Types::Moose qw(ArrayRef);
use Math::Vector::Real;

subtype Vector2D, as 'Math::Vector::Real';

coerce Vector2D, from ArrayRef, via { V(@$_) };

1;
