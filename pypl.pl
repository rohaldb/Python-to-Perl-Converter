#!/usr/bin/perl -w
use strict;
# written by ben rohald 2017
# + - * / // % **
our @variables;
our $indentation = 0;

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
    } elsif ($line =~ /\s*while\s*(.*?)\s*:\s*(.*)/) {
        #while statement, be it inline or multiline
        whileStatement($1,$2);
    } elsif ($line =~ /^\s*print\(("*)(.*?)"*\)$/) {
        #printing a string
        printIndentation();
        printString($1,$2);
    } elsif ($line =~ /^\s*(.*?)\s*=\s*(.*)/) {
        #assignment of a variable
        printIndentation();
        variableAssignment($1,$2);
    } else {
        # Lines we can't translate are turned into comments
        printIndentation();
        print "#$line\n";
    }
}

sub whileStatement {
  my ($condition, $optional_inline) = @_;

  printIndentation();
  $condition = insertDollars($condition);
  print "while ($condition) {\n";
  $indentation++;

  if (!$optional_inline) {
    #just a while statement
    $condition = insertDollars($condition);
  } else {
    my @statements = split '\s*;\s*', $optional_inline;
    foreach my $statement (@statements) {
        patternMatch($statement);
    }
    # print "statements are = '@statements'\n";
    $indentation--;
    printIndentation(); print "}\n";
    # print "inline, while '$condition', do '$1' then do '$2'";
  }
}

sub printString {
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
    #check if first declaration or updating
    my $exists = 0;
    foreach my $var (@variables) {
      $exists = 1 if ($var eq $lhs);
    }
    push @variables, $lhs unless ($exists);
    $rhs = insertDollars($rhs);
    print "\$$lhs = $rhs;\n";
}

sub printIndentation {
   foreach (1..$indentation) {
      print "\t";
   }
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
    foreach my $var (our @variables) {
        $str =~ s/\b$var\b/\$$var/g;
    }
    return $str;
}
