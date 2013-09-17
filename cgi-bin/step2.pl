#!/usr/local/bin/perl

use CGI::Cookie;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw( :standard);
use DBI;
use Template;


my $tt2 = new Template({
    INCLUDE_PATH=>'../temp'   
});

my $dns = 'DBI:mysql:imgx1_claster:localhost';
my $db_user_name = 'imgx1_claster';
my $pass = 'tapochek';
my $dbh = DBI->connect($dns, $db_user_name, $pass);


$dbh->do("SET NAMES utf8");

my $branch_claster=param("branch");
my $emp_in_region=param("employed_in_region");
my $emp_in_country=param("employed_in_country");

$dbh->do("INSERT INTO branches 
	SET name=\"$branch_claster\", employed_in_country=\"$emp_in_country\", employed_in_region=\"$emp_in_region\" 
	ON DUPLICATE KEY UPDATE employed_in_country=\"$emp_in_country\", employed_in_region=\"$emp_in_region\";");

my $sth=$dbh->prepare("SELECT branch_id FROM branches WHERE name='$branch_claster';");
$sth->execute
	or die "Неудалось выполнить запрос".DBI::errstr;
my $branch_index = $sth -> fetchrow_array;


my $claster_name = param("claster_name");

$dbh->do("INSERT INTO clasters (name) VALUES ('$claster_name');")
		or die "Неудалось выполнить запрос".DBI::errstr;

$sth = $dbh->prepare("SELECT claster_id FROM clasters WHERE name=\"$claster_name\";");
$sth->execute
	or die "Неудалось выполнить запрос".DBI::errstr;
$claster_index = $sth -> fetchrow_array;


$dbh->do("INSERT INTO rel_clasters_branches (claster_id,branch_id) VALUES ('$claster_index','$branch_index');");


my $cookie=new CGI::Cookie(-name => 'claster_id',
			-value => $claster_index,
			-expires => '+1d',
			-path => '/cgi-bin',
			-domain => '.imgx1.tmweb.ru'			
				);


print header(-type => "text/html", -charset=>'utf8', -cookie => $cookie );

my @features_names = param("dynamic");
my @indexes;

foreach my $feature (@features_names) {
		$dbh->do("INSERT IGNORE INTO features (name) VALUES ('$feature');");
		$sth = $dbh->prepare("SELECT feature_id FROM features  WHERE name=\"$feature\";");
		$sth->execute 
				or die "не удалось выполнить запрос".DBI::errstr;
		push(@indexes, $sth -> fetchrow_array);		
}

my @features_weights = param("weight");

my $count = 0;
foreach (0..@indexes-1) {
	my $w = $features_weights[$_];
	if (!((($w !=~ m/^[+-]?\d+$/) || ($w =~ m/^[+-]?\d+\.?\d*$/)) && ($w > 0))) {
		$count = 1;
		last;
	}
}

if ($count == 1) {
	foreach (0..@indexes-1) {
		$dbh->do("INSERT INTO weights_of_features VALUES ($indexes[$_], $claster_index, 1);") 
			or die "не удалось выполнить запрос".DBI::errstr;
	}
}
else {
	foreach (0..@indexes-1) {
		$dbh->do("INSERT INTO weights_of_features (feature_id, claster_id, weight) VALUES ($indexes[$_], $claster_index, $features_weights[$_]);") 
			or die "не удалось выполнить запрос".DBI::errstr;
	}
}



foreach (@indexes) {
		$dbh->do("INSERT INTO rel_features_clasters VALUES ($claster_index, $_);") 
				or die "не удалось выполнить запрос".DBI::errstr;		
}

$sth->finish;
$dbh->disconnect;

$tt2->process("step2.html");

#end