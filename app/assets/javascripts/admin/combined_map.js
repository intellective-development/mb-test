
var polygon_styles = {
  invisible: {
      fillColor: '#fff',
      fillOpacity: 0,
      opacity: 0,
      weight: 0
  },
  medium: {
      fillColor: '#0f0',
      fillOpacity: 0.2,
      opacity: 0.2,
      weight: 1
  },
  loud: {
      fillColor: '#0f0',
      fillOpacity: 0.45,
      color: '#00f',
      opacity: 0.4,
      weight: 1
  },
}

var mapbox_token = 'pk.eyJ1IjoibGlhbWZkIiwiYSI6ImQxY1puTTQifQ.2ayUx63VpVQqoGQxCvMVrQ';
L.mapbox.accessToken = mapbox_token;


var completeMapView = {
  layer_list: {},
  layer_control: $('#menu-ui')[0],
  zones_loaded: false,
  suppliers_loaded: false,

  initialize: function(){
    var initial_center_coords = [ 40.7475170623211, -73.9657974243164 ];
    this.mapContainer = L.mapbox.map('map', 'mapbox.streets');
    this.map = this.setCenter(initial_center_coords);
    this.$loader = $('.admin-loader');

    this.initializeLayer(L.mapbox.featureLayer(), 'zones', 2, 'maps/zones');
    this.initializeLayer(L.mapbox.featureLayer(), 'suppliers', 4, 'maps/suppliers');

    this.initializeEventHandlers();
  },
  initializeLayer: function(layer, name, zIndex, data_url){
    var view = completeMapView;
    layer.setZIndex(zIndex).addTo(this.map);
    this.layer_list[name] = layer;

    if(data_url){ // loadurl handles all the logic for inserting elements
      layer.loadURL(data_url);
    }
    layer.on('ready', function(layer){
      view.hideLayer("zones");
      if (name === 'zones'){
        view.zones_loaded = true;
      } else if (name === 'suppliers'){
        view.suppliers_loaded = true;
      }
      view.hideLoader();
    });
  },
  initializeEventHandlers: function(){
    this.layer_list.suppliers.on('click', this.supplierClick)
    this.layer_list.suppliers.on('mouseover', this.supplierMouseover)
    this.layer_list.suppliers.on('mouseout', this.supplierMouseout)
    $('select#supplier').change(this.focusSupplier);
  },
  hideLoader: function(){
    if (this.zones_loaded && this.suppliers_loaded){
      this.$loader.hide();
    }
  },
  supplierClick: function(e){
    var view = completeMapView;
    var marker = e.layer.feature,
        supplier_zones = view.supplierZones(marker.properties.supplier.id );
    _.each(supplier_zones, function(zone){
      zone.pinned = zone.pinned ? false : true; //toggle it, accounts for inital case
      if (zone.pinned){
        zone.setStyle(polygon_styles.loud)
      } else {
        zone.setStyle(polygon_styles.invisible)
      }
    });
  },
  supplierMouseover: function(e){
    var view = completeMapView;
    var marker = e.layer.feature,
       supplier_zones = view.supplierZones(marker.properties.supplier.id );
    _.each(supplier_zones, function(zone){
      zone.hovered = true;
      if (!zone.pinned) {
        zone.setStyle(polygon_styles.medium)
      }
    });

    var popup = e.layer.bindPopup("<a href=" + marker.properties.supplier.url + ">"+ marker.properties.supplier.name+ "</a>").openPopup();
  },
  supplierMouseout: function(e){
    var view = completeMapView;
    var marker = e.layer.feature,
       supplier_zones = view.supplierZones(marker.properties.supplier.id );
    _.each(supplier_zones, function(zone){
      if (zone.hovered && !zone.pinned) {
        zone.setStyle(polygon_styles.invisible)
      }
      zone.hovered = false;
    });
    //var popup = e.layer.closePopup();
  },
  focusSupplier: function(e){
    var view = completeMapView;
    var data = JSON.parse($(e.target).val());
    view.setCenter(data.coords);

    view.hideLayer('zones'); //hide all others
    supplier_zones = view.supplierZones(data.id);
    _.each(supplier_zones, function(zone){
      zone.pinned = true; //toggle it, accounts for inital case
      zone.setStyle(polygon_styles.loud)
    });
  },
  hideLayer: function(layer_name){
    _.each(this.layer_list[layer_name]._layers, function(layer){
      layer.setStyle(polygon_styles.invisible);
    });
  },
  supplierZones: function(supplier_id){
    return _.select(this.layer_list.zones._layers, function(layer){
      return supplier_id == layer.feature.properties.supplier.id
    });
  },
  setCenter: function(coords){
    return this.mapContainer.setView(coords, 12);
  }
}

completeMapView.initialize();
