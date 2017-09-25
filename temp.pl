#!/usr/bin/perl -w

sub mypush1 {
    my ($array_ref,@elements) = @_;
    if (@elements) {
        @$array_ref = (@$array_ref, @elements);
    } else {
        @$array_ref = (@$array_ref, $_);
    }
}
# same but with prototype
sub mypush2(\@@) {
    my ($array_ref,@elements) = @_;
    if (@elements) {
        @$array_ref = (@$array_ref, @elements);
    } else {
        @$array_ref = (@$array_ref, $_);
    }
}

@a = (1..10);
mypush1 \@a, 11..20;
mypush2 @a, 21;
print "@a\n";
