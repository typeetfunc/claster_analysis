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