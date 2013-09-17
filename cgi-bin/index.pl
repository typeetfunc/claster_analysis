#!/usr/local/bin/perl

use Set::Scalar;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw( :standard);
use DBI;
use Template;
use strict;
use JSON::XS;
print "Content-type: text/html; charset=utf8 \n\n";

my $tt2 = Template->new({
INCLUDE_PATH => '../temp',
DEFAULT_ENCODING => 'utf8',
ENCODING => 'utf8',
}) || die "$tt2::ERROR\n";

my $dns = 'DBI:mysql:imgx1_claster:localhost';
my $db_user_name = 'imgx1_claster';
my $pass = 'tapochek';
my $dbh = DBI -> connect($dns, $db_user_name, $pass) 
				or die "Error in Query for DB".DBI::errstr;

$dbh->do("SET NAMES utf8");
$dbh -> {'mysql_enable_utf8'} = 1;
my $sth = $dbh -> prepare("SELECT name FROM clasters");
$sth -> execute() 
		or die "Не удалось выполнить запрос".DBI::errstr;

my @clasters_name;
while ( defined(my $name = $sth -> fetchrow_array) ){
	push (@clasters_name,$name);	
}
my $json_array=JSON::XS->new()->latin1->pretty->encode(\@clasters_name);

my $vars={
		array_claster => $json_array
	};
$tt2->process("step1.html",$vars);

$dbh -> disconnect();
