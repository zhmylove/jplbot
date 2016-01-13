### USER VARIABLES SECTION START #############################################
#
# Nick name and XMPP resource name used by bot. 
$name = 'AimBot';
# Path to file for karma saving routine
$karmafile = '/tmp/karma';
# Path to file for sayto saving routine
$karmafile = '/tmp/sayto';
# Address of XMPP server of the bot's account
$server = 'zhmylove.ru';
# Port of XMPP server of the bot's account
$port = 5222;
# Username of bot's account on the server
$username = 'aimbot';
# Password for this username
$password = 'password';
# Interval in seconds between background_checks() calee
$loop_sleep_time = 60;
# Address of a conference server, where forums are expected to be
$conference_server = 'conference.jabber.ru';
# MUC forums (chatrooms) with their passwords
%forum_passwords = ('ubuntulinux' => 'ubuntu');
# All colors, selected for the bombs
@colors = (
   'бело-оранжевый', 'оранжевый',
   'бело-зелёный', 'зелёный',
   'бело-синий', 'синий',
   'бело-коричневый', 'коричневый',
);
# Minimum number of colors to select from @colors
$colors_minimum = 3;
# Maximum number of sayto messages per forum
$sayto_max = 128;
# 1 week before cleanup
$sayto_keep_time = 604800;
#
### USER VARIABLES SECTION END   #############################################
