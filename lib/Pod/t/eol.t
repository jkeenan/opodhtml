#!./perl -w

use Test::More tests => 3;

open(POD, ">$$.pod") or die "$$.pod: $!";
print POD <<__EOF__;
=pod

=head1 NAME

crlf

=head1 DESCRIPTION

clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf
clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf
clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf
clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf

    clrf clrf clrf clrf
    clrf clrf clrf clrf
    clrf clrf clrf clrf

clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf
clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf
clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf
clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf clrf

=cut
__EOF__
close(POD);

use Pod::Html;

# --- CR ---

open(POD, "<$$.pod") or die "$$.pod: $!";
open(IN,  ">$$.in")  or die "$$.in: $!";
while (<POD>) {
  tr/\x0D\x0A//d;
  print IN $_, "\x0D";
}
close(POD);
close(IN);

pod2html("--title=eol", "--infile=$$.in", "--outfile=$$.o1");

# --- LF ---

open(POD, "<$$.pod") or die "$$.pod: $!";
open(IN,  ">$$.in")  or die "$$.in: $!";
while (<POD>) {
  tr/\x0D\x0A//d;
  print IN $_, "\x0A";
}
close(POD);
close(IN);

pod2html("--title=eol", "--infile=$$.in", "--outfile=$$.o2");

# --- CRLF ---

open(POD, "<$$.pod") or die "$$.pod: $!";
open(IN,  ">$$.in")  or die "$$.in: $!";
while (<POD>) {
  tr/\x0D\x0A//d;
  print IN $_, "\x0D\x0A";
}
close(POD);
close(IN);

pod2html("--title=eol", "--infile=$$.in", "--outfile=$$.o3");

# --- now test ---

local $/;

open(IN, "<$$.o1") or die "$$.o1: $!";
my $cksum1 = unpack("%32C*", <IN>);

open(IN, "<$$.o2") or die "$$.o2: $!";
my $cksum2 = unpack("%32C*", <IN>);

open(IN, "<$$.o3") or die "$$.o3: $!";
my $cksum3 = unpack("%32C*", <IN>);

ok($cksum1 == $cksum2, "CR vs LF");
ok($cksum1 == $cksum3, "CR vs CRLF");
ok($cksum2 == $cksum3, "LF vs CRLF");

END {
  1 while unlink("$$.pod", "$$.in", "$$.o1", "$$.o2", "$$.o3");
}