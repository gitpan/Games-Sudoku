use 5.6.1;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sudoku',
    VERSION_FROM      => 'lib/Games/Sudoku/Board.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Games/Sudoku/Board.pm', # retrieve abstract from module
       AUTHOR         => 'Eugene Kulesha <kulesha@gmail.com>') : ()),
);
