#!/usr/bin/perl -w

my $shell_file;


#initialize files array and handle stdin
if (scalar @ARGV == 0) {
    my $stdin_file = "temp.sh";
    unless(open FILE, '>'.$stdin_file){
        die "Unable to create file\n";
    }
    while ($line = <>) {
        print FILE $line;
    }
    close FILE;
    
    $shell_file = $stdin_file;
}
else {
    $shell_file = $ARGV[0];
}

my $perl_file = "tmp.pl";

open F, '<', $shell_file or die "Cannot open $shell_file: $!\n";
open PF, '>', $perl_file or die "Cannot open $perl_file: $!\n";

my @lines = <F>;

foreach $l (@lines){

    #chomp($l);
    # for shebang line
    if($l =~ /^\#\!/s){
        $l = "\#\!/usr/bin/perl\n";
    }

    # for echo (handles single and double quote usage as well)
    if($l =~ /echo ['"]?(.*[^'"])['"]?/s){
        chomp($l);
        $l =~ s/echo ['"]?(.*[^'"])['"]?/print "$1\\n";\n/g;

        # special case where double quotes are used inside double quotes
        if($l =~ /""(.*[^"])"(.*)"/s){
            $l =~ s/""(.*[^"])"(.*)"/"\\"$1\\"$2"/g;
        }
    }

    # for variable declarations
    if($l =~ /([a-zA-Z]+)=(.*)/s){
        my ($lhs, $rhs) = split(/=/, $l);
        chomp($rhs);                                    # to remove trailing newline char from split
        $l =~ s/$lhs=$rhs/\$$lhs = '$rhs';/g;
    }

    # for (ls|ls -l) command
    if($l =~ /(ls .*)/s){
        $l =~ s/(ls .*)/system "$1";/g;
    }

    # for isolated shell commands
    if(($l =~ /(pwd)$/s) || ($l =~ /(id)$/s) || ($l =~ /(date)$/s) || ($l =~ /(ls)$/s)){
        $l =~ s/($1)/system "$1";/g;
    }

    # for cd command
    if($l =~ /cd (.*)/s){
        $l =~ s/cd (.*)/chdir '$1';/g;
    }

    # handling normal for loops
    if($l =~ /for (.*) in (.*)/s){
        @wds = ();

        if($2 =~ /\*.([a-z]+)/s){
            $l =~ s/for (.*) in (.*)/foreach \$$1 (glob("$2"))/g;
            
        }
        else {
            $params = $2;
            foreach $p (split( / /, $params)){

                if($p =~ /([a-zA-Z]+)/s){
                    $p =~ s/($1)/'$1'/g;
                }

                push @wds, $p; 
            }

            $params = join ', ', @wds;
            chomp($params);
            $l =~ s/for ($1) in ($2)/foreach \$$1 ($params)\n/g;
        }
         
    }

    # handle do and done for for loops
    if(($l =~ /(do)$/s) || ($l =~ /(done)$/s)){
        if($l =~ /(do)$/s){
            $l =~ s/($1)/{/g;
        } else {
            $l =~ s/($1)/}/g;
        }

    }
    
    # for read command
    if($l =~ /read (.*)/s){
        $l =~ s/read (.*)/\$$1 = <STDIN>;\n    chomp \$$1;/g;
    }

    # for command-line args
    if($l =~ /\$([0-9])/s){
        $n = $1 - "1";
        $l =~ s/($1)/ARGV[$n]/g;
    }

    # handle if else
    if(($l =~ /if test (.*)/s) || ($l =~ /else/s)){

        # convert if
        if($l =~ /if test (.*)/s){
            my ($lhs, $rhs) = split(/=/, $l);
        }

    }

    
    print PF $l;
   
}

close PF;
close F;

open FILE, '<', $perl_file or die "Cannot open $perl_file: $!\n";

@lines = <FILE>;

foreach $l (@lines){
    print $l;
}

close FILE;

