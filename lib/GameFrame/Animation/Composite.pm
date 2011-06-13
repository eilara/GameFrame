package GameFrame::Animation::Composite;

# should share a role with Animation class

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

sub start_animation {
    my $self = shift;
    $_->start_animation for $self->animations;
}

sub restart_animation {
    my $self = shift;
    $_->restart_animation for $self->animations;
}

sub stop_animation {
    my $self = shift;
    $_->stop_animation for $self->animations;
}

sub pause_animation {
    my $self = shift;
    $_->pause_animation for $self->animations;
}

sub resume_animation {
    my $self = shift;
    $_->resume_animation for $self->animations;
}

# TODO what should this answer while paused?
sub is_animation_started {
    my $self = shift;
    for ($self->animations)
        { return 1 if $_->is_animation_started }
    return 0;
}

sub wait_for_animation_complete {
    my $self = shift;
    $_->wait_for_animation_complete
        for grep { $_->is_animation_started } $self->animations;
}

1;


