// 05.02.11 - NE - Updated logic to include Title 2 and Title 3 in query results and map footprint determination. 
// 04.08.11 - NE - Edited map click query to return results only if a Unit is queried.
// 04.07.11 - NE - Improved identify for multiple features.
// 04.05.11 - NE - Added query to for map click to return CBRS Unit.
// 04.01.11 - NE - Update to baseSwitch function to fix level of details truncation for imagery w/ labels.
// 03.30.11 - NE - Geocoder bug fix.

// End as Template
// 06.28.10 - JB - Added new Wim LayerLegend component
// 03.26.10 - JB - Created
 /***
 * ActionScript file for template */

import com.esri.ags.FeatureSet;
import com.esri.ags.Graphic;
import com.esri.ags.events.FindEvent;
import com.esri.ags.events.GeometryServiceEvent;
import com.esri.ags.events.MapMouseEvent;
import com.esri.ags.geometry.Extent;
import com.esri.ags.geometry.Geometry;
import com.esri.ags.geometry.MapPoint;
import com.esri.ags.layers.TiledMapServiceLayer;
import com.esri.ags.symbols.InfoSymbol;
import com.esri.ags.tasks.IdentifyTask;
import com.esri.ags.tasks.QueryTask;
import com.esri.ags.tasks.supportClasses.AddressCandidate;
import com.esri.ags.tasks.supportClasses.AddressToLocationsParameters;
import com.esri.ags.tasks.supportClasses.FindResult;
import com.esri.ags.tasks.supportClasses.GeneralizeParameters;
import com.esri.ags.tasks.supportClasses.IdentifyParameters;
import com.esri.ags.tasks.supportClasses.Query;
import com.esri.ags.utils.GraphicUtil;
import com.esri.ags.utils.WebMercatorUtil;
import com.esri.ags.virtualearth.VEGeocodeResult;

import controls.MeasureMap;
import controls.skins.CBRADataWindowSkin;
import controls.skins.CBRADisclaimerSkin;

import flash.display.StageDisplayState;
import flash.events.Event;
import flash.events.MouseEvent;

import gov.usgs.wim.controls.WiMInfoWindow;
import gov.usgs.wim.controls.skins.WiMInfoWindowSkin;

import mx.collections.ArrayCollection;
import mx.controls.*;
import mx.core.FlexGlobals;
import mx.core.IFlexDisplayObject;
import mx.core.UIComponent;
import mx.events.CloseEvent;
import mx.events.FlexEvent;
import mx.managers.PopUpManager;
import mx.rpc.AsyncResponder;
import mx.utils.ObjectProxy;

