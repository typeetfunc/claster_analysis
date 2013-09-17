#!/usr/bin/perl -w

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw( :standard);
use PDL;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use List::MoreUtils qw(pairwise ) ;
use PDL::Matrix;
use PDL::MatrixOps;
use Template;
use DBI;
use JSON::XS;
use Set::Scalar;

print "Content-type: text/html;charset=utf8\n\n";

my $tt2 = new Template({
    INCLUDE_PATH=>'../temp'
});

=pod

is_array_of(type:string,array:array):bool;
Тип:Предикат.
Принимает:строка из данного диапазона:"SCALAR","ARRAY","HASH","CODE".
Возвращает:истину если все определенные значения в массиве пренадлежат данному типу.
Побочный эффект: ---.

=cut
sub is_array_of ($@) {
	my ($type,@array) = @_;
	if ($type eq "SCALAR"){
		$type = "";
	}
	@array = grep {defined($_)} @array;
	@array !=0 or return 1; 
	my $count_ref = grep { ref( $_ ) eq $type } @array;
	if ( $count_ref == @array){
		return 1;
	} else {
		return;
	} 
}
=pod

select_column_matrix(matrix:array of array,x:integer):array;
Тип:Функция, без побочных эффектов.
Принимает:двумерный массив и номер столбца в данном массиве
Возрашает:столбец двумерного массива соотвествующий номеру столбца.
Побочный эффект: ---.

=cut
sub select_column_matrix (\@$){
	my ($matrix,$x)=@_;
	is_array_of "ARRAY",@$matrix 
			or die "Неподходящий формат входных данных - данный массив содержит не только ссылки на массивы";
	my @column = map { $_->[$x] } @$matrix; 	
	return @column;
}

=pod

mean(list:array):real;
Тип:Функция.
Принимает: список чисел.
Возращает: арифметическое среднее списка своих аргументов.
Побочный эффект: ---.

=cut
sub mean {	
	is_array_of "SCALAR",@_ 
			or die "Неподходящий формат входных данных - данный массив содержит не только скалярные данные";
	my $sum = sum @_;
	my $count = grep { defined($_) } @_;
	$count !=0 or return;  	
	return $sum/$count;
}

=pod

p_norm(pow:int):lambda(vector1:array,vestor2:array,weights:array):real;
Тип:Карринг-Функция.
Принимает:целое четное число(в случае несоотвествия число округляется вверх до ближайшего подходящего).
Возращает:Функцию реализующую метрику Евклида со степенью pow для двух векторов.
Побочный эффект: ---.

=cut
sub p_norm ($) {
	my $pow = shift @_;
	$pow > 1 or $pow = 2;
	($pow % 2) == 0 or $pow++;
	return sub {
		my ($vector1,$vector2,$weights) = @_;		
		foreach ($vector1,$vector2){
			is_array_of "SCALAR",@$_ 
				or die "Неподходящий формат входных данных - данный массив содержит не только скалярные данные";
		}
		my @substr_in_sq = pairwise { ($a - $b)**$pow } @$vector1,@$vector2;
		@substr_in_sq = pairwise { $a * $b} @substr_in_sq,@$weights;	
		my $sum = sum @substr_in_sq;	
		return $sum**(1/$pow);
	}
}

=pod

manhatten_norm(vector1:array,vestor2:array,weights:array):real;
Тип:Функция.
Принимает:2 вектора значений, вектор весов для компонент векторов значений.
Возращает:растояние между векторами посчитанное при помощи "манхэтанской"" метрики("растояние городских кварталов").
Побочный эффект: ---.

=cut
sub manhatten_norm (\@\@\@) {
	my ($vector1,$vector2,$weights) = @_;	
	foreach ($vector1,$vector2){
		is_array_of "SCALAR",@$_ 
				or die "Неподходящий формат входных данных - данный массив содержит не только скалярные данные";
	}
	my @substr_vec = pairwise { abs($a - $b) } @$vector1,@$vector2;	
	@substr_vec = pairwise { $a * $b } @substr_vec,@$weights;
	my $sum = sum @substr_vec;	
	return $sum;
}

=pod

cov(vector1:array,vestor2:array):real;
Тип:Функция.
Принимает:2 вектора значений.
Возращает: коварицию для 2 векторов.
Побочный эффект: ---.

