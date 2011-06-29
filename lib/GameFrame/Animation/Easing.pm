package GameFrame::Animation::Easing;

use Moose;
use Math::Trig;

sub linear {
    my ($class, $t) = @_;
    return $t;
}

sub swing {
    my ($class, $t) = @_;
    0.5 - 0.5 * cos($t * pi);
}

sub out_bounce {
    my ($class, $t) = @_;
    my $s = 7.5625;
    my $p = 2.75;
    return 
        $t < 1.0/$p ? $s * $t**2:
        $t < 2.0/$p ? $s * ($t - 1.500/$p)**2 + 0.75:
        $t < 2.5/$p ? $s * ($t - 2.250/$p)**2 + 0.9375:
                      $s * ($t - 2.625/$p)**2 + 0.984375;
}

sub in_bounce {
    my ($class, $t) = @_;
    return 1 - $class->out_bounce(1 - $t);
}

sub in_out_bounce {
    my ($class, $t) = @_;
    return
        $t < 0.5? $class->in_bounce(2*$t) / 2:
                  $class->out_bounce(2*$t - 1) / 2 + 0.5;
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
