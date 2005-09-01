package Games::Sudoku::Board;

use strict;
use warnings;

use Games::Sudoku::Cell;

our $VERSION = '0.06';

# Array will hold the number and difficulty of steps taken to find a solution
# It can be used later to classify the board difficulty
my @Route = ();

sub showRoute {
    print " @Route \n";
}


sub new {
    my $caller = shift;
    my $caller_is_obj = ref($caller);

    my $class = $caller_is_obj || $caller;

    my $self = {
	NAME => shift || 'Root ',
	DEBUG => shift || 0,
	PAUSE => shift || 0, 
	UNSOLVED => 81, 
	STEP => 0, 
	ERROR => [ ],
	MOVES => [ ],
	
    };

    foreach (my $i = 1; $i < 10; $i++) {
	foreach (my $j = 1; $j < 10; $j++) {
	    my $ik = int (($i-1)/3);
	    my $jk = int (($j-1)/3);
	    my $s = $ik *3 + $jk + 1; 
	    push @{$self->{BOARD}}, new Games::Sudoku::Cell($i, $j, $s);
	}
    }

    bless $self, $class;
}

# Function verifies the layout. 
# Contributed by Michael Cartmell
 
sub verify {
    my $self = shift;
    my $OK   = 1;
    my %data = (
		row  => [],
		col  => [],
		quad => []
		);

    foreach my $cell ( @{ $self->{BOARD} } ) {
	$data{row}[ $cell->row ][ $cell->value ]++;
	$data{col}[ $cell->col ][ $cell->value ]++;
	$data{quad}[ $cell->quad ][ $cell->value ]++;
    }
    foreach my $type (qw(row col quad)) {
	foreach my $line ( 1 .. 9 ) {
	    foreach my $value ( 1 .. 9 ) {
		unless ( defined $data{$type}[$line][$value] ) {
		    $OK = undef;
		    warn "In $type $line, $value did not occur\n"
			if $self->debug;
		}
		elsif ( $data{$type}[$line][$value] > 1 ) {
		    $OK = undef;
		    warn
			"In $type $line, $value occured $data{$type}[$line][$value] times\n"
			if $self->debug;
		}
	    }
	}
    }
    return $OK ? 'Solution verified' : 'Failed to verify';
}

sub init{
    my $self = shift;
    my $gdata = shift;
    for (my $i=0; $i<@$gdata; $i++) {
	my $p = $self->{BOARD}[$i];
	$p->value = $gdata->[$i];
    }
    return undef;
}

sub initFromFile {
    my $self = shift;
    my $fname = shift;
    local $/;
    open FH, "$fname" or die "ERROR: $fname : $!\n";
    my $fdata = <FH>;
    close FH;
    my @gdata = $fdata =~ m/(\d)/sg;
    $self->init(\@gdata);
}

sub displayBoard {
    my $self = shift;
    
    my $header = sprintf "***** %s *** STEP %d ", $self->_name, scalar(@Route);
    print $header, "*" x (84 - length $header);

    foreach my $p (sort { 10*($a->row <=> $b->row) + ($a->col <=> $b->col) }@{$self->{BOARD}}) {
	if ($p->col == 1) {
	    print "\n";
	}
	print $p->value ? sprintf("%8d ", $p->value): sprintf("(%6s) ", @{$p->accept} == 9 ? '1 .. 9' : join('', @{$p->accept}));
    }
    print "\n", "*" x 84, "\n";
}

sub solve {
    my $self = shift;

    do {
	do {
	    $self->pause();
	    $self->displayBoard() if ($self->_findSimple() && $self->debug);
	    if ($self->_error) {
		if ($self->debug) {
		    print "WRONG BRANCH :",$self->_name(), "\n";
		}
		return -1;
	    }
	} while ($self->_updateBoard());
	
	$self->displayBoard() if ($self->_findMedium() && $self->debug);
    } while ($self->_unsolved  && $self->_updateBoard());

    if ($self->_unsolved) {
	my $branches = $self->_findHard();
	if ($self->debug) {
	    print "*** BRANCHES: \n";
	    foreach (@$branches) {
		print "@{$_} \n";
	    }
	}
	my $sb;

	foreach my $b (@$branches) {
	    $sb = $self->new(
			     $self->_name."/ B(@$b)",
			     $self->debug,
			     $self->pause
			     );
	    foreach my $c (@{$self->{BOARD}}) {
		my $index = ($c->row - 1) * 9 + $c->col - 1;
		$sb->{BOARD}->[$index]->value = $c->value;
		$sb->{BOARD}->[$index]->accept = $c->accept;
	    }
	    my $code;
	    push @$code, $b;
	    $self->displayBoard() if $self->debug;
	    $sb->_moves = $code;
	    $sb->_updateBoard();
	    $sb->solve();
	    push @Route, 'R'; # Branch processed 
	    last if (! $sb->_unsolved);
	}
	# $sb contains the successfull branch;
	# update the parent board ...

	foreach my $c (@{$sb->{BOARD}}) {
	    my $index = ($c->row - 1) * 9 + $c->col - 1;
	    $self->{BOARD}->[$index]->value = $c->value;
	    $self->{BOARD}->[$index]->accept = $c->accept;
	}
	$self->_unsolved = $sb->_unsolved;
	
    }
    return undef;
}

