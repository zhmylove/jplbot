### USER VARIABLES SECTION START #############################################
#
# Nick name and XMPP resource name used by bot
$cfg{name} = 'AimBot';

# Path to file for karma saving routine
$cfg{karmafile} = '/tmp/karma';
# Time between same src->dst karma change allowed
$cfg{karma_reject_time} = 7;

# Path to file for kicker admins
$cfg{kick_file} = '/tmp/kick';

# Path to file for Telegram message counters
$cfg{tg_count_file} = '/tmp/count_tg';

# Address of XMPP server of the bot's account
$cfg{server} = 'zhmylove.ru';
# Port of XMPP server of the bot's account
$cfg{port} = 5222;

# Username of bot's account on the server
$cfg{username} = 'aimbot';
# Password for this username
$cfg{password} = 'password';
# Token for Telegram
$cfg{token} = 'token';
# Username for Telegram
$cfg{tg_name} = '@korg_bot';
# Yandex API key for translator
$cfg{yandex_api} = 'key';
# Optionally set here SOCKS proxy like 'socks://[user:pass@]host:port';
$cfg{proxy} = '';
# Optionally set here LocalAddr for LWP
$cfg{local_addr} = '';

# Maximum number of messages per hour
$cfg{max_messages_per_hour} = 150;

# Interval in seconds between background_checks() calee
$cfg{loop_sleep_time} = 60;

# Address of a conference server, where forums are expected to be
$cfg{conference_server} = 'conference.jabber.ru';
# MUC forums (chatrooms) with their passwords
$cfg{room_passwords} = {'ubuntulinux' => 'ubuntu'};

# Number of distinct likes allowed per user
$cfg{last_like_max} = 3;

# Files used for bot addressed messages
$cfg{tome_file} = '/tmp/tome.txt';
$cfg{tome_dict} = undef;
$cfg{tome_tg_file} = '/tmp/tome_tg.txt';
# Maximum number of bot addressed messages per module instance
$cfg{tome_max} = 300;
# Maximum message length
$cfg{tome_msg_max} = 300;

# All colors, selected for the bombs
$cfg{colors} = [
   'бело-оранжевый', 'оранжевый',
   'бело-зелёный', 'зелёный',
   'бело-синий', 'синий',
   'бело-коричневый', 'коричневый',
];
# Minimum number of colors to select from @colors
$cfg{colors_minimum} = 3;

# Path to file for sayto saving routine
$cfg{saytofile} = '/tmp/sayto';
# Maximum number of sayto messages per forum
$cfg{sayto_max} = 128;
# 1 week before cleanup
$cfg{sayto_keep_time} = 604800;
#
### USER VARIABLES SECTION END   #############################################