=cut
sub cov (\@\@){
	my ($x,$y) = @_;	
	my @xy = pairwise { $a * $b } @$x,@$y;
	return  (mean @xy)-((mean @$x)*(mean @$y));
}

=pod

normaliz_by_square_deviation(list:array):array
Тип:Функция.
Принимает:вектор значений.
Возращает:нормированный вектор значений - из вектора вычитается среднее вектора,
далее вектор делится на среднеквадратичное отклонение вектора.
Побочный эффект: ---.

=cut
sub normaliz_by_square_deviation{
	my @vector = @_;	
	my $dispersion = cov @vector,@vector;	
	my $square_deviation = sqrt(@vector/(@vector-1)*$dispersion) || return @vector;	;	
	my $mean = mean @vector;	
	my @norm_vector = map { ($_ - $mean)/ $square_deviation } @vector;	
	return @norm_vector;
}

=pod

normaliz_by_func(func:function):lambda(list:array):array;
Тип:Карринг-Функция высшего порядка..
Принимает:Функцию от вектора возращающюю вещественное число != 0.
Возращает: Функцию нормирующюю вектор значений делителем который возврашает func.
Побочный эффект: ---.

=cut
sub normaliz_by_func(\&){
	my $func = shift @_;
	return sub {
		my @vector = @_;
		my @norm_vector = map { abs($_) } @vector;
		my $divisor = &$func(@norm_vector) || return @vector;	
		@norm_vector = map { $_/$divisor } @vector;	
		return @norm_vector;
	}	
}

=pod

triang_matrix_min_idx(matrix:array of array):pair;
Тип:Функция.
Принимает:двумерный массив.
Возращает:индексы минимального элемента в верхнем треугольнике матрицы(не включая главную диагональ).
Побочный эффект: ---.

=cut
sub triang_matrix_min_idx (\@){
	my $matrix = shift @_;
	my ($i_min,$j_min);
	my $min = 100000000000;
	for my $i (0..@$matrix-1){
		for my $j ($i+1..@{$matrix->[$i]}-1){
			if (defined($matrix->[$i][$j]) and $matrix->[$i][$j] < $min){
				($i_min,$j_min,$min) = ($i,$j,$matrix->[$i][$j]);				
			}
		}
	}		
	return ($i_min,$j_min);
}

=pod

transpose_matrix (matrix:array of array):array of array;
Тип:Функция.
Принимает:матрица - двумерный массив.
Возращает:транспонированная матрица(двумерный массив) .
Побочный эффект: ---.

=cut
sub transpose_matrix (\@){
	my $matrix = shift @_;
	is_array_of "ARRAY",@$matrix 
			or die "Неподходящий формат входных данных - данный массив содержит не только ссылки на массивы";	
	my @len = map { scalar @$_ } @$matrix;
	my $n = max @len;
	my @tran_matrix;
	foreach (0..$n-1){
		my @next_column = select_column_matrix @$matrix,$_;
		push (@tran_matrix,[@next_column]);
	}
	return @tran_matrix;
}

=pod

make_z_features_matrix(features:array of array,func_norm:function):array of array;
Тип:Функция высшего порядка.
Принимает:матрица значений характеристик объектов анализа в следующем формате
	:столбцы - индексы характеристик
	:строки - индексы обьектов.
Возращает: матрица к каждому столбцу которой приминена функция нормировки.
Побочный эффект: ---.

=cut
sub make_z_features_matrix (\@\&){
	my ($features,$func_norm) = @_;
	my @z_features = transpose_matrix @$features;
	@z_features = map { [ &$func_norm(@$_) ] } @z_features;
	@z_features = transpose_matrix @z_features;
	return @z_features;
}

=pod

make_matrix_distance (features:array of array,weights:array,metric:function):array of array;
Тип:Функция высшего порядка.
Принимает:матрица значений характеристик объектов анализа, массив весов значимости характеристик,функция реализующая метрику.
Возращает:матрица растоянний между объектами - взвешенный граф.
Побочный эффект: ---.

=cut
sub make_matrix_distance (\@\@\&){
	my ($features,$weights,$metric) = @_;	
	my @matrix;
	my $n=@$features-1;
	foreach my $i (0..$n){
		foreach my $j (0..$n){
			if ($i < $j){
				$matrix[$i][$j] = &$metric( $features->[$i],$features->[$j],$weights,@$features);
			} elsif ($i > $j){
				$matrix[$i][$j] = $matrix[$j][$i];
			} else {
				$matrix[$i][$i] = 0;
			}						
		}		
	}	
	return @matrix;
}

