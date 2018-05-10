#!/usr/bin/perl
# By Digdilem. Takes over the air POCSAG pager and automated messages using rtl_fm and multimon-ng and inserts them into a mysql database.
# Free for anyone who wants it.
#
# mysql structure:

#CREATE DATABASE IF NOT EXISTS `sdr_pocsag` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
#--
#-- Table structure for table `sdr_pocsag`
#--
#
#CREATE TABLE `sdr_pocsag` (
#  `id` int(11) NOT NULL,
#  `time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
#  `message` varchar(250) NOT NULL
#) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# Calling command
# rtl_fm -o 4 -A lut -s 22050 -f 153.350M - | multimon-ng -t raw -a POCSAG512 -a POCSAG1200 -a POCSAG2400 -f alpha /dev/stdin | /home/flash/sdr-logger.pl


use DBI;

my $db='sdr_pocsag';
my $dbusername='sdr_pocsag';
my $dbpassword='PASSWORD';
# Database Inits
my $dsn = "DBI:mysql:host=localhost;database=$db";
our $dbh = DBI->connect ($dsn, $dbusername, $dbpassword, { PrintError => 0 })  or die "Cannot connect to server ".DBI->errstr."\n";

# Loop forever or until CTRL+C

while(<>){ # Read stdin
	my $msg = substr $_, 61; # chars offset to start of message
	$msg =~ s/<.*>//g; # Removed <NUL> <DEL> etc
	$msg =~ s/'/"/g;
	# Some dull autoamted filters
	next if $msg =~ /CH3B|GAZ|Errors|AUTOCALL|zabbix| Custom alert|keepalive|RECOVERY:|Nagios|Logcheck/i;
	next if length($msg) < 10; # Empty or crap

	# Check db to see if it already exists - we don't want to store duplicates.
	chomp($msg);
	my $count_sth = $dbh->prepare("SELECT COUNT(*) FROM sdr_pocsag WHERE message = '$msg';");
	$count_sth->execute();
	my $dupecnt=$count_sth->fetchrow;
	if ($dupecnt == 0) {   # Otherwise it's a dupe and we want to ignore it
		print "$msg \n";
		my $sql = "INSERT INTO sdr_pocsag (message) VALUES ('$msg') ";
		$dbh->do($sql);
		}
	}