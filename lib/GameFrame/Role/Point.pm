package GameFrame::Role::Point;

use Moose::Role;
use MooseX::Types::Moose qw(Num);

has x => (is => 'rw', required => 1, isa => Num, default => 0);
has y => (is => 'rw', required => 1, isa => Num, default => 0);

1;


