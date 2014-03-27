
// strings correspond to ids of report div
// used with function display_report_div
var report_tabs = ['all_reports_button', 'open_reports_button', 'eliminated_reports_button', 'make_report_button'];

$(document).ready(function() {

    // style all reports as selected
    selected_tab_css_update('all_reports_button');

    //show all reports on start
    $('#new_report').css('display','none');

    // keep the map on the page when scrolling
    $(window).scroll(function() {
        var scrollAmount = $(window).scrollTop();
        if (scrollAmount > 200) {
            $("#map_div").css("margin-top", scrollAmount - 263);
        } else {
            $("#map_div").css("margin-top", -63);
        }
    });



    // TODO @awdorsett - Are these methods still used? If so refactor
    // start of methods
	$("select.elimination_type").change(function() {
		if ($(this).val() == "Outro tipo") {
			window.location = "/feedbacks/new?title=other_type";
		}
	});
	
	$("select.elimination_methods").each(function() {
		$(this).find("option").filter(function() {
			return $(this).text() == "Método de eliminação";
		}).prop("selected", true);
	});
	$("select.elimination_methods").change(function() {
		if ($(this).val() == "Outro método") {
			window.location.href = "/feedbacks/new?title=other_method";
		} else {
			$(this).parent().find("input#selected_elimination_method").val($(this).val());
		}
	});
    // end of methods

});


function filter_reports(e, filter_class){
    e.preventDefault();

    // hide new report div
    $('#new_report').css('display','none');

    // style tab as selected
    selected_tab_css_update(e.target.id);

    // loop through reports looking for appropriate class based on passed class (@param filter_class)
    if (filter_class === 'all'){
        $('.report').each(function(){
            $(this).css('display','block');
        });
    }
    else{
        $('.report').each(function(){
            var value = $(this).hasClass(filter_class) ? 'block' : 'none';
            $(this).css('display',value);
        })
    }
}
// displays new report div
function display_new_report(e){
    e.preventDefault();
    // style tab as selected
    selected_tab_css_update(e.target.id);

    if($('#new_report').css('display') == 'none'){

        // clear existing form
        $('#new_report_form form').trigger('reset');

        // hide all reports
        $('.report').each(function(){
            $(this).css('display','none');
        });

        // display new report div
        $('#new_report').css('display','block');
    }

}

// pass the id of tab to change the css so that it appears as selected
// e.g. larger size, different color, etc
function selected_tab_css_update(id){

    // loop through report tabs and add active the the one that whose id is passed
    $.each(report_tabs, function(i, tab_id){
        if (tab_id == id)
            $("#" + tab_id).addClass('active');
        else
            $("#" + tab_id).removeClass('active');
    })
}


// TODO @awdorsett - refactor to reuse update location
// TODO @awdorsett - need to implement visual queues for marcar no mapa (drop a marker)
// temporary to be used with "Marcar no mapa" button on new report form
function update_location_coordinates_new_report(e){
    e.preventDefault();

    if( $('#x').val() == '' || $('#y').val() == ''){
        $('#new_report input[name=commit]').attr('disabled',true);
        var data = {"f": "pjson",
                    "Street": $('#street_type').val() +
                        " " + $('#street_name').val() +
                        " " + $('#street_number').val()
                    }
        $.ajax({
            url: "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates",
            type: "GET",
            timeout: 5000, // milliseconds
            dataType: "jsonp",
            data: data,
            success: function(m) {
                var candidates = m.candidates;

                //possible location found, update form values
                if (candidates.length > 0) {
                    $('#x').val(candidates[0].location.x);
                    $('#y').val(candidates[0].location.y);
                }


            },
            error: function(m) {
                //ajax call unsuccessful, server may be down
                // TODO @awdorsett how to handle map failure for macar no mapa
            }
        });
        $('#new_report input[name=commit]').attr('disabled',false);

    }

}

//@params location - json of location object for report
//@params event - click event for form submission
// -# TODO @awdorsett - fix magic numbers
function update_location_coordinates(location,event){

    //make sure the form being submitted has long/lat input fields
    //i.e. don't run when selecting elimination type
    if(event.target.form[7].id == 'latitude' && event.target.form[8].id == 'longitude'){

        //if either value is null then try to get coords again
        if (location.latitude == null || location.longitude == null){
            event.preventDefault();

            //disable submit button so user cant submit multiple times
            $(".report_submission").attr("disabled",true);

                $.ajax({
                    url: "http://pgeo2.rio.rj.gov.br/ArcGIS2/rest/services/Geocode/DBO.Loc_composto/GeocodeServer/findAddressCandidates",
                    type: "GET",
                    timeout: 5000, // milliseconds
                    dataType: "jsonp",
                    data: {"f": "pjson", "Street": location.street_type + " " + location.street_name + " " + location.street_number},
                    success: function(m) {
                        var candidates = m.candidates;

                        //possible location found, update form values
                        if (candidates.length > 0) {
                            event.target.form[7].value = candidates[0].location.x;
                            event.target.form[8].value = candidates[0].location.y;
                        }

                       $(event.target.form).submit();

                    },
                    error: function(m) {
                        //ajax call unsuccessful, server may be down
                        // TODO @awdorsett how to handle second request for map failure
                        $(".report_submission").attr("disabled",false);
                        $(event.target.form).submit();
                    }
                });
        }

    }
}
