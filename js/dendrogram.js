


// получаем координаты в декартовой системе координат
function decart(d) {
    return [d.y, d.x];
}


var 
paramDecart = {
    width: 750,
    height: 600,
    coord: decart,
    widthShift: 350,
    tranlateX: 75,
    tranlateY: 0
};

// строит дендрограмму по заданным параметрам
function makeDendrogram(parentD3, param) {
    
    // размеры svg
    
    // создаем svg-элемент и корневой узел
    var svg = parentD3.append("svg")
        .attr("style", 'border: solid 1px #197b30; margin-left:450px')
        .attr("width", param.width)
        .attr("height", param.height)
        .append("g")
        // передвигаем вправо для подписи корня
        .attr("transform", "translate(" + param.tranlateX + ", " + param.tranlateY + ")");
    
    /*
    	макет (компоновщик) для построения дендрограммы
		(иерархического дерева)
	*/
    var cluster = d3.layout.cluster()
        // задаем размеры для макета
        .size([param.height, param.width - param.widthShift]);
    
    // задаем систему координат
    var diagonal = d3.svg.diagonal()
        .projection(param.coord);
    
    // макет расставляет узлы и связи
    var nodes = cluster.nodes(treeData),
        links = cluster.links(nodes);
                
    // далее идет добавление и манипуляция svg-элементами
    
    // добавляем линии связей узлов, полученные с помощью макета
    var link = svg.selectAll(".link")
        .data(links)
        .enter()
        .append("path")
        .attr("class", "link")
        .attr("d", diagonal);
                
    // добавляем узлы и перемещаем в расчитанные позиции
    var node = svg.selectAll(".node")
        .data(nodes)
        .enter()
        .append("g")
        .attr("class", "node")
        .attr("transform", function(d) { 
            return "translate(" + param.coord(d).join(",") + ")"; 
        })
                
    // добавляем в вершины узлов кружочки разного размера
    node.append("circle")
        .attr("r", function(d){
            if(!d.size)
                return 3;
            
            return d.size;
        });
                
    // добавляем текстовые подписи полей name
    node.append("text")
        .attr("dx", function(d) { return d.children ? -8 : 12; })
        .attr("dy", 4)
        .attr("class", "ololo")
        .style("text-anchor", function(d) { return d.children ? "end" : "start"; })
        .text(function(d) { return d.name + ' (' + d.depth + ')'; });
    
    
    
 //d3.select(self.frameElement).style("height", param.height + "px");
}


