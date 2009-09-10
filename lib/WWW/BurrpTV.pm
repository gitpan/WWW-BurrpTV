=head1 NAME

WWW::BurrpTV - Parse tv.burrp.com for TV listings.

=head1 SYNOPSIS

	use WWW::BurrpTV;

	my $tv = WWW::BurrpTV->new ( 
				     cache => '/tmp/module',
				   );

	$tv->timezone('Asia/Bahrain'); 

	# Get current playing show on Discovery Channel

	my $shows = $tv->get_shows(channel => 'Discovery Channel');

	my $current_playing_show = $$shows[0]; # First item in the array is the current playing show.

	print $current_playing_show->{_show};
	print $current_playing_show->{_time12};
	print $current_playing_show->{_link};

=head1 DESCRIPTION

=head2 Overview

	WWW::BurrpTV is an object oriented interface to parse TV listings from tv.burrp.com.
=cut

package WWW::BurrpTV;


use HTML::TreeBuilder;
use DateTime;
use LWP::UserAgent;
use Carp;

use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.02';

use vars qw ( 
	      %CHANNELS 
	      $UA 
	      $TIMEZONE
	    );

BEGIN {
	      our %CHANNELS;
	      our $UA = LWP::UserAgent->new();
	      our $TIMEZONE = 'Asia/Kolkata'; # Default timezone
       }

=head1 CONSTRUCTOR

=over 4

=item new()

Object's constructor. Takes an optional hash argument which can be used to cache the list of channels. This does not cache the TV listings.

		my $tv = WWW::BurrpTV->new ( 
					     cache => '/tmp/module', # Path to use as cache (optional). Make sure the path exists.
					   );
=cut

sub new {
		my ($class,%args) = @_;
		my $cache = 0;
		my $self = bless({}, $class);
		my $write = 0;
		if ((exists $args{cache}) && (!-d $args{cache})) { carp 'Directory does not exist. Channel list will not be cached.'; }
		else { $write = 1; }

		$cache = $args{cache}.'/cache' if exists $args{cache};
		delete $args{cache}; # No longed needed.

	        for my $key (keys %args) { carp "Ignored invalid argument ($key)"; }

		my $html;

		if ($cache) {
					open my $cachefile, '<', $cache or goto skip_read_cache;
					while (<$cachefile>) { $html .= $_; }
					close $cachefile;
			     }

		skip_read_cache:

		if (!$html) {
				my $channel_list_url = 'http://tv.burrp.com/channels.html';
				my $http = $UA->get($channel_list_url);
				$html = $http->decoded_content;
				croak $http->status_line unless $http->is_success;

				if (($cache) && ($write)) {
						my $write_success = 0;
						open my $cachefile, '>', $cache or carp $!;
						print {$cachefile} $html;
						close $cachefile;
					    }
			    }

		my $tree = HTML::TreeBuilder->new();
		my $parsed = $tree->parse($html);
		$tree->eof;

		my $channel_array = $parsed->{'_content'}[1]{'_content'}[2]{'_content'}[0]{'_content'}[1]{'_content'}[1]{'_content'}[1]{'_content'}[1]{'_content'};

		for (@$channel_array) { 
					my $channel_name = $_->{_content}[0]->{_content}[0];
					my $link = $_->{_content}[0]->{href};
					$channel_name =~ s/^\s*(.*?)\s*$/$1/;
					$CHANNELS{$channel_name} = 'http://tv.burrp.com'.$link;
				      }

		$tree = $tree->delete();
		$parsed = $parsed->delete();
		return $self;
        }

=back 

=head1 METHODS

=over 4

=item channel_list()

This method does not take any arguments, and returns a hashref.

	$tv->channel_list();

=item timezone()

Change the default timezone (Asia/Kolkata).

	$tv->timezone('Europe/Monaco');

=item get_shows()

Takes the channel name and an optional timezone as arguments, and returns an arrayref.

	$tv->get_shows (
			 channel	=>	'Discovery Channel',
			 timezone	=>	'Asia/Bahrain',      # Optional
		       );
=cut

sub channel_list {
return \%CHANNELS;
}




sub timezone {
	my ($class,$new_timezone) = @_;
	my ($success,$error) = verify_timezone($new_timezone);

	if ($success) { $TIMEZONE = $new_timezone; }
	else { carp $error; }
	return;
}

sub verify_timezone {
	my ($timezone_to_verify) = @_;
	my $dt_object = DateTime->now();
	eval { $dt_object->set_time_zone($timezone_to_verify); };
	my $error = $@;
	chomp $error;

	return (0,$error) if $@;
	return 1;
}

