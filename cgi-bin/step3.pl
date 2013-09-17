#!/usr/local/bin/perl

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw( :standard);
use DBI;
use Template;
print "Content-type: text/html; charset=utf8 \n\n";

my $tt2 = Template->new({
INCLUDE_PATH => '../temp',
INTERPOLATE  => 1,
}) || die "$tt2::ERROR\n";

my $dns = 'DBI:mysql:imgx1_claster:localhost';
my $db_user_name = 'imgx1_claster';
my $pass = 'tapochek';
my $dbh = DBI->connect($dns, $db_user_name, $pass) or die "Error in Query for DB".DBI::errstr;

$dbh->do("SET NAMES utf8");
my $claster_index=cookie("claster_id");

my @companies_in_claster = param("dynamic_i");
my @indexes_i;
my @companies_out_claster = param("dynamic_o");
my @indexes_o;
my $claster_index=cookie("claster_id");
my %cmp_i;
my %cmp_o;
my %features;

foreach my $comp (@companies_in_claster) {
		my $sth = $dbh->prepare("SELECT company_id FROM companies WHERE name='$comp';");
		$sth->execute or die "Error in Query for DB".DBI::errstr;
		my $company_id = $sth -> fetchrow_array;
		my $rows_of_query = $sth -> rows;
		my $compn = $comp;
		if(($rows_of_query == 0) && ($comp ne "")) {
			$dbh->do("insert into companies (name) values('$comp');")
				or die "Error in Query for DB".DBI::errstr;			
			my $sth1 = $dbh->prepare("SELECT company_id FROM companies WHERE name='$comp';");
			$sth1->execute or die "Error in Query for DB".DBI::errstr;
			$company_id = $sth1 -> fetchrow_array;
		}
		$cmp_i{$company_id} = $comp;
}

foreach my $comp1 (@companies_out_claster) {
		my $sth = $dbh->prepare("SELECT company_id FROM companies WHERE name='$comp1';");
		$sth->execute;
		my $company_id = $sth -> fetchrow_array;
		my $rows_of_query = $sth -> rows;
		if(($rows_of_query == 0) && ($comp1 ne "")) {
			$dbh->do("insert into companies (name) values('$comp1');") 
					or die "Error in Query for DB".DBI::errstr;			
			my $sth1 = $dbh->prepare("SELECT company_id FROM companies WHERE name='$comp1';");
			$sth1->execute or die "Error in Query for DB".DBI::errstr;
			$company_id = $sth1 -> fetchrow_array;
		}
		$cmp_o{$company_id} = $comp1;
}

foreach (keys %cmp_i) {
		$dbh->do("insert into rel_clasters_companies values($claster_index, $_);")
			or die "Error in Query for DB".DBI::errstr;
}

foreach (keys %cmp_o) {
		$dbh->do("insert into rel_no_clasters_companies values($claster_index, $_);")
			or die "Error in Query for DB".DBI::errstr;
}			
$sth = $dbh->prepare("SELECT feature_id FROM rel_features_clasters WHERE claster_id='$claster_index';");
$sth->execute 
	or die "Error in Query for DB".DBI::errstr;
my $rows = $sth->rows;


my $i;
my @feature_id;

for ($i = 0; $i < $rows; $i++) {   
   push (@feature_id, $sth->fetchrow_array);
}

foreach my $id (@feature_id) {
	my $sth11 = $dbh->prepare("SELECT name FROM features WHERE feature_id='$id';");
	$sth11->execute 
	or die "Error in Query for DB".DBI::errstr;
	my $feature = $sth11 -> fetchrow_array;
	$features{$id}=$feature;
}
my $vars={
	features => \%features,
	companies_i => \%cmp_i,
	companies_o => \%cmp_o,
	c => $compn
};
 
$sth->finish;
$dbh->disconnect;


$tt2->process("step3.html", $vars);

#end
