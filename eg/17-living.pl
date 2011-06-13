#!/usr/bin/perl
use FindBin qw($Bin);
use lib "$Bin/../lib";

# how to create objects that live, can be hit, and then die
# click mouse to damage the cursor monster until it dies

package GameFrame::eg::LivingSprite;
use Moose;
use Coro;

with qw(
    GameFrame::Role::SDLEventHandler
    GameFrame::Role::Sprite
    GameFrame::Role::Movable
    GameFrame::Role::Living
    GameFrame::Role::HealthBar
);

sub on_mouse_button_up { shift->hit(30) }

sub on_death {
    my $self = shift;
    async { $self->move(to => sub { [100, 480] }) };
}

after paint => sub {
    my ($self, $surface) = @_;
    $surface->draw_gfx_text(
        $self->translate_point(y => 35),
        0xFFFFFFFF,
        "HP=". $self->hp,
    );
};

# ------------------------------------------------------------------------------

package main;
use strict;
use warnings;
use FindBin qw($Bin);
use aliased 'GameFrame::App';

my $app = App->new(
    title    => 'Living Example',
    bg_color => 0x0,
);

my $sprite = GameFrame::eg::LivingSprite->new(
    xy                => [100, 100],
    v                 => 200,
    start_hp          => 100,
    image             => 'arrow',
    health_bar_offset => [0, -10],
);

$app->run;


