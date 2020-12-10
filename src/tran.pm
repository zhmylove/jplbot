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
use HTTP::Cookies;
use Storable qw( lock_store lock_retrieve );

my $FILE_COOKIES = '/tmp/jplbot_tran_cookies.dat';
my $FILE_SID = '/tmp/jplbot_sid.dat';

sub new($) {
   my $self = shift;

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

our $SID;
our $SID_time;
# Avoid API (.net) domain here
our @SID_domains = (
   'https://translate.yandex.ru',
   'https://translate.yandex.com',
);
our $CAPTCHA_time = 0;

my $ua = LWP::UserAgent->new(
   cookie_jar => HTTP::Cookies->new(
      file => '/tmp/jplbot_tran_cookies.dat',
      autosave => 1,
   ),
);
$ua->env_proxy;

sub _load_SID() {
   return if defined $SID;
   my $ref = lock_retrieve($FILE_SID);
   return unless defined $ref;
   $SID = $ref->{SID};
   $SID_time = $ref->{SID_time};
}

sub _save_SID() {
   lock_store({ SID => $SID, SID_time => $SID_time, }, $FILE_SID);
}

sub _update_SID() {
   # Update SID every 10 minutes
   return if defined $SID and time - $SID_time < 60 * 10;
   return if time - $CAPTCHA_time < 60 * 5;

   my $req = HTTP::Request->new(GET => $SID_domains[int(@SID_domains * rand)]);
   $req->header('cache-control' => 'no-cache');
   $req->header('pragma' => 'no-cache');
   $req->header('user-agent' =>
      (
         'Mozilla/5.0 (Nintendo 3DS; U; ; en) Version/1.7412.EU',
         'curl/7.54',
         'Mozilla/5.0 (PlayStation 4 3.11) AppleWebKit/537.73 (KHTML, Gecko)',
         'Dalvik/2.1.0 (Linux; U; Android 6.0.1; Nexus Player Build/MMB29T)',
      )[int(4 * rand())]
   );
   rand() > 0.5 and $req->header('upgrade-insecure-requests' => '1');
   $req->header('accept' => 'text/html');
   $req->header('accept-language' => 'en-US,en;q=0.9');
   my $res = $ua->request($req);

   unless ($res->is_success) {
      $SID = undef;
      return;
   }

   if ($res->content =~ /SID:\s*'([^']+)/s) {
      $SID = (join ".", map { scalar reverse } split /\./, $1, -1) . "-0-0";
      $SID_time = time;
      # save the cookies manually
      $ua->cookie_jar->save();
      _save_SID();
   } elsif ($res->content =~ /captcha/is) {
      $CAPTCHA_time = time;
      $ua->cookie_jar->clear($_) for @SID_domains;
      $ua->cookie_jar->save();
   }
}

sub translate($$) {
   my $self = shift;
   my $TXT = shift // return '';

   _update_SID();

   return '' unless defined $SID;

   my $LANG = "en-ru";
   $LANG = "ru-en" unless $TXT =~ /^[a-z0-9-_,?'!.\s]*$/i;
   utf8::encode($TXT);

   my $URI = URI->new(
      'https://translate.yandex.net/api/v1/tr.json/translate'
   );
   $URI->query_form(id => $SID, lang => $LANG, text => $TXT, srv => "tr-text");
   my $req = HTTP::Request->new(GET => $URI);
   $req->content_type('application/javascript; charset=utf-8');

   my $res = $ua->request($req);
   return '' unless $res->is_success;

   return '' unless (get_value_from_json($res->content, 'code') == 200);

   return get_value_from_json($res->content, 'text');
}

1;
