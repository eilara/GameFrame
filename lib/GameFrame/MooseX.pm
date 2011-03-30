package GameFrame::MooseX;

use Moose;
use Moose::Exporter;
use Moose::Util qw(apply_all_roles);
use aliased 'MooseX::Role::BuildInstanceOf';

Moose::Exporter->setup_import_methods(
    with_meta => ['compose_from'],
);

sub _compute_prefix($) {
    my $target = shift;    
    $target =~ /([^:]+)$/;
    return lc $1;
}

sub compose_from {
    my ($meta, $target, %args) = @_;
    my $prefix = delete($args{prefix}) || _compute_prefix $target;
    my $inject = delete $args{inject};
    my $has    = delete $args{has};

    my $build_args = {target => $target, prefix => $prefix, %args};
    apply_all_roles($meta, BuildInstanceOf, $build_args);

    if ($inject) {
        if (my $ref = ref $inject) {

            if ($ref eq 'CODE') {
                $meta->add_around_method_modifier("merge_${prefix}_args", sub {
                    my ($orig, $self) = @_;
                    return ($self->$orig, $inject->($self));
                });

            } elsif ($ref eq 'ARRAY') {
                $meta->add_around_method_modifier("merge_${prefix}_args", sub {
                    my ($orig, $self) = @_;
                    return ($self->$orig, map { $_ => $self->$_ } @$inject);
                });

            } else {
                die 'inject can only take list of methods or code';
            }

        } else {
            die 'inject can only take list of methods or code';
        }
    }

    if ($has) {
        $meta->add_attribute("+$prefix", %$has);
    }
}

1;
