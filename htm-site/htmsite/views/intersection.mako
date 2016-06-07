<%
from bson import json_util
import json
import time
def mkunix(dt):
  return int(time.mktime(dt.timetuple()))
%>
<%include file="header.html"/>
%if intersection is None:
<div class="container">
    <div class="row">
        <div class="col-lg-12">
            <div class="panel panel-default">
                <div class="panel-body">
                   <div class="bs-callout bs-callout-danger">
                      <h4>No such intersection exists!</h4>
                          I don't know about that intersection
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
%else:

<%
pfield = str(intersection['sensors'][0])
if isinstance(intersection['sensors'], basestring):
 popular_sensors = []
 intersection['sensors'] = []
else:
 popular_sensors = map(int,intersection['sensors'])
 intersection['sensors'] = sorted(map(int,intersection['sensors']))
has_anything = scores_count > 0
del intersection['_id']
%>

<script type="text/javascript" src="//cdn.jsdelivr.net/bootstrap.daterangepicker/2/daterangepicker.js"></script>
<script type="text/javascript" src="/assets/fontawesome-markers.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.8.3/underscore-min.js"></script>
<div class="container">
  <h1>Intersection: ${intersection['intersection_number']}</h1>
    <div class="row">
        <div class="col-lg-6">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-info fa-fw"></i> Info
                </div>
                <table class="table table-striped">
                    <thead>
                        <tr>
                        <th>Attribute</th>
                        <th>Value</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                           if '_neighbours' in intersection and type(intersection['_neighbours']) is dict:
                            _neighbours = intersection['_neighbours']
                           else:
                            _neighbours = None
                        %>
                        % for k,v in intersection.items():
                        <tr>
                            % if k in ['scats_diagram', '_neighbours']:
                            <%
                            continue
                            %>
                            % endif
                            <td>${k.replace('_',' ').title()}</td>
                            <td>
                            % if k == 'neighbours':
                                %if _neighbours is not None:
                                        ## make a table neighbour id - from - to
                                            Table of sensors from neighbour intersection to this intersection
                                            <table class="table">
                                                <thead>
                                                <tr><th>Intersection</th><th>From</th><th>To</th></tr>
                                                </thead>
                                                <tbody>
                                                % for nid in _neighbours:
                                                    <tr>
                                                        <td><a href="/intersection/${nid}">${nid}</a></td>
                                                        <td>${", ".join(map(lambda x: str(x*8), _neighbours[nid]['from']))}</td>
                                                        <td>${", ".join(map(lambda x: str(x*8), _neighbours[nid]['to']))}</td>
                                                    </tr>
                                                % endfor
                                                </tbody>
                                            </table>
                                % else:
                                    % for n in v:
                                        <a href="/intersection/${n['intersection_number']}">${n['intersection_number']}</a>
                                    % endfor
                                %endif


                            % elif k == 'loc':
                                Lat: ${v['coordinates'][1]}, Lng: ${v['coordinates'][0]}
                            % elif k == 'sensors':
                                %for sensor in v:
                                    <span
                                        %if str(sensor) == str(pfield):
                                            class="active"
                                        %endif
                                    ><a href="#observations" class="sensor-swapper">${sensor}</a></span>
                                %endfor
                            % else:
                                ${v}
                            % endif
                            </td>
                        </tr>
                        % endfor
                    </tbody>
                </table>
                <div class="panel list-group" id="accordion">
                <a href="#" class="list-group-item" data-toggle="collapse" data-target="#sm" data-parent="#menu">Reports
                 <span id="chevron" class="glyphicon glyphicon-chevron-up pull-right"></span>
                </a>

                <div id="sm" class="sublinks panel-collapse collapse">
                    % for i in reports:
                  <a href="/reports/${intersection['intersection_number']}/${i.replace(' ','_').lower()}" class="list-group-item small">${i}</a>
                   %endfor
               </div>
            </div>
            </div>

        </div>
        <div class="col-lg-6">

            <%include file="time_range_panel.html"/>
        </div>
    </div>
    % if has_anything:
        <div class="row">
            <div class="col-lg-12" >
                <div class="panel panel-default">
                    <div class="panel-heading" id="observations">
                        <i class="fa fa-line-chart fa-fw"></i>
                            Observation <i class="fa fa-spinner fa-pulse loaderImage"></i>
                            <div class="dropdown pull-right">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown" id="sensor-label">Sensor: ${pfield}<b class="caret"></b></a>

                                <ul class="dropdown-menu" role="menu" aria-labelledby="prediction-sensor-menu">
                                    %for sensor in popular_sensors:
                                        <li
                                        %if int(sensor) == int(pfield):
                                            class="active"
                                        %endif
                                        ><a  class="sensor-swapper">${sensor}</a></li>
                                    %endfor
                                </ul>
                            </div>

                    </div>
                    <div class="panel-body">
                       <figure style="width: 100%; height: 300px;"  id="prediction-chart"></figure>
                    </div>
                </div>
            </div>
        </div>
        <div class="row">
            <div class="col-lg-12">
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <i class="fa fa-line-chart fa-fw"></i> Anomaly Scores <i class="fa fa-spinner fa-pulse loaderImage"></i>
                        
                        <span id="date-range-text" class="pull-right"></span>
                    </div>
                    <!-- /.panel-heading -->
                    <div class="panel-body">
                       <button type="button" class="btn btn-info btn-arrow-left shift-data">Older</button>
                       <button type="button" class="btn btn-info btn-arrow-right pull-right shift-data">Newer</button>
                       <figure style="width: 100%; height: 300px;"  id="anomaly-chart"></figure>
                       <form href="" class="form-inline" id="anomaly-params">
                           <div class="form-group">
                              <label for="threshold">Threshold</label>
                              <input type="text" class="form-control" id="threshold-input" placeholder="0.99" value="0.99">
                              <label for="threshold">Mean Filter</label>
                              <input type="number" class="form-control" id="mean-filter" placeholder="0" min="1" value="1">
                           </div>
                           <div class="checkbox">
                              <label><input type="checkbox" id="logarithm-input"> Log of likelihood</label>
                          </div>
                          <div class="form-group">
                            <label id="anomaly-list-label">High Anomaly at: </label><p id="form-anomalies"></p>
                          </div>
                          
                       </form>
                       
                    </div>
                </div>
            </div>
        </div>
    %else:
        <div class="row">
            <div class="col-lg-12">
                <div class="panel panel-default">
                    <div class="panel-body">
                       <div class="bs-callout bs-callout-danger">
                          <h4>Nothing to Display!</h4>
                          There's no flow data for this intersection!
                        </div>
                    </div>
                </div>
            </div>
        </div>
    %endif
    <div class="row">
        <div class="col-lg-6">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-line-chart fa-fw"></i> Incidents
                </div>
                <!-- /.panel-heading -->
                <table class="table table-striped">
                    <thead>
                      <tr>
                        <th>Time</th>
                        <th>Error</th>
                        <th>Vehicles</th>
                        <th>Weather</th>
                        <th>Crash Type</th>
                        <th>Involves 4WD</th>
                        <th>Total Damage</th>
                      </tr>
                    </thead>
                    <tbody id='incidents-table'>
                    </tbody>
                </table>
            </div>
        </div>
         <div class="col-lg-6">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <i class="fa fa-map fa-fw"></i> Nearby Accidents
                     <div class="dropdown pull-right">
                         <a href="#" class="dropdown-toggle" data-toggle="dropdown" id="radius-label">Radius: ${radius}m<b class="caret"></b></a>

                         <ul class="dropdown-menu" role="menu" aria-labelledby="radius-label">
                            %for i in [50,100,150,200,250,300]:
                                <li><a  class="radius-swapper">${i}</a></li>
                            %endfor
                         </ul>
                     </div>
                </div>
                <div class="panel-body">
                    <div style="height:600px" id="map-incident"></div>
                </div>
                <!-- /.panel-body -->
            </div>
        </div>
        %if 'scats_diagram' in intersection:
             <div class="col-lg-12">
                <div class="panel panel-default">
                    <div class="panel-heading">
                        <i class="fa fa-info fa-fw"></i> SCATS Diagram
                    </div>
                    <div class="panel-body">
