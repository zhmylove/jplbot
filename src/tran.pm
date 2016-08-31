#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package tran;

use LWP;

my $ID = 'c967dd7e.57c54f57.eb15d78c-1-0';

sub new($;$) {
   my $self = shift;
   my $cfg = shift // {};

   $ID = $cfg->{ID} // $ID;

   return bless {}, $self;
}

sub get_text_from_json($) { # due to lack of JSON
   my $JSON = shift // return '';
   utf8::decode($JSON);

   return '' unless $JSON =~ /"text":\["(.*?[^\\])(?=")/;
   (my $txt = $1) =~ s/\\"/"/g;
   return $txt;
}

sub translate($$) {
   my $self = shift;
   my $TXT = shift // return '';

   my $ua = LWP::UserAgent->new();
   $ua->env_proxy;

   my $LANG = "en-ru";
   $LANG = "ru-en" unless $TXT =~ /^[a-z0-9-_,?'!.\s]*$/i;
   utf8::encode($TXT);

   my $req = HTTP::Request->new(
      POST => 'http://translate.yandex.net/api/v1/tr.json/translate?' .
      "id=$ID&srv=tr-text&lang=$LANG&reason=auto");
   $req->content_type('application/x-www-form-urlencoded');
   $req->content("options=4&text=$TXT");

   my $res = $ua->request($req);
   return '' unless $res->is_success;

   return get_text_from_json($res->content);
}

1;
