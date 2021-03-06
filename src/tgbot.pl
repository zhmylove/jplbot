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

say localtime . " Starting TGBOT...";

# DEFAULT VALUES. don't change them here
# see comments in the 'config.pl'
my $name          = $cfg{name}            // 'AimBot';
my $tg_name       = $cfg{tg_name}         // '@korg_bot';
my $token         = $cfg{token}           // 'token';
my $tome_tg_file  = $cfg{tome_tg_file}    // '/tmp/tome_tg.txt';
my $tome_dict     = $cfg{tome_dict}       // '';
my $karma_tg_file = $cfg{karma_tg_file}   // '/tmp/karma_tg';
my $tg_count_file = $cfg{tg_count_file}   // '/tmp/count_tg';
my $yandex_api    = $cfg{yandex_api}      // 'yandex_api';
my $proxy         = $cfg{proxy}           // '';
my $local_address = $cfg{local_address}   // '';

my $tg = WWW::Telegram::BotAPI->new(token=>$token, force_lwp=>1);
die "Name mismatch: $name" if $name ne $tg->getMe->{result}{first_name};

my $ua = $tg->agent;
if (length $proxy > 0) {
   if ($ua->isa('LWP::UserAgent')) {
      require LWP::Protocol::socks;
      $ua->proxy([qw.http https.] => $proxy);
   } else {
      die "Error: $proxy LWP::UserAgent not in use!";
   }
}

$ua->local_address($local_address) if length $local_address;

my $tome = tome->new($config_file);
$tome->read_tome_file($tome_tg_file, $tome_dict);

my $karma = karma->new($config_file, $karma_tg_file);

my $tran = tran->new($yandex_api);

my $start_time = time;
my $offset  = 0;
my $updates = 0;
my $starting = 1;

store {}, $tg_count_file unless -r $tg_count_file;
my %chat_counter = %{retrieve($tg_count_file)};

$SIG{'INT'} = \&shut_down;
$SIG{'TERM'} = \&shut_down;
$SIG{'USR2'} = \&save_data;
srand;

# Ignore API errors on sendMessage
sub try_send_message {
   eval { $tg->sendMessage(@_) }
}

# Save data periodically
# a0: signal name
# rc: -
sub save_data {
   my $signum = $_[0];
   say localtime . " Saving data...";

   $karma->backup_karma() if $signum; # not when shutting down

   $tome->save_tome_file();

   store \%chat_counter, $tg_count_file and
   say "Counters saved to: $tg_count_file";
}

# Shutdown routine
# args: -
# rc: -
sub shut_down {
   save_data();

   $karma->shut_down();

   say localtime . " Uptime: " . (time - $start_time);

   exit 0;
}

