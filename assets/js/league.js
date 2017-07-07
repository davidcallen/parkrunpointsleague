$("#eventName").selectmenu({
	// select: onEventNameSelect
	change: onEventNameChange
});
$("#eventYear").selectmenu({});
$("#gender").selectmenu({ });
function bntClickGO(form) {
	var eventName = $("#eventName").val();
	var year = $("#eventYear").val();
	var gender = $("#gender").val();
	window.location.href = "/league?e=" + eventName + "&y=" + year + "&g=" + gender;
}
function onEventNameSelect(event, ui) {
	getYearsForEvent();
}
function onEventNameChange(event, ui) {
	getYearsForEvent();
}
function getYearsForEvent() {
	var eventName = $("#eventName").val();
	var selectedEventYear = getParameterByName('y'); 
	if(selectedEventYear === undefined)
	{
		selectedEventYear = $("#eventYear").val();
	}
	$.ajax({
		type: 'POST',
		dataType: 'json',
		url: '/league/getyears?e=' + eventName,
		success: function(data) {
			console.log("got json");
			if(data) {
				$("#eventYear").html("");
				$.each(data, function(index,item) {
					var selectedAttr = "";
					if(selectedEventYear && item == selectedEventYear)
					{
						selectedAttr = "selected='selected'";
					}
					$("#eventYear").append("<option " + selectedAttr + " value='" + item + "'>" + item + "</option>");
				});
				$("#eventYear").selectmenu("refresh");
			}
		}
	});
}
// Get the years on page load for the currently selected event
getYearsForEvent();

// TODO : use http://medialize.github.io/URI.js/jquery-uri-plugin.html instead of below ?
function getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, "\\$&");
    var regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}
