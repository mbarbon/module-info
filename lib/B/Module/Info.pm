package B::Module::Info;

use B;
use B::Utils qw(walkoptree_filtered opgrep all_roots);

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
                 print join "\n", keys %roots;
             }
            );


sub compile {
    my($mode) = shift;

    return $modes{$mode};
}

1;
