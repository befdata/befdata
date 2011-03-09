// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


function selectPersonRoles(select) {
    var option = select.options[select.selectedIndex];
    var ul = select.parentNode.getElementsByTagName('ul')[0];
    var choices = ul.getElementsByTagName('input');
    for (var i = 0; i < choices.length; i++) if (choices[i].value == option.value) return;
    var li = document.createElement('li');
    var input = document.createElement('input');
    var text = document.createTextNode(option.firstChild.data);
    input.type = 'hidden';
    input.name = 'personroles[]';
    input.value = option.value;
    li.appendChild(input);
    li.appendChild(text);
    li.setAttribute('onclick', 'this.parentNode.removeChild(this);');
    ul.appendChild(li);
}


function selectPeople(select) {
    var option = select.options[select.selectedIndex];
    var ul = select.parentNode.getElementsByTagName('ul')[0];
    var choices = ul.getElementsByTagName('input');
    for (var i = 0; i < choices.length; i++) if (choices[i].value == option.value) return;
    var li = document.createElement('li');
    var input = document.createElement('input');
    var text = document.createTextNode(option.firstChild.data);
    input.type = 'hidden';
    input.name = 'people[]';
    input.value = option.value;
    li.appendChild(input);
    li.appendChild(text);
    li.setAttribute('onclick', 'this.parentNode.removeChild(this);');
    ul.appendChild(li);
}

function clone_element_before(element) {
    var input = Element.previous(element);
    var name = input.name;
    var id= input.id;
    name = name.replace(/\[([0-9])\]*/, function(variable, p1) {
        var zahl = parseInt(p1)
        zahl = zahl +1
      return "[" + zahl + "]";
        });
    id = id.replace(/_([0-9])*_/, function(variable, p1) {
        var zahl = parseInt(p1)
        zahl = zahl +1
      return "_" + zahl + "_";
        });
    var new_input = document.createElement('input')
    new_input.name = name;
    new_input.type = input.type
    new_input.id = id;
    new_input.size = 30;
    element.insert({before: new_input});
}

