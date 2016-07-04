#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package keywords;

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

         return (1, 0, "убунта нинужна >_<") if int(2*rand);
      }

      when (/(?:perl|перл)/i) {

         return (1, 0, "папа ^_^") if int(2*rand);
      }

      when (m{(^\S+?: |\s|\b|^)(?:man|ман|[mм])[: ]/?/?([a-z0-9-._]+)}i) {
         return (0, undef) unless defined $2;

         return (1, 0, "$1https://www.freebsd.org/cgi/man.cgi?query=$2");
      }

      when (/^(?:(?:добро|все|ребя)\w*)*\s*утр/i || /^утр\w*\s*[.!]*\s*$/i) {

         return (1, 1, "и тебе доброе утро!");
      }

      when (/^ку[\s!]*\b/i || /^(?:всем\s*)?приве\w*[.\s!]*$/i ||
         /^здаро\w*\s*/) {

         return (1, 0, "Привет, привет!");
      }

      when (/^пыщь?(?:-пыщь?)?[.\s!]*$/i) {

         return (1, 1, "пыщь-пыщь, ололо, я -- водитель НЛО!");
      }

      when (/^(?:доброй|спокойной|всем)?\s*ночи[.\s!]*$/i ||
         /^[\w.,\s]*[шс]пать[.\s!]*$/i) {

         return (1, 0, "Сладких снов!");
      }

   }

   return (0, 0, undef); # it's not a keyword
}

1;
