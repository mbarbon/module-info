package B::Module::Info;

$VERSION = '0.03';

use B;
use B::Utils qw(walkoptree_filtered walkoptree_simple
                opgrep all_roots);

sub state_change {
    return opgrep {name => [qw(nextstate dbstate setstate)]}, @_
}

my $cur_pack;
sub state_call {
    my($op) = shift;
    my $pack = $op->stashpv;
    print "$pack\n" if $pack ne $cur_pack;
    $cur_pack = $pack;
}


my %modes = (
             packages => sub { 
                 walkoptree_filtered(B::main_root,
                                     \&state_change,
                                     \&state_call );
             },
             subroutines => sub {
                 my %roots = all_roots;
                 while( my($name, $op) = each %roots ) {
                     next if $name eq '__MAIN__';
                     local($File, $Start, $End);
                     walkoptree_simple($op, \&sub_info);
                     print "$name at $File from $Start to $End\n";
                 }
             },
             modules_used => sub {
                 walkoptree_filtered(B::main_root,
                                     \&is_begin,
                                     \&begin_is_use );
             },
            );

sub sub_info {
    $File  ||= $B::Utils::file;
    $Start = $B::Utils::line if !$Start || $B::Utils::line < $Start;
    $End   = $B::Utils::line if !$End   || $B::Utils::line > $End;
}

sub is_begin {
    my($op) = shift;
    print $op->name;
    return $op->name eq 'begin';
}

sub begin_is_use {
    my($op) = shift;
    print "Saw begin\n";
}

sub compile {
    my($mode) = shift;

    return $modes{$mode};
}

1;
