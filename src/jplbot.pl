#!/usr/local/bin/perl
# made by: KorG
use strict;
use warnings;
use v5.18;
no warnings 'experimental';
use utf8;

use Net::Jabber::Bot;
use Storable;
use LWP;

# DEFAULT VALUES, don't change them here
# See comments in the 'config.pl'
our $name = 'AimBot';
our $karmafile = '/tmp/karma';
our $server = 'zhmylove.ru';
our $port = 5222;
our $username = 'aimbot';
our $password = 'password';
our $loop_sleep_time = 60;
our $conference_server = 'conference.jabber.ru';
our %forum_passwords = ('ubuntulinux' => 'ubuntu');
our @colors = (
   'бело-оранжевый', 'оранжевый',
   'бело-зелёный', 'зелёный',
   'бело-синий', 'синий',
   'бело-коричневый', 'коричневый',
);
our $minimum_colors = 3;

unless (my $ret = do './config.pl') {
   warn "couldn't parse config.pl: $@" if $@;
   warn "couldn't do config.pl: $!" unless defined $ret;
   warn "couldn't run config.pl" unless $ret;
}

srand;
store {}, $karmafile unless -r $karmafile;
my %karma = %{retrieve($karmafile)};
my $last_bomb_time = 0;
my %bomb_time;
my %bomb_correct;
my %bomb_resourse;
my %bomb_nick;
my $col_count = int($minimum_colors + ($#colors - $minimum_colors + 1) * rand);
my %col_hash;
$col_hash{lc($_)} = 1 for @colors;

my $qname = quotemeta($name);
$SIG{INT} = \&shutdown;
$SIG{TERM} = \&shutdown;
binmode STDOUT, ':utf8';
my $bot_address = "https://github.com/tune-it/jplbot";

sub shutdown {
   store \%karma, $karmafile and say "Karma saved to: $karmafile";
   exit 0;
}

sub bomb_user {
   my ($bot, $user) = @_;
   my $to = $bomb_resourse{lc($user)};
   my $nick = $bomb_nick{lc($user)};

   delete $bomb_time{lc($user)};
   delete $bomb_correct{lc($user)};
   delete $bomb_resourse{lc($user)};
   delete $bomb_nick{lc($user)};

   $bot->SendGroupMessage($to, "$nick: ты взорвался!");

   my $xml = "<iq from='$username\@$server/$name' id='korg1' to='$to' " .
   "type='set'><query xmlns='http://jabber.org/protocol/muc#admin'><item " .
   "nick='$nick' role='none'><reason>Bombed!</reason></item></query></iq>";

   $bot->jabber_client->SendXML($xml);
}

sub background_checks {
   my $bot = shift;
   store \%karma, $karmafile;
   foreach(keys %bomb_time){
      bomb_user($bot, $_) if (time > $bomb_time{lc($_)} + 60);
   }
}

sub new_bot_message {
   my %msg = @_;
   my $bot = $msg{'bot_object'};

   my $from = $msg{'from_full'};
   $from =~ s{^.+/([^/]+)$}{$1};

   my $resourse = $msg{'from_full'};
   $resourse =~ s{^(.+)/[^/]+$}{$1};

   my $to_me = ($msg{'body'} =~ s{^$qname: }{});

   if ($msg{'type'} eq "chat") {
      $bot->SendPersonalMessage($msg{'reply_to'},
         "Я не работаю в привате. Если Вы нашли проблему, у Вас есть предложения или " .
         "пожелания, пишите issue на $bot_address");
      return;
   }

   given ($msg{'body'}) {

      when (/^date\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: " . localtime);
      }

      when (/^time\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: " . time);
      }

      when (/(?:ubunt|убунт)/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "убунта нинужна >_<") if int(2*rand);
      }

      when (/^(?:(?:добро|все|ребя)\w*)*\s*утр/i || /^утр\w*\s*[.!]*\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: и тебе доброе утро!");
      }

      when (/^ку[\s!]*\b/i || /^(?:всем\s*)?прив\w*[.\s!]*$/i ||
         /^здаро\w*\s*/) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "Привет, привет!");
      }

      when (/^пыщь?(?:-пыщь?)?[.\s!]*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: пыщь-пыщь, дави прыщь!");
      }

      when (/^(?:доброй|спокойной|всем)?\s*ночи[.\s!]*$/i ||
         /^[\w.,\s]*[шс]пать[.\s!]*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "Сладких снов!");
      }

      when (/^help\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: пробуй так: bomb date fortune karma time");
      }

      when (/^fortune\s*$/i) {
         my $fortune = `/usr/games/fortune -s`;
         chomp $fortune;
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: $fortune");
         sleep 1;
      }

      when (/^karma\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: твоя карма: " . ($karma{lc($from)}||0));
      }

      when (/^karma\s*(\S+)$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: карма $1: " . ($karma{lc($1)}||0));
      }

      when (/^bomb\s*$/i) {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: бомба -- это не игрушки!");
      }

      when (/^bomb\s*(\S+)$/i) {
         my $name = $1;

         if ($from eq $name) {
            $bot->SendGroupMessage($msg{'reply_to'},
               "$from: привык забавляться сам с собой?");
            return;
         }

         if (defined $bomb_time{lc($name)}) {
            $bot->SendGroupMessage($msg{'reply_to'},
               "$from: на $name уже установлена бомба.");
            return;
         }

         if (abs(time - $last_bomb_time) < 180) {
            $bot->SendGroupMessage($msg{'reply_to'},
               "$from: у меня ещё не восполнен боезапас. Жди.");
            return;
         }

         $last_bomb_time = time;

         my %selected_colors;
         while($col_count != keys %selected_colors){
            $selected_colors{$colors[int($#colors * rand)]} = 1;
         }

         my $selected_colors_t = join ', ', (sort keys %selected_colors);

         $selected_colors_t =~ s/,( \S+)$/ и$1/i;

         $bomb_time{lc($name)} = time;
         $bomb_correct{lc($name)} = (keys %selected_colors)[0];
         $bomb_resourse{lc($name)} = $resourse;
         $bomb_nick{lc($name)} = $name;

         my $txt = "Привет от $from, $name! Я хочу сыграть с тобой в игру.\n" .
         "Правила очень простые. Всю свою жизнь ты не уважал random, " .
         "и теперь пришло время поплатиться. \n" .
         "На тебе бомба, из которой торчат " .
         "$selected_colors_t провода. \n" .
         "Твоя задача -- правильно выбрать провод. " .
         "До взрыва осталось 1-2 минуты. Время пошло!";

         $bot->SendGroupMessage($msg{'reply_to'}, $txt);
      }

      when (/^(\w+):\s*\+[+1]+\s*$/) {
         return if $1 eq $from;
         $karma{lc($1)}++;
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: поднял карму $1 до " . $karma{lc($1)});
      }

      when (/^(\w+):\s*\-[-1]+\s*$/) {
         return if $1 eq $from;
         $karma{lc($1)}--;
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: опустил карму $1 до " . $karma{lc($1)});
      }

      when (m{(https?://\S+)}) {
         my $uri = $1;
         my $ua = LWP::UserAgent->new();
         my %type;
         $ua->timeout(10);
         $ua->env_proxy;
         $ua->agent('Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:46.0)' .
            'Gecko/20100101 Firefox/46.0');

         $ua->add_handler(response_header => sub {
               my $response = shift;

               if (scalar $response->code >= 400) {
                  $bot->SendGroupMessage($msg{'reply_to'},
                     "$from: сервер вернул код: " .
                     $response->code . ", разбирайся сам!");

                  die;
               }

               foreach($response->header("Content-type")){
                  given ($_) {
                     when (m{^text/html} || /korg/) { $type{'html'}++; }
                     when (m{^image/}) { $type{'image'}++; }
                  }
               }

               if ($type{'image'}) {
                  my $length = $response->header('Content-Length');
                  $length = -1 unless $length > 0;

                  while($length=~s/(?<=\d)(?=\d{3}\b)/ /){}

                  $bot->SendGroupMessage($msg{'reply_to'},
                     "$from: Content-Length: $length байт.");

                  die;
               }
            });

         $ua->add_handler(response_done => sub {
               my $response = shift;

               if ($type{'image'}) {
                  # do nothing for all other chunks of response
               } elsif ($type{'html'}) {
                  my $content = $response->decoded_content;

                  return if scalar $response->code < 200 || 
                  scalar $response->code >= 400;

                  $content =~ m{.*<title[^>]*>(.*?)</title.*}si;

                  my $title = defined $1 ? $1 : "";

                  if ($title eq "") {
                     $title = $uri;
                     $title =~ s{^https?://([^/]+)/.*$}{$1};
                  }

                  $bot->SendGroupMessage($msg{'reply_to'},
                     "$from: заголовок: [$title]");
               } else {
                  $bot->SendGroupMessage($msg{'reply_to'},
                     "$from: да ну нафиг это парсить...");
               }
            });

         my $response = $ua->get($uri);
      }

      when (sub{return $col_hash{lc($_)} || 0}) {
         return unless defined $bomb_correct{lc($from)};

         if ($bomb_correct{lc($from)} eq $msg{'body'}) {
            delete $bomb_time{lc($from)};
            delete $bomb_correct{lc($from)};
            delete $bomb_resourse{lc($from)};
            delete $bomb_nick{lc($from)};
            $bot->SendGroupMessage($msg{'reply_to'},
               "$from, расслабься, это был всего-лишь розыгрыш!");
         } else {
            bomb_user($bot, $from);
         }
      }

      default {
         $bot->SendGroupMessage($msg{'reply_to'},
            "$from: how about NO, братиша?") if $to_me;
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
