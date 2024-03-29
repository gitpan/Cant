package Cant;

require 5.005_62;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Cant ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	cant
	wcant
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	cant
	wcant
);
our $VERSION = '1.01';

#
# cant and wcant -- print an error message and optionally die when a
#	system or library call fails.
#

sub _cant_fmt {
    my(@pre, @post, $first);
    @pre = "$0: Unable to ";
    $first = shift;
    if ($first =~ s:^\n::) {
	unshift @pre, "\n";
    }
    unshift @_, $first;
    if (substr($_[-1], -1, 1) eq "\n") {
	# Strip the newline
	@post = ( substr( pop @_, 0, -1) );
    } else {
	if ($!) {
	    # Stick the errno message on the end
	    @post = ( ": $!" );
	} elsif ($?>>8 == 0) {
	    # Do nothing.  No errno, no last program return code --
	    # it's kind of ambiguous
	} elsif (($? & 0377) == 0) {
	    # Error return from program
	    @post = ( ": program returned ", $? >> 8 );
	} elsif (($? & 0377) == 0177) {
	    # 'stopped' return from program
	    @post = ( ": program stopped with signal ", $? >> 8 );
	} else {
	    # Death by signal
	    @post = ( ": program died with signal ", $? & 0177 );
	    push @post, ", coredumped"		if $? & 0200;
	}
	my($temp) = $_[0];
	if ($temp =~ s:\n: join("", @post, "\n") :e) {
	    shift @_;
	    @post = ();
	    push @pre, $temp;
	}
    }
    (@pre, @_, @post)
}

sub cant {
    my($package, $file, $line) = caller;
    @_ = &_cant_fmt;
    if (!defined $package || $package eq "main" || $package eq "") {
	die @_, " at $file line $line\n"
    } else {
	goto &croak
    }
}

sub wcant {
    my($package, $file, $line) = caller;
    @_ = &_cant_fmt;
    if (!defined $package || $package eq "main" || $package eq "") {
	warn @_, " at $file line $line\n"
    } else {
	goto &carp
    }
}

1
__END__
=head1 NAME

Cant - Perl extension for easy error messages

=head1 SYNOPSIS

  use Cant;

  open(FOO, "foo")		or cant "open 'foo'";
  $pid = fork();
  defined $pid			or cant "fork";
  ! system("some command")	or wcant "run 'some command'";

  print "Prepping system...";
  !system("foo")		or cant "\nrun foo";

=head1 DESCRIPTION

The Cant module provides easy shorthands for warning and dieing of
system or library errors.  The messages generated by C<cant> and
C<wcant> always begin with the program name (from $0), a colon, and
then "Unable to" and the first argument to C<cant> or C<wcant>.  As
a result, you can usually write your C<cant> invocations so as be
sensical when read in the script and get sensical errors message
out.

The exact message generated depends on the values of the $! and $?
variables.  The first match is choosen from the following possibilities:

=over 4

=item *

If the last argument to C<cant> or C<wcant> ends with a newline,
nothing will be used.

=item *

If $! is not empty/zero, the value ": $!" is used.

=item *

If the exit status found in $? is a normal exit of zero, nothing
is will be used.

=item *

If a non-zero normal exit status is found in $?, the text ": program
returned" and the actual exitcode will be used.

=item *

If a 'stopped by signal' exit status is found in $?, the text ":
program stopped with signal " and the signal number will be used.
Note that you'll normally only see such exit statuses if you pass
the WUNTRACED flag to waitpid().

=item *

If a 'death by signal' exit status is found in $?, the text ":
program died with signal " and the signal number will be used.  If
the process codedumped in the process, the text ", coredumped" will
the added to that.

=back

The text from the above will be put after all other arguments to
C<cant> or C<wcant>, unless the first argument contains a newline
anywhere but at the very beginnning.  If there is such a non-leading
newline, the text will be inserted immeadiately after that newline.

Finally, the text " at I<filename> line I<line>\n" will be
added at the very end containing the actual filename and line number
of the call to C<cant> or C<wcant>.

If the first argument starts with a newline, that newline will be
suppressed from its apparent place in the message and instead a
newline will be put at the start of the message, before anything
else.  This allows you to force a leading newline when you think
the message will be generated while they're already on the current
line, as in the last example in the SYNOPSIS.

=head1 BUGS

The formatting rules are too complicated.

=head1 HISTORY

=over 8

=item 1.00

Finally gave Cant.pm the wrapping of a module.  The earliest version
of cant() was simply
    sub cant { die "$0: Unable to", @_, ": $!" }

It evolved from there first to add handling of program errors ($?),
then newline formatting singals, and finally the "trailing newline
means no extra message".  You've come a long way, baby...

=item 1.01

If cant() or wcant() appears to be called from a package besides
main they'll now invoke croak/carp instead of die/warn.

=back

=head1 AUTHOR

Philip Guenther, guenther@gac.edu

=head1 COPYING

Copyright (C) 1998-2000, Philip Guenther.  All rights reserved.
This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perlfunc(1).

=cut
