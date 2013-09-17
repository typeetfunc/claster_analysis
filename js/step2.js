$(document).ready(function(){


	var i = $('inputs_l').size() + 2;
	var j = $('inputs_r').size() + 2;
	$("[id='add1']").click(function() {
		$('<p class="f_c_left">Предприятие №'+i+'</p>'+ '&nbsp;').fadeIn('slow').appendTo("[id='f_c_l']");
		$('<input type="text" name="dynamic_i" class="inputs_l" placeholder="Введите название предприятия">').fadeIn('slow').appendTo("[id='f_n_l']");
		i++;
	});
	$("[id='add2']").click(function() {
		$('<p class="f_c_right">Предприятие №'+j+'</p>'+ '&nbsp;').fadeIn('slow').appendTo("[id='f_c_r']");
		$('<input type="text" name="dynamic_o" class="inputs_r" id="i_r" placeholder="Введите название предприятия">').fadeIn('slow').appendTo("[id='f_n_r']");
		j++;
	});
	
	$("[id='del1']").click(function() {
	if(i > 1) {
		$('.inputs_l:last').remove();
		$('.f_c_left:last').remove();
		i--; 
	}
	});

	$("[id='del2']").click(function() {
	if(j > 1) {
		$('.inputs_r:last').remove();
		$('.f_c_right:last').remove();
		j--; 
	}
	});

	$("[id='res1']").click(function() {
		$('#f_c_l').empty();
		$('#f_n_l').empty();
		i=1;
	});
	$("[id='res2']").click(function() {
		$('#f_c_r').empty();
		$('#f_n_r').empty();
		j=1;
	});


jQuery('[placeholder]').placeholder();

});

function com() {

	var testList = 0;
	var list = $("input:text");
	for(var j = 0; j < list.length; j++) {
		if (list[j].value == "") {
			alert("Заполнены не все поля!");
			return false;
			break;
		}
	};
};