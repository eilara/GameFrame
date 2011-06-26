package GameFrame::Animation::Composite;

use Moose;
use Set::Object;

has children => (
    is       => 'ro',
    isa      => 'Set::Object',
    default  => sub { Set::Object->new },
    handles  => {
        add_animations   => 'insert',
        add_animation    => 'insert',
        remove_animation => 'remove',
        animations       => 'members',
    },
);

with 'GameFrame::Role::Animation';

sub start_animation   { shift->_for_children('start_animation') }
sub restart_animation { shift->_for_children('restart_animation') }
sub stop_animation    { shift->_for_children('stop_animation') }
sub pause_animation   { shift->_for_children('pause_animation') }
sub resume_animation  { shift->_for_children('resume_animation') }

# TODO what should this answer while paused?
sub is_animation_started {
    my $self = shift;
    for ($self->animations)
        { return 1 if $_->is_animation_started }
    return 0;
}

sub wait_for_animation_complete {
    my $self = shift;
    $_->wait_for_animation_complete for $self->animations;
}

sub _for_children {
    my ($self, $method, @args) = @_;
    $_->$method(@args) for $self->animations;
}

1;


