# jplbot
Simple jabber bot written in perl by KorG.
The command list follows:
* time           -- show time.
* date           -- show date & time.
* help           -- show help message.
* karma [user]   -- show specified user's karma (yours by default).
* top [number]   -- show karma top
* bomb [user]    -- put a bomb on the user or taunt unless argument passed.
* user: ++       -- increment or decrement specified user's karma.
* user: +1
* user: -1
* user: --
* fortune        -- show random thesis from fortune(6).
* http://uri     -- show information about first found URI.
* man://page     -- show link to the manpage on freebsd.org.
* m:page
* Ngoogle://txt  -- show Nth (1 by default) link of google search results.
* g:txt
* sayto/user/txt -- send txt to user's private when bot founds him or her presence notification.

To request voice, just send a private message to bot with body: "voice".

Original paper (in russian) is available via [Tune-IT blogs](http://www.tune-it.ru/web/korg/home/-/blogs/пишем-простенького-jabber-бота-на-perl).  
Feel free to change 'time' into 'scalar localtime' in the code if you prefer human-readable format :)

## Dependencies
* cpan Net::Jabber
* cpan Net::Jabber::Bot
* cpan LWP::Protocol::https
* cpan Google::Search

## Files
* src/jplbot.pl                        -- main executable file.
* src/config.pl                        -- configuration file included when needed.
* patch/Net/Jabber/Bot.pm.patch        -- patch for Net::Jabber::Bot to avoid some warnings, add password functionality and comment-out message parser to perform it manually.
* patch/Google/Search/Error.pm.patch   -- patch for Google::Search::Error to avoid a warning
* rc.d/jplbot                          -- rc(8) script for FreeBSD

## What if ...
If you liked this bot, you can send me a postcard to [s@zhmylove.ru](mailto:s@zhmylove.ru) and star this project on the github.  
If you want to propose some features, code improvements or bug reports, just use "Issues". Yep, I'll read them.
