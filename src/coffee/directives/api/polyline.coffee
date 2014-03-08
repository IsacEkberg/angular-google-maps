angular.module("google-maps.directives.api")
.factory "Polyline", ["Logger", "$timeout", "array-sync", "GmapUtil", "BaseObject", (Logger, $timeout, arraySync, GmapUtil, BaseObject) ->
    $log = Logger
    DEFAULTS = {}
    class Poilyline extends BaseObject
        @include GmapUtil
        constructor:()->
            self = @
        restrict: "ECA"
        replace: true
        require: "^googleMap"
        scope:
            path: "=path"
            stroke: "=stroke"
            clickable: "="
            draggable: "="
            editable: "="
            geodesic: "="
            icons: "=icons"
            visible: "="

        link: (scope, element, attrs, mapCtrl) =>

            # Validate required properties
            if angular.isUndefined(scope.path) or scope.path is null or scope.path.length < 2 or not @validatePathPoints(scope.path)
                $log.error "polyline: no valid path attribute found"
                return

            # Wrap polyline initialization inside a $timeout() call to make sure the map is created already
            $timeout =>
                buildOpts = (pathPoints) ->
                    opts = angular.extend({}, DEFAULTS,
                        map: map
                        path: pathPoints
                        strokeColor: scope.stroke and scope.stroke.color
                        strokeOpacity: scope.stroke and scope.stroke.opacity
                        strokeWeight: scope.stroke and scope.stroke.weight
                    )
                    angular.forEach
                        clickable: true
                        draggable: false
                        editable: false
                        geodesic: false
                        visible: true
                    , (defaultValue, key) ->
                        if angular.isUndefined(scope[key]) or scope[key] is null
                            opts[key] = defaultValue
                        else
                            opts[key] = scope[key]

                    opts
                map = mapCtrl.getMap()
                polyline = new google.maps.Polyline(buildOpts(@convertPathPoints(scope.path)))
                extendMapBounds map, pathPoints  if @isTrue(attrs.fit)
                if angular.isDefined(scope.editable)
                    scope.$watch "editable", (newValue, oldValue) ->
                        polyline.setEditable newValue if newValue != oldValue

                if angular.isDefined(scope.draggable)
                    scope.$watch "draggable", (newValue, oldValue) ->
                        polyline.setDraggable newValue if newValue != oldValue

                if angular.isDefined(scope.visible)
                    scope.$watch "visible", (newValue, oldValue) ->
                        polyline.setVisible newValue if newValue != oldValue

                if angular.isDefined(scope.geodesic)
                    scope.$watch "geodesic", (newValue, oldValue) ->
                        polyline.setOptions buildOpts(polyline.getPath()) if newValue != oldValue

                if angular.isDefined(scope.stroke) and angular.isDefined(scope.stroke.weight)
                    scope.$watch "stroke.weight", (newValue, oldValue) ->
                        polyline.setOptions buildOpts(polyline.getPath()) if newValue != oldValue

                if angular.isDefined(scope.stroke) and angular.isDefined(scope.stroke.color)
                    scope.$watch "stroke.color", (newValue, oldValue) ->
                        polyline.setOptions buildOpts(polyline.getPath()) if newValue != oldValue

                arraySyncer = arraySync(polyline.getPath(), scope, "path")

                # Remove polyline on scope $destroy
                scope.$on "$destroy", ->
                    polyline.setMap null
                    if arraySyncer
                        arraySyncer()
                        arraySyncer = null
]