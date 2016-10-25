//12.05.11 - NE - Added title property. 
//03.29.11 - NE - Created.

package controls
{
	import controls.skins.CBRADisclaimerSkin;
	
	import com.esri.ags.Map;
	
	import mx.controls.Text;
	
	import spark.components.SkinnableContainer;

	public class CBRADisclaimer extends SkinnableContainer
	{
		private var _map:Map;
		
		private var _disclaimerText:String;
		private var _title:String;
		private var _disclaimerHtmlText:Text;
		
		[Bindable]
		public function get map():Map {
			return _map;
		}
		
		public function set map(m:Map):void {
			_map = m;
		}
		
		[Bindable]
		public function get disclaimerText():String {
			return _disclaimerText;
		}
		
		public function set disclaimerText(dText:String):void {
			_disclaimerText = dText;
		}
		
		[Bindable]
		public function get title():String {
			return _title;
		}
		
		public function set title(dTitle:String):void {
			_title = dTitle;
		}
		
		[Bindable]
		public function get disclaimerHtmlText():Text {
			return _disclaimerHtmlText;
		}
		
		public function set disclaimerHtmlText(dHtmlText:Text):void {
			_disclaimerHtmlText = dHtmlText;
		}
		
		override public function stylesInitialized():void {  
			super.stylesInitialized();
			this.setStyle("skinClass",Class(controls.skins.CBRADisclaimerSkin));
		}
		
		public function CBRADisclaimer()
		{
			
		}
	}
}