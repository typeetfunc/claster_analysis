$(document).ready(function(){

$('input:radio').filter('[id=evclid]').attr('checked', true);
$('input:radio').filter('[id=close]').attr('checked', true);
$('input:radio').filter('[id=standart]').attr('checked', true);

	var j = $('inputs_r').size() + 2;

	$("[id='add2']").click(function() {
		$('<div class="f_cnt" id="f_c_r" > <div class="nomer" style = "width: 20%; float: left; height: 18px; margin-bottom:21px; text-align: center;"><p>'+j+'</p></div><div class = "weight" style="width: 20%; float: left; height: 18px; margin-bottom:21px;"><input type="text" name="weight" class="inputs_m" id="i_m"></div><div><input type="text" name="dynamic" class="inputs_r" id="i_r" placeholder="Введите название характеристики"></div></div>').fadeIn('slow').appendTo("[id='form1']");
		j++;
	});

	$("[id='del2']").click(function() {
	if(j > 1) {
		$('.f_cnt:last').remove();
		j--; 
	}
	});

	$("[id='res2']").click(function() {
		while (j != 1) {
			$('.f_cnt:last').remove();
			j--;
		}
	});

	$("[id='ny']").click(function() {
		$('#norma').show('normal');	

	});
	$("[id='evclid']").click(function() {
		$('#norma').show('normal');
	});
	$("[id='city']").click(function() {
		$('#norma').hide('normal');
		$('input:radio').filter('[name=norma]').attr('checked', false);
	});


jQuery('[placeholder]').placeholder();

});

function com(array) {
	var clasterName = document.getElementById("claster_name").value;
	var test = 0;
	for (var i = 0; i < array.length; i++) {
		if (array[i]==clasterName){
			test = 1;
			break;
		}
	};
	var testList = 0;
	var list = $("input:text");
	for(var j = 0; j < list.length; j++) {
		if (list[j].value == "") {
			testList = 1;
		}
	};

	if(test == 1) {
		alert("Такой кластер уже существует!")
		return false;
	}
	else if (testList == 1) {
			alert("Заполнены не все поля!");
			return false;
		}
		else {
			return true;
		}
};