=pod

sum_square_of_deviation (features:array of array, claster1:array, claster2:array):real;
Тип:Функция.
Принимает:матрица значений характеристик объектов анализа, список объектов в первом кластере, список объектов во втором кластере.
Возращает:сумму квадратов отклонений значений характеристик объектов содержащихся в двух кластерах от средних значений характеристик.
Побочный эффект: ---.

=cut
sub sum_square_of_deviation (\@\@\@) {
	my ($features,$claster1,$claster2)=@_;
	my @claster = (@$claster1,@$claster2);
	my @features_claster = @$features[ @claster ];
	my $n_features=@{ $features->[0] };
	my @square_of_deviation;
	foreach (0..$n_features-1){
		my @vector_feature = select_column_matrix @features_claster,$_;
		my $mean = mean @vector_feature;
		@vector_feature = map { ($_ - $mean)**2 } @vector_feature;
		push @square_of_deviation,(sum @vector_feature);
	}
	return sum @square_of_deviation;
}

=pod

select_subgraph_value(graph:array of array, nodes1:array, nodes2:array):array;
Тип:Функция.
Принимает: матрица смежности взвешенного графа,первый список вершин, второй список вершин.
Возращает: веса ребер подграфа на ребрах инцедентных сразу вершинам из первого и второго списка.
Побочный эффект: ---.

=cut
sub select_subgraph_value(\@\@\@){
	my ($graph,$nodes1,$nodes2) = @_;
	my @subgraph;
	foreach my $node1 (@$nodes1){
		foreach my $node2 (@$nodes2){
			unless ($node1 == $node2){
				push @subgraph,$graph -> [$node1][$node2];
			}			
		}
	}
	return @subgraph;
}


sub rule_nearest_neighbor (\@\@\@){
	return min &select_subgraph_value(@_);	
}
sub rule_mean_neighbor (\@\@\@){
	return mean &select_subgraph_value(@_);
}
sub rule_farthest_neighbor (\@\@\@){
	return max &select_subgraph_value(@_);
}
sub rule_central_neighbor (\@\@\@){
	# body...
}

=pod

make_func_distance(func:function,$matrix):lambda;
Тип:Карринг - Функция высшего порядка.
Принимает: Функция являющаяся мерой растоянния между двумя наборами объектов, матрица необходимая этой функции для определения растояния.
Возращает: Функция опеределяющая растоянние между кластерами: lambda(clast1:array,clast2:array):real;
					Тип:Функция - замыкание.
					Принимает:список объектов первого кластера, список объектов второго кластера.
					Возращает:растояние между двумя кластерами.
					Побочный эффект: ---. .
Побочный эффект: ---.

=cut
sub make_func_distance (\&\@){
	my ($func,$matrix) = @_;
	return sub {
		my ($clast1,$clast2) = @_;		
		return &$func($matrix,$clast1,$clast2);		
	}
}

=pod

make_target_func(func_distance:function):lambda;
Тип:Карринг - Функция высшего порядка.
Принимает: Функция опеределяющая растоянние между кластерами.
Возращает: Функция создающая для набора кластеров табличную целевую функцию: lambda(clasters:array of sets):array of array;
					Тип:Функция - замыкание.
					Принимает:список кластеров.
					Возращает:таблицу "растоянний" между кластерами.
					Побочный эффект: ---.
Побочный эффект: ---.

=cut
sub make_target_func (\&) {
	my ($func_distance) = @_;
	return sub {		
		my $n = @_ - 1;
		my @target_func;
		foreach my $i (0..$n-1){
			foreach my $j ($i+1..$n){		
				$target_func[$i][$j] = &$func_distance(\@{ $_[$i] }, \@{ $_[$j] });
			}
		}
		return \@target_func;
	}
}

=pod
agglomerative_hierarchical_analysis(func_distance:function):lambda;
Тип:Карринг - Функция высшего порядка.
Принимает: Функция опеределяющая растоянние между кластерами.
Возращает: Функция проводящая процедуру иерархического анализа для некотрой матрицы растояний 
и функции растояния:lambda($m_distance:array of array):array of sets;
					Тип:Функция - замыкание.
					Принимает:Матрица растояний, необходимая для первого шага любого иерархического анализа  -
					- объединение двух самых близких объектов.
					Возращает:список шагов выполнения метода(шаг - множество объединенных объектов на этом шаге),список
					значений растояния между объединенными объектами для каждого шага.
					Побочный эффект: ---.