# Function will generate a random board.
# Still under development. 

sub generateBoard {
    my $self = shift;
    while ($self->_generateCell()) {}
}

sub debug {
    my $self = shift;
    $self->{DEBUG} = shift if (@_);
    return $self->{DEBUG};
}

sub pause {
    my $self = shift;

    if (@_) {
	$self->{PAUSE} = shift;
    } else {
	if ($self->{PAUSE} && $self->debug) {
	    print " *** Press ENTER to continue ****\n";
	    my $enter = <STDIN>;
	}
    }
}

##### Internal Functions #####################################################

sub _unsolved :lvalue { $_[0]->{UNSOLVED}; }
sub _moves :lvalue {$_[0]->{MOVES};}
sub _error :lvalue {$_[0]->{ERROR};}
sub _step :lvalue {$_[0]->{STEP};}
sub _name :lvalue { $_[0]->{NAME} ;}

sub _findHard {
    my $self = shift;

    my $cell = (sort { @{$a->accept} <=> @{$b->accept} } grep {! $_->value} @{$self->{BOARD}})[0];
    my $branches;

    foreach my $v ( @{$cell->accept} ) {
	push @$branches, [ $cell->row, $cell->col, $v ];
    }

    push @Route, 'H' if $branches;
    return $branches;
}

sub _findMedium {
    my $self = shift;

    my $notfound = 0;
    my $code;
    my $ccode;
    my $error;

# Go through the board a row by row, locating the cells that in their 'accept' filed have a number that can go only into that cell, e.g

# in case of (12) (13) (234), only cell 3 can accept 4

    for (my $row = 1; $row < 10; $row ++) {
	my %vals;
	# Get all the cells that belong to the row
	my @cells =  grep{ ($_->value == 0) && ($_->row == $row) } @{$self->{BOARD}};

	# Build a hash that will have numbers as its keys and cell coordinates that accept this number as its value
	foreach my $rv (@cells) {
	    foreach my $av (@{$rv->accept}) {
		push @{$vals{$av}}, [$rv->row, $rv->col, $av];
	    }
	}

	# Find those numbers that only have one cell coordinate
	foreach my $key (keys %vals) {
	    if (scalar @{$vals{$key}} == 1) {
		push @$code, pop @{$vals{$key}};
	    }
	}
    }

    if ($code) {
# Found some moves - go and update the board
	$self->_moves = $code;
	push @Route, 'M';
	return scalar(@$code);
    }


# Repeat the same process for columns
    for (my $col = 1; $col < 10; $col ++) {
	my %vals;
	my @cells =  grep{ ($_->value == 0) && ($_->col == $col) } @{$self->{BOARD}};

	foreach my $rv (@cells) {
	    foreach my $av (@{$rv->accept}) {
		push @{$vals{$av}}, [$rv->row, $rv->col, $av];
	    }
	}

	foreach my $key (keys %vals) {
	    if (scalar @{$vals{$key}} == 1) {
		push @$code, pop @{$vals{$key}};
	    }
	}
    }

    if ($code) {
# Found some moves - go and update the board
	$self->_moves = $code;
	push @Route, 'M';
	return scalar(@$code);
    }

# And for squares
    for (my $quad = 1; $quad < 10; $quad ++) {
	my %vals;
	my @cells =  grep{ ($_->value == 0) && ($_->quad == $quad) } @{$self->{BOARD}};

	foreach my $rv (@cells) {
	    foreach my $av (@{$rv->accept}) {
		push @{$vals{$av}}, [$rv->row, $rv->col, $av];
	    }
	}

	foreach my $key (keys %vals) {
	    if (scalar @{$vals{$key}} == 1) {
		push @$code, pop @{$vals{$key}};
	    }
	}
    }

    if ($code) {
# Found some moves - go and update the board
	$self->_moves = $code;
	push @Route, 'M';
	return scalar(@$code);
    }
    
    return 0;
}