##                         <div style="height:600px">
                            <img class="img-responsive" src="data:image/png;base64,${intersection['scats_diagram']}">
##                         </div>
                    </div>
                    <!-- /.panel-body -->
                </div>
            </div>
         %endif
    </div>
</div>
<script type="text/javascript">
var None = null;
var True = true;
var False = false;
var anomalyChart, predictionChart;

var incidents = ${json.dumps(incidents,default=json_util.default)|n};
var radius = ${radius};
var pfield = '${pfield}';
// highlight the ith incident in the map
// and on the table

var highlightAccident = function(idx) {
    var query = '#incidents-table > tr:nth-child('+idx+')';
    $(query).addClass('info').siblings().removeClass('info');
    $.each(crashMarkers, function(index, obj){
        obj.setIcon(markerIcon(index==idx-1));
    });
};
%if has_anything:
var allData;

var hideLoader = function() {
    $('.loaderImage').hide();
};
var modelRunning = 
%if 'running' in intersection:
    true;
%else:
    false;
%endif
var loadData = function(from,to, callback) {
    console.log("Loading data from json",from,to);
    var args =  {
            'from': from,
             'to': to,
    };
    $('.loaderImage').show();
    $.getJSON( '/get_readings_anomaly_${intersection['intersection_number']}.json', args,
        function(data) {
            if(data.length == 0) {
                // no data!
                console.log('No data');
            } else {
                allData = data;
                var txt = moment.utc(data[0]["datetime"]["$date"]).format('LLL') + " - " + moment.utc(data[data.length-1]["datetime"]["$date"]).format('LLL');
                
                $('#date-range-text').text(txt);
                if(callback)
                    callback(); 
                anomalyChart.updateOptions({
                  dateWindow: null,
                  valueRange: null
                });
                predictionChart.updateOptions({
                  dateWindow: null,
                  valueRange: null
                });
            }
            hideLoader();
        }).
        fail(function(){ hideLoader();});
};
function Queue (size) {
    this.queue = [];
    this.size = size;
};
Queue.prototype.push = function(item) {
    this.queue.push(item);
    if(this.queue.length > this.size)
        this.queue.shift();
};
Queue.prototype.shift = function() {
    return this.queue.shift();
    }
