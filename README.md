# jplbot
Simple Jabber and Telegram bot written in perl by KorG.
The full command list follows:
* time           -- show time.
* date           -- show date & time.
* help           -- show help message.
* karma [user]   -- show specified user's karma (yours by default).
* top [number]   -- show karma top.
* user: ++       -- increment or decrement specified (answered) user's karma.
* user: +1
* user: -1
* user: --
* fortune        -- show random thesis from fortune(6).
* poem           -- show some depressive suicidal rhymes.
* http://uri     -- show information about first found URI.
* man://page     -- show link to the manpage on freebsd.org.
* m:page
* man page
* g:txt          -- transform txt into link to Google and show the title.
* sayto/user/txt -- send txt to user's private when bot founds him or her presence notification.
* ! txt          -- translate txt from en-ru and vice versa.
* !! [txt]       -- xlate layout en-ru and vice versa of the txt or the last message.

#### Jabber specific commands
* add-kicker     -- grant the user kicker privileges.
* remove-kicker  -- remove the user from the list.
* list-kickers   -- list users with kick privileges.
* kick {user}    -- kick the user if you have respective rights.
* bomb {user}    -- put a bomb on the user or taunt unless argument passed.

To request voice in a Jabber MUC, just send a private message to bot with body: "voice".

Original article about bot's creation (in russian) is available via [Tune-IT blogs](http://www.tune-it.ru/web/korg/home/-/blogs/пишем-простенького-jabber-бота-на-perl).  
Feel free to change 'time' into 'scalar localtime' in the code if you prefer human-readable format :)

## Dependencies
* /usr/games/fortune
* /usr/games/poem                      -- script to print a random poem (may be symlink for /usr/bin/true)
* cpan LWP::Protocol::https
* cpan LWP::Protocol::socks            -- (optional) SOCKS proxy capability

#### XMPP
* cpan Net::Jabber
* cpan Net::Jabber::Bot

#### Telegram
* cpan Test::Without::Module
* cpan JSON::MaybeXS
* cpan WWW::Telegram::BotAPI

## Files
* src/jplbot.pl                        -- main executable file for Jabber.
* src/tgbot.pl                         -- main executable file for Telegram.
* src/config.pl                        -- configuration file included when needed.
* src/keywords.pm                      -- keywords module.
* src/tome.pm                          -- ToMe module.
* src/karma.pm                         -- karma module.
* src/tran.pm                          -- translate module.
* src/xlate.pm                         -- layout translation module.
* src/cat\_hash.pl                     -- utility to view saved hashes (karma, tg\_counters, kick, ...).
* patch/Net/Jabber/Bot.pm.patch        -- patch for Net::Jabber::Bot to avoid some warnings, add password functionality and comment-out message parser to perform it manually.
* rc.d/jplbot                          -- rc(8) script for FreeBSD

## cat\_hash.pl
Well, some lists (karma, kick, ...) saved at the end of the work. You can simply view them using
```sh
$ ./cat_hash.pl /path/to/file
$ ./cat_hash.pl # shows /tmp/count_tg by default
```

## Signals
* INT       -- perform shutdown procedures.
* TERM      -- perform shutdown procedures.
* USR1      -- fall into debugger (*for jplbot started with -d parameter only*).
* USR2      -- save dynamic data (karma, kick, ...).
So if you want to save dynamic data more frequent, just tune-up your crontab:
```
15 * * * * /bin/pkill -USR2 -f jplbot.pl
15 * * * * /bin/pkill -USR2 -f tgbot.pl
```

## What if ...
If you liked this bot, you can send me a postcard to [s@zhmylove.ru](mailto:s@zhmylove.ru) and star this project on the github.  
If you want to propose some features, code improvements or bug reports, just use "Issues" feature. Yep, I'll read them.
