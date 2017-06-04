#!/usr/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package tran;

use LWP;

my $KEY = 'yandex_api';

# args: self API_key
sub new($;$) {
   my $self = shift;
   $KEY = shift // $KEY;

   return bless {}, $self;
}

sub get_value_from_json($$) { # due to lack of JSON
   my $JSON = shift // return '';
   my $key = shift // return '';
   utf8::decode($JSON);

   return '' unless
   $JSON =~ /"$key":(?<q>(?:\["))?(.*?(?(<q>)[^\\]|[^,]))(?=(?(<q>)"|,))/;

   (my $txt = $2) =~ s/\\"/"/g;
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

   my $URI = URI->new(
      'https://translate.yandex.net/api/v1.5/tr.json/translate'
   );
   $URI->query_form(key => $KEY, lang => $LANG, text => $TXT);
   my $req = HTTP::Request->new(GET => $URI);
   $req->content_type('application/javascript; charset=utf-8');

   my $res = $ua->request($req);
   return '' unless $res->is_success;

   return '' unless (get_value_from_json($res->content, 'code') == 200);

   return get_value_from_json($res->content, 'text');
}

1;
