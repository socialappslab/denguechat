
angular.module("denguechat.controllers").controller("adminTimeseriesCtrl", ["$scope", "$http", "$attrs", "TimeSeries", "analyticsInit", function ($scope, $http, $attrs, TimeSeries, analyticsInit) {
  $scope.loading       = false;
  $scope.neighborhoods = [];
  $scope.timeseries    = [];
  $scope.odds_ratios   = [];
  $scope.options       = {unit: "monthly", timeframe: "6", positive: true, potential: true, negative: true, geographies: []};
  $scope.customDateRange = false;
  $scope.chartLoading = false;
  $scope.noChartData  = false;
  $scope.state = {chart: false}

  $scope.analytics_options = analyticsInit.options

  $scope.tagTransform = function(newTag) {
    return null
  }

  $scope.groupBy = function(item) {
    return item.category
  }

  var prepareParams = function() {
    // General params.
    var params = {
      geographies: JSON.stringify($scope.options.geographies),
      unit: $scope.options.unit
    };

    // Send specific params depending on what the user is viewing currently.
    if ($scope.customDateRange) {
      params.custom_start_month = $scope.options.customStartMonth,
      params.custom_start_year = $scope.options.customStartYear,
      params.custom_end_month = $scope.options.customEndMonth,
      params.custom_end_year = $scope.options.customEndYear
    } else {
      params.timeframe = $scope.options.timeframe
    }

    return params;
  }

  $scope.refreshChartWithParams = function() {
    $scope.timeseries  = []
    $scope.odds_ratios  = []
    $scope.loading     = true;
    $scope.serverError = false;
    $scope.serverErrorMessage = null;
    $scope.timeseries    = [];
    $scope.noChartData  = false;

    var params = prepareParams()

    req = TimeSeries.get(params).$promise
    req.then(function(response) {
      $scope.timeseries  = response.timeseries;
      $scope.odds_ratios = response.odds_ratios;

      if ($scope.timeseries.length === 0)
        $scope.serverErrorMessage = "Sin datos";

      if ($scope.timeseries.length <= 1) {
        $scope.noChartData = true;
      } else {
        $scope.state.chart = true
        $scope.noChartData = false;
        drawChart("timeseries-chart", response, $scope.options.unit)
      }
    })
    req.catch(function(res) {
      $scope.$emit(denguechat.error, res)
    })
    req.finally(function(res) { $scope.loading = false; })
  }

  $scope.generateCsv = function() {
    $scope.loading     = false;
    $scope.serverError = false;
    $scope.serverErrorMessage = null;
    var params = prepareParams()

    window.location.href = "/api/v0/graph/timeseries.csv?" + $.param(params)
  }


  // $scope.toggleNeighborhood = function(id) {
  //   index = $scope.neighborhoods.indexOf(id)
  //   if (index === -1)
  //     $scope.neighborhoods.push(id)
  //   else {
  //     $scope.neighborhoods.splice(index, 1)
  //   }
  //
  //   console.log($scope.neighborhoods)
  // }

  var googleChartOptions = function(chartID, data) {
    colors = []
    if ($scope.options.positive)
      colors.push("#e74c3c")
    if ($scope.options.potential)
      colors.push("#f1c40f")
    if ($scope.options.negative)
      colors.push("#2ecc71")


    var options =  {
      annotations: {
        alwaysOutside: true
      },
      // width: 500,
      // height: 350,
      chartArea: {
        left: 50,
        right: 50,
        top: 50,
        bottom: 50,
        width: "90%",
        height: "100%"
      },
      hAxis: {
        showTextEvery: parseInt(data.getNumberOfRows() / 4)
      },
      vAxis: {
        format: "#\'%\'"
      },
      legend: {
        position: "none",
        alignment: "start",
        textStyle: {
          fontSize: "15"
        }
      },
      colors: colors,
      tooltip: { isHtml: true }
    };
    return options;
  }

  function drawChart(chartID, rawData, unit) {
    var dataTable    = new google.visualization.DataTable();

    // Create the type columns for the table.
    // var columnNames = ;
    // dataTable.addColumn("string", columnNames[0])
    // for (var i = 1; i < columnNames.length; i++) {
    //
    // }

    dataTable.addColumn("string", rawData.header.time);

    if ($scope.options.positive) {
      dataTable.addColumn("number", rawData.header.positive);
      dataTable.addColumn({type: 'string', role: 'annotation'});
      dataTable.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});
    }

    if ($scope.options.potential) {
      dataTable.addColumn("number", rawData.header.potential);
      dataTable.addColumn({type: 'string', role: 'annotation'});
      dataTable.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});
    }

    if ($scope.options.negative) {
      dataTable.addColumn("number", rawData.header.negative);
      dataTable.addColumn({type: 'string', role: 'annotation'});
      dataTable.addColumn({type: 'string', role: 'tooltip', 'p': {'html': true}});
    }

    // Iterate over the raw data.
    rawData = rawData.timeseries
    for (var i = 0; i < rawData.length; i++) {
      row = [
        rawData[i].date
      ]

      if ($scope.options.positive) {
        row = row.concat([
          rawData[i].positive.percent,
          customAnnotationForPercent(rawData[i].positive.percent, unit),
          customToolTipForData(rawData[i])
        ])
      }

      if ($scope.options.potential) {
        row = row.concat([
          rawData[i].potential.percent,
          customAnnotationForPercent(rawData[i].potential.percent, unit),
          customToolTipForData(rawData[i])
        ])
      }

      if ($scope.options.negative) {
        row = row.concat([
          rawData[i].negative.percent,
          customAnnotationForPercent(rawData[i].negative.percent, unit),
          customToolTipForData(rawData[i])
        ])
      }

      var rowIndex = dataTable.addRow( row )
      dataTable.setRowProperty(rowIndex, "rowData", rawData[i]);
    }

    var view    = new google.visualization.DataView(dataTable);
    var options = googleChartOptions(chartID, dataTable)
    var chart   = new google.visualization.ColumnChart(document.getElementById(chartID));
    chart.draw(view, options);
  }

  // Let's not display the annotations for now.
  var customAnnotationForPercent = function(percent, unit) {
    if (unit == "monthly")
      return String(percent) + "%";
    else
      return "";
  }

  var customToolTipForData = function(data) {
    var s = "<table class = 'table'><tbody>"
    s += "<tr><td>Fecha de visita</td><td>" + data.date + "</td></tr>";
    s += "<tr><td>Lugares visitados</td><td>" + data.total.count + "</td></tr>"
    s += "<tr><td>Lugares positivos</td><td>" + data.positive.count + " (" + data.positive.percent + "%)</td></tr>"
    s += "<tr><td>Lugares potenciales</td><td>" + data.potential.count + " (" + data.potential.percent + "%)</td></tr>"
    s += "<tr><td>Lugares negativos</td><td>" + data.negative.count + " (" + data.negative.percent + "%)</td></tr>"
    s += "</tbody></table>"
    return s;
  }
}]);
