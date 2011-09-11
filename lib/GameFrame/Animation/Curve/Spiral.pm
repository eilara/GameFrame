package GameFrame::Animation::Curve::Spiral;

use Moose;
use Scalar::Util qw(weaken);
use Math::Trig;
use Math::Vector::Real;

has [qw(from begin_radius end_radius)] => (is => 'ro', required => 1);

has begin_angle    => (is => 'ro', default => 0);
has rotation_count => (is => 'ro', default => 1);

extends 'GameFrame::Animation::Curve';

sub compute_curve_length {
    my $self = shift;
    return 2 * pi * $self->end_radius * $self->rotation_count; # upper limit
}

sub _build_solve_curve_cb {
    my $self = shift;
    weaken $self;
    return sub {
        my $elapsed = shift;
        my $angle  = $self->begin_angle + 2*pi * $self->rotation_count * $elapsed;
        my $radius = $self->begin_radius + ($self->end_radius - $self->begin_radius) * $elapsed;
        my $value  = $self->from + $radius * V(cos($angle), sin($angle));
        return $value;
    };
}

1;

__END__

/*
Copyright (c) 2009 Drew Cummins

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/