Побочный эффект: ---.
=cut
sub agglomerative_hierarchical_analysis(\&){
	my ($func_distance) = @_;
	return sub {
		my ($m_distance) = @_;
		$m_distance or die "Отсутсутвует матрица растояний между объектами";
		my @clasters = map { $_ = Set::Scalar->new($_) } (0..@$m_distance-1);		
		my ($i_min,$j_min) = triang_matrix_min_idx @$m_distance;		
		$clasters[$i_min]+= $clasters[$j_min];
		my (@union_obj,@dist);
		push @union_obj,$clasters[$i_min];
		push @dist,$m_distance->[$i_min][$j_min];
		splice @clasters,$j_min,1;						
		my $target_func = make_target_func &$func_distance;
		while (@clasters > 1){
			my $link_tf_table = &$target_func (@clasters);			
			($i_min,$j_min) = triang_matrix_min_idx @$link_tf_table;			
			$clasters[$i_min]+= $clasters[$j_min];
			push @union_obj,$clasters[$i_min];
			push @dist,$link_tf_table->[$i_min][$j_min];
			splice @clasters,$j_min,1;
		}		
		return \@union_obj,\@dist;
	}
}



=pod
replace_in_list_set(list:array of set,pattern:set,val:scalar):array of set;
Тип:Функция.
Принимает:массив множеств,заменяемое подмножество, значение на которое заменяеться подмножество .
Возращает: массив множеств, в каждом из которох искомое подмножество заменено на некотрое значение.
Побочный эффект: ---.

=cut
sub replace_in_list_set (\@$$){
	my ($list,$pattern,$val) = @_;
	my @res = map {$_->clone} @$list;
	@res = map {
		if ($pattern < $_){
			$_ = $_ - $pattern;
			$_->insert($val);
		}else{
			$_;
		}
	} @res;
	return @res;
} 

=pod

list_idx_to_list_value(list_idx:array,list_val:array):array;
Тип:Функция.
Принимает:список индексов, список значений .
Возращает: заменяет в списке индексов индексы на значения, располагающиеся по соотвествующим индексам в списке значений.
Побочный эффект: ---.

=cut
sub list_idx_to_list_value (\@\@){
	my ($list_idx,$list_val) = @_;
	my $set_idx = Set::Scalar->new(0..@$list_val);
	my @res = map { $set_idx->has($_) ? $list_val->[$_] : $_ } @$list_idx;
	return @res;
}


=pod
list_obj_to_name(steps:array of sets, names_step:array of string, names_company: array of string):array of array;
Тип:Функция.
Принимает: массив шагов метода, массив названий шагов, массив названий объектов.
Возращает: массив шагов метода с подставленными названиями объектов и свернутыми объектами в шаги метода.
Побочный эффект: ---.

=cut
sub list_obj_to_name (\@\@\@){
	my ($steps,$names_step,$names_company) = @_;
	my @steps = @$steps;
	my @new_steps;	
	foreach my $name (@$names_step){
		my $step = $steps[0];	
		@steps = @steps[1..@steps-1];	
		@steps = replace_in_list_set @steps,$step,$name;
		my @new_step = $step->elements();
		my @named_list = list_idx_to_list_value @new_step,@$names_company;
		push @new_steps, [@named_list];
	}
	return @new_steps;
}


=pod
list_step2bin_treeD3(list_step:array of array, list_name:array, list_dist:array):JSON string;
Тип:Функция.
Принимает:массив шагов метода, массив названий шагов, массив расстояний шагов метода.
Возращает:иерехическое дерево в формат D3.js.Пример:
{
        'name': 'name1',
		'children: [{
			'name': 'subname1',
			'children: [...]
		}, {
		    'name': 'subname2'
		}]
	},
	{
		'name': 'name2',
	}    

Побочный эффект: ---.