Queue.prototype.avg = function() {
    return _.reduce(this.queue, function(x,y){return x+y},0)/this.queue.length;
}
var makeAnomalyReadingArrays = function(sensor, only) {
    var threshold = parseFloat($('#threshold-input').val());
    var meanFilter = parseInt($('#mean-filter').val());
    var logarithm = $('#logarithm-input').is(':checked');
    console.log("threshold:", threshold, "log", logarithm, "mean filter size", meanFilter);
    //return an array made from all data
    var aData = new Array(allData.length);
    var pData = new Array(allData.length);
    var out;
    var queue = null;
    if(meanFilter > 1) {
        queue = new Queue(meanFilter);
    }
    if (only == 'anomaly')
       out = {'aData': aData};
    else if(only == 'readings')
        out = {'pData': pData};
    else
        out = {'aData': aData, 'pData': pData};
    allData.forEach(function(row, index, in_array) {
        // columns are: date,anomaly, likelihood, incident, incident_predict],
        
        var row_time = row["datetime"]["$date"];
        
        if(only != 'anomaly') {
            
            var value = row['readings'][sensor] < ${max_vehicles}?row['readings'][sensor]:null;
            var mean_value = null;
            if(queue) {
                queue.push(value);
                mean_value = queue.avg();
            }
            pData[index] = [new Date(row_time), value, mean_value];
        }   
        if(row['anomalies'] !== undefined && only != 'readings') {
            anomalyCount = _.filter(row['anomalies'],function(n){return n['likelihood'] > threshold;}).length ;
            aData[index] = [new Date(row_time),
                        row['anomalies'][sensor]['score'],
                        !logarithm?row['anomalies'][sensor]['likelihood']:
                                   Math.log(1.0 - row['anomalies'][sensor]['likelihood'])/ -23.02585084720009,
                        _.find(incidents,function(n){return Math.round(n['datetime']['$date']/300000)*300000 == row_time;})?1.1:null,
                         anomalyCount >= 1 ?anomalyCount/ Object.keys(row['anomalies']).length:null
                       ];
       } else {
            aData[index] = [new Date(row_time),null,null
            ,_.find(incidents,function(n){return n['datetime']['$date'] == row_time;})?1.1:null,
            null];
       }
    });
    return out
};

