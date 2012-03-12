use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gearman::Scalable::Spawner',
    AUTHOR              => q{HyeonSeung Kim <sng2nara@hanmail.net>},
    VERSION_FROM        => 'lib/Gearman/Scalable/Spawner.pm',
    ABSTRACT_FROM       => 'lib/Gearman/Scalable/Spawner.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gearman-Scalable-Spawner-*' },
);
