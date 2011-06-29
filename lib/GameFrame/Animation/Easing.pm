package GameFrame::Animation::Easing;

# TODO do these have to take $from?

use Moose;
use Math::Trig;

sub linear {
    my ($class, $elapsed, $from, $delta) = @_;
    return $from + $delta * $elapsed;
}

sub swing {
    my ($class, $elapsed, $from, $delta) = @_;
    return $from + $delta * (-0.5*cos($elapsed*pi)+0.5);
}

sub in_bounce {
    my ($class, $elapsed, $from, $delta) = @_;
    return $from + $delta - $class->out_bounce(1 - $elapsed, 0, $delta);
}

sub out_bounce {
    my ($class, $elapsed, $from, $delta) = @_;
    return $from + $delta * (
        $elapsed < (1.0/2.75)? 7.5625 * $elapsed**2:
        $elapsed < (2.0/2.75)? 7.5625 * ($elapsed-1.500/2.75)**2 + 0.750000:
        $elapsed < (2.5/2.75)? 7.5625 * ($elapsed-2.250/2.75)**2 + 0.937500:
                               7.5625 * ($elapsed-2.625/2.75)**2 + 0.984375
    );
}

sub in_out_bounce {
    my ($class, $elapsed, $from, $delta) = @_;
    return $from + 0.5 + 0.5 * ($elapsed < 0.5?
        $class->in_bounce($elapsed*2, 0, $delta):
        $class->out_bounce($elapsed*2-1, 0, $delta) + $delta
    );
}

1;

#
# TERMS OF USE - EASING EQUATIONS
# 
# Open source under the BSD License. 
# 
# Copyright Â© 2001 Robert Penner
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
# 
# Redistributions of source code must retain the above copyright notice, this list of 
# conditions and the following disclaimer.
# Redistributions in binary form must reproduce the above copyright notice, this list 
# of conditions and the following disclaimer in the documentation and/or other materials 
# provided with the distribution.
# 
# Neither the name of the author nor the names of contributors may be used to endorse 
# or promote products derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY 
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
#  COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECI
