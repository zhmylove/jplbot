#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package karma;

use Storable;

my $karmafile     = '/tmp/karma';
my %karma         = ();
my $reject_time   = 7;
my $last_like_max = 3;
my %last_like;

my $initialized   = 0;

# arg: self cfg_file
sub new($$) {
   my $self = shift;
   my $config_file = shift // die 'No karma config specified';

   our %cfg;

   unless (my $rc = do $config_file) {
      warn "couldn't parse $config_file: $@" if $@;
      warn "couldn't do $config_file: $!" unless defined $rc;
      warn "couldn't run $config_file" unless $rc;
   }

   $karmafile     = $cfg{karmafile} if defined $cfg{karmafile};
   $last_like_max = $cfg{last_like_max} if defined $cfg{last_like_max};
   $reject_time   = $cfg{karma_reject_time} if defined $cfg{karma_reject_time};

   store {}, $karmafile unless -r $karmafile;
   %karma = %{retrieve($karmafile)};
   say "Karma records: " . keys %karma if scalar keys %karma;

   $initialized = 1;
   return bless {}, $self;
}

# arg: self
sub save_karma_file($) {
   return unless $initialized;

   store \%karma, $karmafile and say "Karma saved to: $karmafile";
}

# arg: self top_count
sub get_top($$) {
   my $top;
   my $self = shift;

   my $topN = shift // 10;
   $topN = 10 if $topN eq "" || $topN < 1 || $topN > 25;

   $top .= "$_($karma{$_}), " for (
      sort {$karma{$b} <=> $karma{$a}} keys %karma
   )[0..$topN-1];
   $top =~ s/, $//;

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
      if (defined $last_like{$src}->{$dst}) {
         return 0 if (time - $last_like{$src}->{$dst} < $reject_time);
         undef $last_like{$src}->{$dst};
      }
      if ($last_like_max <= keys $last_like{$src}) {
         return 0;
      } else {
         $last_like{$src}->{$dst} = time;
         return 1;
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

   my $karma = $karma{lc($dst)} || 0;

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

   $karma{lc($dst)}++;
   return "поднял карму $dst до " . $karma{lc($dst)};
}

# arg: self src dst
sub dec_karma($$$) {
   my $self = shift;
   my $src  = shift;
   my $dst  = shift // return -1;

   return "пффф" if $dst eq $src;

   return "нельзя изменять карму так часто!" unless
   allowed_like($src, $dst);

   $karma{lc($dst)}--;
   return "опустил карму $dst до " . $karma{lc($dst)};
}

1;