var setupDygraphs = function() {

    loadData(${mkunix(time_start)},${mkunix(time_end)},function(){
         var arReadings = makeAnomalyReadingArrays(pfield);
         if (arReadings.aData.length == 0) {
            console.log("no anomaly data");
            $('#anomaly-chart').before('<div class="bs-callout bs-callout-danger">\
             <h4>Nothing to Display!</h4>\
          There\'s no anomaly values for this time period. It might not have been analysed yet.\
        </div>').height('0');
        } else {
            anomalyChart = new Dygraph(document.getElementById('anomaly-chart'), arReadings.aData, {
              title: 'Anomaly value for intersection ${intersection['intersection_number']}',
              ylabel: 'Anomaly',
              xlabel: 'Date',
              anomaly: {
                    color: "blue",
                },
              likelihood: {
                    color: "red",
                },
              incident: {
                    color: "green",
                    strokeWidth: 0.0,
                    pointSize: 4,
              },
              incident_predict: {
                    color: "orange",
                    strokeWidth: 0.0,
                    pointSize: 4,
              },
              axes: {
                y: {
                    valueRange: [0,1.3]
                }
              },
              zoomCallback: function(min, max, yRanges) {
                  zoomGraph(predictionChart, min, max);
              },
              highlightCallback: function(event, x, points, row, seriesName) {
                  highlightX(predictionChart, row);
                  if (points[2].xval) {
                      // find idx of point[2] in incidents array
                      // using xval
                    var accidentIdx = 1+_.findIndex(incidents, function(x){return Math.round(x["datetime"]["$date"]/300000)*300000 == points[2].xval;});
                    //console.log("Moused over", accidentIdx);
                    highlightAccident(accidentIdx);
                  }
                  if (points[3].yval) {
                      $('#anomaly-list-label').text("High Anomaly at "+moment.utc(points[3].xval).format('LLLL'));
                      var threshold = parseFloat($('#threshold-input').val());
                      var sensors = [];
                      _.each(allData[row]['anomalies'], function(val, key) {
                        if(val.likelihood > threshold)
                            sensors.push(key);    
                      });
                      var anomaly_list = $('p#form-anomalies');
                      anomaly_list.empty();
                      $.each(sensors, function(i, val){
                          anomaly_list.append('<a href="#observations" class="sensor-swapper">'+val+'</a> ');
                      });
                  }
              },
              labels: ['UTC', 'anomaly', 'likelihood', 'incident', 'incident_predict'],
               <%include file="dygraph_weekend.js"/>
            });
        }
         predictionChart = new Dygraph(document.getElementById('prediction-chart'), arReadings.pData, {
             labels: ['UTC','Reading', 'Mean'],
             title: 'Observation on Sensor: '+ pfield,

             ylabel: 'Volume',
             xlabel: 'Date',
             zoomCallback: function(min, max, yRanges) {
                 zoomGraph(anomalyChart, min, max);
             },
             highlightCallback: function(event, x, point, row, seriesName) {
                 highlightX(anomalyChart, row);
             },
             <%include file="dygraph_weekend.js"/>
        });
           

    });
   
};
if (!${has_anything}) {
    console.log("no readings data");
        $('#prediction-chart').before('<div class="bs-callout bs-callout-danger">\
      <h4>Nothing to Display!</h4>\
      There\'s no readings for this time period. It might not have been analysed yet.\
    </div>').height('0');
}
var zoomGraph = function(graph, min, max) {
    if(graph)
    graph.updateOptions({
        dateWindow: [min, max]
    });
};
var highlightX = function(graph, row) {
    if(graph)
        graph.setSelection(row);
};

var dispFormat = "%d/%m/%y %H:%M";



