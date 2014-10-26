#
# PERL Modul
# Tk-Frontend Basic Class
#
# Copyright (C) 1998,1999 Dirk Tostmann (tostmann@tiss.com)
#
# $rcs = ' $Id: Application.pm 1.3 1999/01/22 18:31:12 MASTER Exp $ ' ;	
#
#######################################################
package Tk::Application;
#######################################################
#
$Tk::Application::VERSION = 0.03;
#
use Tk;
use Tk::Label;
use Tk::CmdLine;
use Tk::Balloon;
use FreezeThaw qw(freeze thaw);
use strict;
#
#######################################################
sub new {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self  = {
	       TW     => MainWindow->new(),
	       APPNAME=> shift || 'TkApplication',
	       TITLE  => shift,
	       FONT   => '-*-Helvetica-Medium-R-Normal--*-150-*-*-*-*-*-*',
	       FIXFONT=> '-*-courier-Medium-R-Normal--*-150-*-*-*-*-*-*',
	      };
  
  return unless $self->{TW};
  
  bless $self, $class; 
  
  $self->{TITLE} = $self->{APPNAME} unless $self->{TITLE};
  
  $self->{TW}->protocol('WM_DELETE_WINDOW' => sub{$self->QUIT});
  
  $self;
}
#
#
#######################################################
sub RUN { 
  my $self = shift;
  
  MainLoop;
}

