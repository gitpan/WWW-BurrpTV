use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'WWW::BurrpTV',
    VERSION_FROM      => 'lib/WWW/BurrpTV.pm', # finds $VERSION
    PREREQ_PM         => {
    
				'DateTime'		=> 0,
				'Time::Normalize'	=> 0,
				'LWP::UserAgent'	=> 0,
				'HTML::TreeBuilder'	=> 0,
    
    
    			  },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/WWW/BurrpTV.pm', # retrieve abstract from module
       AUTHOR         => 'death <death@localdomain>') : ()),
);