=cut
sub list_step2bin_treeD3 (\@\@\@){
	my ($list_step,$list_name,$list_dist) = @_;
	my $set_names_step = Set::Scalar->new(@$list_name);
	my ($count,%hash_steps);
	foreach my $name (@$list_name){
		my @children = map { $set_names_step->has($_) ? $hash_steps{$_} : {name => $_ } } @{$list_step->[$count]};		
		$hash_steps{$name} = {name => $name, children => [@children],size => $list_dist->[$count]}; 
		$count++;
	}	
	my $json_bin_tree = JSON::XS->new()->latin1->pretty->encode($hash_steps{$list_name->[-1]});
	return $json_bin_tree;
}


=pod
process_claster_analiz(matr_dist:array of array, company: array of string,method:function,name_of_step:string):
				in list context - (array of array,JSON string),in scalar context - array of array;
Тип:Функция высшего порядка.
Принимает: Матрица растояний, массив имен объектов, функция осуществляющая иерархический анализ, строк - имя шага.
Возращает: список шагов метода, иерархической дерево.
Побочный эффект: ---.

=cut
sub process_claster_analiz(\@\@\&$){
	my ($matr_dist,$company,$method,$name_of_step) = @_;
	my ($list_sets_steps,$list_distance) = &$method($matr_dist);
	my @names_step = map { "$name_of_step".$_ } (1..@$list_sets_steps);
	my @list_named_obj = list_obj_to_name @$list_sets_steps,@names_step,@$company;
	my $json_bin_tree = list_step2bin_treeD3 @list_named_obj,@names_step,@$list_distance;
	my $count;
	my @list_named_obj = map { {distance=>$list_distance->[$count++],children=>$_} } @list_named_obj;
	wantarray ? return (\@list_named_obj,$json_bin_tree) : return \@list_named_obj;
}

=pod
make_selecter_this_by_cond(scheme:hash of hash of array):lambda
Тип:Функция высшего порядка.
Принимает: Схема отображающая сущности в названия таблиц и доменов таблиц БД.
Возращает: Функция генерирущая SQL по данной схеме c некотрым условие
:lambda(this:string, cond:interpolate string):array of string;
Побочный эффект: ---.

=cut
sub make_selecter_this_by_cond (\%){
	my $scheme = shift @_;
	return sub {
		my ($this,$cond) = @_;
		my @sql_str;
		foreach my $FROM ( @{ $scheme->{$this}{FROM} } ){
			my $sql; 
			my $that_select = join ', ',@{ $scheme->{$this}{SELECT} };
			if ($cond){
				$sql = join ' ',('SELECT',$that_select,'FROM',$FROM,'WHERE',$cond);
			} else {
				$sql = join ' ',('SELECT',$that_select,'FROM',$FROM);
			}		
			$sql = join '',$sql,';';		
			push @sql_str,$sql;
		}
		wantarray ? return @sql_str : return $sql_str[0]; 
	}	
}

=pod
make_performer_sql(db:DBI_connection_object):lambda
Тип:Функция высшего порядка.
Принимает: Обьект DBI отвечающий за взаимодействие с базой данных.
Возращает: Функция выполняющая список SQL запросов и обьединяющая результаты этих запросов
:lambda(sql_str:array of string):in list context (array OR array of array, array), in scalar context array OR array of array;
Побочный эффект: выполнение запросов к базе данных, связанной с данных объектом DBI.

=cut
sub make_performer_sql($) {
	my $db = shift @_;
	return sub {
		my @sql_str = @_;
		my (@res,@row);
		foreach my $sql (@sql_str){
			my $sth = $db->prepare($sql) or die "не удалось подготовить запрос:".DBI::errstr;
			$sth->execute()	or die "не удалось запустить запрос:".DBI::errstr;
			my $res_arr_ref = $sth->fetchall_arrayref;			
			if (@$res_arr_ref == 1 and @{$res_arr_ref->[0]} == 1){
				push @res, @{$res_arr_ref->[0]};							
				push @row,1;
			} else {			
				push @row,(scalar @$res_arr_ref);						
				push @res,@$res_arr_ref;			
			}		
		}		
		wantarray ? return (\@res,@row) : return \@res;
	}		
}


