#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

use WWW::Telegram::BotAPI;

use tome;

my $config_file = './config.pl';
our %cfg;

unless (my $rc = do $config_file) {
   warn "couldn't parse $config_file: $@" if $@;
   warn "couldn't do $config_file: $!" unless defined $rc;
   warn "couldn't run $config_file" unless $rc;
}

# DEFAULT VALUES. don't change them here
# see comments in the 'config.pl'
my $name          = $cfg{name}            // 'AimBot';
my $tg_name       = $cfg{tg_name}         // '@korg_bot';
my $token         = $cfg{token}           // 'token';
my $tome_tg_file  = $cfg{tome_tg_file}    // '/tmp/tome_tg.txt';

my $tg = WWW::Telegram::BotAPI->new(token=>$token);
die "Name mismatch: $name" if $name ne $tg->getMe->{result}{first_name};

my $tome = tome->new($config_file);
$tome->read_tome_file($tome_tg_file);

my $start_time = time;
my $offset  = 0;
my $updates = 0;

$SIG{'INT'} = \&shutdown;
$SIG{'TERM'} = \&shutdown;
$SIG{'USR2'} = \&save_data;
srand;

sub save_data {
   $tome->save_tome_file();
}

sub shutdown {
   save_data

   say "Uptime: " . (time - $start_time);

   exit 0;
}

for(;;) {
   $updates = $tg->getUpdates ({
         timeout => 30,
         $offset ? (offset => $offset) : ()
      });

   next unless (defined $updates && $updates &&
      (ref $updates eq "HASH") && $updates->{ok});

   for my $upd (@{ $updates->{result} }) {
      $offset = $upd->{update_id} + 1 if $upd->{update_id} >= $offset;
      my $process = 0;

      if (defined $upd->{message}{reply_to_message}) {
         next if $upd->{message}{reply_to_message}{from}{first_name} ne $name;
         $process = 1;
      }

      next unless (my $text = $upd->{message}{text});
      if (
         $text =~ s/^$name(?:[,:])\s*// ||
         $text =~ s/^$tg_name(?:[,:])?\s*// ||
         $process
      ) {
         $tg->sendMessage({
               chat_id => $upd->{message}{chat}{id},
               reply_to_message_id => $upd->{message}{message_id},
               text => $tome->message($text)
            });
      }
   }
}
