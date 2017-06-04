#!/usr/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

use Storable;
use POSIX;

# originally to show message counters
my $file = shift // '/tmp/count_tg';

my %h = %{retrieve($file)} or die "Retrieve: $file: $!";

write while (my ($name, $count) = each %h);

format STDOUT =
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>>>>>>>>>>
$name,$count
.
