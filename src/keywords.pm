#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package keywords;

# arg: self src txt
# ret: keyword reply
sub parse($$$) {
   my $self = shift;
   my $src = shift;
   my $txt = shift // return (0, undef);

   given ($txt) {

      when (/^(?:date|дата)\s*$/i) {

         return (1, "$src: " . localtime);
      }

      when (/^(?:time|время)\s*$/i) {

         return (1, "$src: " . time);
      }

      when (/emacs/i) {

         return (1, "use vim or die;") if int(2*rand);
      }

      when (/sudo/) {
         return (1, "sudo нинужно >_<") if int(2*rand);
      }

      when (/(?:ubunt|убунт)/i) {

         return (1, "убунта нинужна >_<") if int(2*rand);
      }

      when (/(?:perl|перл)/i) {

         return (1, "папа ^_^") if int(2*rand);
      }

      when (m{(^\S+?: |\s|^)(?:man|ман|[mм]):/?/?(\S+)}i) {
         return (0, undef) unless defined $2;

         return (1, "$1https://www.freebsd.org/cgi/man.cgi?query=$2");
      }

      when (/^(?:(?:добро|все|ребя)\w*)*\s*утр/i || /^утр\w*\s*[.!]*\s*$/i) {

         return (1, "$src: и тебе доброе утро!");
      }

      when (/^ку[\s!]*\b/i || /^(?:всем\s*)?приве\w*[.\s!]*$/i ||
         /^здаро\w*\s*/) {

         return (1, "Привет, привет!");
      }

      when (/^пыщь?(?:-пыщь?)?[.\s!]*$/i) {

         return (1, "$src: пыщь-пыщь, ололо, я -- водитель НЛО!");
      }

      when (/^(?:доброй|спокойной|всем)?\s*ночи[.\s!]*$/i ||
         /^[\w.,\s]*[шс]пать[.\s!]*$/i) {

         return (1, "Сладких снов!");
      }

   }

   return (0, undef); # it's not a keyword
}

1;
