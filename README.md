# IBMFTP-historical
This was a terminal emulator and file transfer program I wrote near the beginning of my career.

Written at SRI International ~1982, for the original IBM PC, this was designed to allow users
of the central computer facilities (where I worked) to use the PCs as termainls for the mainframes,
and transfer files back and forth using the MODEM2 protocols.  It was set up with knowlege of the
local environment, so that such transfers were a simple matter of hitting a function key and
typing a file name.

At the time, there were few programming environmets available for the PC.  Somewhat paradoxically,
IBM's BASICA interpreter had better capabilities for dealing with serial communications than DOS
itself, and most of the user interface of this progam is written in BASIC.

BASIC wasn't fast enough to do terminal emulation, so THAT part of the program was written
in x86 Assembly lanaguage, processed by an MIT-authored cross-assembler.  The code emulated
a Heath-19 terminal (popular at the time, and with enough smarts to run display editors.)
(BASIC also had surprisingly good facilities for "calling" assembly language.)

IBMFTP.BAS - the main program, in BASICA.
HEATH.A86 - the Heath terminal emulator.
CHKSUM.A86 - compute the MODEM2 checksum (also in assembly, for speed, and for the math.)
