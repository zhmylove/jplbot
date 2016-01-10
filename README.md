# jplbot
Simple jabber bot written in perl by KorG.
The command list follows:
* time           -- show time.
* date           -- show date & time.
* help           -- show help message.
* karma [user]   -- show specified user's karma (yours by default).
* bomb [user]    -- put the bomb on the user or taunt unless argument passed.
* user: ++       -- increment or decrement specified user's karma.
* user: +1
* user: -1
* user: --
* fortune        -- show random thesis from fortune(6).
* http://uri     -- show information about first found URI.

Original paper (in russian) is available via [Tune-IT blogs](http://www.tune-it.ru/web/korg/home/-/blogs/пишем-простенького-jabber-бота-на-perl).  
Feel free to change 'time' into 'scalar localtime' in the code if you prefer human-readable format :)

## Dependencies
* cpan Net::Jabber
* cpan Net::Jabber::Bot
* cpan LWP::Protocol::https

## Files
* src/jplbot.pl         -- main executable file.
* src/config.pl         -- configuration file included when needed.
* patch/Bot.pm.patch  -- patch for Net::Jabber::Bot to avoid some warnings, add password functionality and comment-out message parser to perform it manually.

