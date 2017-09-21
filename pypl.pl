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
    $line = spaceOperators($line);

    if ($line =~ /^#!/ && $. == 1) {
        # translate #! line
        print "#!/usr/bin/perl -w\n";
    } elsif ($line =~ /^\s*(#|$)/) {
        # Blank & comment lines can be passed unchanged
        print $line;
    } elsif ($line =~ /\s*while\s*(.*?)\s*:\s*(.*)/) {
        #while statement, be it inline or multiline
        conditionalStatement($1,$2, "while");
    } elsif ($line =~ /\s*if\s*(.*?)\s*:\s*(.*)/) {
        #while statement, be it inline or multiline
        conditionalStatement($1,$2, "if");
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

sub sanitizeOperators {
  my $line = $_[0];
  #while we have an invalid // operator, swap it
  while ($line =~ /((\w+)\s*\/\/\s*(\w+))/) {
    $line =~ s/$1/int($2\/$3)/g;
  }
  #swap <> for !=
  $line =~ s/<>/!=/g;
  # if line starts with not, add brackting format
  if ($line =~ /(\bnot\b\s*(.*))/) {
    $line = "not($2)";
  }
  return $line;
}

#used to handle if and while statments
sub conditionalStatement {
  #in the format if/while(condition): optional_inline; optional_inline
  #type = while vs if
  my ($condition, $optional_inline, $type) = @_;

  $condition = sanitizeOperators($condition);
  printIndentation();
  $condition = insertDollars($condition);
  print "$type ($condition) {\n";
  $indentation++;

  if (!$optional_inline) {
    #just a if/while statement
    $condition = insertDollars($condition);
  } else {
    #may have multiple inline statements, split them up and handle each appropriately
    my @statements = split '\s*;\s*', $optional_inline;
    foreach my $statement (@statements) {
        patternMatch($statement);
    }
    $indentation--;
    printIndentation(); print "}\n";
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

sub spaceOperators {
    my $line = $_[0];
    #provide appropriate spacing
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
