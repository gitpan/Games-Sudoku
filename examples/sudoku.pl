#!/usr/bin/perl

use strict;
use warnings;
use lib "../lib";

use Games::Sudoku::Board;
use Getopt::Long;

my ($fname, $pause, $debug) = ('', 0, 0);

GetOptions('file=s' => \$fname, 'pause' => \$pause, 'debug' => \$debug);

my $game = new Games::Sudoku::Board;

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


if ($fname) {
    $game->initFromFile($fname);
} else {
    $game->init(\@board);
}

$game->debug($debug);

$game->pause($pause);

$game->displayBoard();

$game->solve();

$game->displayBoard();

