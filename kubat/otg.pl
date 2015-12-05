#!/usr/bin/env perl

use strict;
use Data::Dumper;
use Getopt::Std;
use constant {

    # The version of this script.
    # 1.00 [KK 2011-10-18] First version
    # 1.01 [KK 2011-10-26] Reworked Grid class to use hashrefs for
    #   the board. Added typical usage to the info output.
    # 1.02 [KK 2012-02-13] Two Perl warnings avoided, thanks Stuart Skelton!
    VER => '1.02',

    # More info at Steve Gibson's site..
    ORGURL => 'https://www.grc.com/offthegrid.htm',

    # Author of this script
    AUTHOR => 'Karel Kubat, karel@kubat.nl, http://www.kubat.nl',
    
    # The grid alphabet. Also defines the size.
    ALPHABET => 'abcdefghijklmnopqrstuvwxyz',

    # Number of times each row/col must get swapped before we consider
    # a grid random enough.
    NSWAPS => 100,
};

# Parse commandline flags and check them
my %opts = ( n => NSWAPS,
	     a => ALPHABET );
getopts('s:a:gl:n:v', \%opts) or usage();
die("Bad -n swaps\n") if ($opts{n} < 1);

# Take action
my $grid = Grid->new($opts{a});
$grid->generate($opts{n}) if ($opts{g});
$grid->load($opts{l})     if ($opts{l});
$grid->verbose()          if ($opts{v});