var opts = {
  "dataFormatX": function (x) { return d3.time.format('${date_format}').parse(x); },
  "tickFormatX": function (x) { return d3.time.format(dispFormat)(x); },
  "mouseover": function (d, i) {
    var pos = $(this).offset();
    $(tt).text(d3.time.format(dispFormat)(d.x) + ': ' + d.y)
      .css({top: topOffset + pos.top, left: pos.left + leftOffset})
      .show();
  },
  "mouseout": function (x) {
    $(tt).hide();
  }
};
<%
start_title = time_start.strftime('%d/%m/%Y')
end_title = time_end.strftime('%d/%m/%Y')
%>
%endif

<%
if scores_count == 0:
   start_title = incidents[0]['datetime'].strftime('%d/%m/%Y')
   end_title = incidents[-1]['datetime'].strftime('%d/%m/%Y')
%>

var daterangepickerformat = 'DD/MM/YYYY H:mm';
$('input[name="daterange"]').daterangepicker({
    timePicker: true,
    timePickerIncrement: 5,
    locale: {
        format: daterangepickerformat
    },
    startDate: '${start_title}',
    endDate: '${end_title}'
}).on('apply.daterangepicker', function(env, picker) {
    var dates = $('#dateinput').val().split('-');
    loadData(moment.utc(dates[0].trim(),daterangepickerformat).unix() ,
             moment.utc(dates[1].trim(), daterangepickerformat).unix(),
             setChartsFromMake);
});
var mapCrash;
var lat, lng;

