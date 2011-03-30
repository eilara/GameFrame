package GameFrame::Role::GameFromFile;

# consume to have your class be instantiated from a file
# call run($file) on the class to create an instance of it
# and call ->app->run() on the instance

use Moose::Role;

requires 'app';

sub run {
    my ($class, $file) = @_;
    open my $fh, $file or die "Can't read $file: $!";
    my $data = join '', <$fh>;
    close $fh;
    my $conf = eval "use FindBin qw(\$Bin);$data";
    die "Can't eval [$file]: $@" if $@;
    $class->new(%$conf)->app->run;
}

1;
