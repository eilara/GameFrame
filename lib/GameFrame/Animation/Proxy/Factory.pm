package GameFrame::Animation::Proxy::Factory;

use Moose;
use aliased 'GameFrame::Animation::Proxy';
use aliased 'GameFrame::Animation::Proxy::Int'    => 'IntProxy';
use aliased 'GameFrame::Animation::Proxy::Vector' => 'VectorProxy';
use List::Util qw(first);

sub find_proxy {
    my ($class, %args) = @_;
    my $target         = $args{target};
    my $att_name       = $args{attribute};
    my $is_known_int   = first { $_ eq $att_name } qw(x y w h);

    return IntProxy if $is_known_int;

    my $att = $target->meta->find_attribute_by_name($att_name);
    return Proxy unless $att; # could be method or something

    my $type = $att->type_constraint;
    return Proxy unless $type;

    return $type eq 'Int'                     ? IntProxy:
           $type eq 'GameFrame::Types::Vector'? VectorProxy:
                                                Proxy;
}

1;