for(;;) {
   eval {
      $updates = $tg->getUpdates ({
            timeout => 7,
            $offset ? (offset => $offset) : ()
         });
   };

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
         try_send_message({
               chat_id => $upd->{message}{chat}{id},
               text =>
               "En taro " . $upd->{message}{new_chat_member}{first_name} .
               "!\n" . keywords->rules($upd->{message}{chat}{username})
            });

         next;
      }

      next unless (my $text = $upd->{message}{text});

      # highest priority for layout quickfix message
      if ($text =~ /^!!\s*(.*)/) {
         my $xlate = $1 || $upd->{message}{reply_to_message}{text};
         next unless defined $xlate && length $xlate;

         try_send_message({
               chat_id => $upd->{message}{chat}{id},
               text => xlate->cry($xlate) || next
            });
         next;
      }

      unless ($chat_counter{$chat} % 256) {
         my $tome_msg = $tome->message('');

         try_send_message({
               chat_id => $upd->{message}{chat}{id},
               text => $tome_msg
            }) if length $tome_msg;
      }

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

         my $tome_msg = $tome->message($text);
         next unless length $tome_msg;

         try_send_message({
               chat_id => $upd->{message}{chat}{id},
               reply_to_message_id => $upd->{message}{message_id},
               text => $tome_msg
            });

         next;
      }

      my ($keyword, $personal, $reply) = keywords->parse($text);
      if ($keyword) {
         my @reply_to_message_id = (
            reply_to_message_id => $upd->{message}{message_id}
         ) if $personal;

         try_send_message({
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

            try_send_message({
                  chat_id => $upd->{message}{chat}{id},
                  text => $top
               });
         }

         when (/^rules\s*$/i) {

            my $rules = keywords->rules($upd->{message}{chat}{username});
            try_send_message({
                  chat_id => $upd->{message}{chat}{id},
                  text => $rules
               }) if length $rules // '';
         }

         when (/^(?:karma|карма)\s*$/i) {
            my $karma = $karma->get_karma($src);

            try_send_message({
                  chat_id => $upd->{message}{chat}{id},
                  reply_to_message_id => $upd->{message}{message_id},
                  text => ucfirst($karma)
               });
         }

         when (/^\s*\+[+1]+\s*/i) {
            next unless $is_reply;

            my $username = $upd->{message}{reply_to_message}{from}{username};
            next if defined $username && $username =~ /bot$/i;

            my $text = $karma->inc_karma($src, $repl_author);
            $text =~ s/=[^=\s]*\s(?!.*=)/ /;
            $text =~ s/(?:\s=|=\s)/ /;
            $text =~ s/=/ /g;

            try_send_message({
                  chat_id => $upd->{message}{chat}{id},
                  reply_to_message_id => $upd->{message}{message_id},
                  text => ucfirst($text)
               });
         }

         when (/^\s*(?:-[-1]+|—)\s*/i) {
            next unless $is_reply;

            my $username = $upd->{message}{reply_to_message}{from}{username};
            next if defined $username && $username =~ /bot$/i;

            my $text = $karma->dec_karma($src, $repl_author);
            $text =~ s/=[^=\s]*\s(?!.*=)/ /;
            $text =~ s/(?:\s=|=\s)/ /;
            $text =~ s/=/ /g;

            try_send_message({
                  chat_id => $upd->{message}{chat}{id},
                  reply_to_message_id => $upd->{message}{message_id},
                  text => ucfirst($text)
               });
         }

         when (m{(?:(?<b>^)|\s)(?:google|[гg]):/?/?((?(<b>)\S.*|\S+))}i) {
            next unless defined $2;

            my $text = $2;
            $text =~ s/\s+/+/g;
            try_send_message({
                  chat_id => $upd->{message}{chat}{id},
                  text => "https://www.google.ru/search?q=$text"
               });
         }

         when (/^!\s*(\S.*)/) {
            my $text = $tran->translate($1);
            next unless $text;

            try_send_message({
                  chat_id => $upd->{message}{chat}{id},
                  reply_to_message_id => $upd->{message}{message_id},
                  text => ucfirst($text)
               });
         }

         when (/^\s*(?:suicide|суицид)\s*$/i) {
            my $chat = $upd->{message}{chat}{id};
            my $user = $upd->{message}{from}{id};
            my $mesg = "Ах, какая жалость!";

            # Warning: bot must have adminstrator rights in a chat.
            # If something went wrong, check updates/settings recommendation
            # on the following link:
            # https://core.telegram.org/bots/api#kickchatmember
            eval {
               $tg->kickChatMember ({chat_id => $chat, user_id => $user});
               $tg->unbanChatMember({chat_id => $chat, user_id => $user});
            };

            try_send_message({chat_id => $chat, text => $mesg}) unless $@;
         }

         # sudden joke from bot
         when (/\b(?:(?:ba|k|z|c)?sh|joke)\b/i) {
            my $chat = $upd->{message}{chat}{id};
            my $joke = sweets->fetch_xkcdb_joke || 
                        "Ой, как-то не выходит пошутить";
            try_send_message({ chat_id => $chat, text => $joke });
         }

         when (/\b(?:баш|шутк(?:а|у))\b/i) {
            next if int(3.5*rand);

            my $chat = $upd->{message}{chat}{id};
            my $joke = sweets->fetch_bash_joke || 
                        "Ой, как-то не выходит пошутить";
            try_send_message({ chat_id => $chat, text => $joke });
         }

         when (/^\s*(?:weather|погода)(?:\s+(.*?))?\s*$/i) {
            my $chat = $upd->{message}{chat}{id};
            my $city = $1;
            my $url  = sweets->get_weather_image_url($city);
            if ($url) {
                $tg->sendPhoto({ chat_id => $chat, photo => $url });
            } else {
                try_send_message({ 
                        chat_id => $chat,
                        text    => "Поломать меня решил?!"
                    });
            }
         }
      }
   }
}
