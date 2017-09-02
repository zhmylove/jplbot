#!/usr/bin/perl
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
use tran;
use xlate;
use sweets;

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
my $yandex_api    = $cfg{yandex_api}      // 'yandex_api';

my $tg = WWW::Telegram::BotAPI->new(token=>$token);
die "Name mismatch: $name" if $name ne $tg->getMe->{result}{first_name};

my $tome = tome->new($config_file);
$tome->read_tome_file($tome_tg_file);

my $karma = karma->new($config_file, $karma_tg_file);

my $tran = tran->new($yandex_api);

my $start_time = time;
my $offset  = 0;
my $updates = 0;
my $starting = 1;
my $lastmsg = '';

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
   save_data;

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

      if ($starting) {
         next unless (($upd->{message}{date} // 0) >= $start_time);
         $starting = 0;
      }

      my $process = 0;
      my $is_reply = 0;
      my $repl_author = '';

      my $chat = join " ", (
         $upd->{message}{chat}{type} // '',
         $upd->{message}{chat}{username} // '',
         $upd->{message}{chat}{title} // ''
      );
      $chat_counter{$chat}++;

      if (defined $upd->{message}{new_chat_member}) {
         $tg->sendMessage({
               chat_id => $upd->{message}{chat}{id},
               text =>
               "En taro " . $upd->{message}{new_chat_member}{first_name} . "!"
            });

         next;
      }

      next unless (my $text = $upd->{message}{text});

      # highest priority for layout quickfix message
      if ($text =~ /^!!\s*(.*)/) {
         $lastmsg = $1 || $lastmsg;

         $tg->sendMessage({
               chat_id => $upd->{message}{chat}{id},
               text => xlate->cry($lastmsg) || next
            });
         next;
      }

      $lastmsg = $text;

      $tg->sendMessage({
            chat_id => $upd->{message}{chat}{id},
            text => $tome->message('')
         }) unless ($chat_counter{$chat} % 256);

      next if defined $upd->{message}{forward_date};

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
         $text =~ s/^[бb](от|ot)?(?:\s*$|\s*[,?:!]\s*)//i ||
         $text =~ s/^$name(?:[,:]|\b)\s*//i ||
         $text =~ s/^$tg_name(?:[,:]|\b)?\s*//i ||
         $process ||
         $text =~ s/[,\s](?<cleanup>бот|bot)(?:[ау]|ом|ов)?(?:[,?:!\s]|$)//i
      ) {
         $text = '' if $+{cleanup};

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

         when (m{(?:(?<b>^)|\s)(?:google|[гg]):/?/?((?(<b>)\S.*|\S+))}i) {
            next unless defined $2;

            my $text = $2;
            $text =~ s/\s+/+/g;
            $tg->sendMessage({
                  chat_id => $upd->{message}{chat}{id},
                  text => "https://www.google.ru/search?q=$text"
               });
         }

         when (/^!\s*(\S.*)/) {
            my $text = $tran->translate($1);
            next unless $text;

            $tg->sendMessage({
                  chat_id => $upd->{message}{chat}{id},
                  reply_to_message_id => $upd->{message}{message_id},
                  text => ucfirst($text)
               });
         }

         when (/^\s*\/(?:suicide|суицид)\s*$/i) {
            my $chat = $upd->{message}{chat}{id};
            my $user = $upd->{message}{from}{id};
            my $mesg = "Ах, какая жалость!";

            # Warning: bot must have adminstrator rights in a chat.
            # If something went wrong, check updates/settings recommendation
            # on the following link:
            # https://core.telegram.org/bots/api#kickchatmember
            $tg->kickChatMember ({ chat_id => $chat, user_id => $user });
            $tg->unbanChatMember({ chat_id => $chat, user_id => $user });
            $tg->sendMessage    ({ chat_id => $chat, text    => $mesg });
         }

         # sudden joke from bot
         when (/\b(?:(?:ba|k|z|c)?sh|joke)\b/i) {
            my $chat = $upd->{message}{chat}{id};
            my $joke = sweets->fetch_xkcdb_joke || 
                        "Ой, как-то не выходит пошутить";
            $tg->sendMessage({ chat_id => $chat, text => $joke });
         }

         when (/\b(?:баш|шутк(?:а|у))\b/i) {
            my $chat = $upd->{message}{chat}{id};
            my $joke = sweets->fetch_bash_joke || 
                        "Ой, как-то не выходит пошутить";
            $tg->sendMessage({ chat_id => $chat, text => $joke });
         }

         when (/^\s*(?:weather|погода)(?:\s+(.*?))?\s*$/i) {
            my $chat = $upd->{message}{chat}{id};
            my $city = $1;
            my $url  = sweets->get_weather_image_url($city);
            $tg->sendPhoto({ chat_id => $chat, photo => $url });
         }
      }
   }
}