my $action = shift(@ARGV) || '';
if ($action eq 'print' and $#ARGV == -1) {
    print($grid->asstring());
} elsif ($action eq 'encryptfile' and $#ARGV == 0) {
    my $cont = '';
    open(my $if, $ARGV[0]) or die("$0: Cannot read $ARGV[0]: $!\n");
    while (my $line = <$if>) {
	$cont .= $line;
    }
    $grid->encrypt($opts{s}) if ($opts{s});
    my $enc = $grid->encrypt($cont);
    my $linelen = 0;
    while (length($enc)) {
	print(substr($enc, 0, 2), ' ');
	$linelen += 3;
	if ($linelen > 76) {
	    print("\n");
	    $linelen = 0;
	}
	$enc = substr($enc, 2);
    }
    print("\n") if ($linelen);
} elsif ($action eq 'encryptstring' and $#ARGV == 0) {
    $grid->encrypt($opts{s}) if ($opts{s});
    print($grid->encrypt($ARGV[0]), "\n");
} elsif ($action eq 'decryptfile' and $#ARGV == 0) {
    my $cont = '';
    open(my $if, $ARGV[0]) or die("$0: Cannot read $ARGV[0]: $!\n");
    while (my $line = <$if>) {
	$cont .= $line;
    }
    $grid->encrypt($opts{s}) if ($opts{s});
    print($grid->decrypt($cont), "\n");
} elsif ($action eq 'decryptstring' and $#ARGV == 0) {
    $grid->encrypt($opts{s}) if ($opts{s});
    print($grid->decrypt($ARGV[0]), "\n");
} else {
    print STDERR ("Unknown action $action @ARGV\n") if ($#ARGV > -1);
    usage();
}

# Show usage and croak
sub usage {
    die(
"\n",
"This is OTG V", VER, " - Off The Grid encryption/decryption made easy!\n",
"Read ", ORGURL, " for more info.\n",
"Copyright (c) ", AUTHOR, ".\n",	
"\n",
"Usage:\n",
"  otg -g [-a ALPHABET] [-n SWAPS]          print\n",
"  otg -l FILE [-a ALPHABET]                print\n",
"  otg -l FILE [-a ALPHABET] [-s SEED] [-v] encryptfile FILE\n",
"  otg -l FILE [-a ALPHABET] [-s SEED] [-v] encryptstring STRING\n",
"    Flag -a: Default ALPHABET is ", ALPHABET, "\n",
"    Flag -g: A new grid is generated.\n",
"    Flag -l: A grid is loaded from the FILE (use - for stdin)\n",
"    Flag -n: Default SWAPS is ", NSWAPS, ". More is more random.\n",
"    Flag -s: Seeds encryption/decryption. Default is to start at (0,0).\n",
"    Flag -v: Makes encryption more verbose\n",	
"\n",
"Typical usage:\n",
"  otg -g print > MySecretGrid.txt\n",
"  otg -l MySecretGrid.txt encryptfile Plain.txt > Encrypted.txt\n",
"  otg -l MySecretGrid.txt decryptfile Encrypted.txt\n",
"\n");
}

{
    package Grid;
    use strict;
    use Exporter;
    our @ISA    = qw(Exporter);    
    our @EXPORT = qw(new generate asstring);

    sub new {
	my ($class, $alphabet) = @_;
	my $self  = { alphabet => $alphabet,
		      grid     => undef,
		      x        => 0,
		      y        => 0,
		      dir      => 'h',
		      verbose  => undef
		    };
	
	# Initialize the board
	for my $y (0..length($alphabet) - 1) {
	    for my $x (0..length($alphabet) - 1) {
		$self->{grid}->{$y}->{$x} = 0;
	    }
	}
	
	return bless($self, $class);
    }

    sub verbose {
	my $self = shift;
	$self->{verbose} = 1;
	$self;
    }

    sub msg {
	my $self = shift;
	return unless ($self->{verbose});
	print(@_);
	$self;
    }

    sub generate {
	my ($self, $swaps) = @_;

	# Generate a random sequence from the alphabet
	my @remaining = split('', $self->{alphabet});
	my @matrix;
	while ($#remaining > -1) {
	    my $index = int(rand($#remaining + 1));
	    push(@matrix, $remaining[$index]);
	    splice(@remaining, $index, 1);
	}

	# Fill the table with matrix copies, always shifted over
	for my $y (0..length($self->{alphabet}) - 1) {
	    for my $i (0..$#matrix) {
		if (int(rand(1000000)) & 1) {
		    $matrix[$i] = lc($matrix[$i]);
		} else {
		    $matrix[$i] = uc($matrix[$i]);
		}
	    }
	    for my $x (0..length($self->{alphabet}) - 1) {
		$self->{grid}->{$y}->{$x} = $matrix[$x];
	    }
	    push(@matrix, shift(@matrix));
	}

	# Initialize the swaps counters.
	my (@rowswaps, @colswaps);
	for my $c (0..length($self->{alphabet}) - 1) {
	    $rowswaps[$c] = 0;
	    $colswaps[$c] = 0;
	}

	# Start swaps.
	while (1) {
	    # Swaps needed?
	    my $colswap_needed = undef;
	    for my $c (@colswaps) {
		if ($c < $swaps) {
		    $colswap_needed++;
		    last;
		}
	    }
	    my $rowswap_needed = undef;
	    for my $c (@rowswaps) {
		if ($c < $swaps) {
		    $rowswap_needed++;
		    last;
		}
	    }
	    last unless ($rowswap_needed or $colswap_needed);

	    if ($colswap_needed) {
		my $x1 = int(rand(length($self->{alphabet})));
		my $x2 = int(rand(length($self->{alphabet})));
		for my $y (0..length($self->{alphabet}) - 1) {
		    my $ch = $self->{grid}->{$y}->{$x1};
		    $self->{grid}->{$y}->{$x1} = $self->{grid}->{$y}->{$x2};
		    $self->{grid}->{$y}->{$x2} = $ch;
		}
		$colswaps[$x1]++;
		$colswaps[$x2]++;
	    }
	    if ($rowswap_needed) {
		my $y1 = int(rand(length($self->{alphabet})));
		my $y2 = int(rand(length($self->{alphabet})));
		for my $x (0..length($self->{alphabet}) - 1) {
		    my $ch = $self->{grid}->{$y1}->{$x};
		    $self->{grid}->{$y1}->{$x} = $self->{grid}->{$y2}->{$x};
		    $self->{grid}->{$y2}->{$x} = $ch;
		}
		$rowswaps[$y1]++;
		$rowswaps[$y2]++;
	    }
	}
	return $self;
    }

    sub asstring {
	my $self = shift;
	my $ret = '';

	for my $y (0..length($self->{alphabet}) - 1) {
	    for my $x (0..length($self->{alphabet}) - 1) {
		my $ch = $self->{grid}->{$y}->{$x};
		if (ord($ch)) {
		    $ret .= $ch;
		} else {
		    $ret .= '.';
		}
		$ret .= ' ';
	    }
	    $ret .= "\n";
	}

	return $ret;
    }

    sub load {
	my ($self, $file) = @_;
	open (my $if, $file)
	  or die("$0: Cannot read $file: $!\n");

	my $row = 0;
	while (my $line = <$if>) {
	    chomp($line);
	    $line =~ s{\s*}{}g;
	    last if ($line eq '');

	    $self->msg("Got line: [$line]\n");
	    
	    # Check length requirement
	    die("$0: Input line [$line] doesn't match length of alphabet [",
		$self->{alphabet}, "]\n")
	      if (length($line) != length($self->{alphabet}));

	    my @chars = split('', $line);

	    # Check one-char per line requirement
	    my %count;
	    for my $c (split('', $self->{alphabet})) {
		$count{lc($c)} = 1;
	    }
	    for my $c (@chars) {
		die("$0: Input character [$c] of line [$line] ",
		    "does not occur in alphabet [",
		    $self->{alphabet}, "]\n")
		  if ($count{lc($c)} == 0);
		$count{$c}++;
		die("$0: Input character [$c] of line [$line] occurs twice\n")
		  if ($count{$c} > 2);
	    }

	    # Check one per column requirement.
	    for my $x (0..$#chars) {
		for my $y (0..$row - 1) {
		    die("$0: Input character [", $chars[$x],
			"] of line [$line] ",
			"has occurred previously in this column\n")
		      if ($self->{grid}->{$y}->{$x} eq $chars[$x]);
		}
	    }

	    # All passed. Set into table.
	    for my $x (0..$#chars) {
		$self->{grid}->{$row}->{$x} = $chars[$x];
	    }
	    $row++;
	}
	
	return $self;
    }

    sub encrypt {
	my ($self, $plain) = @_;
	my $ret = '';
	my $count = 0;
	for my $ch (split('', $plain)) {
	    next if (index($self->{alphabet}, lc($ch)) < 0 and
		     index($self->{alphabet}, uc($ch)) < 0);
	    $count++;
	    $self->msg("[$count, at (", $self->{y}, ",", $self->{x},
		       ")] Looking for: [$ch] ",
		       "(output so far: $ret)\n");
	    # $ret .= ' ' if (length($ret) > 0);
	    $ret .= $self->_encrypt($ch);
	}
	return $ret;
    }

    sub _encrypt {
	my ($self, $ch) = @_;
	my $ret = '';
	
	if ($self->{dir} eq 'h') {
	    # Move right or left
	    my $char_x = $self->_colindex($ch);
	    $self->msg("HOR: $ch found at (", $self->{y}, ",$char_x)\n");
	    if ($self->{x} > $char_x) {
		# Move left
		$char_x--;
		$char_x %= length($self->{alphabet});
		for my $i (0..1) {
		    $ret .= $self->{grid}->{$self->{y}}->{$char_x};
		    $char_x--;
		    $char_x %= length($self->{alphabet});
		}
	    } else {
		# Move right
		$char_x++;
		$char_x %= length($self->{alphabet});
		for my $i (0..1) {
		    $ret .= $self->{grid}->{$self->{y}}->{$char_x};
		    $char_x++;
		    $char_x %= length($self->{alphabet});
		}
	    } 
	    $self->{x} = $char_x;
	    $self->{dir} = 'v';
	} else {
	    # Move up or down
	    my $char_y = $self->_rowindex($ch);
	    $self->msg("VER: $ch found at ($char_y,", $self->{x}, ")\n");
	    if ($self->{y} > $char_y) {
		# Move up
		$char_y--;
		$char_y %= length($self->{alphabet});
		for my $i (0..1) {
		    $ret .= $self->{grid}->{$char_y}->{$self->{x}};
		    $char_y--;
		    $char_y %= length($self->{alphabet});
		}
	    } else {
		# Move down
		$char_y++;
		$char_y %= length($self->{alphabet});
		for my $i (0..1) {
		    $ret .= $self->{grid}->{$char_y}->{$self->{x}};
		    $char_y++;
		    $char_y %= length($self->{alphabet});
		}
	    }
	    $self->{y} = $char_y;
	    $self->{dir} = 'h';
	}
	return $ret;
    }

    sub decrypt {
	my ($self, $plain) = @_;
	my $ret;

	$plain =~ s{\s*}{}g;
	die("$0: Input does not split into duets\n")
	  if (length($plain) & 1);
	
	my $i = 0;
	while ($i < length($plain)) {
	    my $duet = substr($plain, $i, 2);
	    $i += 2;
	    my $ch = $self->_decrypt($duet);
	    $self->msg("$duet decoded into $ch (now: x=", $self->{x},
		       ", y=", $self->{y}, ", dir=", $self->{dir}, ")\n");
	    $ret .= $ch;
	}
	return $ret;
    }

    sub _decrypt {
	my ($self, $duet) = @_;

	if ($self->{dir} eq 'h') {
	    # Move right or left.
	    $self->{dir} = 'v';
	    for my $x (0..length($self->{alphabet}) - 1) {
		my $next_x = ($x + 1) % length($self->{alphabet});
		if ( ($self->{grid}->{$self->{y}}->{$x} eq
		      substr($duet, 0, 1)) and
		     ($self->{grid}->{$self->{y}}->{$next_x} eq
		      substr($duet, 1, 1)) ) {
		    # Moved right.
		    $self->{x} = ($next_x + 1) % length($self->{alphabet});
		    return $self->{grid}
		      ->{$self->{y}}
		      ->{($x - 1) % length($self->{alphabet})};
		} elsif ( ($self->{grid}->{$self->{y}}->{$x} eq
			   substr($duet, 1, 1)) and
			  ($self->{grid}->{$self->{y}}->{$next_x} eq
			   substr($duet, 0, 1)) ) {
		    # Moved left.
		    $self->{x} = ($x - 1) % length($self->{alphabet});
		    return $self->{grid}
		      ->{$self->{y}}
		      ->{($next_x + 1) % length($self->{alphabet})};
		}
	    }
	    die("$0: Decryption failed (looking for $duet, ",
		"x=", $self->{x}, ", y=", $self->{y},
		", dir=", $self->{dir}, "\n");
	} else {
	    # Move up or down.
	    $self->{dir} = 'h';
	    for my $y (0..length($self->{alphabet}) - 1) {
		my $next_y = ($y + 1) % length($self->{alphabet});
		if ( ($self->{grid}->{$y}->{$self->{x}} eq
		      substr($duet, 0, 1)) and
		     ( $self->{grid}->{$next_y}->{$self->{x}} eq
		       substr($duet, 1, 1)) ) {
		    # Moved down.
		    $self->{y} = ($next_y + 1) % length($self->{alphabet});
		    return $self->{grid}
		      ->{($y - 1) % length($self->{alphabet})}
		      ->{$self->{x}};
		} elsif ( ($self->{grid}->{$next_y}->{$self->{x}} eq
		      substr($duet, 0, 1)) and
		     ( $self->{grid}->{$y}->{$self->{x}} eq
		       substr($duet, 1, 1)) ) {
		    # Moved up.
		    $self->{y} = ($y - 1) % length($self->{alphabet});
		    return $self->{grid}
		      ->{($next_y + 1) % length($self->{alphabet})}
		      ->{$self->{x}};
		}
	    }
	    die("$0: Decryption failed (looking for $duet, ",
		"x=", $self->{x}, ", y=", $self->{y},
		", dir=", $self->{dir}, "\n");
	}
    }	

    sub _colindex {
	my ($self, $ch) = @_;
	for my $x (0..length($self->{alphabet}) - 1) {
	    return $x if ( ($self->{grid}->{$self->{y}}->{$x} eq lc($ch)) or
			   ($self->{grid}->{$self->{y}}->{$x} eq uc($ch)) );
	}
	die("$0: Internal fry in _colindex\n",
	    "searching for [$ch]\n",
	    "object dump follows\n",
	    ::Dumper($self));
    }

    sub _rowindex {
	my ($self, $ch) = @_;
	for my $y (0..length($self->{alphabet}) - 1) {
	    return $y if ( ($self->{grid}->{$y}->{$self->{x}} eq lc($ch)) or
			   ($self->{grid}->{$y}->{$self->{x}} eq uc($ch)) );
	}
	die("$0: Internal fry in _rowindex\n",
	    "searching for [$ch]\n",
	    "object dump follows\n",
	    ::Dumper($self));
    }
}
