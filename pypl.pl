#!/usr/bin/perl -w

# written by ben rohald 2017

while ($line = <>) {
    if ($line =~ /^#!/ && $. == 1) {

        # translate #! line
        print "#!/usr/bin/perl -w\n";

    } elsif ($line =~ /^\s*(#|$)/) {

        # Blank & comment lines can be passed unchanged
        print $line;

    } elsif ($line =~ /^\s*print\(("*)(.*)"*\)$/) {
        $print_content = $2;
        if ($1) {
            print "print \"$2\\n\";\n";
        } else {
            #we are printing a variable
            foreach $var (@variables) {
                $print_content =~ s/$var/\$$var/g;
            }
            print "print \"$print_content\\n\";\n";
        }

    } elsif ($line =~ /^\s*(.*)=(.*)/) {
        $lhs = $1;
        $rhs = $2;
        $lhs =~ s/ *//g;
        push @variables, $lhs;
        foreach $var (@variables) {
            $rhs =~ s/$var/\$$var/g;
        }
        # variable assignment
        print "\$$lhs=$rhs;\n";
    } else {

        # Lines we can't translate are turned into comments
        print "#$line\n";
    }
}