#
#######################################################
sub SETUP {
  my $self = shift;
  $self->{TW}->title($self->{TITLE}) if $self->{TITLE};
  
  $self->{MENUBAR} = $self->{TW}->Frame(qw/-relief raised -bd 2/);
  $self->{MENUBAR}->pack(-side => 'top', -fill => 'x');
  $self->create_statusbar;
  $self->create_menubar;
  
  # Create Main Frame
  $self->{MF} = $self->{TW}->Frame(qw//);
  $self->{MF}->pack(-side => 'top', -fill => 'both', -expand => 1);
  
  
  $self->{BALLOON} = $self->{TW}->Balloon(-statusbar => $self->{STATUSBAR});
  1;
}

#######################################################
sub QUIT {
  my $self = shift;
  $self->{TW}->destroy;
}

#####################################################################
sub THAW {
  my $self = shift;
  
  open(TXT, $self->ini_file) || return;
  my $data='';
  while (<TXT>) {
    $data .= $_;
  }

  close(TXT);
  
  return unless $data;
  
  my @DATA = ();
  
  eval{(@DATA) = thaw($data);};
  
  return if $@;
  
  $self->ShowMsg("config loaded from ".$self->ini_file);
  
  $self->load(\@DATA);
}

#####################################################################
sub FREEZE {
  my $self = shift;
  
  my $vars = [];
  $self->store($vars);
  my $data = freeze(@$vars);
  
  open(TXT, ">".$self->ini_file) || return;
  print TXT $data;
  close(TXT);
}

######################################################################
sub store($$) {
 my ($self,$vars) = @_;
# $self->SUPER::store($vars);
 push @$vars, $self->{TITLE};
 push @$vars, $self->{FONT};
 push @$vars, $self->{FIXFONT};
 
};

######################################################################
sub load($$) {
  my ($self,$vars) = @_;
  # $self->SUPER::load($vars);
  $self->{TITLE}   = shift (@$vars) || 'TkApplication';
  $self->{XFONT}    = shift (@$vars) || '-*-Arial-Medium-R-Normal--*-140-*-*-*-*-*-*';
  $self->{XFIXFONT} = shift (@$vars) || '-*-Courier-*-*-*--*-160-*-*-*-*-*-*';
}

#######################################################
sub ini_file {
  my $self = shift;
  
  # sourceExe comes from perl2exe...
  my $path = $ENV{sourceExe} || $0;
  
  $path =~ s/\\/\//g;
  $path =~ s/\/[^\/]+$//;
  
  if ($^O =~ /win/i) {
    return "$path/".$self->{APPNAME}.'.ini'; 
  } else {
    return $ENV{HOME}.'/.'.$self->{APPNAME}; 
  }
}
#######################################################
sub create_statusbar {
  my $self = shift;
  my $feedback = $self->{TW}->Frame();
  $feedback->pack(-side => 'bottom', -fill => 'x');
  $self->{STATUSBAR} = $feedback->Label(
					-relief      => 'sunken',
					-height      => 1,
					-background  => 'gray',
					-borderwidth => 2,
					-anchor      => 'w',				   
				       );
  $self->{STATUSBAR}->pack(-side => 'left', -fill => 'x', -expand => 1);
}

#######################################################
sub NotDone {
  my $self = shift;
  print "Do NIL\n";
}

#######################################################
# Just an example, overwrite it!
sub create_menubar {
  my $self = shift;
  
  $self->mkmb('File', 0, 'File related stuff',
	      [
	       ['Open',      \&NotDone,     0],
	       ['New',       \&NotDone,     0],
	       ['Print',     \&NotDone,     0],
	       ['Exit',      sub{ $self->QUIT},        0],
	      ]);
  
  $self->mkmb('Help', 0, 'There when you need it',
	      [
	       ['About..',   \&NotDone,     0],
	       ['Intro',     \&NotDone,     0],
	       ['Contents',  \&NotDone,     0],
	      ],'right');
  
}

#######################################################
sub ShowMsg {
  my $self = shift;
  my $msg  = shift;
  $self->{STATUSBAR}->configure(-text=>$msg);  
  $self->{STATUSBAR}->update;
}

#######################################################
sub ClearMsg {
  my $self = shift;
  $self->ShowMsg('');
}

#######################################################
sub mkmb {
  
  # (Ripped from nTk examples)
  # Make a Menubutton widget; note that the menu is automatically created.  
  # We maintain a list of the Menubutton references since some callers 
  # need to refer to the Menubutton, as well as to suppress stray name 
  # warnings with Perl -w.
  
  require Tk::Menubutton;
  
  my $self = shift;
  my($mb_label, $mb_label_underline, $mb_msg, $mb_list_ref, $side) = @_;
  my $mb = $self->{MENUBAR}->Menubutton(
					-text       => $mb_label, 
					-underline  => $mb_label_underline,
				       );
  my($menu) = $mb->Menu(-tearoff => 0);
  $mb->configure(-menu => $menu);
  
  my $mb_list;
  foreach $mb_list (@{$mb_list_ref}) {
    if ($mb_list->[0] eq '-') {
      $mb->separator; 
    } else {
      $mb->command(
		   -label      => $mb_list->[0], 
		   -command    => $mb_list->[1] , 
		   -underline  => $mb_list->[2], 
		   -font       => $self->{FONT},
		  );
    }
  }
  $mb->pack( -side => $side || 'left');
  $self->{TW}->bind($mb, '<Enter>' => sub { $self->ShowMsg($mb_msg)} );
  $self->{TW}->bind($mb, '<Leave>' => sub { $self->ClearMsg});
  
  $self->{MButtons}->{$mb_label} = $mb;
  return $mb;
  
}				# end mkmb

###########################################################
sub MsgBox {
  my $self = shift;
  $self->{TW}->messageBox(
			  -message => shift,
			  -icon => shift || 'error', 
			  -type => shift || 'OK',
			  -title => shift || $self->{TITLE},
			 );   
}

###########################################################
sub ErrorMsgBox {
  my $self = shift;
  $self->MsgBox(shift,'error','OK');
}

###########################################################
sub InfoMsgBox {
  my $self = shift;
  $self->MsgBox(shift,'info','OK');
}

###########################################################
sub attach_balloon {
  my $self = shift;
  my $obj  = shift || return;
  $self->{BALLOON}->attach($obj,
			   -msg => shift,
			   -statusmsg => shift,  
			   );
}
###########################################################
1;







