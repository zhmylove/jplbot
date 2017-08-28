#!/usr/bin/perl
# made by: csepanda

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package sweets;

use LWP;
use Encode qw/decode/;
use HTML::Entities;

my $ua = LWP::UserAgent->new();

my $BASH = "http://bash.im/random";

sub fetch_bash_joke {
    my $response = $ua->get($BASH);

    return undef unless ($response->is_success && $response->content_type eq 'text/html');

    my $bash = decode("Windows-1251", $response->content);
    my $quote = $1 if $bash =~ m/<div class="quote">.*?<div class="text">(.*?)<\/div>/s;

    $quote =~ s/<br.*?>/\n/g;

    return decode_entities($quote);
}

1;
