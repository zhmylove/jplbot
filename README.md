# jbot
Simple jabber bot written in perl by KorG.
The command list follows:
   time           -- show time.
   help           -- show help message.
   karma [user]   -- show specified user's karma (yours by default).
   user: ++       -- increment or decrement specified user's karma.
   user: +1
   user: -1
   user: --
   fortune        -- show random thesis from fortune(6).

Feel free to change 'time' into 'scalar localtime' in the code if you prefer human-readable format :)

## Dependencies
cpan Net::Jabber
cpan Net::Jabber::Bot

## Files
*src/jbot.pl         -- main executable file.
*patch/Bot.pm.patch  -- patch for Net::Jabber::Bot to avoid some warnings, add password functionality and comment-out message parser to perform it manually.