var setChartsFromMake = function() {
  var arReadings = makeAnomalyReadingArrays(pfield);
  predictionChart.updateOptions( { 'file': arReadings.pData, 'title': 'Observation on Sensor: '+pfield});
  anomalyChart.updateOptions( { 'file': arReadings.aData, axes: {y: {valueRange: [0,1.3]}}});
  
};
$(document).ready(function() {
   if(${scores_count}>0)
       setupDygraphs();
   lat = ${intersection['loc']['coordinates'][1]};
   lng = ${intersection['loc']['coordinates'][0]};


  mapCrash = new GMaps({
    lat: lat,
    lng: lng,
    div: '#map-incident',
    zoom: 15
  });
  $('.shift-data').click(function(e) {
    // determine if we are older or newer
    var older = $(this).text()=='Older';
    var from,to;
    if(older) {
        to = predictionChart.getValue(0,0)/1000; // lowest reading
        from = to - (${day_range}*24*60*60);// lowest reading in chart - ${day_range} days
    } else {
        to = predictionChart.getValue(predictionChart.numRows()-1,0)/1000;
        from = to + (${day_range}*24*60*60);
    }
    loadData(from, to, setChartsFromMake);
    // load accidents from the new timeframe too
    updateIncidents(radius, from, to);
  });
  % if 'running' in intersection:
    var intervalId = window.setInterval(function(){
        console.log("reloading because site is running");
        from = predictionChart.getValue(0,0)/1000;
        to = predictionChart.getValue(predictionChart.numRows()-1,0)/1000;
        loadData(from, to, setChartsFromMake);
        
        $.getJSON('/intersection_${intersection['intersection_number']}.json',function(data){
            if(!data.hasOwnProperty('running')) {
                console.log("Stopping reloading");
                clearInterval(intervalId);
            }
        });
    },1000*10);
  %endif
  setupIncidents(radius);
  function toggleChevron(e) {
      $(e.target)
        .parent()
        .find('span.glyphicon')
        .toggleClass('glyphicon-chevron-down glyphicon-chevron-up');
  }
  $('#accordion').on('hidden.bs.collapse', toggleChevron);
  $('#accordion').on('shown.bs.collapse', toggleChevron);

  $('body').on('click', '.sensor-swapper', function() {
     pfield = $(this).text();
     console.log('sensor swapping to',pfield);
      setChartsFromMake();
     
     $('#sensor-label').html('Sensor: '+pfield+' <b class="caret"></b>');
     $('.sensor-swapper:contains("'+pfield+'")').parent().addClass('active').siblings().removeClass('active');
  });
   $('.radius-swapper').click(function() {
      radius = $(this).text();
      $('#radius-label').html('Radius: '+radius+'m <b class="caret"></b>');
      updateIncidents(radius);
  });
  $('#incidents-table').on('mouseover', 'tr', function() {
     var idx = $(this).index();

        highlightAccident(idx+1);
     // highlight the one on the chart too
     if(anomalyChart)
        anomalyChart.setSelection(incidents[idx]);
  });

  $('#anomaly-params').change(function() {
    console.log("Anomaly chart params updated");
    setChartsFromMake();
  }).on('submit',function(ev){ev.preventDefault();});
});
var mapCircle = null;
var setupIncidents = function(newRadius) {
    radius = newRadius;
 var mainMarker = {
    lat: lat,
    lng: lng,
    title: '${intersection['intersection_number']}'
  };
  mapCrash.removeMarkers();
  mapCrash.addMarker(mainMarker);
  %for i in intersection['neighbours']:
    mapCrash.addMarker({
         lat: ${i['loc']['coordinates'][1]},
         lng: ${i['loc']['coordinates'][0]},
         title: '${i['intersection_number']}',
         infoWindow:{content: '<a href="/intersection/'+${i['intersection_number']}+'">'+${i['intersection_number']}+'</a>'}
    });
  %endfor
  if (mapCircle != null) {
    mapCircle.setRadius(radius);
    }
  else {
   mapCircle = mapCrash.drawCircle({
        lat:lat,
        lng:lng,
        radius: radius,
        editable: false,
        fillColor: '#004de8',
        fillOpacity: 0.27,
        strokeColor: '#004de8',
        strokeOpacity: 0.62,
        strokeWeight: 1

  });
  }
    $.each(incidents, function(idx, obj){
      var windowStr = '<b>Damage:</b> $'+this.Total_Damage+
                      '<br><b>Vehicles:</b> '+this.Total_Vehicles_Involved+
                      '<br><b>Cause:</b> '+this.App_Error+
                      '<br><b>Type:</b> '+this.Crash_Type+
                      '<br><b>Date:</b> '+moment.utc(this.datetime['$date']).format('LLL');
      var m = mapCrash.addMarker({
        lat: this.loc['coordinates'][1],
        lng: this.loc['coordinates'][0],
        infoWindow: {content:windowStr},
        icon: markerIcon(false),
        click: function(e) {
            highlightAccident(1+ idx);
        }
      });
      crashMarkers.push(m);
  });

  // populate the table and the anomalychart
  $('#incidents-table').empty();
  $.each(incidents, function(idx1, value) {
    var row = $('<tr></tr>');
    $.each(['datetime','App_Error','Total_Vehicles_Involved',
        'Weather_Cond - Moisture_Cond', 'Crash_Type', 'Involves_4WD', 'Total_Damage'],function(idx2, field) {

        row.append('<td>'+ _.map(field.split('-'), function(x){if(x=='datetime')return moment.utc(value[x]['$date']).format('LLLL');else return value[x.trim()];}).join(' - ') +'</td>');
    });
    $('#incidents-table').append(row);
  });
  if(anomalyChart)
    anomalyChart.updateOptions( { 'file': makeAnomalyReadingArrays(pfield, 'anomaly').aData});

};
var updateIncidents = function(radius, start, end) {

    if(!start) {
        start = $('input[name="daterange"]').data('daterangepicker').startDate.unix();
        end = $('input[name="daterange"]').data('daterangepicker').endDate.unix();
    }
    console.log("Updating incidents in radius ", radius, "from ",start, " to ",end);
    $.getJSON('/accidents/${intersection['intersection_number']}/'+start+'/'+end+'/'+radius, function(data) {
        // repopulate table and markers
        incidents = data[0];
        radius = data[1];
        crashMarkers = [];
        setupIncidents(radius);
    });
};
var crashMarkers = [];
var crashDefault = '#B71C1C';
var crashSelected = '#D9EDF7';

var markerIcon = function(selected) {
    return {
            path: fontawesome.markers.EXCLAMATION_CIRCLE,
            scale: 0.5,
            strokeWeight: 0.2,
            strokeColor: 'black',
            strokeOpacity: 1,
            fillColor: selected?crashSelected:crashDefault,
            fillOpacity: 1,
           };
};

</script>

%endif

<%include file="footer.html"/>
