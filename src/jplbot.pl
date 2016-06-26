#!/usr/local/bin/perl
# made by: KorG
use strict;
use v5.18;
use utf8;
use warnings;
no warnings 'experimental';

use Net::Jabber::Bot;
use Storable;
use LWP;

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
my $name      = $cfg{name}         // 'AimBot';
my $karmafile = $cfg{karmafile}    // '/tmp/karma';
my $saytofile = $cfg{saytofile}    // '/tmp/sayto';
my $tome_file = $cfg{tome_file}    // '/tmp/tome.txt';
my $sayto_keep_time = $cfg{sayto_keep_time}             // 604800;
my $sayto_max = $cfg{sayto_max}    // 128;
my $server    = $cfg{server}       // 'zhmylove.ru';
my $port      = $cfg{port}         // 5222;
my $username  = $cfg{username}     // 'aimbot';
my $password  = $cfg{password}     // 'password';
my $max_messages_per_hour = $cfg{max_messages_per_hour} // 7200;
my $loop_sleep_time    = $cfg{loop_sleep_time}          // 60;
my $conference_server  = $cfg{conference_server} // 'conference.jabber.ru';
my %room_passwords     = %{ $cfg{room_passwords} // {
   'ubuntulinux' => 'ubuntu'
}};
my $last_like_max      = $cfg{last_like_max}            // 3;
my $colors_minimum     = $cfg{colors_minimum}           // 3;
my @colors             = @{ $cfg{colors}                // [
   'бело-оранжевый', 'оранжевый',
   'бело-зелёный', 'зелёный',
   'бело-синий', 'синий',
   'бело-коричневый', 'коричневый',
]};

store {}, $karmafile unless -r $karmafile;
store {}, $saytofile unless -r $saytofile;
my %karma = %{retrieve($karmafile)};
my %sayto = %{retrieve($saytofile)};
say "Karma records: " . keys %karma if scalar keys %karma;
say "Sayto records: " . keys %sayto if scalar keys %sayto;
my $tome = tome->new($config_file);
$tome->read_tome_file($tome_file);

