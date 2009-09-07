package WWW::BurrpTV;

use LWP::UserAgent;
use HTML::TreeBuilder;
use DateTime;
use Time::Normalize;

use 5.010000;
use strict;
use warnings;

our @ISA = qw();

our $VERSION = '0.01';


# Preloaded methods go here.

#### Globals #####
our %channels;
our $ua = LWP::UserAgent->new();
our $html_tree = HTML::TreeBuilder->new;

##################

sub new {
		my ($class,%args) = @_;
		my $cache = 0;
		my $self = bless({}, $class);
		$cache = $args{cache}.'/cache' if $args{cache};
		
		my $html = '';
		
		if ($cache) {
					open CACHE, '<', $cache or goto skip_read_cache; ## Problem
					while (<CACHE>) { $html .= $_; }
					close CACHE;
			     }
		
		skip_read_cache:
		
		if (!$html) {
				my $channel_list_url = 'http://tv.burrp.com/channels.html';
				my $http = $ua->get($channel_list_url);
				$html = $http->decoded_content;

				if ($cache) {
						open CACHE, '>', $cache;
						print CACHE $html;
						close CACHE;
					    }
			    }

		my $parsed = $html_tree->parse($html);
		$html_tree->eof;
		my $channel_array = $parsed->{'_content'}[1]{'_content'}[2]{'_content'}[0]{'_content'}[1]{'_content'}[1]{'_content'}[1]{'_content'}[1]{'_content'}; # Used Data::Dumper to find this.
		
		for (@$channel_array) { 
					my $channel_name = $_->{_content}[0]->{_content}[0];
					my $link = $_->{_content}[0]->{href};
					$channel_name =~ s/^\s*(.*?)\s*$/$1/;                    # Remove unwanted spaces from the channel name.
					$channels{$channel_name} = 'http://tv.burrp.com'.$link;
				      }
		return $self;
        }
	  
sub channel_list {
return \%channels if %channels;
}

sub get_shows {
         my ($class,%args) = @_;
         my $input_channel = $args{'channel'};
         
         my $timezone = 'Asia/Kolkata';
         $timezone = $args{'timezone'} if exists $args{'timezone'};
         
         
         my $url = $channels{$input_channel};
         my $http = $ua->get($url);
         my $html = $http->decoded_content;
	 my $parsed = $html_tree->parse($html);
	 $html_tree->eof;
	 my $listing_array = $parsed->{'_content'}[1]{'_content'}[8]{'_content'}[0]{'_content'}[0]{'_content'}[3]{'_content'}[1]{'_content'}[1]{'_content'};
	 pop (@$listing_array);
	 shift(@$listing_array);
	 my (@listing_today,@listing_tomorrow);
	 my @listing;
	 my $today = 1;
	 for (@$listing_array) {
	 			 my $time = $_->{_content}[0]->{_content}[0]->{_content}[0];
	 			 my $sup = $_->{_content}[0]->{_content}[0]->{_content}[1]->{_content}[0];
	 			 my $show_link = $_->{_content}[2]->{_content}[0]->{href};
	 			 my $full_link;
	 			 $full_link = 'http://tv.burrp.com'.$show_link if $show_link;
	 			 my $show = $_->{_content}[2]->{_content}[0]->{_content}[1]->{_content}[0];
	 			 $time =~ s/^ (.+)/$1/;
	 			 $show =~ s/(.*?)\s+$/$1/ if $show;
	 			 if (!$show) { $today = 0; }
	 			 else {
	 			 
	 			 	 ################## TIME CONVERSION ###############################
	 			 	 my ($hour,$minutes) = $time =~ /(\d+):(\d+)/;
	 			 	 my $nt = normalize_hms($hour,$minutes,0,$sup);
	 			 	 my $time_now = DateTime->now( time_zone => 'Asia/Kolkata' );
                     
				  	 my $dt = DateTime->new (
					  			   time_zone	=>	'Asia/Kolkata',
					  			   year		=>	$time_now->year,
					  			   month	=>	$time_now->month,
					  			   day		=>	$time_now->day,
					  			   hour		=>	$nt->{h24},
					  			   minute	=>	$minutes
					  			);
					  			
					 $dt->set_time_zone($timezone);
					 my $human_time = $dt->hour_12.':'.$dt->minute.' '.$dt->am_or_pm;
	 			 	 ##################################################################
	 			 
		 			 my $show_info = {_time24 => $dt->hms, _time12 => $human_time,_show => $show, _link => $full_link};
		 			 if ($today) { push @listing_today,$show_info; }
		 			 else { push @listing_tomorrow,$show_info; }
		 			 
		 		      }
	 		       }
	 my @full_listing = (@listing_today,@listing_tomorrow);
	 return \@full_listing;
}


1;
__END__

=head1 NAME

WWW::BurrpTV - Parse tv.burrp.com for TV listings.

=head1 SYNOPSIS

		Example:

		my $tv = WWW::BurrpTV->new ( 
					     cache => '/tmp/module', # Path to use as cache (optional).
					   );
			   
The cache is used only to store the list of available TV channels. It does not cache the TV listings.

=head1 DESCRIPTION

This module has the following methods.

channel_list() - Returns a hashref.

get_shows() - Takes a hash as argument.

	      Example:
	               $tv->get_shows (
			     		channel		=>	'Star Movies', #Required. Channel names are the ones listed by channel_list()
			     		timezone	=>	'Asia/Taipei', #Optional. Defaults to Asia/Kolkata
				      );


Returns a hashref with the keys _show, _link, _time24 (24 hour format), _time12 (12 hour format).

=head1 SEE ALSO

http://tv.burrp.com/

=head1 AUTHOR

rarbox, E<lt>rarbox@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by rarbox

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
