use Test::More;
use warnings;
use strict;

plan tests => 5;


use_ok('WWW::BurrpTV');
my $tv = WWW::BurrpTV->new(cache => 't/files');
isa_ok($tv, 'WWW::BurrpTV');

my $list = $tv->channel_list;
is($list->{'Star Movies'}, 'http://tv.burrp.com/channel/star-movies/59/', 'Channel list retrieval');

my $shows = $tv->get_shows(channel => 'discovery channel');
is($$shows[0]->{_channel}, 'Discovery Channel', 'Listing parse (channel name)');

$shows = $tv->get_shows(channel => 'STAR WORLD', timezone => 'Asia/Taipei');
my ($am_or_pm) = $$shows[0]->{_time12} =~ /(.{2})$/;
$am_or_pm =~ s/a/P/i;

is($am_or_pm,'PM','Listing parse (Time)');
