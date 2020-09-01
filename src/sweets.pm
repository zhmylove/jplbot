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
use tables qw/%entity2char/;

my $ua = LWP::UserAgent->new();

my $BASH  = "http://bash.im/random";
my $XKCDB = "http://www.xkcdb.com/random";
my $WTTR  = "http://wttr.in/";

my $WTTR_SUFFIX_IMAGE = "_0_lang=ru.png";

sub fetch_bash_joke {
    my $response = $ua->get($BASH);
    my ($key, $value);

    return "" unless (
       $response->is_success && $response->content_type eq 'text/html'
    );

    my $bash = decode("UTF-8", $response->content);
    $bash =~ m/<div class="quote__body">(.*?)<\/div>/s;
    my $quote = $1 // "";

    $quote =~ s/<br.*?>/\n/g;
    $quote =~ s/^\s*//s;
    $quote =~ s/\s+$//s;

    # Can be replaced with linear replacement algorithm, 
    # but for this domain problem regex performance is enough and another
    # solution cannot be more readable rather than such regex-cycle.
    $quote =~ s/&$key;/$value/g while(($key, $value) = each %entity2char);

    return $quote;
}

sub fetch_xkcdb_joke {
    my $response = $ua->get($XKCDB);
    my ($key, $value);

    return "" unless ($response->is_success && 
                         $response->content_type eq 'text/html');

    my $quote = ($response->content =~ 
        m/<p class="quoteblock">.*?<span class="quote">(.*?)<\/span>/s) ?
        $1 : "";

    # xkcdb quotes already have line breakers as well as <br>
    $quote =~ s/<br.*?>//g;
    $quote =~ s/&$key;/$value/g while(($key, $value) = each %entity2char);

    return $quote;
}

sub get_weather_image_url($) {
    my $self = shift;
    my $city = shift // "Saint+Petersburg";
    $city =~ s/\s+/+/g;
    return "" if $city =~ m/[^+\w]/;
    return "" if $city =~ m/^\++$/;
    my $url = $WTTR . $city . $WTTR_SUFFIX_IMAGE;
    
    #check for image
    my $response = $ua->get($url);
    return "" unless ($response->is_success && 
                         $response->content_type eq 'image/png');

    return $url;
}

1;
