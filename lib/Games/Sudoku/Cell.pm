package Games::Sudoku::Cell;

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self = {
	ROW => shift, 
	COL => shift, 
	QUAD => shift,
	VALUE => shift || 0,
	ACCEPT => [ qw(1 2 3 4 5 6 7 8 9) ]
	};

    bless ($self, $class);
    return $self;
}

sub value :lvalue { $_[0]->{VALUE}; }
sub quad :lvalue { $_[0]->{QUAD}; }
sub row :lvalue { $_[0]->{ROW}; }
sub col :lvalue { $_[0]->{COL}; }
sub accept :lvalue { $_[0]->{ACCEPT} }

1;
