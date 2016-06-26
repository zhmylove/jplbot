#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

package tome;

my $tome_file     = undef;
my $tome_max      = 300;
my $tome_msg_max  = 300;

my %tome;
srand;

# arg: self cfg_file
sub new($$$) {
   my $self = shift;
   my $config_file = shift // die 'No tome config specified';

   my %cfg;

   unless (my $rc = do $config_file) {
      warn "couldn't parse $config_file: $@" if $@;
      warn "couldn't do $config_file: $!" unless defined $rc;
      warn "couldn't run $config_file" unless $rc;
   }

   $tome_max = $cfg{tome_max} if defined $cfg{tome_max};
   $tome_msg_max = $cfg{tome_msg_max} if defined $cfg{tome_msg_max};

   return bless {}, $self;
}

# arg: self txt_file
sub read_tome_file($$) {
   my $self = shift;
   $tome_file = shift // die 'No tome.txt file specified';

   if (-r $tome_file) {
      open my $tome_fh, "<:utf8", $tome_file or warn "Can't open $tome_file!";
      chomp, $tome{$_} = 1 while (<$tome_fh>);
      close $tome_fh;
      say "Tome records: " . keys %tome if scalar keys %tome;
   }
}

sub save_tome_file {
   die 'No tome.txt file specified' unless defined $tome_file;

   open my $tome_fh, ">:utf8", $tome_file or warn "Can't open $tome_file!";
   say $tome_fh join "\n", keys %tome and say "Tome saved to: $tome_file";
}

# arg: self new_message
sub message($$) {
   my $self = shift;
   my $txt = shift // die 'Insufficient arguments';

   my $rndkey = (keys %tome)[rand keys %tome];
   
   if ($txt =~ m{[^\s\n]}) {
      my $txt = (split '\n', $txt)[0];

      delete $tome{ $rndkey } if (keys %tome >= $tome_max);
      $tome{$txt} = substr $txt, 0, $tome_msg_max;
   }

   return $rndkey;
}

1;
