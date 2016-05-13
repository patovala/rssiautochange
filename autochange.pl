# /AUTOCHANGE <n> - Change user to window 1 after <n> seconds of inactivity
# (c) 2016 Patricio Valarezo (patovala@pupilabox.net.ec)
#
# Heavily inspired by /autochange by Larry Dafner
#
# /autochange <n> - Mark user away after <n> seconds of inactivity
# /AWAY - play nice with autochange
# New, brighter, whiter version of my autochange script. Actually works :)
# (c) 2000 Larry Daffner (vizzie@airmail.net)
#     You may freely use, modify and distribute this script, as long as
#      1) you leave this notice intact
#      2) you don't pretend my code is yours
#      3) you don't pretend your code is mine
#
# share and enjoy!

# /autochange <seconds> will move your attention to window 1 after <seconds> of
# inactivity.

use strict;
use Irssi;
use Irssi::Irc;

use vars qw($VERSION %IRSSI);
$VERSION = "0.4";
%IRSSI = (
    authors => 'Patricio Valarezo',
    contact => 'patovala@pupilabox.net.ec',
    name => 'Change to window 1 after timeout',
    description => 'Automatically moves to window 1 after timeout seconds',
    license => 'BSD',
    url => 'https://github.com/patovala/rssiautochange',
    changed => 'Fri May 13 16:57:30 ECT 2016',
    changes => 'First script upload'
);

my ($autoaway_sec, $autoaway_to_tag, $autoaway_state);
$autoaway_state = 0;

#
# /autochange - set the autochange timeout
#
sub cmd_autochange {
  my ($data, $server, $channel) = @_;

  if (!($data =~ /^[0-9]+$/)) {
    Irssi::print("autoaway: usage: /autochange <seconds>");
    return 1;
  }

  $autoaway_sec = $data;

  if ($autoaway_sec) {
    Irssi::settings_set_int("autoaway_timeout", $autoaway_sec);
    Irssi::print("autochange timeout set to $autoaway_sec seconds");
  } else {
    Irssi::print("autoway disabled");
  }

  if (defined($autoaway_to_tag)) {
    Irssi::timeout_remove($autoaway_to_tag);
    $autoaway_to_tag = undef;
  }

  if ($autoaway_sec) {
    $autoaway_to_tag =
      Irssi::timeout_add($autoaway_sec*1000, "auto_timeout", "");
  }
}

#
# away = Set us away or back, within the autochange system
sub cmd_away {
  my ($data, $server, $channel) = @_;

  if ($data eq "") {
    $autoaway_state = 0;
  } else {
    if ($autoaway_state eq 0) {
      Irssi::timeout_remove($autoaway_to_tag);
      $autoaway_to_tag = undef;
      $autoaway_state = 2;
    }
  }
}

sub auto_timeout {
  my ($data, $server) = @_;

  # we're in the process.. don't touch anything.
  $autoaway_state = 3;
  foreach my $server (Irssi::servers()) {
      $server->command("/1");
  }

  Irssi::timeout_remove($autoaway_to_tag);
  $autoaway_state = 1;
}

sub reset_timer {
   if ($autoaway_state eq 1) {
     $autoaway_state = 3;
     foreach my $server (Irssi::servers()) {
         $server->command("/AWAY");
     }

     $autoaway_state = 0;
   }
  if ($autoaway_state eq 0) {
    if (defined($autoaway_to_tag)) {
      Irssi::timeout_remove($autoaway_to_tag);
      $autoaway_to_tag = undef();
    }
    if ($autoaway_sec) {
      $autoaway_to_tag = Irssi::timeout_add($autoaway_sec*1000
					    , "auto_timeout", "");
    }
  }
}

Irssi::settings_add_int("misc", "autoaway_timeout", 0);

my $autoaway_default = Irssi::settings_get_int("autoaway_timeout");
if ($autoaway_default) {
  $autoaway_to_tag =
    Irssi::timeout_add($autoaway_default*1000, "auto_timeout", "");

}

Irssi::command_bind('autochange', 'cmd_autochange');
Irssi::command_bind('away', 'cmd_away');
Irssi::signal_add('send command', 'reset_timer');