#схема БД по которой генерится SQL
my %SCHEME = (company => {  FROM => ["rel_clasters_companies NATURAL JOIN companies", 
									"rel_no_clasters_companies NATURAL JOIN companies"],
							SELECT => ["company_id","name"]
						 },
			  feature => { 	FROM => ["rel_features_clasters NATURAL JOIN features"],
			  				SELECT => ["feature_id", "name"]
			  			 },
			   weight => { 	FROM => ["weights_of_features"],
			  				SELECT => ["weight"]
			  			 },
			   emp_info_generic => { FROM => ["emp_info"],
			   						 SELECT => ['*']
			   					   },
			   emp_info_branch => { FROM => ["rel_clasters_branches	NATURAL JOIN branches"], 
			   						SELECT => ["employed_in_country", "employed_in_region"]
			   					  },
			   claster_info => { FROM => ["clasters"],
			   					 SELECT => ["name","metrica", "norma", "method_single_link", "pow_pnorm"]			
			   				   }
			  );

#установка соединия с БД 
my $db = DBI->connect('DBI:mysql:imgx1_claster:localhost','imgx1_claster','tapochek')
		or die "Неудачная попытка соединения с базой данных:".DBI::errstr; 
$db->do("SET NAMES utf8");
my $select_this_by_cond = make_selecter_this_by_cond %SCHEME;
my $perform_sql = make_performer_sql $db;

sub select_this_by_cond($;$){
	return &$select_this_by_cond($_[0],$_[1]);
}
sub perform_sql(@){
	return &$perform_sql(@_);
}



my $claster_id = cookie("claster_id") or die "Invalid cookie!";

#получение данных по занятым по росии и области во всех отраслях и в отрасли кластера
my @sql = ( select_this_by_cond('emp_info_generic'), select_this_by_cond('emp_info_branch',"claster_id = $claster_id") );
my $res_sql = perform_sql @sql;



my ($emp_in_country,$emp_in_region,$emp_in_country_branch,$emp_in_region_branch) = map { @$_ } @$res_sql;
#print "EMP INFO -  $emp_in_country, $emp_in_region, $emp_in_country_branch, $emp_in_region_branch<br>"; 
#считаем коэфицент локализации
my $LQ;
eval{
	$LQ = ($emp_in_region_branch/ $emp_in_region) / ( $emp_in_country_branch/$emp_in_country);
} or $LQ = "-1";
#print "LQ - $LQ<br>";

#получение информации о кластере параметрах анализа
$res_sql = perform_sql(select_this_by_cond('claster_info',"claster_id = $claster_id"));
my ($name_claster,$metric, $norm, $func_dist, $pow) = @{$res_sql->[0]};
#print "CLASTER INFO - $name_claster,$metric, $norm, $func_dist, $pow <br>";

#получаем индификаторы и имена компаний участвующих в анализе
($res_sql,my $in_claster,my $out_claster) = perform_sql( select_this_by_cond 'company',"claster_id = $claster_id" );

my @company_id = select_column_matrix @$res_sql,0;
my @company = select_column_matrix @$res_sql,1;
my @idx_claster_company = (0..$in_claster-1);
my @idx_noclaster_company = ($in_claster..$in_claster+$out_claster-1);
#print "company_id - @company_id<br>company_name - @company<br> ";
#print "in clast - $in_claster<br> out_claster - $out_claster<br>";

#получаем индификаторы и названия характеристик которые будут использоваться в анализе
$res_sql = perform_sql select_this_by_cond 'feature',"claster_id = $claster_id";
my @feature_id = select_column_matrix @$res_sql,0;
my @feature = select_column_matrix @$res_sql,1;
#print "feature_id - @feature_id<br>feature_name - @feature<br> ";
#получаем соотвествующие веса характеристик

@sql = map { &select_this_by_cond('weight',"claster_id = $claster_id AND feature_id = $_") } @feature_id ;
$res_sql = perform_sql @sql;
my @weights = @$res_sql;
#print "weights  - @weights<br>";
#разбираем параметры запроса - строим таблицу характеристик
my @values_of_features;
foreach my $comp_id (@company_id){
	my @line_features;
	foreach my $feat_id (@feature_id){		
		my $val = param("$comp_id"."_"."$feat_id");
		push @line_features,$val;
		$db->do("INSERT IGNORE INTO values_of_features (company_id, feature_id, value) VALUES ($comp_id,$feat_id,$val);");		
	}
	push @values_of_features,[@line_features];
}
my $result = $db->disconnect;

#print "@$_ <br> " foreach (@values_of_features);