import spark.components.Group;




			[Bindable]
			private var genAlpha:Number = 0.6;
			[Bindable]
			private var mapX:Number = 0;
			[Bindable]
			private var mapY:Number = 0;

			private var wetPoint:MapPoint;

			[Bindable]
			private var windLoc:String;

			private var _queryWindow:WiMInfoWindow;

			private var measureToolActivated:Boolean;

			private var _measureWindow:WiMInfoWindow;

			[Bindable]
			public var measureToolClose:Function;

			[Embed(source='assets/images/cbrsSearch.png')]
			[Bindable]
			private var cbrsIcon:Class;

			private var popUpBoxes:Object = new Object();

			private var bufferClickPopUp:String;
			
			//Array of parameters for info queries
			private var queryParameters:Object = {
													cities: new ArrayCollection(["POP1990", "City Population", "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/"]),
													rivers: new ArrayCollection(["RIVERS", "River", "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/"])
												 };
	  		
			    		
			    		
    		/**
    		 * load mapper
    		 * */
    		private function load():void
    		{
				//mapLegend.layers = [ cbrsDeterminationZones , cbrsUnits ];
			}
				
    		
    		//Handles click requests for map layer info
    		private function onMapClick(event:MapMouseEvent):void
    		{
				
				if (measureToolActivated) {
					return;
				}
				
    			queryGraphicsLayer.clear();
    			infoGraphicsLayer.clear();
				
				PopUpManager.removePopUp(_queryWindow);
				
    			var identifyParameters:IdentifyParameters = new IdentifyParameters();
				identifyParameters.returnGeometry = true;
				identifyParameters.tolerance = 0;
				identifyParameters.width = map.width;
				identifyParameters.height = map.height;
				identifyParameters.geometry = event.mapPoint;
				identifyParameters.layerOption = IdentifyParameters.LAYER_OPTION_ALL;
				identifyParameters.layerIds = [0,2,4];
				identifyParameters.mapExtent = map.extent;
				identifyParameters.spatialReference = map.spatialReference;										
		    	 				
    			var identifyTask:IdentifyTask = new IdentifyTask();
				identifyTask.showBusyCursor = true;
				identifyTask.url = "https://fwspublic.wim.usgs.gov/arcgis/rest/services/CBRAMapper/GeoCBRA/MapServer";
    			identifyTask.execute( identifyParameters, new AsyncResponder(infoResult, infoFault, event) );
		    }
    		
    		private function onExtentChange():void {
				//trace(map.extent);
			}
    		
    		/* Query tooltip methods */
    		
    	    private function infoResult(resultSet:Array, event:MouseEvent):void
    		{
				var buffZoneClick: Boolean = false;
				for (i=0;i<resultSet.length;i++) {
					if (resultSet[i].layerName == "CBRS_Determination_Zone") {
							
							showPopUpBox(event, 'infoBox3');
							buffZoneClick = true;
							
					}
				}
							

				if (!buffZoneClick) {
					
				
				var containsUnit:Boolean = false;
				var unit:String = '';
				for (i=0;i<resultSet.length;i++) {
					
					if (resultSet[i].layerName == "CBRS_Units") {
						containsUnit = true;
						unit = resultSet[i].feature.attributes.Unit;
					}
				}
				
    			if (resultSet.length != 0 && containsUnit == true) {
					
					var i:int;
					//var cbrsData:Object = new Object();
					//var cbrsData:ArrayCollection = new ArrayCollection();
					var dataObj:Object = new Object();
					var aGraphic:Graphic;
					var bGraphic:Graphic;
					
					//var totalAcreage:String;
					
					for (i=0;i<resultSet.length;i++) {
						if (resultSet[i].layerName == "CBRS_Map_Footprints") {
							trace(resultSet[i].feature.attributes.Title.search(unit) != -1);
							trace(resultSet[i].feature.attributes.Title.search(unit));
							trace(resultSet[i].feature.attributes.Title);
							trace(unit);
							trace(resultSet[i].feature.attributes.Title_2);
							trace(resultSet[i].feature.attributes.Title_3);
						}
						if (resultSet[i].layerName == "CBRS_Units") {
							if (aGraphic == null) {
								aGraphic = resultSet[i].feature;
								aGraphic.symbol = aQuerySym;
			            		queryGraphicsLayer.add(aGraphic);
								
								if (dataObj == null) {
									dataObj = resultSet[i].feature.attributes;
								} else {
									dataObj.Unit = resultSet[i].feature.attributes.Unit;
									dataObj.Name = resultSet[i].feature.attributes.Name;
									dataObj.Unit_Type = resultSet[i].feature.attributes.Unit_Type;
									dataObj.Year_Designated = resultSet[i].feature.attributes.Year_Designated;
									dataObj.Tier = resultSet[i].feature.attributes.Tier;
									dataObj.Fast_Acres = resultSet[i].feature.attributes.Fast_Acres;
									dataObj.Wet_Acres = resultSet[i].feature.attributes.Wet_Acres;
									
									if (dataObj.Tier == 2){
										dataObj.totalAcreage = "Approximately " + (Number(dataObj.Fast_Acres) + Number(dataObj.Wet_Acres)) + " acres.";
										
									} else {
										
										dataObj.totalAcreage = "Data not available at this time.";
									}
									
								
								}
							}
						} else if (resultSet[i].layerName == "CBRS_Map_Footprints" && resultSet[i].feature.attributes.Title.search(unit) != -1) {
							if (bGraphic == null) {
								bGraphic = resultSet[i].feature;
								bGraphic.symbol = bQuerySym;
								queryGraphicsLayer.add(bGraphic);
								
								if (dataObj == null) {
									dataObj = resultSet[i].feature.attributes;
								} else {
									dataObj.Map_Link = resultSet[i].feature.attributes.Map_Link;
									dataObj.Map_Date = resultSet[i].feature.attributes.Map_Date;
									dataObj.Scale = resultSet[i].feature.attributes.Scale;
									dataObj.Title = resultSet[i].feature.attributes.Title;
									dataObj.Title_2 = resultSet[i].feature.attributes.Title_2;
									dataObj.Title_3 = resultSet[i].feature.attributes.Title_3;
								}
							}
						} else if (resultSet[i].layerName == "CBRS_Map_Footprints" && resultSet[i].feature.attributes.Title_2.search(unit) != -1) {
							if (bGraphic == null) {
								bGraphic = resultSet[i].feature;
								bGraphic.symbol = bQuerySym;
								queryGraphicsLayer.add(bGraphic);
								
								if (dataObj == null) {
									dataObj = resultSet[i].feature.attributes;
								} else {
									dataObj.Map_Link = resultSet[i].feature.attributes.Map_Link
									dataObj.Map_Date = resultSet[i].feature.attributes.Map_Date;
									dataObj.Scale = resultSet[i].feature.attributes.Scale;
									dataObj.Title = resultSet[i].feature.attributes.Title;
									dataObj.Title_2 = resultSet[i].feature.attributes.Title_2;
									dataObj.Title_3 = resultSet[i].feature.attributes.Title_3;
								}
							}
						} else if (resultSet[i].layerName == "CBRS_Map_Footprints" && resultSet[i].feature.attributes.Title_3.search(unit) != -1) {
							if (bGraphic == null) {
								bGraphic = resultSet[i].feature;
								bGraphic.symbol = bQuerySym;
								queryGraphicsLayer.add(bGraphic);
								
								if (dataObj == null) {
									dataObj = resultSet[i].feature.attributes;
								} else {
									dataObj.Map_Link = resultSet[i].feature.attributes.Map_Link
									dataObj.Map_Date = resultSet[i].feature.attributes.Map_Date;
									dataObj.Scale = resultSet[i].feature.attributes.Scale;
									dataObj.Title = resultSet[i].feature.attributes.Title;
									dataObj.Title_2 = resultSet[i].feature.attributes.Title_2;
									dataObj.Title_3 = resultSet[i].feature.attributes.Title_3;
								}
							}
						}
					}
					
					if (bGraphic == null) {
						for (i=0;i<resultSet.length;i++) {
							if (resultSet[i].layerName == "CBRS_Map_Footprints") {
								bGraphic = resultSet[i].feature;
								bGraphic.symbol = bQuerySym;
								queryGraphicsLayer.add(bGraphic);
								
								if (dataObj == null) {
									dataObj = resultSet[i].feature.attributes;
								} else {
									dataObj.Map_Link = resultSet[i].feature.attributes.Map_Link
									dataObj.Map_Date = resultSet[i].feature.attributes.Map_Date;
									dataObj.Scale = resultSet[i].feature.attributes.Scale;
									dataObj.Title = resultSet[i].feature.attributes.Title;
									dataObj.Title_2 = resultSet[i].feature.attributes.Title_2;
									dataObj.Title_3 = resultSet[i].feature.attributes.Title_3;
								}
							}
						}
					}
					
					trace("title :"+dataObj.Title+":");
					trace("title 2:"+dataObj.Title_2+":");
					trace("title 3:"+dataObj.Title_3+":");
					
					_queryWindow = PopUpManager.createPopUp(map, CBRADataWindow, false) as WiMInfoWindow;
					_queryWindow.addEventListener(CloseEvent.CLOSE,closePopUp);
					_queryWindow.data = dataObj;
					_queryWindow.setStyle("skinClass", CBRADataWindowSkin);
					_queryWindow.x = (FlexGlobals.topLevelApplication.width/2) - (_queryWindow.width/2);
					_queryWindow.y = (FlexGlobals.topLevelApplication.height/2) - (_queryWindow.height/2);
					
					
					
				} 
			}  
			}
    		private function infoFault(info:Object, token:Object = null):void
    		{
    			Alert.show(info.toString());
    		} 
    		   	
		 	/* End query tooltip methods */
		
		
    			
    		    		
    		private function baseSwitch(event:FlexEvent):void            
    		{                
	    		var tiledLayer:TiledMapServiceLayer = event.target as TiledMapServiceLayer;                
	    		if (tiledLayer.tileInfo != null && tiledLayer.id != "labelsMapLayer") {
					map.lods = tiledLayer.tileInfo.lods;
				}
    		}
    		
    		/*public function closePopUp(event:Event) {
						PopUpManager.removePopUp(_queryWindow);
					}*/
    		
    		
			/* Geo-coding methods */
			/*private function geoCode(searchString:String):void
			{
				if (geocoder.searchValue.text == 'Type Address, Landmark, etc...' || geocoder.searchValue.text == '') {
					Alert.show("Please enter an address into the Find Location tool.");
				} else {
					veGeocoder.addressToLocations(geocoder.searchValue.text, new AsyncResponder(onResult, onFault));
				}
				
				function onResult(results:Array, token:Object = null):void
				{
					if (results.length > 0)
					{
						var veResult:VEGeocodeResult = results[0];
						map.extent = WebMercatorUtil.geographicToWebMercator(veResult.bestView) as Extent;
						//map.extent = veResult.bestView;
					}
					else
					{
						Alert.show("Could not find " + searchString + ". Please try again");
					}
				}
			}*/

			//Original code taken from ESRI sample: http://resources.arcgis.com/en/help/flex-api/samples/index.html#/Geocode_an_address/01nq00000068000000/
			//Adjusted for handling lat/lng vs. lng/lat inputs
			private function geoCode(searchCriteria:String):void
			{
				var parameters:AddressToLocationsParameters = new AddressToLocationsParameters();
				//parameters such as 'SingleLine' are dependent upon the locator service used.
				parameters.address = { SingleLine: searchCriteria };
				
				// Use outFields to get back extra information
				// The exact fields available depends on the specific locator service used.
				parameters.outFields = [ "*" ];
				
				locator.addressToLocations(parameters, new AsyncResponder(onResult, onFault));
				function onResult(candidates:Array, token:Object = null):void
				{
					if (candidates.length > 0)
					{
						var addressCandidate:AddressCandidate = candidates[0];
						
						map.centerAt(addressCandidate.location);
						
						// Zoom to an appropriate level
						// Note: your attribute and field value might differ depending on which Locator you are using...
						if (addressCandidate.attributes.Loc_name.indexOf("AddressPoint") != -1) // US_RoofTop
						{
							map.scale = 9028;
						}
						else if (addressCandidate.attributes.Loc_name.indexOf("StreetAddress") != -1)
						{
							map.scale = 18056;
						}
						else if (addressCandidate.attributes.Loc_name.indexOf("StreetName") != -1) // US_Streets, CAN_Streets, CAN_StreetName, EU_Street_Addr* or EU_Street_Name*
						{
							map.scale = 36112;
						}
						else if (addressCandidate.attributes.Loc_name.indexOf("Postal") != -1
							|| addressCandidate.attributes.Loc_name.indexOf("PostalExt") != -1) // US_ZIP4, CAN_Postcode
						{
							map.scale = 144448;
						}
						else if (addressCandidate.attributes.Loc_name.indexOf("Postal") != -1) // US_Zipcode
						{
							map.scale = 144448;
						}
						else if (addressCandidate.attributes.Loc_name.indexOf("AdminPlaces") != -1) // US_CityState, CAN_CityProv
						{
							map.scale = 288895;
						}
						else if (addressCandidate.attributes.Loc_name.indexOf("WorldGazetteer") != -1) // US_CityState, CAN_CityProv
						{
							map.scale = 577791;
						}
						else
						{
							map.scale = 1155581;
						}
						//myInfo.textFlow = TextFlowUtil.importFromString("<span fontWeight='bold'>Found:</span><br/>" + addressCandidate.address.toString()); // formated address
					}
					else
					{
						Alert.show("Sorry, couldn't find a location for this address"
							+ "\nAddress: " + searchCriteria);
					}
				}
				
				function onFault(info:Object, token:Object = null):void
				{
					//myInfo.htmlText = "<b>Failure</b>" + info.toString();
					Alert.show("Failure: \n" + info.toString());
				}
			}

			public function latLonNeedsFix(criteria:String):Boolean {
				var needsFix:Boolean = false;
				
				if (criteria.search(",") != -1) {
					var newSearchArray:Array = criteria.split(",");
					if (Number(newSearchArray[1]) < 0 || Number(newSearchArray[1]) > 90) {
						needsFix = true;
					}
				}
				
				return needsFix;
			}

    		
    		private function onFault(info:Object, token:Object = null):void
    		{
    			Alert.show("Error: " + info.toString(), "problem with Locator");
    		}
    		
    		/* End geo-coding methods */

			public function startMeasure(pEvt:MouseEvent):void 
			{
				measureToolClose();
				PopUpManager.removePopUp(_measureWindow);
				measureToolActivated = true;
				_measureWindow = PopUpManager.createPopUp(map, MeasureTool, false) as WiMInfoWindow;
				_measureWindow.setStyle("skinClass", WiMInfoWindowSkin);
				_measureWindow.x = (FlexGlobals.topLevelApplication.width/2) - (_measureWindow.width/2);
				_measureWindow.y = (FlexGlobals.topLevelApplication.height/2) - (_measureWindow.height/2);
				_measureWindow.addEventListener(CloseEvent.CLOSE, closePopUp);
			}
				

			public function closePopUp(event:CloseEvent):void {
				PopUpManager.removePopUp(event.currentTarget as WiMInfoWindow);
				 if (event.currentTarget is MeasureTool) {
					measureLayer.clear();
					measureToolClose();
					measureToolActivated = false;
				}
			}

    		/* CBRS Search methods */
			private function cbrsFind(searchString:String):void
			{
				cbrsTask.execute(cbrsParams);
			}
			private function cbrsResult(event:FindEvent):void
			{
				if (event.findResults.length > 0)
				{
					var graphic:Graphic = FindResult(event.findResults[0]).feature;
					var graphicsExtent:Extent = GraphicUtil.getGraphicsExtent(new Array(graphic));
					if (graphicsExtent)
					{
						map.extent = graphicsExtent.expand(2);
						return;
					}
				} else {
					Alert.show("No results. Please try again.");
				}
			}
    		
    		/* Full screen methods */
    		/*public function isFullScreen() : Boolean
    		{	
    			return (this.stage.displayState == StageDisplayState.FULL_SCREEN);
    		}
    		
    		public function goFullScreen():void
    		{
    			try {
    				this.stage.displayState = StageDisplayState.FULL_SCREEN;
    			}
    			catch (e:Error)
    			{
    				Alert.show(e.toString() + this.stage.displayState, "Error");
    			}
    		}
    		
    		public function exitFullScreen():void
    		{
    			this.stage.displayState = StageDisplayState.NORMAL;
    		}
    		
    		public function toggleFullScreen():void
    		{
    			//stage.addEventListener(FullScreenEvent.FULL_SCREEN, handleFullScreen);
    			if ( !isFullScreen() ) {
    				goFullScreen();
    			} else {
    				exitFullScreen();
    			}
    		}  
    		
    		/* End full screen methods */
    		
    	/*
    		public function toggleOverlays():void {
    			if (header.visible) {
    				header.visible = false;
	    			headerLogo.visible = false;
					baseLayers.visible = false;
					navigation.visible = false;
					geocoder.visible = false;
					operationLayers.visible = false;
					//printButton.visible = false;
    			} else {
    				header.visible = true;
    				headerLogo.visible = true;
					baseLayers.visible = true;
					navigation.visible = true;
					geocoder.visible = true;
					operationLayers.visible = true;
					//printButton.visible = true;					
    			}
    		} */


			public function showPopUpBox(event:MouseEvent, popupName:String):void
			{
				popUpBoxes[ popupName ] = PopUpManager.createPopUp(this, Group) as Group;
				popUpBoxes[ popupName ].addElement( this[ popupName ] );
				popUpBoxes[ popupName ].x = event.stageX - 55;
				popUpBoxes[ popupName ].y = event.stageY - 10;	
				(popUpBoxes[ popupName ] as UIComponent).addEventListener(FlexEvent.CREATION_COMPLETE, function(event:FlexEvent):void {					
					//Don't place offscreen
					if ((popUpBoxes[ popupName ].x + popUpBoxes[ popupName ].width) > popUpBoxes[ popupName ].stage.stageWidth) {
						popUpBoxes[ popupName ].x = popUpBoxes[ popupName ].stage.stageWidth - popUpBoxes[ popupName ].width;
					}
				});
			}
    		