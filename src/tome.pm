#!/usr/local/bin/perl
# made by: KorG

use strict;
use v5.18;
use warnings;
no warnings 'experimental';
use utf8;
binmode STDOUT, ':utf8';

=encoding utf8

=head1 NAME

B<tome> -- parser of messages, sent "to me"

=head1 SYNOPSIS

B<tome> provides a simple mechanism for intercommunication with previously
parsed messages.  The workflow of the module consists of initialization of
the B<tome> subsystem and collection of new messages to an internal database 
contemporaneously with retrieval a random messages from the history.

=head1 DESCRIPTION

The typical use case of the B<tome> module is developement of the chat bots.
You must specify a I<configuration> file and a I<database> file used to keep a
history.  These files are used to be stored in B<$config_file> and
B<$tome_file> variables respectively (L<EXAMPLES>).  A path to the 
I<configuration> file must be given as a parameter of the object's ctor.
And the I<database> file path is set during B<read_tome_file()> subroutine
call.  I<database> have to be manually saved to the appropriate file with 
B<save_tome_file()> subroutine.  Messages handler is named B<message()>.
Returned values are removed from the array as far as the limit of the
messages exceeded.  The I<configuration> could contain the variables below:

   $cfg{tome_max}       = 300;
   $cfg{tome_msg_max}   = 300;

They specifies a maximum number of saved messages per module instance and
a maximum message length.

=head1 EXAMPLES

   use tome;
   my $tome = tome->new($config_file);
   $tome->read_tome_file($tome_file);

   my $reply = $tome->message($text);

=head1 METHODS

=over

=cut

package tome;

my $tome_file     = undef;
my $tome_max      = 300;
my $tome_msg_max  = 300;

my @tome;
srand;

=item B<new($$)>

   Returns an instance of the tome object
   Argument 0 is a reference to self package
   Argument 1 is a name of the configuration file

This function is a typical constuctor, which also reads a configuration file
and sets some restrictions of the module.

=cut

sub new($$) {
   my $self = shift;
   my $config_file = shift // die 'No tome config specified';

   our %cfg;

   unless (my $rc = do $config_file) {
      warn "couldn't parse $config_file: $@" if $@;
      warn "couldn't do $config_file: $!" unless defined $rc;
      warn "couldn't run $config_file" unless $rc;
   }

   $tome_max = $cfg{tome_max} if defined $cfg{tome_max};
   $tome_msg_max = $cfg{tome_msg_max} if defined $cfg{tome_msg_max};

   return bless {}, $self;
}

=item B<read_tome_file($$)>

   Returns nothing interesting
   Argument 0 is a reference to self package
   Argument 1 is a name of the tome file

This function slurps the array of the phrases used to generate a replies.

=cut

sub read_tome_file($$) {
   my $self = shift;
   $tome_file = shift // die 'No tome.txt file specified';

   if (-r $tome_file) {
      open my $tome_fh, "<:utf8", $tome_file or warn "Can't open $tome_file!";
      chomp (@tome = <$tome_fh>);
      @tome = grep { !/^[+\s\d-]+$/ } @tome;
      close $tome_fh;
      say "Tome records: " . scalar @tome if @tome;
   }
}

=item B<save_tome_file($)>

   Returns nothing interesting
   Argument 0 is a reference to self package

This function writes the phrases array to the I<$tome_file>.

=cut

sub save_tome_file {
   die 'No tome.txt file specified' unless defined $tome_file;

   open my $tome_fh, ">:utf8", $tome_file or warn "Can't open $tome_file!";
   say $tome_fh join "\n", @tome and say "Tome saved to: $tome_file";
}

=item B<message($$)>

   Returns a text of the answer message
   Argument 0 is a reference to self package
   Argument 1 is an incoming message to parse

This function intended to parse the incoming messages and store them 
into the history array.  And in some conditions is picks a random message
saved in the array previously and uses it as a return value.

=cut

sub message($$) {
   my $self = shift;
   my $txt  = shift // die 'Insufficient arguments';
   
   my $rnd_idx = int rand scalar @tome; 
   my $rnd_msg = $tome[$rnd_idx];

   return $rnd_msg if $txt =~ m{[/@]};

   $_ eq $txt && return $rnd_msg for @tome;
   
   if ($txt =~ m{[^+\s\d-]}) {
      my $txt = (split '\n', $txt)[0];
      $txt = substr ($txt, 0, $tome_msg_max);
      if (@tome >= $tome_max) {
         $tome[$rnd_idx] = $txt;
      } else {
         push @tome, $txt;
      }      
   }

   return $rnd_msg;
}

1;

=back

=head1 AUTHOR

Originally developed by Sergey Zhmylove.

This module is free software. You can redistribute it and/or modify it 
under the terms of the license bundled with it.

=cut
