#!/usr/bin/perl -w
# this program reads in an even number of lines from stdin, then prints out each line and the number of characters in that line by using a hash

print("please enter some data", "\n");
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
# update hash to store lengths
foreach $i (0..scalar(@lengths) - 1) {
    $str = "$a[$i]";
    $my_dict{$str} = $lengths[$i];
}
# itterate over hash and print
foreach $key (sort(keys %my_dict)) { 
    print("$key has length $my_dict{$key}", "\n");
}
