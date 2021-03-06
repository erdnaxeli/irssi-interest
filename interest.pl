use strict;
use Irssi; #20020101.0250 ();
use vars qw($VERSION %IRSSI); 
$VERSION = "1.1.0";
%IRSSI = (
    authors     => "Alexandre Morignot",
    contact	=> "moise\@cervoi.se", 
    name        => "Interestings chans",
    description => "Sort the chans' windows by interest",
    license	=> "Public Domain",
    url		=> "http://irssi.org/",
    changed	=> "2013-02-05T23:12+0100"
);


my %interests;


sub sort_chan {
  my $i = 1;

  foreach my $id (sort {-1 * ($interests{$a} <=> $interests{$b})} keys %interests) {
    my ($stag, $chan) = split ('\+', $id);
    my $server = Irssi::server_find_tag ($stag);

    # on vérifie qu'on a bien trouvé un serveur
    next unless ($server);

    my $win = $server->window_find_item ($chan);

    # on vérifie qu'on a bien trouvé une fenêtre
    next unless ($win);

    $i++;
    $win->set_refnum($i);
  }
}


sub load {
  foreach my $win (Irssi::windows()) {
    if ($win->{'active'}->{'type'} eq 'CHANNEL') {
      my $chan = $win->{'active'}->{'name'};
      my $server = $win->{'active'}->{'server'}->{'tag'};

      $interests{$server .'+'. $chan} = 0 if (!$server eq '');
    }
  }

  open INTERESTS, "$ENV{HOME}/.irssi/interests";

  while (<INTERESTS>) {
    # I don't know why this is necessary only inside of irssi
    my @lines = split "\n";
    foreach my $line (@lines) {
      my($id, $interest) = split ":", $line;

      $interests{$id} = $interest if (!$id eq '');
    }
  }

  close INTERESTS;
}


sub save {
  open INTERESTS, ">$ENV{HOME}/.irssi/interests";

  foreach my $id (keys %interests) {
    print INTERESTS "$id:$interests{$id}\n";
  }

  close INTERESTS;
}


sub cmd_interesting {
  my ($add, $args, $cserver, $witem) = @_;
  my $cchan = $witem->{name};

  if ($witem->{'type'} eq "CHANNEL" && $cserver->{connected}) {
    my $cstag = $cserver->{tag};
    $interests{$cstag .'+'. $cchan} += $add;

    sort_chan();

  }

  save();
}


sub cmd_list {
  foreach my $id (sort {-1 * ($interests{$a} <=> $interests{$b})} keys %interests) {
    Irssi::print ((split ('\+', $id))[1] . " : $interests{$id}") if ($interests{$id} != 0);
  }
}


# on charge la liste des chans enregistrés
load();

# on trie les chans
sort_chan();

Irssi::command_bind '++' => sub { cmd_interesting(50, @_); };
Irssi::command_bind '--' => sub { cmd_interesting(-40, @_); };
Irssi::command_bind('listinterests', 'cmd_list');
Irssi::signal_add('message own_public',
    sub {
        my ($server, $message, $chan) = @_;
        my $win = $server->window_find_item ($chan)->{'active'};
        cmd_interesting (1, '', $server, $win);
    });
