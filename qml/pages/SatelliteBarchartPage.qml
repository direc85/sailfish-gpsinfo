import QtQuick 2.0
import Sailfish.Silica 1.0
import QtSensors 5.0
import harbour.gpsinfo 1.0
import "../QChart"
import "../components"

Page {
    id: satelliteBarchartPage
    allowedOrientations: Orientation.Portrait | Orientation.Landscape | Orientation.LandscapeInverted
    property GPSDataSource gpsDataSource

    PageHeader {
        id: header
        title: qsTr("Satellite signal strengths")
    }

    Item {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

    Chart {
        id: rssiBarChart;
        width: parent.width - 2 * Theme.horizontalPageMargin
        height: satelliteBarchartPage.isPortrait ? width : parent.height - 2 * Theme.horizontalPageMargin
        anchors.centerIn: parent
        chartAnimated: true;
        chartAnimationEasing: Easing.Linear;
        chartAnimationDuration: 2000;
        chartType: Charts.ChartType.BAR
        property variant satellites : gpsDataSource.satellites;
        property bool componentLoaded: false
        Component.onCompleted: {
            chartData = {
                labels: [],
                datasets: [{
                        data: [],
                        fillColor: []
                    }]
            }
            chartOptions = {
                scaleStartValue: 0,
                scaleStepWidth: 5,
                scaleSteps: 10,
                scaleOverride: true,
                scaleFontColor: Theme.secondaryHighlightColor,
                scaleFontSize: Theme.fontSizeSmall,
                scaleFontFamily: Theme.fontFamily
            }
            rssiBarChart.componentLoaded = true
        }

        function getRSSI_Color(rssi)
        {
            return "hsl(" + (rssi < 40 ? rssi : 40) * 3 + ",100%,35%)";
        }

        onSatellitesChanged: {
            if (!rssiBarChart.componentLoaded || pageStack.currentPage !== satelliteBarchartPage)
                return;

            var results = [];
            gpsDataSource.satellites.forEach(function(sat) {

                // Add visible satellites
                if(sat.signalStrength > 0)
                    results.push(sat)
            });

            if(results.length > 0) {
                // Sort satellites by signal strength
                if(settings.barChartOrder == "signal")
                    results.sort(function(a,b) {return b.signalStrength - a.signalStrength})

                // Clear the chart data
                rssiBarChart.chartData.labels = []
                rssiBarChart.chartData.datasets[0].data = []
                rssiBarChart.chartData.datasets[0].fillColor = []

                // Insert the data
                results.forEach(function(barSat) {
                    rssiBarChart.chartData.labels.push(barSat.identifier);
                    rssiBarChart.chartData.datasets[0].data.push(barSat.signalStrength);
                    rssiBarChart.chartData.datasets[0].fillColor.push(getRSSI_Color(barSat.signalStrength));
                });

                // Draw minimum of 5 (10) bars in portrait (landscape)
                var additionalBars = 0
                if(satelliteBarchartPage.isPortrait && results.length < 5)
                    additionalBars = 5 - results.length
                else if(satelliteBarchartPage.isLandscape && results.length < 10)
                    additionalBars = 10 - results.length

                while(additionalBars > 0){
                    rssiBarChart.chartData.labels.push(" ");
                    rssiBarChart.chartData.datasets[0].data.push(0);
                    rssiBarChart.chartData.datasets[0].fillColor.push("transparent");
                    additionalBars--
                }
            }
            rssiBarChart.requestPaint();
        }
    }
    }
    InfoField {
        id: satellitesInfo
        label: qsTr("Satellites in use / view")
        value: gpsDataSource.numberOfUsedSatellites + " / " + gpsDataSource.numberOfVisibleSatellites
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        visible: parent.isPortrait
    }
}