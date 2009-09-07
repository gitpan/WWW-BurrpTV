use lib 'lib';
use WWW::BurrpTV;
use Data::Dumper;
use warnings;
use strict;


my $tv = WWW::BurrpTV->new ( 
			     cache => '/home/death/Desktop/module',   # Optional. Make sure the folder exists.
			   );
			  
print Dumper $tv->channel_list; # Completed



print Dumper $tv->get_shows (
			     channel =>	'Star Movies',
			     timezone => 'Asia/Karachi', #Optional. Defaults to Asia/Kolkata
			   );


			  
			  
			  
