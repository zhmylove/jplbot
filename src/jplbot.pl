#!/usr/local/bin/perl
# made by: KorG
use strict;
use warnings;
use v5.18;
use utf8;
no warnings 'experimental';

use Net::Jabber::Bot;
use Storable;
use LWP;

### DEFAULT VALUES ###
our $name = 'AimBot';
# Path to file for karma saving routine
our $karmafile = '/tmp/karma';
# Address of XMPP server of the bot's account
our $server = 'zhmylove.ru';
# Port of XMPP server of the bot's account
our $port = 5222;
# Username of bot's account on the server
our $username = 'aimbot';
# Password for this username
our $password = 'password';
# Interval in seconds between background_checks() calee
our $loop_sleep_time = 60;
# Address of a conference server, where forums are expected to be
our $conference_server = 'conference.jabber.ru';
# MUC forums (chatrooms) with their passwords
our %forum_passwords = ('ubuntulinux' => 'ubuntu');

unless (my $ret = do './config.pl') {
   warn "couldn't parse config.pl: $@" if $@;
   warn "couldn't do config.pl: $!"    unless defined $ret;
   warn "couldn't run config.pl"       unless $ret;
}

my $qname = quotemeta($name);
store {}, $karmafile unless -r $karmafile;
my %karma = %{retrieve($karmafile)};
$SIG{INT} = \&shutdown;
$SIG{TERM} = \&shutdown;

sub shutdown {
   store \%karma, $karmafile and say "Karma saved to: $karmafile";
   exit 0;
}

sub background_checks {
   my $bot = shift;
   store \%karma, $karmafile;
}

sub new_bot_message {
   my %msg = @_;
   my $bot = $msg{'bot_object'};

   my $from = $msg{'from_full'};
   $from =~ s{^.+/([^/]+)$}{$1};

   my $to_me = ($msg{'body'} =~ s{^$qname: }{});

   given ($msg{'body'}) {

      when (/^time\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: " . time);
      }

      when (/^help\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: пробуй так: fortune karma time");
      }

      when (/^fortune\s*$/i) {
         my $fortune = `/usr/games/fortune -s`;
         chomp $fortune;
         $fortune =~ s/[\n\t]+/ /g;
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: $fortune");
         sleep 1;
      }

      when (/^karma\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: твоя карма: " . ($karma{lc($from)}||0));
      }

      when (/^karma\s*(\w+)$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: карма $1: " . ($karma{lc($1)}||0));
      }

      when (/^(\w+):\s*\+[+1]\s*$/) {
         return if $1 eq $from;
         $karma{lc($1)}++;
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: поднял карму $1 до " . $karma{lc($1)});
      }

      when (/^(\w+):\s*\-[-1]\s*$/) {
         return if $1 eq $from;
         $karma{lc($1)}--;
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: опустил карму $1 до " . $karma{lc($1)});
      }

      when (m{(https?://\S+)}) {
         my $uri = $1;
         my $ua = LWP::UserAgent->new();
         $ua->timeout(10);
         $ua->env_proxy;
         $ua->agent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:46.0)' .
            'Gecko/20100101 Firefox/46.0');

         my $response = $ua->request(
            HTTP::Request->new(HEAD => $uri)
         );

         if ($response->code < 200 or $response->code > 299) {
            $bot->SendGroupMessage($msg{'reply_to'},
               "$from: сервер вернул код: " .
               $response->code . ", разбирайся сам!");
            return;
         }

         my %type;
         foreach($response->header("Content-type")){
            given ($_) {
               when (m{^text/html}) { $type{'html'}++; }
               when (m{^image/}) { $type{'image'}++; }
            }
         }

         if ($type{'html'}) {
            my $response = $ua->request(
               HTTP::Request->new(GET => $uri)
            );
            my $content = $response->decoded_content;
            $content =~ m{.*<title[^>]*>(.*?)</title.*}i;
            $bot->SendGroupMessage($msg{'reply_to'},
               "$from: title: $1");
         } elsif ($type{'image'}) {
            $bot->SendGroupMessage($msg{'reply_to'},
               "$from: Content-Length: " .
               $response->header('Content-Length') . " байт.");
         } else {
            $bot->SendGroupMessage($msg{'reply_to'},
               "$from: да ну нафиг это парсить...");
         }
      }

      default {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: how about no, братиша?") if $to_me;
      }
   }
}

my %forum_list;
$forum_list{$_} = [] for keys %forum_passwords; # [] due to Bot.pm.patch

my $bot = Net::Jabber::Bot->new(
   server => $server,
   conference_server => $conference_server,
   port => $port,
   username => $username,
   password => $password,
   alias => $name,
   resource => $name,
   safety_mode => 1,
   message_function => \&new_bot_message,
   background_function => \&background_checks,
   loop_sleep_time => $loop_sleep_time,
   forums_and_responses => \%forum_list,
   forums_passwords => \%forum_passwords,
);

$bot->Start();
