#!/usr/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

# Tears of blood run down my face,
# Somebody help me get out of this place,
# I taste your fear instead of smell,
# It is not heaven, just pure hell.
#
# Tears of blood run down my cheak,
# I need to take another peek.
# Why on earth do we live?
# Somebody has that answere to give.
#
# Tears of blood drip down my lips,
# My friends, I know, they have some tips,
# Tears of blood are all I see,
# Children in pain, and then there's me.
#
# (c) Beki Castro
# Oh such beautiful russian language!

package xlate;

my $tear1 = '~!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:ZXCVBNM<>"?';
my $tear3 = 'Ё!"№;%:?*()_+ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЯЧСМИТЬБЮЭ,';
my $tear2 = '`1234567890=qwertyuiop[]asdfghjkl;zxcvbnm,.'."'".'/';
my $tear4 = 'ё1234567890=йцукенгшщзхъфывапролджячсмитьбюэ.';

my $pain1 = $tear1 . $tear2 . $tear3 . $tear4;
my $pain2 = $tear3 . $tear4 . $tear1 . $tear2;

sub cry {
   shift if $_[0] eq "xlate"; # skip package name if any

   return '' unless "@_" =~ /\w/;
   return eval '"@_" =~ ' . sprintf "y-%s-%s-r", $pain1, $pain2;
}

1;