my %jid_DB = ();
my %bomb_time;
my %bomb_correct;
my %bomb_resourse;
my %bomb_nick;
my %bomb_jid;
my $last_bomb_time = 0;
my %last_like;
my $col_count = int($colors_minimum + ($#colors - $colors_minimum + 1) * rand);
my %col_hash;
my %room_list;
$col_hash{lc($_)} = 1 for @colors;
$room_list{$_} = [] for keys %room_passwords; # [] due to Bot.pm.patch

my $start_time = time;
my $qname = quotemeta($name);
my $bot_address = "https://github.com/tune-it/jplbot"; # kinda copyleft
my $rsymbols = "\x{20}\x{22}\x{26}\x{27}\x{2f}\x{3a}\x{3c}\x{3e}\x{40}";
my $rb = "[$rsymbols]";
my $rB = "[^$rsymbols]";
my $debug_request = 0;

$SIG{'INT'} = \&shutdown;
$SIG{'TERM'} = \&shutdown;
$SIG{'USR1'} = \&debug;
$SIG{'USR2'} = \&save_data;
binmode STDOUT, ':utf8';
srand;

sub debug {
   $DB::single = 1;
   $debug_request = 1;

   return # for debugging purposes
}

sub save_data {
   store \%karma, $karmafile and say "Karma saved to: $karmafile";
   store \%sayto, $saytofile and say "Sayto saved to: $saytofile";

   $tome->save_tome_file();
}

sub get_jid {
   my $room = shift // '.';
   my $nick = shift // '.';

   return $nick unless defined $jid_DB{"jid_$room"};
   return $jid_DB{"jid_$room"}->{$nick} // $nick;
}

sub shutdown {
   save_data

   say "Uptime: " . (time - $start_time);

   exit 0;
}

sub say_to {
   my ($bot, $room, $nick) = @_;
   my $dst = lc $nick;

   return unless (defined $sayto{$room} && defined $sayto{$room}->{$dst});

   foreach my $src (keys $sayto{$room}->{$dst}) {
      $bot->SendPersonalMessage("$room\@$conference_server/$nick",
         "Тебе писал $src: [" . $sayto{$room}->{$dst}->{$src}->{'text'} . "]");

      delete $sayto{$room}->{$dst}->{$src};

      delete $sayto{$room}->{$dst} unless scalar keys $sayto{$room}->{$dst};
   }
}

sub allowed_like {
   my ($src, $dst) = @_;
   return 0 unless defined $dst;

   if (exists $last_like{$src}) {
      if (exists $last_like{$src}->{$dst}) {
         return 0;
      } else {
         if ($last_like_max <= keys $last_like{$src}) {
            return 0;
         } else {
            $last_like{$src}->{$dst} = 1;
            return 1;
         }
      }
   } else {
      $last_like{$src}->{$dst} = 1;
      return 1;
   }

   return 0; # just because
}

sub give_role {
   my ($bot, $dst, $nick, $role) = @_;

   my $xml = "<iq from='$username\@$server/$name' id='korg1' to='$dst' " .
   "type='set'><query xmlns='http://jabber.org/protocol/muc#admin'><item " .
   "nick='$nick' role='$role'></item></query></iq>";

   $bot->jabber_client->SendXML($xml);
}

sub bomb_user {
   my ($bot, $user) = @_;
   my $dst = $bomb_resourse{lc($user)};
   my $room = (split '@', $dst)[0];
   my $nick = $bomb_nick{lc($user)};
   my $jid = $bomb_jid{lc($user)};

   delete $bomb_time{lc($user)};
   delete $bomb_correct{lc($user)};
   delete $bomb_resourse{lc($user)};
   delete $bomb_nick{lc($user)};
   delete $bomb_jid{lc($user)};

   return unless $bot->IsInRoomJid($room, $jid);

   $bot->SendGroupMessage($dst,
      "Детка, только дай мне повод и я взорву для тебя весь город!");

   my $current = '';
   foreach (keys $jid_DB{"jid_$room"}) {
      $current = $_ if $jid_DB{"jid_$room"}->{$_} eq $jid;
   }
   $current =~ s/'/\&apos;/g;

   give_role($bot, $dst, $current, 'none');
}

sub background_checks {
   my $bot = shift;
   store \%karma, $karmafile;

   foreach(keys %bomb_time){
      bomb_user($bot, $_) if (time >
         $bomb_time{lc($_)} + $loop_sleep_time);
   }

   foreach my $room (keys %room_passwords) {
      foreach my $dst (keys $sayto{$room}) {
         foreach my $src (keys $sayto{$room}->{$dst}) {
            delete $sayto{$room}->{$dst}->{$src} if ( time >
               $sayto{$room}->{$dst}->{$src}->{'time'} + $sayto_keep_time
            );
         }

         delete $sayto{$room}->{$dst} unless scalar keys $sayto{$room}->{$dst};
      }
   }

   undef %last_like;
}

sub new_bot_message {
   my %msg = @_;

   $DB::single = 1 if $debug_request;

   my $bot = $msg{'bot_object'};

   my ($resource, $src) = split '/', $msg{'from_full'};
   my $room = (split '@', $resource)[0];

   if ($msg{'body'} =~ s{^$qname: }{}) {
      my $rndkey = $tome->message($msg{'body'});

      $bot->SendGroupMessage($msg{'reply_to'},
         # you require more random values
         "$src: $rndkey"
      ) if ($rndkey);

      return;
   }

   if ($msg{'type'} eq "chat") {
      if ($msg{'body'} eq "voice" || $msg{'body'} eq "голос") {
         give_role($bot, $resource, $src, 'participant');
         $bot->SendPersonalMessage($msg{'reply_to'}, "Вам предоставлен голос");
         return;
      }

      $bot->SendPersonalMessage($msg{'reply_to'},
         "Я не работаю в привате. Если Вы нашли проблему, " .
         "у Вас есть предложения или пожелания, пишите issue на $bot_address");
      return;
   }

   PARSE_MESSAGE: # for google://

   given ($msg{'body'}) {

      when (/^(?:date|дата)\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: " . localtime);
      }

      when (/^(?:time|время)\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: " . time);
      }

      when (/emacs/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "use vim or die;") if int(2*rand);
      }

      when (/sudo/) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "sudo нинужно >_<") if int(2*rand);
      }

      when (/(?:ubunt|убунт)/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "убунта нинужна >_<") if int(2*rand);
      }

      when (/(?:perl|перл)/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "папа ^_^") if int(2*rand);
      }

      when (/^(?:top|топ)\s*(\d*)\s*$/i) {
         my $top;
         my $topN = $1;

         $topN = 10 if $topN eq "" || $topN < 1 || $topN > 25;

         $top .= "$_($karma{$_}), " for (
            sort {$karma{$b} <=> $karma{$a}} keys %karma
         )[0..$topN-1];
         $top =~ s/, $//;

         $bot->SendGroupMessage($msg{'reply_to'}, $top);
      }

      when (/^help\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: я написал тебе в личку");

         $bot->SendPersonalMessage($msg{'reply_to'} . "/$src",
            "Краткая справка: \n" .
            " bomb        nick      -- установить бомбу\n" .
            " date                  -- вывести дату\n" .
            " fortune               -- вывеси цитату\n" .
            " karma       nick      -- вывести карму\n" .
            " top                   -- вывести топ по карме\n" .
            " sayto      /nick/text -- сказать пользователю\n" .
            " time                  -- вывести время\n" .
            "\n" .
            "Вопросы и предложения: $bot_address\n" .
            "В благодарность вы можете нажать Star на странице проекта. " .
            "Это совершенно бесплатно.\n" .
            "Чмоки ;-)"
         );
      }

      when (/^(?:fortune|ф)\s*$/i) {
         my $fortune = `/usr/games/fortune -s`;
         chomp $fortune;
         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: $fortune");
         sleep 1;
      }

      when (/^(?:karma|карма)\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: твоя карма: " . ($karma{lc($src)}||0));
      }

      when (/^(?:bomb|бомба)\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: бомба -- это не игрушки!");
      }

      when (m{^sayto[^/]*/([^/]*?)$rb?/(.*)$}s) {
         my $dst = $1;
         my $txt = $2;

         if (my @nick = $bot->IsInRoom($room, $dst)) {
            $bot->SendGroupMessage($msg{'reply_to'},
               "@nick: смотри, тебе пишет $src!");

            return;
         }

         if (defined $sayto{$room}) {
            if (scalar keys $sayto{$room} > $sayto_max) {
               $bot->SendGroupMessage($msg{'reply_to'},
                  "$src: у меня кончилось место :(");

               return;
            }

            if (defined $sayto{$room}->{lc($dst)}->{$src} &&
               defined $sayto{$room}->{lc($dst)}->{$src}->{'text'}) {
               $bot->SendGroupMessage($msg{'reply_to'},
                  "$src: предыдущее значение: [" .
                  $sayto{$room}->{lc($dst)}->{$src}->{'text'} .
                  "]");
            }
         }

         $sayto{$room}->{lc($dst)}->{$src} = {
            text => $txt,
            time => time,
         };

         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: замётано.");
      }

      when (m{(?:^|\s)(?:google|[гg]):/?/?(\S+)}i) {
         return unless defined $1;

         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: https://www.google.ru/search?q=$1");

         $msg{'body'} = "https://www.google.ru/search?q=$1";
         goto "PARSE_MESSAGE";
      }

      when (m{(https?://\S+)}) {
         my $uri = $1;
         my $ua = LWP::UserAgent->new();
         my %type;
         my $dead = 0;
         $ua->timeout(10);
         $ua->env_proxy;
         $ua->agent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:46.0)' .
            'Gecko/20100101 Firefox/46.0');

         $ua->add_handler(response_header => sub {
               my $response = shift;

               return if $dead;
               undef %type;

               if (scalar $response->code >= 400) {
                  $bot->SendGroupMessage($msg{'reply_to'},
                     "$src: сервер вернул код: " .
                     $response->code . ", разбирайся сам!");

                  $dead = 1;
                  return;
               }

               foreach($response->header("Content-type")){
                  given ($_) {
                     when (m{^text/html} || /korg/) { $type{'html'}++; }
                     when (m{^image/}) { $type{'image'}++; }
                  }
               }

               if ($type{'image'}) {
                  return if $response->code >= 300;

                  my $length = $response->header('Content-Length') // -1;
                  $length = -1 unless $length > 0;

                  while ($length =~ s/(?<=\d)(?=\d{3}\b)/ /){}

                  $bot->SendGroupMessage($msg{'reply_to'},
                     "$src: Content-Length: $length байт.");

                  $dead = 1;
                  return;
               }
            });

         $ua->add_handler(response_done => sub {
               my $response = shift;

               return if $dead;

               if ($type{'image'}) {
                  # do nothing for all other chunks of response
               } elsif ($type{'html'}) {
                  my $content = $response->decoded_content // '';

                  return if scalar $response->code < 200 || 
                  scalar $response->code >= 300;

                  $content =~ m{.*<title[^>]*>(.*?)</title.*}si;

                  my $title = $1 // '';

                  if ($title eq "") {
                     $title = $uri;
                     $title =~ s{^https?://([^/]+)/.*$}{$1};
                  }

                  $bot->SendGroupMessage($msg{'reply_to'},
                     "$src: заголовок: [$title]");
               } else {
                  $bot->SendGroupMessage($msg{'reply_to'},
                     "$src: да ну нафиг это парсить...");
               }
            });

         my $response = $ua->get($uri);
      }

      when (m{(^\S+?: |\s|^)(?:man|ман|[mм]):/?/?(\S+)}i) {
         return unless defined $2;

         $bot->SendGroupMessage($msg{'reply_to'},
            "$1https://www.freebsd.org/cgi/man.cgi?query=$2");
      }

      when (/^(?:(?:добро|все|ребя)\w*)*\s*утр/i || /^утр\w*\s*[.!]*\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: и тебе доброе утро!");
      }

      when (/^ку[\s!]*\b/i || /^(?:всем\s*)?приве\w*[.\s!]*$/i ||
         /^здаро\w*\s*/) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "Привет, привет!");
      }

      when (/^пыщь?(?:-пыщь?)?[.\s!]*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$src: пыщь-пыщь, ололо, я -- водитель НЛО!");
      }

      when (/^(?:доброй|спокойной|всем)?\s*ночи[.\s!]*$/i ||
         /^[\w.,\s]*[шс]пать[.\s!]*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "Сладких снов!");
      }

      when (sub{return $col_hash{lc($_)} || 0}) {
         return unless defined $bomb_correct{lc($src)};

         if ($bomb_correct{lc($src)} eq $msg{'body'}) {
            delete $bomb_time{lc($src)};
            delete $bomb_correct{lc($src)};
            delete $bomb_resourse{lc($src)};
            delete $bomb_nick{lc($src)};
            delete $bomb_jid{lc($src)};

            $bot->SendGroupMessage($msg{'reply_to'},
               "$src, расслабься, это был всего-лишь розыгрыш!");
         } else {
            bomb_user($bot, $src);
         }
      }

      default {
         # manual check for nick presence, performance hack
         foreach my $nick (keys $jid_DB{$room}) {
            my $qnick = quotemeta($nick);

            if (" $msg{body} " =~ m{$rb$qnick$rb}i) {

               given ($msg{'body'}) {

                  when (/^(?:karma|карма)$rb*?$qnick\s*?$/i) {
                     $bot->SendGroupMessage($msg{'reply_to'},
                        "$src: карма $nick " . ($karma{lc($nick)}||0));
                  }

                  when (/^(?:bomb|бомба)$rb*?$qnick\s*?$/i) {
                     if ($src eq $nick) {
                        $bot->SendGroupMessage($msg{'reply_to'},
                           "$src: привык забавляться сам с собой?");

                        return;
                     }

                     if ($src eq $name) {
                        $bot->SendGroupMessage($msg{'reply_to'},
                           "$src: отказать.");

                        return;
                     }

                     if (defined $bomb_time{lc($nick)}) {
                        $bot->SendGroupMessage($msg{'reply_to'},
                           "$src: на $nick уже установлена бомба.");

                        return;
                     }

                     if (abs(time - $last_bomb_time) < 180) {
                        $bot->SendGroupMessage($msg{'reply_to'},
                           "$src: you require more vespene gas!");

                        return;
                     }

                     $last_bomb_time = time;

                     my %selected_colors;
                     while($col_count != keys %selected_colors){
                        $selected_colors{$colors[rand $#colors]} = 1;
                     }

                     my $selected_colors_t = join ', ', (
                        sort keys %selected_colors
                     );

                     $selected_colors_t =~ s/,( \S+)$/ и$1/i;

                     $bomb_time{lc($nick)} = time;
                     $bomb_correct{lc($nick)} = (keys %selected_colors)[0];
                     $bomb_resourse{lc($nick)} = $resource;
                     $bomb_nick{lc($nick)} = $nick;
                     $bomb_jid{lc($nick)} = get_jid($room, $nick);

                     my $txt = "Привет от $src, $nick! " .
                     "Я хочу сыграть с тобой в игру.\n" .
                     "Правила очень простые. " .
                     "Всю свою жизнь ты не уважал random, " .
                     "и теперь пришло время поплатиться. \n" .
                     "На тебе бомба, из которой торчат " .
                     "$selected_colors_t провода. \n" .
                     "Твоя задача -- правильно выбрать провод. " .
                     "До взрыва осталось 1-2 минуты. Время пошло!";

                     $bot->SendGroupMessage($msg{'reply_to'}, $txt);
                  }

                  when (/^($qnick):?\s*\+[+1]+\s*$/) {
                     return if $nick eq $src;

                     unless (allowed_like lc($src), lc($nick)) {
                        $bot->SendGroupMessage($msg{'reply_to'},
                           "$src: нельзя изменять карму так часто!");

                        return;
                     }

                     $karma{lc($nick)}++;
                     $bot->SendGroupMessage($msg{'reply_to'},
                        "$src: поднял карму $nick до " . $karma{lc($nick)});
                  }

                  when (/^($qnick):?\s*\-[-1]+\s*$/) {
                     return if $nick eq $src;

                     unless (allowed_like lc($src), lc($nick)) {
                        $bot->SendGroupMessage($msg{'reply_to'},
                           "$src: нельзя изменять карму так часто!");

                        return;
                     }

                     $karma{lc($nick)}--;
                     $bot->SendGroupMessage($msg{'reply_to'},
                        "$src: опустил карму $nick до " . $karma{lc($nick)});
                  }
               }

               return;
            }
         }
      }
   }
}

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
   forums_and_responses => \%room_list,
   forums_passwords => \%room_passwords,
   JidDB => \%jid_DB,
   SayTo => \&say_to,
   SayToDB => \%sayto,
   shutdown => \&save_data,
);

$bot->max_messages_per_hour($max_messages_per_hour);
$bot->Start();