#хэш устанавливающий соответсвие между параметрами анализа и использующейся нормировкой 
my %func_norm;
$func_norm{by_sq_deviation} = \&normaliz_by_square_deviation;
$func_norm{min} = normaliz_by_func &min ;
$func_norm{max} = normaliz_by_func &max ;
$func_norm{mean} = normaliz_by_func &mean;
#хэш устанавливающий соответсвие между параметрами анализа и использующейся метрикой для определния расстояния между объектами 
my %metrica;
$metrica{mahalonobis} = \&manhatten_norm; #\&mahalonobis_norm;
$metrica{pnorm} = p_norm($pow);
$metrica{ny} = \&manhatten_norm;

my @z_features;
#метрика махалонобиса обладает свойством нормируемости данных ибо учитывает корреляциии
if ($metric eq "mahalonobis"){
	@z_features = @values_of_features;
} else {
	@z_features = make_z_features_matrix @values_of_features, &{ $func_norm{$norm} };
}
#print "@$_ <br> " foreach (@z_features);

my @matrix_distance = make_matrix_distance @z_features,@weights,&{ $metrica{$metric} };

#print "matrix dist:<br>";
#print "@$_<br>" foreach (@matrix_distance);
#print "<br>";
#выбираем из матрицы растояний значения внутри предпологаемого кластера и значения между кластером и окружением
my @claster_graph_val = select_subgraph_value @matrix_distance,@idx_claster_company,@idx_claster_company;
my @out_claster_graph_val = select_subgraph_value @matrix_distance,@idx_claster_company,@idx_noclaster_company;
#находим характеристики этих значений
my ($min_in_claster,$min_out_claster) = ( min(@claster_graph_val), min(@out_claster_graph_val) );
my ($max_in_claster,$max_out_claster) = ( max(@claster_graph_val), max(@out_claster_graph_val) );
my ($mean_in_claster,$mean_out_claster) = ( mean(@claster_graph_val), mean(@out_claster_graph_val) );
print "$min_in_claster,$min_out_claster,<br>$max_in_claster,$max_out_claster<br>,$mean_in_claster,$mean_out_claster<br>";
print "@claster_graph_val <br> @out_claster_graph_val <BR>";
#хэш устанавливающий соответсвие между параметрами анализа и использующегося метода анализа
my %func_distance;
$func_distance{min} = make_func_distance &rule_nearest_neighbor,@matrix_distance;
$func_distance{max} = make_func_distance &rule_farthest_neighbor,@matrix_distance;
$func_distance{mean} = make_func_distance &rule_mean_neighbor,@matrix_distance;
$func_distance{ward} = make_func_distance &sum_square_of_deviation,@z_features;

#создаем функции для метода анализа связей(с выбранным пользователем методом определения растояния между кластерами) и метода уорда
my $method_link = agglomerative_hierarchical_analysis &{ $func_distance{$func_dist} };
my $method_ward = agglomerative_hierarchical_analysis &{ $func_distance{ward} };

my ($list_steps_link,$json_bin_tree_link) = process_claster_analiz @matrix_distance,@company,&$method_link,'Шаг №';

#foreach (@$list_steps_link){
#	print "incl_obj:@{ $_->{children} }<br>";
#	print "dist:$_->{distance}<br><br>";
#}

print "$json_bin_tree_link<br>";


my ($list_steps_ward,$json_bin_tree_ward) = process_claster_analiz @matrix_distance,@company,&$method_ward,'Шаг №';

#foreach (@$list_steps_ward){
#	print "incl_obj:@{ $_->{children} }<br>";
#	print "dist:$_->{distance}<br><br>";
#}

print "$json_bin_tree_ward<br>";

my @companies_i = @company[@idx_claster_company];
my @companies_o = @company[@idx_noclaster_company];
my @companies_id_tt = (@idx_claster_company,@idx_noclaster_company);






my $vars={
	companies_i=>\@companies_i,
	companies_o=>\@companies_o,
	companies_full=>\@company,
	features=>\@feature,
	z_features=>\@z_features,
	companies_id=>\@companies_id_tt,
	matrix_distance=>\@matrix_distance,
	min_i=>$min_in_claster,
	max_i=>$max_out_claster,
	min_o=>$min_out_claster,
	max_o=>$max_out_claster,
	mid_i=>$mean_in_claster,
	mid_o=>$mean_out_claster,
	json_str_link=>$json_bin_tree_link,
	json_str_ward=>$json_bin_tree_ward,
	vectors=>$list_steps_ward,
	single_link=>$list_steps_link,
	LQ=>$LQ
};


$tt2->process("report.html",$vars);

	