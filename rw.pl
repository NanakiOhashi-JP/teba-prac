#!/usr/bin/env perl

use strict;
use warnings;

use Tokenizer;
use BracketsID;
use RewriteTokens2;

my $input = join("", <>);

my @tokens = Tokenizer->new->load("token.def")
    ->set_input($input)->tokens;

chomp @tokens;
BracketsID->new->conv(\@tokens);

RewriteTokens->new->syntax_check->rule(&file("parser.rules"))->apply(\@tokens);

print join("\n", @tokens), "\n";

sub file {
    my $f = shift;
    open (my $fh, '<', $f) || die "Can't open $f: $@";
    my $text = join("", <$fh>);
    close($fh);
    return $text;
}
