package GameFrame::Role::Spawner;

use Moose::Role;
use MooseX::Types::Moose qw(Int);
use aliased 'GameFrame::Animation::Proxy::Int' => 'IntProxy';

with qw(
    GameFrame::Role::Animated
    GameFrame::Role::Active::Container
);

sub spawn {
    my ($self, %args) = @_;
    my $waves = delete $args{waves} || "Can't spawn with no waves";
    $self->animate({
        target      => $self,
        attribute   => 'current_wave',
        proxy_class => IntProxy,
        from_to     => [1, $waves],
        %args,
    });
}

sub current_wave {
    my ($self, $new_wave) = @_;
    my $current_wave = $self->next_child_idx;
    return $current_wave if @_ == 1;
    return if $current_wave >= $new_wave;
    $self->create_next_child for 1..($new_wave - $current_wave);
}

1;

