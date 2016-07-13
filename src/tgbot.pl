#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

use WWW::Telegram::BotAPI;
use Storable;

use tome;
use keywords;
use karma;

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
my $karma_tg_file = $cfg{karma_tg_file}   // '/tmp/karma_tg';
my $tg_count_file = $cfg{tg_count_file}   // '/tmp/count_tg';

my $tg = WWW::Telegram::BotAPI->new(token=>$token);
die "Name mismatch: $name" if $name ne $tg->getMe->{result}{first_name};

my $tome = tome->new($config_file);
$tome->read_tome_file($tome_tg_file);

my $karma = karma->new($config_file, $karma_tg_file);

my $start_time = time;
my $offset  = 0;
my $updates = 0;

store {}, $tg_count_file unless -r $tg_count_file;
my %chat_counter = %{retrieve($tg_count_file)};

$SIG{'INT'} = \&shutdown;
$SIG{'TERM'} = \&shutdown;
$SIG{'USR2'} = \&save_data;
srand;

sub save_data {
   $tome->save_tome_file();
   $karma->save_karma_file();

   store \%chat_counter, $tg_count_file and
   say "Counters saved to: $tg_count_file";
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
      my $is_reply = 0;
      my $repl_author = '';

      my $chat = join " ", (
         $upd->{message}{chat}{type},
         $upd->{message}{chat}{username} // '',
         $upd->{message}{chat}{title} // ''
      );
      $chat_counter{$chat}++;

      next unless (my $text = $upd->{message}{text});

      my $src = join '=', (
         $upd->{message}{from}{first_name},
         $upd->{message}{from}{last_name} // '',
         $upd->{message}{from}{username} // ''
      );

      if (defined $upd->{message}{reply_to_message}) {
         $is_reply = 1;

         $process = 1 if (
            $upd->{message}{reply_to_message}{from}{first_name} eq $name
         );

         $repl_author = join '=', (
            $upd->{message}{reply_to_message}{from}{first_name},
            $upd->{message}{reply_to_message}{from}{last_name} // '',
            $upd->{message}{reply_to_message}{from}{username} // ''
         );
      }

      $text =~ s@^/(.*?)(?:$tg_name)?$@$1@i;

      if (
         $text =~ s/^[бb](от|ot)?$//i ||
         $text =~ s/^$name(?:[,:])\s*//i ||
         $text =~ s/^$tg_name(?:[,:])?\s*//i ||
         $process
      ) {
         $tg->sendMessage({
               chat_id => $upd->{message}{chat}{id},
               reply_to_message_id => $upd->{message}{message_id},
               text => $tome->message($text)
            });

         next;
      }

      my ($keyword, $personal, $reply) = keywords->parse($text);
      if ($keyword) {
         my @reply_to_message_id = (
            reply_to_message_id => $upd->{message}{message_id}
         ) if $personal;

         $tg->sendMessage({
               chat_id => $upd->{message}{chat}{id},
               @reply_to_message_id,
               text => $reply
            });

         next;
      }

      given ($text) {
         when (/^(?:top|топ)\s*(\d*)\s*$/i) {
            my $top = $karma->get_top($1) || 'Пустота...';

            $top =~ s/=[^=\s,]*?([()\s,])/$1/g;
            $top =~ s/=/ /g;

            $tg->sendMessage({
                  chat_id => $upd->{message}{chat}{id},
                  text => $top
               });
         }

         when (/^(?:karma|карма)\s*$/i) {
            my $karma = $karma->get_karma($src);

            $tg->sendMessage({
                  chat_id => $upd->{message}{chat}{id},
                  reply_to_message_id => $upd->{message}{message_id},
                  text => ucfirst($karma)
               });
         }

         when (/^\s*\+[+1]+\s*$/i) {
            next unless $is_reply;

            my $text = $karma->inc_karma($src, $repl_author);
            $text =~ s/=[^=\s]*\s/ /;
            $text =~ s/(?:\s=|=\s)/ /;
            $text =~ s/=/ /g;

            $tg->sendMessage({
                  chat_id => $upd->{message}{chat}{id},
                  reply_to_message_id => $upd->{message}{message_id},
                  text => ucfirst($text)
               });
         }

         when (/^\s*\-[-1]+\s*$/i) {
            next unless $is_reply;

            my $text = $karma->dec_karma($src, $repl_author);
            $text =~ s/=[^=\s]*\s/ /;
            $text =~ s/(?:\s=|=\s)/ /;
            $text =~ s/=/ /g;

            $tg->sendMessage({
                  chat_id => $upd->{message}{chat}{id},
                  reply_to_message_id => $upd->{message}{message_id},
                  text => ucfirst($text)
               });
         }
      }
   }
}