sub get_shows {

         my ($class,%args) = @_;
         #my $self = bless({}, $class); #testing.
         if (!exists $args{'channel'}) { croak 'Channel not specified.'; }
         my $input_channel = $args{'channel'};
         delete $args{'channel'}; # Don't need it anymore.
	 my $timezone_override = $TIMEZONE;

         if (exists $args{'timezone'}) { 
         				 my ($success,$error) = verify_timezone($args{'timezone'});
         				 if ($success) { $timezone_override = $args{'timezone'}; }
         				 else { carp $error; }
         				 delete $args{'timezone'};	# Don't need it anymore.
         				}

	 for my $key (keys %args) { carp "Ignored invalid argument ($key)"; }

 	 for (keys %CHANNELS) { if (lc($_) eq lc($input_channel)) { $input_channel = $_; } }

	 croak 'Invalid channel' if !exists $CHANNELS{$input_channel};

         my $url = $CHANNELS{$input_channel};

         my $http = $UA->get($url);
         croak $http->status_line unless $http->is_success;
         my $html = $http->decoded_content;

         my $tree = HTML::TreeBuilder->new();
	 my $parsed = $tree->parse($html);
	 $tree->eof;

         my $today = 1;
         my @listing_today = qw();
         my @listing_tomorrow = qw();
         my @listing = qw();

         for (@{$parsed->{'_content'}[1]{'_content'}[2]{'_content'}[0]{'_content'}[0]{'_content'}[3]{'_content'}[1]{'_content'}[1]{'_content'}}) {          
         		############# Parsed values (with the help of Data::Dumper) ##############
         		my $time = $_->{_content}[0]{_content}[0]{_content}[0];
         		my $am_or_pm = $_->{_content}[0]{_content}[0]{_content}[1]{_content}[0];
         		my $show_link = $_->{_content}[1]{_content}[0]{href};
         		my $episode = $_->{_content}[1]{_content}[0]{title};
         		undef $episode if !$episode;
         		my $full_link;
         		$full_link = 'http://tv.burrp.com'.$show_link if $show_link;
         		my $show = $_->{_content}[2]{_content}[0]{_content}[1]{_content}[0];
         		$time =~ s/^ (.+)/$1/;

	 		if (!$show) { $today = 0; }
	 		else {
	 				 $show =~ s/(.*?)\s+$/$1/;
	 				 my $season;
         				 ($show,$season) = $show =~ /(.*?) \(Season (\d+)\)/ if $show =~ /Season \d+/;

	 			 	 ################## TIME CONVERSION ###############################
	 			 	 my ($hour,$minutes) = $time =~ /(\d+):(\d+)/;
	 			 	 #my $nt = normalize_hms($hour,$minutes,0,$am_or_pm);

                    			 my $dt = DateTime->now(time_zone => 'Asia/Kolkata');

				  	 $dt = DateTime->new (
					  			   time_zone	=>	'Asia/Kolkata', # Timezone used by tv.burrp.com
					  			   year		=>	$dt->year,
					  			   month	=>	$dt->month,
					  			   day		=>	$dt->day,
					  			   #hour	=>	$nt->{h24},
					  			   hour		=>	eval {
												 if ($am_or_pm eq 'PM') {
															  if ($hour == 12) { return $hour; }
															  else { $hour += 12; return $hour; }
															}

														else	{
															  if ($hour == 12) { return 0; }
															  else { return $hour; }
															}
					  			   			     },

					  			   minute	=>	$minutes,
					  		     );


					 $dt->set_time_zone($timezone_override);			# Convert to required timezone
					 #my $minute = $dt->minute;
					 #$minute =~ s/^(\d)$/0$1/ if $minute =~ /^\d$/;			# Prefix 0 for single digit numbers
					 #my $human_time = $dt->hour_12.':'.$minute.' '.$dt->am_or_pm;
	 			 	 ##################################################################

		 			 my $show_info = { 	
		 			 			_channel	=>	$input_channel, 
		 			 			#_time24		=>	$dt->hms =~ /(\d+:\d+)/, # Ignore seconds
		 			 			_time24		=>	$dt->strftime('%H:%M'),
		 			 			#_time12		=>	$human_time,
		 			 			_time12		=>	$dt->strftime('%I:%M %p'),
		 			 			_show		=>	$show, 
		 			 			_link		=>	$full_link, 
		 			 			_season		=>	$season, 
		 			 			_episode	=>	$episode,
		 			 		 };

		 			 if ($today) { push @listing_today,$show_info; }
		 			 else { push @listing_tomorrow,$show_info; }

	 		}
         		##########################################################################

         	      }
         undef $tree;
         undef $parsed;
         #$tree = $tree->delete;
         @listing = (@listing_today,@listing_tomorrow);
         return \@listing;
}

1;
__END__

=back

=head1 SEE ALSO

http://tv.burrp.com/

=head1 AUTHOR

rarbox, E<lt>rarbox@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by rarbox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
