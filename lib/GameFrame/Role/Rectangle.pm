package GameFrame::Role::Rectangle;

use Moose::Role;
use MooseX::Types::Moose qw(Num);

has w => (is => 'rw', required => 1, isa => Num);
has h => (is => 'rw', required => 1, isa => Num);

with 'GameFrame::Role::Point';

1;

