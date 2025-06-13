#!/usr/bin/env perl

use strict;
use warnings;

use Tokenizer;

use Data::Dumper;

if (@ARGV == 0) {
    die "Error: No token.def file specified."
}

my $tf = join("\n",
	      "a A z Z abz ABz",
	      "a129 ab129 a129z",
	      "int intxyz xyzint",
	      "char charxyz xyzchar",
	      "double doublexyz xyzdouble",
	      "if else while for",
	      "ifx elsex whilex forx",
	      "xif xelse xwhile xfor",
	      "0 9 10 99999 -1 -29 3.1415 31.415 -31.415",
	      "{()}",
	      "-+*/",
	      "==<<=>>=",
	      ";",
	      "//comment comment\n",
	      "123xyz",
	      ">==<==",
	      " ", "  \n  ",
	      "// {(-+*/<=>;)}if else while for",
    );

my @oracle = (
'UNIT_BEGIN	<>','IDN	<a>','SP_B	< >','IDN	<A>','SP_B	< >','IDN	<z>','SP_B	< >','IDN	<Z>','SP_B	< >','IDN	<abz>','SP_B	< >','IDN	<ABz>','SP_NL	<\n>','IDN	<a129>','SP_B	< >','IDN	<ab129>','SP_B	< >','IDN	<a129z>','SP_NL	<\n>','TYPE	<int>','SP_B	< >','IDN	<intxyz>','SP_B	< >','IDN	<xyzint>','SP_NL	<\n>','TYPE	<char>','SP_B	< >','IDN	<charxyz>','SP_B	< >','IDN	<xyzchar>','SP_NL	<\n>','TYPE	<double>','SP_B	< >','IDN	<doublexyz>','SP_B	< >','IDN	<xyzdouble>','SP_NL	<\n>','RE_IF	<if>','SP_B	< >','RE_ELSE	<else>','SP_B	< >','RE_WHILE	<while>','SP_B	< >','RE_FOR	<for>','SP_NL	<\n>','IDN	<ifx>','SP_B	< >','IDN	<elsex>','SP_B	< >','IDN	<whilex>','SP_B	< >','IDN	<forx>','SP_NL	<\n>','IDN	<xif>','SP_B	< >','IDN	<xelse>','SP_B	< >','IDN	<xwhile>','SP_B	< >','IDN	<xfor>','SP_NL	<\n>','NUM	<0>','SP_B	< >','NUM	<9>','SP_B	< >','NUM	<10>','SP_B	< >','NUM	<99999>','SP_B	< >','OP	<->','NUM	<1>','SP_B	< >','OP	<->','NUM	<29>','SP_B	< >','NUM	<3.1415>','SP_B	< >','NUM	<31.415>','SP_B	< >','OP	<->','NUM	<31.415>','SP_NL	<\n>','C_L	<{>','P_L	<(>','P_R	<)>','C_R	<}>','SP_NL	<\n>','OP	<->','OP	<+>','OP	<*>','OP	</>','SP_NL	<\n>','OP	<==>','OP	<<>','OP	<<=>','OP	<>>','OP	<>=>','SP_NL	<\n>','SC	<;>','SP_NL	<\n>','SP_C	<//comment comment>','SP_NL	<\n>','SP_NL	<\n>','NUM	<123>','IDN	<xyz>','SP_NL	<\n>','OP	<>=>','OP	<=>','OP	<<=>','OP	<=>','SP_NL	<\n>','SP_B	< >','SP_NL	<\n>','SP_B	<  >','SP_NL	<\n>','SP_B	<  >','SP_NL	<\n>','SP_C	<// {(-+*/<=>;)}if else while for>','UNIT_END	<>',
    );

my @tokens = Tokenizer->new->load($ARGV[0])->set_input($tf)->tokens;
chomp @tokens;
#print map(qq('$_',), @tokens);  exit(0);

my @diff = grep(/^[-+]/, lcs(\@oracle, \@tokens));

if (@diff) {
    print "Differeces: ('-' means oracle token and '+' means your tokenizer's one.) --\n",
	join("\n", @diff), "\n";
} else {
    print "No difference.\n";
}

sub lcs {
    my ($a, $b) = @_;
    my @LT;  # LCS の長さを記録する表
    my @PT;    # 編集経路を記録する表

    my ($D_NONE, $D_ADD, $D_EQ, $D_DEL) = (0, 1, 2, 4);

    for (my $i = 0; $i <= @$a; $i++) {
	$LT[$i][0] = 0;
    }
    for (my $j = 0; $j <= @$b; $j++) {
	$LT[0][$j] = 0;
    }
    $PT[0][0] = $D_NONE;

    my $EQUAL = sub { return $_[0] eq $_[1] };

    for (my $i = 0; $i < @$a; $i++) {
	for (my $j = 0; $j < @$b; $j++) {
	    my ($len, $path);
	    if ($EQUAL->($a->[$i], $b->[$j])) {  # 比較対象が等しいとき
		$len = $LT[$i][$j] + 1;  # LCS が1つ伸びる
		$path = $D_EQ;
	    } else {  # 比較対象が等しくないとき
		my ($len_a, $len_b) = ($LT[$i+1][$j], $LT[$i][$j+1]);
		if ($len_a >= $len_b) { # B の挿入を選択
		    $len = $len_a;
		    $path |= $D_ADD;
		}
		if ($len_a <= $len_b) { # A の削除を選択
		    $len = $len_b;
		    $path |= $D_DEL;
		}
		# 注意: 等しい場合は解が $D_ADD と $D_DEL の論理和が $path になる
	    }
	    $LT[$i+1][$j+1] = $len;
	    $PT[$i+1][$j+1] = $path;
	}
    }

    my ($i, $j) = (scalar(@$a), scalar(@$b));

    my @res;
    while ($PT[$i][$j] != $D_NONE) {
	if ($PT[$i][$j] == $D_EQ) {  # 等しいときは左上へのセルへ移動
	    unshift(@res, "= ". $a->[$i-1]);
	    $i--;  $j--;
	} elsif ($PT[$i][$j] & $D_ADD) {
	    unshift(@res, "+ ". $b->[$j-1]);
	    $j--;                           # 左のセルへ移動
	} else {
	    unshift(@res, "- ". $a->[$i-1]);
	    $i--;                           # 上のセルへ移動
	}
	die "Overrun ($i, $j)" if ($i < -1 || $j < -1);  # for safety
    }
    return @res;
}
