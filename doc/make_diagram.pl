#!/usr/bin/perl

use strict;
use warnings;
use IO::All;
use List::MoreUtils qw(zip);

my $csv = io('diagram.csv')->all;
$csv =~ s/"//g;
my @csv = map { [split ','] } split "\n", $csv;
my @head = @{ shift @csv };
my @classes = map { { zip @head, @$_ } } @csv;

my $classes = join "\n", map { make_class($_) } @classes;

my $out = <<"DOT";
digraph "CamelDefense" {
    graph [splines=true overlap=false];
    $classes
}
DOT

io('diagram.dot')->print($out);

sub make_class {

    my %class    = %{ shift() };
    my $name     = delete $class{class};
    my $parent   = delete $class{parent};
    my $is_multi = delete $class{is_multi};
    my $rows     = join('', map { $class{$_}? qq[<tr><td>$_</td></tr>]: '' } @head);
    my $border   = $is_multi? 1: 0;
    my $name_row = qq[<tr><td bgcolor="black"><font color= "white">$name</font></td></tr>];
    my $table    = "<<table border=\"$border\" cellborder=\"0\">$name_row$rows</table>>";
    my $class    = qq<$name [shape="box" fillcolor="white" label=$table];>;
    $class      .= qq[\n"$parent"-> "$name";] if $parent;

    return $class;
}