sub _findSimple {
    my $self = shift;

    my $notfound = 0;
    my $code;
    my $error;
    $self->_step ++;

    my %cols = ();
    my %rows = ();

    foreach my $p (sort { 10*($a->row <=> $b->row) + ($a->col <=> $b->col) }@{$self->{BOARD}}) {
	next if ($p->value);
	$notfound ++;
	my %vals = map { $_ => 1 } ( qw(1 2 3 4 5 6 7 8 9) );

	my @rvals =  grep{ $_->row == $p->row } @{$self->{BOARD}};
	foreach my $rv (@rvals) {
	    $vals{ $rv->value } = 0;
	}

	my @cvals =  grep{ $_->col == $p->col } @{$self->{BOARD}};
	foreach my $cv (@cvals) {
	    $vals{ $cv->value } = 0;
	}

	my @qvals =  grep{ $_->quad == $p->quad } @{$self->{BOARD}};
	foreach my $rv (@qvals) {
	    $vals{ $rv->value } = 0;
	}

	my @vals = grep { $vals{$_} } sort keys (%vals);
	$p->accept = [ @vals ];
	if (my $num = @vals) {
	    if ($num == 1) {
		my $v = $vals[0];
# Check that we don't have this value yet
		if (grep {($_->[1] == $p->col || $_->[0] == $p->row || $_->[3] == $p->quad) && ($_->[2] == $v)} @$code) {
# Must have gone somewhere wrong - we already assigned this value somewhere in this row/col
		    push @$error, [$p->row, $p->col];
		} else {
		    push @$code, [$p->row, $p->col, $v, $p->quad];
		}

	    }
	} else {
# Must have gone somewhere wrong - there is a cell that does not have a value and cannot accept any values
	    push @$error, [$p->row, $p->col];
	}
    }
    $self->_unsolved = $notfound;
    $self->_moves = $code;
    $self->_error = $error;
    push @Route, 'S' if $code;
    return $code ? (scalar(@$code)) : 0;
}

sub _updateBoard {
    my $self = shift;
    my $code = $self->_moves;

    return 0 unless ($code && @$code);
    if ($self->debug) {
	print "* Updating board:\n";
    }

    while (my $cc = shift (@$code)) {
	my ($i, $j, $v) = @$cc;
	print "SET ($i, $j) = $v\n" if ($self->debug);
	my $index = ($i-1) * 9 + $j - 1;
	my $p = $self->{BOARD}[$index];
	$p->value = $v;
    }    
    return 1;
}

sub _generateCell {

    my $self = shift;

    my $cell = (sort { 10*($a->row <=> $b->row) + 5 * ( @{$a->accept} <=> @{$b->accept} ) + ($a->col <=> $b->col)} grep {! $_->value} @{$self->{BOARD}})[0];

    return 0 unless $cell;

    (print "ERROR!\n" and return 0) unless (scalar(@{$cell->accept}) > 0);
    my $v = $cell->accept->[rand (@{$cell->accept})];

    my $code;
    push @$code, [$cell->row, $cell->col, $v];
    $self->_moves = $code;
    $self->_updateBoard();
    $self->_findSimple();
    return 1;
}


1;

__END__

=head1 NAME

Sudoku - Perl extension for solving Su Doku puzzles

=head1 SYNOPSIS

    use Games::Sudoku::Board;

    my @board = qw(
		   0 2 0 8 1 0 7 4 0
		   7 0 0 0 0 3 1 0 0
		   0 9 0 0 0 2 8 0 5
		   0 0 9 0 4 0 0 8 7
		   4 0 0 2 0 8 0 0 3
		   1 6 0 0 3 0 2 0 0
		   3 0 2 7 0 0 0 6 0
		   0 0 5 6 0 0 0 0 8
		   0 7 6 0 5 1 0 9 0
		   );

   my $game = new Games::Sudoku::Board($game_name, $debug, $pause);

   $game->init(\@board);

   $game->displayBoard();

   $game->solve();

   $game->displayBoard();

   $game->verify();


=head1 DESCRIPTION

    This module solves Su Doku puzzles.

    The puzzle should be stored in a single dimension array or in a file, where unknown characters presented by zero

    A sample code along with test layouts can be found in examples directory of this distribution.


=head1 TODO

    - Add error handling and invalid layout capture

    - Add support for 16x16 boards
    
    - Write better documentation



=head1 AUTHOR

    Eugene Kulesha, <kulesha@gmail.com>

=head1 COPYRIGHT AND LICENSE

    Copyright (C) 2005 by Eugene Kulesha

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself, either Perl version 5.8.4 or,
    at your option, any later version of Perl 5 you may have available.



=cut
