#!/usr/bin/perl -w


foreach $line (<STDIN>) {
    push(@a, $line);
}
if (scalar(@a) % 2 != 0) {
    print("we want an even number of lines please enter one more", "\n");
    $b = <STDIN>;
    push(@a, $b);
}

#calculate lengths
foreach $i (@a) {
    push(@lengths, length($i));
}
%my_dict = ();
foreach $i (0..scalar(@lengths) - 1) {
    $str = "$a[$i]";
    $my_dict{$str} = $lengths[$i];
}

foreach $key (keys %my_dict) {
    print("$key has length $my_dict{$key}", "\n");
}
