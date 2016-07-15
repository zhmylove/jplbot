#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package keywords;

my $fortune_time = 0;

sub get_random(@) {
   return $_[rand @_];
}

# arg: self txt
# ret: keyword personal reply
sub parse($$) {
   my $self = shift;
   my $txt = shift // return (0, 0, undef);

   given ($txt) {

      when (/^(?:date|дата)\s*$/i) {

         return (1, 1, "".localtime);
      }

      when (/^(?:time|время)\s*$/i) {

         return (1, 1, "".time);
      }

      when (/emacs/i) {

         return (1, 0, "use vim or die;") if int(2*rand);
      }

      when (/sudo(?:\s+(\S+))?/i) {

         return (1, 0, "Слабо без sudo?") if (! defined $1 && int(1.25*rand));
         local $_ = $1 // "sudo";
         return (1, 0, "$_ для школоты >_<") if int(1.33*rand);
         return (1, 0, "$_ для слабых!") if int(1.5*rand);
         return (1, 0, "$_ нинужно >_<") if int(2*rand);
      }

      when (/(?:ubunt|убунт)/i) {

         my $t = get_random(
            "убунта нинужна >_<",
            "убунта? Я вас умоляю!",
            "даже LMDE лучше этой вашей убунты!",
            "убу..што? Окстись!"
         );
         return (1, 0, $t) if int(2*rand);
      }

      when (/(?:perl|перл)/i) {

         my $t = get_random(
            "папа ^_^",
            "\@zhmylove очень любит perl :3"
         );
         return (1, 0, $t) if int(2*rand);
      }

      when (m{(^\S+?[:,] |\s|^)(?:man|ман|[mм])[: ]/?/?([a-z0-9-._]+)}i) {
         return (0, undef) unless defined $2;

         return (1, 0, "$1https://www.freebsd.org/cgi/man.cgi?query=$2");
      }

      when (/^(?:(?:добро|все|ребя)\w*)*\s*утр/i || /^утр\w*\s*[.!]*\s*$/i) {

         my $t = get_random(
            "и тебе доброе утро!",
            "добрейшего тебе предрассветного утра!",
            "какое утро?! Солнце ещё высоко!"
         );
         return (1, 1, $t);
      }

      when (/^ку[\s!]*\b/i || /^(?:всем\s*)?приве?\w*[.\s!]*$/i ||
         /^здаро\w*\s*/i) {

         my $t = get_random(
            "Привет, привет!",
            "Хаюшки!",
            "Приветствую тебя!",
            "Низкий Вам поклон!"
         );
         return (1, 0, $t);
      }

      when (/^пыщь?(?:-пыщь?)?[.\s!]*$/i) {

         return (1, 1, "пыщь-пыщь, ололо, я -- водитель НЛО!");
      }

      when (/^(?:доброй|спокойной|всем|спок)?\s*ночи?[.\s!]*$/i ||
         /^[\w.,\s]*[шс]пать[.\s!]*$/i) {

         return (1, 0, "Сладких снов!");
      }

      when (/^(?:fortune|ф)\s*$/i) {
         return (0, 0, undef) if (time - $fortune_time < 2);
         $fortune_time = time;

         chomp (my $fortune = `/usr/games/fortune -s`);

         return (1, 1, $fortune);
      }

   }

   return (0, 0, undef); # it's not a keyword
}

1;
