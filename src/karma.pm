#!/usr/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package karma;

use Storable;
use DB_File;
use Encode qw;encode decode is_utf8;;

my $karmafile     = '/tmp/karma';
my %karma_db      = ();
my $reject_time   = 7;
my $last_like_max = 3;
my %last_like;

my $initialized   = 0;

# arg: self cfg_file karma_file
sub new($$;$) {
   my $self = shift;
   my $config_file = shift // die 'No karma config specified';
   my $arg_file = shift;

   our %cfg;

   unless (my $rc = do $config_file) {
      warn "couldn't parse $config_file: $@" if $@;
      warn "couldn't do $config_file: $!" unless defined $rc;
      warn "couldn't run $config_file" unless $rc;
   }

   $karmafile     = $cfg{karmafile} if defined $cfg{karmafile};
   $karmafile     = $arg_file if defined $arg_file;
   $last_like_max = $cfg{last_like_max} if defined $cfg{last_like_max};
   $reject_time   = $cfg{karma_reject_time} if defined $cfg{karma_reject_time};

   tie (
      %karma_db, "DB_File", "$karmafile.db", O_CREAT | O_RDWR, 0666, $DB_BTREE
   ) or die $!;

   say "Karma records: " . keys %karma_db if scalar keys %karma_db;

   $initialized = 1;
   return bless {}, $self;
}

# arg: self top_count
sub get_top($$) {
   my $top = '';
   my $self = shift;

   my $topN = shift // 10;
   $topN = 10 if $topN eq "" || $topN < 1 || $topN > 25;
   $topN = keys %karma_db if $topN > keys %karma_db;

   $top .= "$_($karma_db{$_}), " for (
      sort {$karma_db{$b} <=> $karma_db{$a}} keys %karma_db
   )[0..$topN-1];
   $top =~ s/, $//;

   $top = decode('utf-8', $top) unless is_utf8($top);

   return $top;
}

# internal function
# arg: src dst
sub allowed_like {
   my ($src, $dst) = @_;
   return 0 unless defined $dst;
   $src = lc $src;
   $dst = lc $dst;

   # needs to be cleverer
   if (exists $last_like{$src}) {
      for (keys %{ $last_like{$src} }) {
         delete $last_like{$src}->{$_} if (
            time - $last_like{$src}->{$_} > $reject_time
         );
      }

      if ($last_like_max <= keys %{ $last_like{$src} }) {
         return 0;
      } else {
         my $rc = ! defined $last_like{$src}->{$dst};

         $last_like{$src}->{$dst} = time;

         return $rc;
      }
   } else {
      $last_like{$src}->{$dst} = time;
      return 1;
   }

   return 0; # just because
}

# arg: self src dst
sub get_karma($$;$) {
   my $self = shift;
   my $src  = shift // return -1;
   my $dst  = shift // $src;

   my $karma = $karma_db{encode 'utf-8', lc $dst} ||= 0;

   return "твоя карма: $karma" if $src eq $dst;
   return "карма $dst $karma";
}

# arg: self src dst
sub inc_karma($$$) {
   my $self = shift;
   my $src  = shift;
   my $dst  = shift // return -1;

   return "пффф" if $dst eq $src;

   # and memorize src -> dst
   return "нельзя изменять карму так часто!" unless
   allowed_like($src, $dst);

   my $rc = ++$karma_db{encode 'utf-8', lc $dst};

   return "поднял карму $dst до $rc";
}

# arg: self src dst
sub dec_karma($$$) {
   my $self = shift;
   my $src  = shift;
   my $dst  = shift // return -1;

   return "пффф" if $dst eq $src;

   return "нельзя изменять карму так часто!" unless
   allowed_like($src, $dst);

   my $rc = --$karma_db{encode 'utf-8', lc $dst};

   return "опустил карму $dst до $rc";
}

1;
