package GameFrame::Animation::Curve::Circle;

# TODO make work in nD

use Moose;
use Math::Trig;
use Math::Vector::Real;

has [qw(from radius)] => (is => 'ro', required => 1);

has begin => (is => 'ro', default => 0);
has end   => (is => 'ro', default => 2*pi);

extends 'GameFrame::Animation::Curve';

sub curve_length {
    my $self = shift;
    return 2 * pi * $self->radius; # upper limit
}

sub solve_curve {
    my ($self, $elapsed) = @_;
    my $begin = $self->begin;
    my $end   = $self->end;
    my $delta = $end - $begin;
    my $angle = $begin + $delta * $elapsed;
    my $from  = $self->from;
    my $value = $from + $self->radius * V(cos($angle), sin($angle));
    return $value;
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
