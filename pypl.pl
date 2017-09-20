#!/usr/bin/perl -w
use strict;
# written by ben rohald 2017
# + - * / // % **
our @variables;
while (my $line = <>) {
    patternMatch($line);
}

sub patternMatch {
    my $line = $_[0];
    $line = sanitizeOperations($line);

    if ($line =~ /^#!/ && $. == 1) {
        # translate #! line
        print "#!/usr/bin/perl -w\n";
    } elsif ($line =~ /^\s*(#|$)/) {
        # Blank & comment lines can be passed unchanged
        print $line;
    } elsif ($line =~ /^\s*print\(("*)(.*?)"*\)$/) {
        #printing a string
        printString($1,$2);

    } elsif ($line =~ /^\s*(.*?)\s*=\s*(.*)/) {
        #assignment of a variable
        variableAssignment($1,$2);
    } else {
        # Lines we can't translate are turned into comments
        print "#$line\n";
    }
}

sub printString() {
    my ($quotation,$print_content) = @_;
    if ($quotation) {
        # printing a string
        print "print \"$print_content\\n\";\n";
    } else {
        #print contains variables
        my $print_content = insertDollars($print_content);

        if ($print_content =~ /\+|-|\*|\/|%/){
            #printing an expression
            print "print $print_content, \"\\n\";\n";
        } else {
            #printing a variable
            print "print \"$print_content\\n\";\n";
        }
    }
}

sub variableAssignment {
    my ($lhs,$rhs) = @_;
    push @variables, $lhs;
    $rhs = insertDollars($rhs);
    print "\$$lhs = $rhs;\n";
}

#formats all operations to be space separated
sub sanitizeOperations {
    my $line = $_[0];
    $line =~ s/\+/ + /g;
    $line =~ s/-/ - /g;
    $line =~ s/\*/ * /g;
    $line =~ s/\// \/ /g;
    $line =~ s/\/\// \/\/ /g;
    $line =~ s/\* \*/ \*\* /g;
    $line =~ s/%/ % /g;
    $line =~ s/  */ /g;
    $line =~ s/\* \*/\*\*/g;
    $line =~ s/\/ \//\/\//g;
    return $line;
}

# inserts $before known variables in a string param
sub insertDollars {
    my $str = $_[0];
    foreach my $var (@variables) {
        $str =~ s/$var/\$$var/g;
    }
    return $str;
}
