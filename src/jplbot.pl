#!/usr/local/bin/perl
# made by: KorG
use strict;
use warnings;
use v5.18;
use utf8;
no warnings 'experimental';

use Net::Jabber::Bot;
use Storable;

my $name = 'AimBot';
my $karmafile = '/tmp/karma';

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
      default {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: how about no, братиша?") if $to_me;
      }
   }
}

my %forum_list = ('ubuntulinux' => []); # [] due to Bot.pm.patch
my %forum_passwords = ('ubuntulinux' => 'ubuntu');

my $bot = Net::Jabber::Bot->new(
   server => 'zhmylove.ru',
   conference_server => 'conference.jabber.ru',
   port => 5222,
   username => 'aimbot',
   password => 'password',
   alias => $name,
   resource => $name,
   safety_mode => 1,
   message_function => \&new_bot_message,
   background_function => \&background_checks,
   loop_sleep_time => 60,
   forums_and_responses => \%forum_list,
   forums_passwords => \%forum_passwords,
);

$bot->Start();
