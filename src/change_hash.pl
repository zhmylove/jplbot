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

my $file = $ARGV[0] // die 'no hash file specified';
my $key  = $ARGV[1] // die 'no hash key specified';
my $val  = $ARGV[2] // die 'no hash value specified';

utf8::decode($key);
utf8::decode($val);

my %h = %{retrieve($file)} or die "retrieve: $file: $!";

die "hash key [$key] unknown" unless defined $h{$key};
$h{$key} = $val;
store \%h, $file or die "store: $file: $!";
