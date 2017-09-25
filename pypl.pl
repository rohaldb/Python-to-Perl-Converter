#!/usr/bin/perl -w

# written by ben rohald 2017
use strict;

our @variables;
our $global_indentation = 0;

while (my $line = <>) {
  my $temp_line = $line;
  $temp_line =~ /^(\s*).*/;
  my $local_indentation = length($1)/4;
  if ($local_indentation < $global_indentation) {
    closeAllBrackets($local_indentation);
  }
  patternMatch($line);
  # close all unclosed brackets if end of file
  closeAllBrackets(0) if (eof || eof());
  # printVariables();
}

sub printVariables {
  my $temp = join ',', @variables;
  print "variables: $temp\n";
}

sub patternMatch {
    my $line = $_[0];
    #$line = spaceOperators($line);

    if ($line =~ /^#!/ && $. == 1) {
        # translate #! line
        print "#!/usr/bin/perl -w\n";
    } elsif ($line =~ /^\s*(#|$)/) {
        # Blank & comment lines can be passed unchanged
        print $line;
    } elsif ($line =~ /^\s*import\s+sys\s*$/) {
        return;
    } elsif ($line =~ /^\s*for\s+(\w+)\s+in\s+range\s*\((.*)\)\s*:/) {
        #for loop with range
        forStatement($1,$2);
    } elsif ($line =~ /\s*while\s*(.*?)\s*:\s*(.*)/) {
        #while statement, be it inline or multiline
        conditionalStatement($1,$2, "while");
    } elsif ($line =~ /\s*\bif\b\s*(.*?)\s*:\s*(.*)/) {
        #while statement, be it inline or multiline
        conditionalStatement($1,$2, "if");
    } elsif ($line =~ /\s*elif\s*(.*?)\s*:\s*$/) {
        #elseif statement
        elseIfStatement($1);
    } elsif ($line =~ /\s*else\s*:\s*$/) {
        #else statement to end conditional
        elseStatement();
    } elsif ($line =~ /^\s*break\s*$/) {
        #else statement to end conditional
        breakStatement($line);
    } elsif ($line =~ /^\s*print\s*\(\s*("{0,1})(.*?)"{0,1}\s*\)\s*$/) {
        #printing. 1 means new line
        printStatment($1,$2,0);
    } elsif ($line =~ /^\s*sys.stdout.write\s*\(\s*("{0,1})(.*?)"{0,1}\s*\)\s*$/) {
        #printing. 0 means no new line
        printStatment($1,$2,1);
    } elsif ($line =~ /^\s*(\w+)\s*(\+=|=|-=|\*=|\/=)\s*(.*)/) {
        #assignment of a variable
        printIndentation();
        variableAssignment($1,$2,$3);
    } else {
        # Lines we can't translate are turned into comments
        printIndentation();
        print "#$line\n";
    }
}

sub elseIfStatement {
  my $condition = insertDollars($_[0]);
  printIndentation();
  print "elsif ($condition) { \n";
  $global_indentation++;
}

sub elseStatement {
  printIndentation();
  print "else { \n";
  $global_indentation++;
}

sub breakStatement {
  my $line = $_[0];
  printIndentation();
  print "last;\n";
}

sub pushOntoVariables {
  my $new_var = $_[0];
  #check if first declaration or updating
  my $exists = 0;
  foreach my $var (@variables) {
    $exists = 1 if ($var eq $new_var);
  }
  push @variables, $new_var unless ($exists);
}

sub forStatement {
  #for range loop
  my $var = $_[0]; my $range = $_[1];
  pushOntoVariables($var);
  if ($range =~ /(.+)\s*,\s*(.+)/) {
    my $lower = insertDollars($1); my $upper = insertDollars($2);
    print "foreach \$$var ($lower..$upper - 1) {\n";
  } elsif ($range =~ /^\s*(\d+)\s*$/) {
    my $upper = insertDollars($1);
    print "foreach \$$var (0..$upper - 1) {\n";
  } else {
    print "problem with range\n";
  }
  $global_indentation++;
}

sub sanitizeOperators {
  my $line = $_[0];
  #while we have an invalid // operator, swap it
  while ($line =~ /((\w+)\s*\/\/\s*(\w+))/) {
    my $full = $1; my $divisor1 = $2; my $divisor2 = $3;
    $line =~ s/$full/int($divisor1\/$divisor2)/g;
  }
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
  $global_indentation++;

  if (!$optional_inline) {
    #just a if/while statement
    $condition = insertDollars($condition);
  } else {
    #may have multiple inline statements, split them up and handle each appropriately
    my @statements = split '\s*;\s*', $optional_inline;
    foreach my $statement (@statements) {
        patternMatch($statement);
    }
    $global_indentation--;
    printIndentation(); print "}\n";
  }
}

sub printStatment {
    my ($quotation,$print_content,$new_line) = @_;
    printIndentation();
    if ($quotation) {
        # printing a string
        print "print \"$print_content\\n\";\n" unless $new_line;
        print "print \"$print_content\";\n" if $new_line;
    } else {
        #print contains variables
        my $print_content = insertDollars($print_content);

        if ($print_content =~ /\+|-|\*|\/|%/){
            #printing an expression
            print "print $print_content, \"\\n\";\n" unless $new_line;
            print "print $print_content;\n" if $new_line;
        } else {
            #printing a variable
            print "print \"$print_content\\n\";\n" unless $new_line;
            print "print \"$print_content\";\n" if $new_line;
        }
    }
}

sub variableAssignment {
    my ($lhs,$operator, $rhs) = @_;
    pushOntoVariables($lhs);
    if ($rhs =~ /sys.stdin.readline\(\)/) {
      # $rhs =~ s/sys.stdin.readline\(\)/<STDIN>/;
      $rhs = "<STDIN>";
    }
    $rhs = sanitizeOperators($rhs);
    $rhs = insertDollars($rhs);
    print "\$$lhs $operator $rhs;\n";
}

# inserts $before known variables in a string param
sub insertDollars {
    my $str = $_[0];
    foreach my $var (our @variables) {
        $str =~ s/\b$var\b/\$$var/g;
    }
    return $str;
}

sub printIndentation {
   foreach (1..$global_indentation) {
      print "    ";
   }
}

sub closeAllBrackets {
  my $local_indentation = $_[0];
  while ($global_indentation != $local_indentation) {
    $global_indentation--;
    printIndentation();
    print "}\n";
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
    $line =~ s/\+ =/\+=/g;
    $line =~ s/- =/-=/g;
    $line =~ s/\* =/\*=/g;
    $line =~ s/\/ =/\/=/g;
    return $line;
}
