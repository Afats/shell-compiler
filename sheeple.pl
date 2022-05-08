#!/usr/bin/perl -w

my $file_name = $ARGV[0];
# read in .sh file
open(my $file, '<', $file_name) or die $!;
my $count = 0;

my @lines;
# While there are lines keep reading
while (my $text = <$file>) {
    # Delete newline
    chomp($text);

    # assign each line to an array
    @lines[$count] = $text;
    $count++;

}

close($file);

foreach $line (@lines) {

    chomp($line);

    # if comments are present in -- fix for comments after code on same line
    if ($line =~ /#[^!].*/) {
        print "$line\n";
    }

    # if $1,$2,etc..
    if ($line =~ /\$([0-9])/) {
        #for argv
        $argv = $1 - "1";
        $line =~ s/($1)/ARGV[$argv]/g;
        #print "$print_line";
    }
     
    # print perl shebang when bash shebang found
    if ($line =~ /^\#\!/) { 
        print "#\!/usr/bin/perl -w\n";
        next;
    }

    # if echo command is present in line
    if ($line =~ /echo ['"]?(.*[^'"])['"]?/) {
        my $print_line = $line =~ s/echo ['"]?(.*[^'"])['"]?/print "$1\\n";\n/gr;

        # special case where double quotes are used inside double quotes
        if($print_line =~ /""(.*[^"])"(.*)"/) {
            $print_line =~ s/""(.*[^"])"(.*)"/"\\"$1\\"$2"/g;
        }

        print "$print_line"; 
        next;
    }

    # if system commands called in line
    if ($line =~ /(pwd |ls |id |date )(.*)/) {
        my $print_line = $line =~ s/(pwd |ls |id |date )(.*)/system "$1$2";\n/gr;
        print "$print_line"; 
        next;
    }

    # if variables assigned in line
    if ($line =~ /([a-zA-Z]+)=([a-zA-Z]+)/) {
        my $print_line = $line =~ s/([a-zA-Z]+)=([a-zA-Z]+)/\$$1 = '$2';\n/gr;    
        print "$print_line";
        next;
    }

    # cd command called in line
    if ($line =~ /cd (.+)/) {
        my $print_line = $line =~ s/cd (.+)/cd '$1';\n/gr;    
        print "$print_line"; 
        next;     
    }

    # exit line
    if ($line =~ /exit /) {
        print "$line;\n";
        next;
    }  
    
    # regular for loop
    if ($line =~ /for (.*) in (.*)/) {

        $var = $1;
        $param = $2;
        
        # glob: [*?].[*?]
        if ($param =~ /([*?]+).([*?a-zA-Z]+)/) {
            $print_line = $line =~ s/for (.*) in (.*)/foreach \$$var (glob("$1.$2")) {\n/gr; 
            print "$print_line";  
        }

        # regular parameters
        else {
            $print_line = $line =~ s/for (.*) in (.*)/foreach \$$var /gr; 
            print "$print_line";
            # add apostrope to word params
            my @spl = split(' ', $param);

            foreach my $p (@spl) {
                # alpha or alphanumeric param
                if ($p =~ /([0-9]*[a-zA-Z]+[0-9]*)|([a-zA-Z]*[0-9]+[a-zA-Z])/) {
                    $p = $p =~ s/([0-9]*[a-zA-Z]+[0-9]*)|([a-zA-Z]+[0-9]*[a-zA-Z])/'$1'/gr;
                }
            }

            $word = join(",", @spl);
            $print_word = $word =~ s/($word)/($1) {\n/gr;

            print "$print_word"; 
        }
        next;
    }

    # done in for loops or fi in if
    if (($line =~ /(done)/) || ($line=~/(fi)/)) {
        
        if ($line =~ /(done)/) {
            $print_line = $line =~ s/$1/}\n/gr;
            print "$print_line";
            next;
        }

        elsif ($line =~ /(fi)/) {
            $print_line = $line =~ s/$1/    }\n/gr;
            print "$print_line";
            next;
        }
    }

    # do in for loops or then in if
    if (($line =~ /do/) || ($line =~ /then/)) {
        next;
    } 

    # if exit 
    if ($line =~ /exit [0-9]/) {
        $print_line = $line =~ s/(exit [0-9])/$1;\n/gr;
        print "$print_line";
        next;
    } 

    # if read command
    if ($line =~ /([ ]*)read (.*)/) {
        $print_line = $line =~ s/([ ]*)read (.*)/$1\$$2 = <STDIN>;\n$1chomp \$$2;\n/gr;
        print "$print_line";
        next;
    }

    # elif 
    if ($line =~ /(elif)/) {
        # else test
        if ($line =~ /elif test (.*)/) {
            ($spl, $rhs) = split('= ', $line);
            @lhs = split(' ', $spl);
            $print_line = $line =~ s/elif test (.*)/    } elsif ('$lhs[2]' eq '$rhs') {\n/gr;
            print "$print_line";
            next;
        }
    }

    # if 
    if ($line =~ /(if) (.*)/) {
        # if test
        if ($line =~ /if test (.*)/) {
            ($spl, $rhs) = split('= ', $line);
            @lhs = split(' ', $spl);
            $print_line = $line =~ s/if test (.*)/if ('$lhs[2]' eq '$rhs') {\n/gr;
            print "$print_line";
            next;
        }

    }
    
    # else
    if ($line =~ /(else)/) {
        $print_line = $line =~ s/else/    } else {\n/gr;
        print "$print_line";
        next;
    }

    # else
    if ($line =~ /(expr) (.*)/) {
        $print_line = $line =~ s/(expr) (.*)/eval "$2";\n/gr;
        print "$print_line";
        next;
    }

    else {
        print "$line\n";
    }
}