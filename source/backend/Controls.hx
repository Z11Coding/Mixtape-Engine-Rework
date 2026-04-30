package backend;

import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.mappings.FlxGamepadMapping;
import flixel.input.keyboard.FlxKey;

class Controls
{
	//Keeping same use cases on stuff for it to be easier to understand/use
	//I'd have removed it but this makes it a lot less annoying to use in my opinion

	//You do NOT have to create these variables/getters for adding new keys,
	//but you will instead have to use:
	//   controls.justPressed("ui_up")   instead of   controls.UI_UP

	//Dumb but easily usable code, or Smart but complicated? Your choice.
	//Also idk how to use macros they're weird as fuck lol

	// Pressed buttons (directions)
	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	private function get_UI_UP_P() return justPressed('ui_up');
	private function get_UI_DOWN_P() return justPressed('ui_down');
	private function get_UI_LEFT_P() return justPressed('ui_left');
	private function get_UI_RIGHT_P() return justPressed('ui_right');
	private function get_NOTE_UP_P() return justPressed('note_up');
	private function get_NOTE_DOWN_P() return justPressed('note_down');
	private function get_NOTE_LEFT_P() return justPressed('note_left');
	private function get_NOTE_RIGHT_P() return justPressed('note_right');

	// Held buttons (directions)
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	private function get_UI_UP() return pressed('ui_up');
	private function get_UI_DOWN() return pressed('ui_down');
	private function get_UI_LEFT() return pressed('ui_left');
	private function get_UI_RIGHT() return pressed('ui_right');
	private function get_NOTE_UP() return pressed('note_up');
	private function get_NOTE_DOWN() return pressed('note_down');
	private function get_NOTE_LEFT() return pressed('note_left');
	private function get_NOTE_RIGHT() return pressed('note_right');

	// Released buttons (directions)
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	private function get_UI_UP_R() return justReleased('ui_up');
	private function get_UI_DOWN_R() return justReleased('ui_down');
	private function get_UI_LEFT_R() return justReleased('ui_left');
	private function get_UI_RIGHT_R() return justReleased('ui_right');
	private function get_NOTE_UP_R() return justReleased('note_up');
	private function get_NOTE_DOWN_R() return justReleased('note_down');
	private function get_NOTE_LEFT_R() return justReleased('note_left');
	private function get_NOTE_RIGHT_R() return justReleased('note_right');

	// The above, but for multikey (this doesn't NEED to be here, but it probably should be)
	public var NOTE_ONE1_P(get, never):Bool;

	public var NOTE_TWO1_P(get, never):Bool;
	public var NOTE_TWO2_P(get, never):Bool;

	public var NOTE_THREE1_P(get, never):Bool;
	public var NOTE_THREE2_P(get, never):Bool;
	public var NOTE_THREE3_P(get, never):Bool;

	public var NOTE_FIVE1_P(get, never):Bool;
	public var NOTE_FIVE2_P(get, never):Bool;
	public var NOTE_FIVE3_P(get, never):Bool;
	public var NOTE_FIVE4_P(get, never):Bool;
	public var NOTE_FIVE5_P(get, never):Bool;

	public var NOTE_SIX1_P(get, never):Bool;
	public var NOTE_SIX2_P(get, never):Bool;
	public var NOTE_SIX3_P(get, never):Bool;
	public var NOTE_SIX4_P(get, never):Bool;
	public var NOTE_SIX5_P(get, never):Bool;
	public var NOTE_SIX6_P(get, never):Bool;

	public var NOTE_SEVEN1_P(get, never):Bool;
	public var NOTE_SEVEN2_P(get, never):Bool;
	public var NOTE_SEVEN3_P(get, never):Bool;
	public var NOTE_SEVEN4_P(get, never):Bool;
	public var NOTE_SEVEN5_P(get, never):Bool;
	public var NOTE_SEVEN6_P(get, never):Bool;
	public var NOTE_SEVEN7_P(get, never):Bool;

	public var NOTE_EIGHT1_P(get, never):Bool;
	public var NOTE_EIGHT2_P(get, never):Bool;
	public var NOTE_EIGHT3_P(get, never):Bool;
	public var NOTE_EIGHT4_P(get, never):Bool;
	public var NOTE_EIGHT5_P(get, never):Bool;
	public var NOTE_EIGHT6_P(get, never):Bool;
	public var NOTE_EIGHT7_P(get, never):Bool;
	public var NOTE_EIGHT8_P(get, never):Bool;

	public var NOTE_NINE1_P(get, never):Bool;
	public var NOTE_NINE2_P(get, never):Bool;
	public var NOTE_NINE3_P(get, never):Bool;
	public var NOTE_NINE4_P(get, never):Bool;
	public var NOTE_NINE5_P(get, never):Bool;
	public var NOTE_NINE6_P(get, never):Bool;
	public var NOTE_NINE7_P(get, never):Bool;
	public var NOTE_NINE8_P(get, never):Bool;
	public var NOTE_NINE9_P(get, never):Bool;

	public var NOTE_TEN1_P(get, never):Bool;
	public var NOTE_TEN2_P(get, never):Bool;
	public var NOTE_TEN3_P(get, never):Bool;
	public var NOTE_TEN4_P(get, never):Bool;
	public var NOTE_TEN5_P(get, never):Bool;
	public var NOTE_TEN6_P(get, never):Bool;
	public var NOTE_TEN7_P(get, never):Bool;
	public var NOTE_TEN8_P(get, never):Bool;
	public var NOTE_TEN9_P(get, never):Bool;
	public var NOTE_TEN10_P(get, never):Bool;

	public var NOTE_ELEV1_P(get, never):Bool;
	public var NOTE_ELEV2_P(get, never):Bool;
	public var NOTE_ELEV3_P(get, never):Bool;
	public var NOTE_ELEV4_P(get, never):Bool;
	public var NOTE_ELEV5_P(get, never):Bool;
	public var NOTE_ELEV6_P(get, never):Bool;
	public var NOTE_ELEV7_P(get, never):Bool;
	public var NOTE_ELEV8_P(get, never):Bool;
	public var NOTE_ELEV9_P(get, never):Bool;
	public var NOTE_ELEV10_P(get, never):Bool;
	public var NOTE_ELEV11_P(get, never):Bool;

	public var NOTE_TWEL1_P(get, never):Bool;
	public var NOTE_TWEL2_P(get, never):Bool;
	public var NOTE_TWEL3_P(get, never):Bool;
	public var NOTE_TWEL4_P(get, never):Bool;
	public var NOTE_TWEL5_P(get, never):Bool;
	public var NOTE_TWEL6_P(get, never):Bool;
	public var NOTE_TWEL7_P(get, never):Bool;
	public var NOTE_TWEL8_P(get, never):Bool;
	public var NOTE_TWEL9_P(get, never):Bool;
	public var NOTE_TWEL10_P(get, never):Bool;
	public var NOTE_TWEL11_P(get, never):Bool;
	public var NOTE_TWEL12_P(get, never):Bool;

	public var NOTE_THIR1_P(get, never):Bool;
	public var NOTE_THIR2_P(get, never):Bool;
	public var NOTE_THIR3_P(get, never):Bool;
	public var NOTE_THIR4_P(get, never):Bool;
	public var NOTE_THIR5_P(get, never):Bool;
	public var NOTE_THIR6_P(get, never):Bool;
	public var NOTE_THIR7_P(get, never):Bool;
	public var NOTE_THIR8_P(get, never):Bool;
	public var NOTE_THIR9_P(get, never):Bool;
	public var NOTE_THIR10_P(get, never):Bool;
	public var NOTE_THIR11_P(get, never):Bool;
	public var NOTE_THIR12_P(get, never):Bool;
	public var NOTE_THIR13_P(get, never):Bool;

	public var NOTE_FORT1_P(get, never):Bool;
	public var NOTE_FORT2_P(get, never):Bool;
	public var NOTE_FORT3_P(get, never):Bool;
	public var NOTE_FORT4_P(get, never):Bool;
	public var NOTE_FORT5_P(get, never):Bool;
	public var NOTE_FORT6_P(get, never):Bool;
	public var NOTE_FORT7_P(get, never):Bool;
	public var NOTE_FORT8_P(get, never):Bool;
	public var NOTE_FORT9_P(get, never):Bool;
	public var NOTE_FORT10_P(get, never):Bool;
	public var NOTE_FORT11_P(get, never):Bool;
	public var NOTE_FORT12_P(get, never):Bool;
	public var NOTE_FORT13_P(get, never):Bool;
	public var NOTE_FORT14_P(get, never):Bool;

	public var NOTE_FIFT1_P(get, never):Bool;
	public var NOTE_FIFT2_P(get, never):Bool;
	public var NOTE_FIFT3_P(get, never):Bool;
	public var NOTE_FIFT4_P(get, never):Bool;
	public var NOTE_FIFT5_P(get, never):Bool;
	public var NOTE_FIFT6_P(get, never):Bool;
	public var NOTE_FIFT7_P(get, never):Bool;
	public var NOTE_FIFT8_P(get, never):Bool;
	public var NOTE_FIFT9_P(get, never):Bool;
	public var NOTE_FIFT10_P(get, never):Bool;
	public var NOTE_FIFT11_P(get, never):Bool;
	public var NOTE_FIFT12_P(get, never):Bool;
	public var NOTE_FIFT13_P(get, never):Bool;
	public var NOTE_FIFT14_P(get, never):Bool;
	public var NOTE_FIFT15_P(get, never):Bool;

	public var NOTE_SIXT1_P(get, never):Bool;
	public var NOTE_SIXT2_P(get, never):Bool;
	public var NOTE_SIXT3_P(get, never):Bool;
	public var NOTE_SIXT4_P(get, never):Bool;
	public var NOTE_SIXT5_P(get, never):Bool;
	public var NOTE_SIXT6_P(get, never):Bool;
	public var NOTE_SIXT7_P(get, never):Bool;
	public var NOTE_SIXT8_P(get, never):Bool;
	public var NOTE_SIXT9_P(get, never):Bool;
	public var NOTE_SIXT10_P(get, never):Bool;
	public var NOTE_SIXT11_P(get, never):Bool;
	public var NOTE_SIXT12_P(get, never):Bool;
	public var NOTE_SIXT13_P(get, never):Bool;
	public var NOTE_SIXT14_P(get, never):Bool;
	public var NOTE_SIXT15_P(get, never):Bool;
	public var NOTE_SIXT16_P(get, never):Bool;

	public var NOTE_SEVT1_P(get, never):Bool;
	public var NOTE_SEVT2_P(get, never):Bool;
	public var NOTE_SEVT3_P(get, never):Bool;
	public var NOTE_SEVT4_P(get, never):Bool;
	public var NOTE_SEVT5_P(get, never):Bool;
	public var NOTE_SEVT6_P(get, never):Bool;
	public var NOTE_SEVT7_P(get, never):Bool;
	public var NOTE_SEVT8_P(get, never):Bool;
	public var NOTE_SEVT9_P(get, never):Bool;
	public var NOTE_SEVT10_P(get, never):Bool;
	public var NOTE_SEVT11_P(get, never):Bool;
	public var NOTE_SEVT12_P(get, never):Bool;
	public var NOTE_SEVT13_P(get, never):Bool;
	public var NOTE_SEVT14_P(get, never):Bool;
	public var NOTE_SEVT15_P(get, never):Bool;
	public var NOTE_SEVT16_P(get, never):Bool;
	public var NOTE_SEVT17_P(get, never):Bool;

	public var NOTE_ATE1_P(get, never):Bool;
	public var NOTE_ATE2_P(get, never):Bool;
	public var NOTE_ATE3_P(get, never):Bool;
	public var NOTE_ATE4_P(get, never):Bool;
	public var NOTE_ATE5_P(get, never):Bool;
	public var NOTE_ATE6_P(get, never):Bool;
	public var NOTE_ATE7_P(get, never):Bool;
	public var NOTE_ATE8_P(get, never):Bool;
	public var NOTE_ATE9_P(get, never):Bool;
	public var NOTE_ATE10_P(get, never):Bool;
	public var NOTE_ATE11_P(get, never):Bool;
	public var NOTE_ATE12_P(get, never):Bool;
	public var NOTE_ATE13_P(get, never):Bool;
	public var NOTE_ATE14_P(get, never):Bool;
	public var NOTE_ATE15_P(get, never):Bool;
	public var NOTE_ATE16_P(get, never):Bool;
	public var NOTE_ATE17_P(get, never):Bool;
	public var NOTE_ATE18_P(get, never):Bool;

	private function get_NOTE_ONE1_P() return justPressed('note_one1');

	private function get_NOTE_TWO1_P() return justPressed('note_two1');
	private function get_NOTE_TWO2_P() return justPressed('note_two2');

	private function get_NOTE_THREE1_P() return justPressed('note_three1');
	private function get_NOTE_THREE2_P() return justPressed('note_three2');
	private function get_NOTE_THREE3_P() return justPressed('note_three3');

	private function get_NOTE_FIVE1_P() return justPressed('note_five1');
	private function get_NOTE_FIVE2_P() return justPressed('note_five2');
	private function get_NOTE_FIVE3_P() return justPressed('note_five3');
	private function get_NOTE_FIVE4_P() return justPressed('note_five4');
	private function get_NOTE_FIVE5_P() return justPressed('note_five5');

	private function get_NOTE_SIX1_P() return justPressed('note_six1');
	private function get_NOTE_SIX2_P() return justPressed('note_six2');
	private function get_NOTE_SIX3_P() return justPressed('note_six3');
	private function get_NOTE_SIX4_P() return justPressed('note_six4');
	private function get_NOTE_SIX5_P() return justPressed('note_six5');
	private function get_NOTE_SIX6_P() return justPressed('note_six6');

	private function get_NOTE_SEVEN1_P() return justPressed('note_seven1');
	private function get_NOTE_SEVEN2_P() return justPressed('note_seven2');
	private function get_NOTE_SEVEN3_P() return justPressed('note_seven3');
	private function get_NOTE_SEVEN4_P() return justPressed('note_seven4');
	private function get_NOTE_SEVEN5_P() return justPressed('note_seven5');
	private function get_NOTE_SEVEN6_P() return justPressed('note_seven6');
	private function get_NOTE_SEVEN7_P() return justPressed('note_seven7');

	private function get_NOTE_EIGHT1_P() return justPressed('note_eight1');
	private function get_NOTE_EIGHT2_P() return justPressed('note_eight2');
	private function get_NOTE_EIGHT3_P() return justPressed('note_eight3');
	private function get_NOTE_EIGHT4_P() return justPressed('note_eight4');
	private function get_NOTE_EIGHT5_P() return justPressed('note_eight5');
	private function get_NOTE_EIGHT6_P() return justPressed('note_eight6');
	private function get_NOTE_EIGHT7_P() return justPressed('note_eight7');
	private function get_NOTE_EIGHT8_P() return justPressed('note_eight8');

	private function get_NOTE_NINE1_P() return justPressed('note_nine1');
	private function get_NOTE_NINE2_P() return justPressed('note_nine2');
	private function get_NOTE_NINE3_P() return justPressed('note_nine3');
	private function get_NOTE_NINE4_P() return justPressed('note_nine4');
	private function get_NOTE_NINE5_P() return justPressed('note_nine5');
	private function get_NOTE_NINE6_P() return justPressed('note_nine6');
	private function get_NOTE_NINE7_P() return justPressed('note_nine7');
	private function get_NOTE_NINE8_P() return justPressed('note_nine8');
	private function get_NOTE_NINE9_P() return justPressed('note_nine9');

	private function get_NOTE_TEN1_P() return justPressed('note_ten1');
	private function get_NOTE_TEN2_P() return justPressed('note_ten2');
	private function get_NOTE_TEN3_P() return justPressed('note_ten3');
	private function get_NOTE_TEN4_P() return justPressed('note_ten4');
	private function get_NOTE_TEN5_P() return justPressed('note_ten5');
	private function get_NOTE_TEN6_P() return justPressed('note_ten6');
	private function get_NOTE_TEN7_P() return justPressed('note_ten7');
	private function get_NOTE_TEN8_P() return justPressed('note_ten8');
	private function get_NOTE_TEN9_P() return justPressed('note_ten9');
	private function get_NOTE_TEN10_P() return justPressed('note_ten10');

	private function get_NOTE_ELEV1_P() return justPressed('note_elev1');
	private function get_NOTE_ELEV2_P() return justPressed('note_elev2');
	private function get_NOTE_ELEV3_P() return justPressed('note_elev3');
	private function get_NOTE_ELEV4_P() return justPressed('note_elev4');
	private function get_NOTE_ELEV5_P() return justPressed('note_elev5');
	private function get_NOTE_ELEV6_P() return justPressed('note_elev6');
	private function get_NOTE_ELEV7_P() return justPressed('note_elev7');
	private function get_NOTE_ELEV8_P() return justPressed('note_elev8');
	private function get_NOTE_ELEV9_P() return justPressed('note_elev9');
	private function get_NOTE_ELEV10_P() return justPressed('note_elev10');
	private function get_NOTE_ELEV11_P() return justPressed('note_elev11');

	private function get_NOTE_TWEL1_P() return justPressed('note_twel1');
	private function get_NOTE_TWEL2_P() return justPressed('note_twel2');
	private function get_NOTE_TWEL3_P() return justPressed('note_twel3');
	private function get_NOTE_TWEL4_P() return justPressed('note_twel4');
	private function get_NOTE_TWEL5_P() return justPressed('note_twel5');
	private function get_NOTE_TWEL6_P() return justPressed('note_twel6');
	private function get_NOTE_TWEL7_P() return justPressed('note_twel7');
	private function get_NOTE_TWEL8_P() return justPressed('note_twel8');
	private function get_NOTE_TWEL9_P() return justPressed('note_twel9');
	private function get_NOTE_TWEL10_P() return justPressed('note_twel10');
	private function get_NOTE_TWEL11_P() return justPressed('note_twel11');
	private function get_NOTE_TWEL12_P() return justPressed('note_twel12');

	private function get_NOTE_THIR1_P() return justPressed('note_thir1');
	private function get_NOTE_THIR2_P() return justPressed('note_thir2');
	private function get_NOTE_THIR3_P() return justPressed('note_thir3');
	private function get_NOTE_THIR4_P() return justPressed('note_thir4');
	private function get_NOTE_THIR5_P() return justPressed('note_thir5');
	private function get_NOTE_THIR6_P() return justPressed('note_thir6');
	private function get_NOTE_THIR7_P() return justPressed('note_thir7');
	private function get_NOTE_THIR8_P() return justPressed('note_thir8');
	private function get_NOTE_THIR9_P() return justPressed('note_thir9');
	private function get_NOTE_THIR10_P() return justPressed('note_thir10');
	private function get_NOTE_THIR11_P() return justPressed('note_thir11');
	private function get_NOTE_THIR12_P() return justPressed('note_thir12');
	private function get_NOTE_THIR13_P() return justPressed('note_thir13');

	private function get_NOTE_FORT1_P() return justPressed('note_fort1');
	private function get_NOTE_FORT2_P() return justPressed('note_fort2');
	private function get_NOTE_FORT3_P() return justPressed('note_fort3');
	private function get_NOTE_FORT4_P() return justPressed('note_fort4');
	private function get_NOTE_FORT5_P() return justPressed('note_fort5');
	private function get_NOTE_FORT6_P() return justPressed('note_fort6');
	private function get_NOTE_FORT7_P() return justPressed('note_fort7');
	private function get_NOTE_FORT8_P() return justPressed('note_fort8');
	private function get_NOTE_FORT9_P() return justPressed('note_fort9');
	private function get_NOTE_FORT10_P() return justPressed('note_fort10');
	private function get_NOTE_FORT11_P() return justPressed('note_fort11');
	private function get_NOTE_FORT12_P() return justPressed('note_fort12');
	private function get_NOTE_FORT13_P() return justPressed('note_fort13');
	private function get_NOTE_FORT14_P() return justPressed('note_fort14');

	private function get_NOTE_FIFT1_P() return justPressed('note_fift1');
	private function get_NOTE_FIFT2_P() return justPressed('note_fift2');
	private function get_NOTE_FIFT3_P() return justPressed('note_fift3');
	private function get_NOTE_FIFT4_P() return justPressed('note_fift4');
	private function get_NOTE_FIFT5_P() return justPressed('note_fift5');
	private function get_NOTE_FIFT6_P() return justPressed('note_fift6');
	private function get_NOTE_FIFT7_P() return justPressed('note_fift7');
	private function get_NOTE_FIFT8_P() return justPressed('note_fift8');
	private function get_NOTE_FIFT9_P() return justPressed('note_fift9');
	private function get_NOTE_FIFT10_P() return justPressed('note_fift10');
	private function get_NOTE_FIFT11_P() return justPressed('note_fift11');
	private function get_NOTE_FIFT12_P() return justPressed('note_fift12');
	private function get_NOTE_FIFT13_P() return justPressed('note_fift13');
	private function get_NOTE_FIFT14_P() return justPressed('note_fift14');
	private function get_NOTE_FIFT15_P() return justPressed('note_fift15');

	private function get_NOTE_SIXT1_P() return justPressed('note_sixt1');
	private function get_NOTE_SIXT2_P() return justPressed('note_sixt2');
	private function get_NOTE_SIXT3_P() return justPressed('note_sixt3');
	private function get_NOTE_SIXT4_P() return justPressed('note_sixt4');
	private function get_NOTE_SIXT5_P() return justPressed('note_sixt5');
	private function get_NOTE_SIXT6_P() return justPressed('note_sixt6');
	private function get_NOTE_SIXT7_P() return justPressed('note_sixt7');
	private function get_NOTE_SIXT8_P() return justPressed('note_sixt8');
	private function get_NOTE_SIXT9_P() return justPressed('note_sixt9');
	private function get_NOTE_SIXT10_P() return justPressed('note_sixt10');
	private function get_NOTE_SIXT11_P() return justPressed('note_sixt11');
	private function get_NOTE_SIXT12_P() return justPressed('note_sixt12');
	private function get_NOTE_SIXT13_P() return justPressed('note_sixt13');
	private function get_NOTE_SIXT14_P() return justPressed('note_sixt14');
	private function get_NOTE_SIXT15_P() return justPressed('note_sixt15');
	private function get_NOTE_SIXT16_P() return justPressed('note_sixt16');

	private function get_NOTE_SEVT1_P() return justPressed('note_sevt1');
	private function get_NOTE_SEVT2_P() return justPressed('note_sevt2');
	private function get_NOTE_SEVT3_P() return justPressed('note_sevt3');
	private function get_NOTE_SEVT4_P() return justPressed('note_sevt4');
	private function get_NOTE_SEVT5_P() return justPressed('note_sevt5');
	private function get_NOTE_SEVT6_P() return justPressed('note_sevt6');
	private function get_NOTE_SEVT7_P() return justPressed('note_sevt7');
	private function get_NOTE_SEVT8_P() return justPressed('note_sevt8');
	private function get_NOTE_SEVT9_P() return justPressed('note_sevt9');
	private function get_NOTE_SEVT10_P() return justPressed('note_sevt10');
	private function get_NOTE_SEVT11_P() return justPressed('note_sevt11');
	private function get_NOTE_SEVT12_P() return justPressed('note_sevt12');
	private function get_NOTE_SEVT13_P() return justPressed('note_sevt13');
	private function get_NOTE_SEVT14_P() return justPressed('note_sevt14');
	private function get_NOTE_SEVT15_P() return justPressed('note_sevt15');
	private function get_NOTE_SEVT16_P() return justPressed('note_sevt16');
	private function get_NOTE_SEVT17_P() return justPressed('note_sevt17');

	private function get_NOTE_ATE1_P() return justPressed('note_ate1');
	private function get_NOTE_ATE2_P() return justPressed('note_ate2');
	private function get_NOTE_ATE3_P() return justPressed('note_ate3');
	private function get_NOTE_ATE4_P() return justPressed('note_ate4');
	private function get_NOTE_ATE5_P() return justPressed('note_ate5');
	private function get_NOTE_ATE6_P() return justPressed('note_ate6');
	private function get_NOTE_ATE7_P() return justPressed('note_ate7');
	private function get_NOTE_ATE8_P() return justPressed('note_ate8');
	private function get_NOTE_ATE9_P() return justPressed('note_ate9');
	private function get_NOTE_ATE10_P() return justPressed('note_ate10');
	private function get_NOTE_ATE11_P() return justPressed('note_ate11');
	private function get_NOTE_ATE12_P() return justPressed('note_ate12');
	private function get_NOTE_ATE13_P() return justPressed('note_ate13');
	private function get_NOTE_ATE14_P() return justPressed('note_ate14');
	private function get_NOTE_ATE15_P() return justPressed('note_ate15');
	private function get_NOTE_ATE16_P() return justPressed('note_ate16');
	private function get_NOTE_ATE17_P() return justPressed('note_ate17');
	private function get_NOTE_ATE18_P() return justPressed('note_ate18');




	public var NOTE_ONE1(get, never):Bool;

	public var NOTE_TWO1(get, never):Bool;
	public var NOTE_TWO2(get, never):Bool;

	public var NOTE_THREE1(get, never):Bool;
	public var NOTE_THREE2(get, never):Bool;
	public var NOTE_THREE3(get, never):Bool;

	public var NOTE_FIVE1(get, never):Bool;
	public var NOTE_FIVE2(get, never):Bool;
	public var NOTE_FIVE3(get, never):Bool;
	public var NOTE_FIVE4(get, never):Bool;
	public var NOTE_FIVE5(get, never):Bool;

	public var NOTE_SIX1(get, never):Bool;
	public var NOTE_SIX2(get, never):Bool;
	public var NOTE_SIX3(get, never):Bool;
	public var NOTE_SIX4(get, never):Bool;
	public var NOTE_SIX5(get, never):Bool;
	public var NOTE_SIX6(get, never):Bool;

	public var NOTE_SEVEN1(get, never):Bool;
	public var NOTE_SEVEN2(get, never):Bool;
	public var NOTE_SEVEN3(get, never):Bool;
	public var NOTE_SEVEN4(get, never):Bool;
	public var NOTE_SEVEN5(get, never):Bool;
	public var NOTE_SEVEN6(get, never):Bool;
	public var NOTE_SEVEN7(get, never):Bool;

	public var NOTE_EIGHT1(get, never):Bool;
	public var NOTE_EIGHT2(get, never):Bool;
	public var NOTE_EIGHT3(get, never):Bool;
	public var NOTE_EIGHT4(get, never):Bool;
	public var NOTE_EIGHT5(get, never):Bool;
	public var NOTE_EIGHT6(get, never):Bool;
	public var NOTE_EIGHT7(get, never):Bool;
	public var NOTE_EIGHT8(get, never):Bool;

	public var NOTE_NINE1(get, never):Bool;
	public var NOTE_NINE2(get, never):Bool;
	public var NOTE_NINE3(get, never):Bool;
	public var NOTE_NINE4(get, never):Bool;
	public var NOTE_NINE5(get, never):Bool;
	public var NOTE_NINE6(get, never):Bool;
	public var NOTE_NINE7(get, never):Bool;
	public var NOTE_NINE8(get, never):Bool;
	public var NOTE_NINE9(get, never):Bool;

	public var NOTE_TEN1(get, never):Bool;
	public var NOTE_TEN2(get, never):Bool;
	public var NOTE_TEN3(get, never):Bool;
	public var NOTE_TEN4(get, never):Bool;
	public var NOTE_TEN5(get, never):Bool;
	public var NOTE_TEN6(get, never):Bool;
	public var NOTE_TEN7(get, never):Bool;
	public var NOTE_TEN8(get, never):Bool;
	public var NOTE_TEN9(get, never):Bool;
	public var NOTE_TEN10(get, never):Bool;

	public var NOTE_ELEV1(get, never):Bool;
	public var NOTE_ELEV2(get, never):Bool;
	public var NOTE_ELEV3(get, never):Bool;
	public var NOTE_ELEV4(get, never):Bool;
	public var NOTE_ELEV5(get, never):Bool;
	public var NOTE_ELEV6(get, never):Bool;
	public var NOTE_ELEV7(get, never):Bool;
	public var NOTE_ELEV8(get, never):Bool;
	public var NOTE_ELEV9(get, never):Bool;
	public var NOTE_ELEV10(get, never):Bool;
	public var NOTE_ELEV11(get, never):Bool;

	public var NOTE_TWEL1(get, never):Bool;
	public var NOTE_TWEL2(get, never):Bool;
	public var NOTE_TWEL3(get, never):Bool;
	public var NOTE_TWEL4(get, never):Bool;
	public var NOTE_TWEL5(get, never):Bool;
	public var NOTE_TWEL6(get, never):Bool;
	public var NOTE_TWEL7(get, never):Bool;
	public var NOTE_TWEL8(get, never):Bool;
	public var NOTE_TWEL9(get, never):Bool;
	public var NOTE_TWEL10(get, never):Bool;
	public var NOTE_TWEL11(get, never):Bool;
	public var NOTE_TWEL12(get, never):Bool;

	public var NOTE_THIR1(get, never):Bool;
	public var NOTE_THIR2(get, never):Bool;
	public var NOTE_THIR3(get, never):Bool;
	public var NOTE_THIR4(get, never):Bool;
	public var NOTE_THIR5(get, never):Bool;
	public var NOTE_THIR6(get, never):Bool;
	public var NOTE_THIR7(get, never):Bool;
	public var NOTE_THIR8(get, never):Bool;
	public var NOTE_THIR9(get, never):Bool;
	public var NOTE_THIR10(get, never):Bool;
	public var NOTE_THIR11(get, never):Bool;
	public var NOTE_THIR12(get, never):Bool;
	public var NOTE_THIR13(get, never):Bool;

	public var NOTE_FORT1(get, never):Bool;
	public var NOTE_FORT2(get, never):Bool;
	public var NOTE_FORT3(get, never):Bool;
	public var NOTE_FORT4(get, never):Bool;
	public var NOTE_FORT5(get, never):Bool;
	public var NOTE_FORT6(get, never):Bool;
	public var NOTE_FORT7(get, never):Bool;
	public var NOTE_FORT8(get, never):Bool;
	public var NOTE_FORT9(get, never):Bool;
	public var NOTE_FORT10(get, never):Bool;
	public var NOTE_FORT11(get, never):Bool;
	public var NOTE_FORT12(get, never):Bool;
	public var NOTE_FORT13(get, never):Bool;
	public var NOTE_FORT14(get, never):Bool;

	public var NOTE_FIFT1(get, never):Bool;
	public var NOTE_FIFT2(get, never):Bool;
	public var NOTE_FIFT3(get, never):Bool;
	public var NOTE_FIFT4(get, never):Bool;
	public var NOTE_FIFT5(get, never):Bool;
	public var NOTE_FIFT6(get, never):Bool;
	public var NOTE_FIFT7(get, never):Bool;
	public var NOTE_FIFT8(get, never):Bool;
	public var NOTE_FIFT9(get, never):Bool;
	public var NOTE_FIFT10(get, never):Bool;
	public var NOTE_FIFT11(get, never):Bool;
	public var NOTE_FIFT12(get, never):Bool;
	public var NOTE_FIFT13(get, never):Bool;
	public var NOTE_FIFT14(get, never):Bool;
	public var NOTE_FIFT15(get, never):Bool;

	public var NOTE_SIXT1(get, never):Bool;
	public var NOTE_SIXT2(get, never):Bool;
	public var NOTE_SIXT3(get, never):Bool;
	public var NOTE_SIXT4(get, never):Bool;
	public var NOTE_SIXT5(get, never):Bool;
	public var NOTE_SIXT6(get, never):Bool;
	public var NOTE_SIXT7(get, never):Bool;
	public var NOTE_SIXT8(get, never):Bool;
	public var NOTE_SIXT9(get, never):Bool;
	public var NOTE_SIXT10(get, never):Bool;
	public var NOTE_SIXT11(get, never):Bool;
	public var NOTE_SIXT12(get, never):Bool;
	public var NOTE_SIXT13(get, never):Bool;
	public var NOTE_SIXT14(get, never):Bool;
	public var NOTE_SIXT15(get, never):Bool;
	public var NOTE_SIXT16(get, never):Bool;

	public var NOTE_SEVT1(get, never):Bool;
	public var NOTE_SEVT2(get, never):Bool;
	public var NOTE_SEVT3(get, never):Bool;
	public var NOTE_SEVT4(get, never):Bool;
	public var NOTE_SEVT5(get, never):Bool;
	public var NOTE_SEVT6(get, never):Bool;
	public var NOTE_SEVT7(get, never):Bool;
	public var NOTE_SEVT8(get, never):Bool;
	public var NOTE_SEVT9(get, never):Bool;
	public var NOTE_SEVT10(get, never):Bool;
	public var NOTE_SEVT11(get, never):Bool;
	public var NOTE_SEVT12(get, never):Bool;
	public var NOTE_SEVT13(get, never):Bool;
	public var NOTE_SEVT14(get, never):Bool;
	public var NOTE_SEVT15(get, never):Bool;
	public var NOTE_SEVT16(get, never):Bool;
	public var NOTE_SEVT17(get, never):Bool;

	public var NOTE_ATE1(get, never):Bool;
	public var NOTE_ATE2(get, never):Bool;
	public var NOTE_ATE3(get, never):Bool;
	public var NOTE_ATE4(get, never):Bool;
	public var NOTE_ATE5(get, never):Bool;
	public var NOTE_ATE6(get, never):Bool;
	public var NOTE_ATE7(get, never):Bool;
	public var NOTE_ATE8(get, never):Bool;
	public var NOTE_ATE9(get, never):Bool;
	public var NOTE_ATE10(get, never):Bool;
	public var NOTE_ATE11(get, never):Bool;
	public var NOTE_ATE12(get, never):Bool;
	public var NOTE_ATE13(get, never):Bool;
	public var NOTE_ATE14(get, never):Bool;
	public var NOTE_ATE15(get, never):Bool;
	public var NOTE_ATE16(get, never):Bool;
	public var NOTE_ATE17(get, never):Bool;
	public var NOTE_ATE18(get, never):Bool;

	private function get_NOTE_ONE1() return pressed('note_one1');

	private function get_NOTE_TWO1() return pressed('note_two1');
	private function get_NOTE_TWO2() return pressed('note_two2');

	private function get_NOTE_THREE1() return pressed('note_three1');
	private function get_NOTE_THREE2() return pressed('note_three2');
	private function get_NOTE_THREE3() return pressed('note_three3');

	private function get_NOTE_FIVE1() return pressed('note_five1');
	private function get_NOTE_FIVE2() return pressed('note_five2');
	private function get_NOTE_FIVE3() return pressed('note_five3');
	private function get_NOTE_FIVE4() return pressed('note_five4');
	private function get_NOTE_FIVE5() return pressed('note_five5');

	private function get_NOTE_SIX1() return pressed('note_six1');
	private function get_NOTE_SIX2() return pressed('note_six2');
	private function get_NOTE_SIX3() return pressed('note_six3');
	private function get_NOTE_SIX4() return pressed('note_six4');
	private function get_NOTE_SIX5() return pressed('note_six5');
	private function get_NOTE_SIX6() return pressed('note_six6');

	private function get_NOTE_SEVEN1() return pressed('note_seven1');
	private function get_NOTE_SEVEN2() return pressed('note_seven2');
	private function get_NOTE_SEVEN3() return pressed('note_seven3');
	private function get_NOTE_SEVEN4() return pressed('note_seven4');
	private function get_NOTE_SEVEN5() return pressed('note_seven5');
	private function get_NOTE_SEVEN6() return pressed('note_seven6');
	private function get_NOTE_SEVEN7() return pressed('note_seven7');

	private function get_NOTE_EIGHT1() return pressed('note_eight1');
	private function get_NOTE_EIGHT2() return pressed('note_eight2');
	private function get_NOTE_EIGHT3() return pressed('note_eight3');
	private function get_NOTE_EIGHT4() return pressed('note_eight4');
	private function get_NOTE_EIGHT5() return pressed('note_eight5');
	private function get_NOTE_EIGHT6() return pressed('note_eight6');
	private function get_NOTE_EIGHT7() return pressed('note_eight7');
	private function get_NOTE_EIGHT8() return pressed('note_eight8');

	private function get_NOTE_NINE1() return pressed('note_nine1');
	private function get_NOTE_NINE2() return pressed('note_nine2');
	private function get_NOTE_NINE3() return pressed('note_nine3');
	private function get_NOTE_NINE4() return pressed('note_nine4');
	private function get_NOTE_NINE5() return pressed('note_nine5');
	private function get_NOTE_NINE6() return pressed('note_nine6');
	private function get_NOTE_NINE7() return pressed('note_nine7');
	private function get_NOTE_NINE8() return pressed('note_nine8');
	private function get_NOTE_NINE9() return pressed('note_nine9');

	private function get_NOTE_TEN1() return pressed('note_ten1');
	private function get_NOTE_TEN2() return pressed('note_ten2');
	private function get_NOTE_TEN3() return pressed('note_ten3');
	private function get_NOTE_TEN4() return pressed('note_ten4');
	private function get_NOTE_TEN5() return pressed('note_ten5');
	private function get_NOTE_TEN6() return pressed('note_ten6');
	private function get_NOTE_TEN7() return pressed('note_ten7');
	private function get_NOTE_TEN8() return pressed('note_ten8');
	private function get_NOTE_TEN9() return pressed('note_ten9');
	private function get_NOTE_TEN10() return pressed('note_ten10');

	private function get_NOTE_ELEV1() return pressed('note_elev1');
	private function get_NOTE_ELEV2() return pressed('note_elev2');
	private function get_NOTE_ELEV3() return pressed('note_elev3');
	private function get_NOTE_ELEV4() return pressed('note_elev4');
	private function get_NOTE_ELEV5() return pressed('note_elev5');
	private function get_NOTE_ELEV6() return pressed('note_elev6');
	private function get_NOTE_ELEV7() return pressed('note_elev7');
	private function get_NOTE_ELEV8() return pressed('note_elev8');
	private function get_NOTE_ELEV9() return pressed('note_elev9');
	private function get_NOTE_ELEV10() return pressed('note_elev10');
	private function get_NOTE_ELEV11() return pressed('note_elev11');

	private function get_NOTE_TWEL1() return pressed('note_twel1');
	private function get_NOTE_TWEL2() return pressed('note_twel2');
	private function get_NOTE_TWEL3() return pressed('note_twel3');
	private function get_NOTE_TWEL4() return pressed('note_twel4');
	private function get_NOTE_TWEL5() return pressed('note_twel5');
	private function get_NOTE_TWEL6() return pressed('note_twel6');
	private function get_NOTE_TWEL7() return pressed('note_twel7');
	private function get_NOTE_TWEL8() return pressed('note_twel8');
	private function get_NOTE_TWEL9() return pressed('note_twel9');
	private function get_NOTE_TWEL10() return pressed('note_twel10');
	private function get_NOTE_TWEL11() return pressed('note_twel11');
	private function get_NOTE_TWEL12() return pressed('note_twel12');

	private function get_NOTE_THIR1() return pressed('note_thir1');
	private function get_NOTE_THIR2() return pressed('note_thir2');
	private function get_NOTE_THIR3() return pressed('note_thir3');
	private function get_NOTE_THIR4() return pressed('note_thir4');
	private function get_NOTE_THIR5() return pressed('note_thir5');
	private function get_NOTE_THIR6() return pressed('note_thir6');
	private function get_NOTE_THIR7() return pressed('note_thir7');
	private function get_NOTE_THIR8() return pressed('note_thir8');
	private function get_NOTE_THIR9() return pressed('note_thir9');
	private function get_NOTE_THIR10() return pressed('note_thir10');
	private function get_NOTE_THIR11() return pressed('note_thir11');
	private function get_NOTE_THIR12() return pressed('note_thir12');
	private function get_NOTE_THIR13() return pressed('note_thir13');

	private function get_NOTE_FORT1() return pressed('note_fort1');
	private function get_NOTE_FORT2() return pressed('note_fort2');
	private function get_NOTE_FORT3() return pressed('note_fort3');
	private function get_NOTE_FORT4() return pressed('note_fort4');
	private function get_NOTE_FORT5() return pressed('note_fort5');
	private function get_NOTE_FORT6() return pressed('note_fort6');
	private function get_NOTE_FORT7() return pressed('note_fort7');
	private function get_NOTE_FORT8() return pressed('note_fort8');
	private function get_NOTE_FORT9() return pressed('note_fort9');
	private function get_NOTE_FORT10() return pressed('note_fort10');
	private function get_NOTE_FORT11() return pressed('note_fort11');
	private function get_NOTE_FORT12() return pressed('note_fort12');
	private function get_NOTE_FORT13() return pressed('note_fort13');
	private function get_NOTE_FORT14() return pressed('note_fort14');

	private function get_NOTE_FIFT1() return pressed('note_fift1');
	private function get_NOTE_FIFT2() return pressed('note_fift2');
	private function get_NOTE_FIFT3() return pressed('note_fift3');
	private function get_NOTE_FIFT4() return pressed('note_fift4');
	private function get_NOTE_FIFT5() return pressed('note_fift5');
	private function get_NOTE_FIFT6() return pressed('note_fift6');
	private function get_NOTE_FIFT7() return pressed('note_fift7');
	private function get_NOTE_FIFT8() return pressed('note_fift8');
	private function get_NOTE_FIFT9() return pressed('note_fift9');
	private function get_NOTE_FIFT10() return pressed('note_fift10');
	private function get_NOTE_FIFT11() return pressed('note_fift11');
	private function get_NOTE_FIFT12() return pressed('note_fift12');
	private function get_NOTE_FIFT13() return pressed('note_fift13');
	private function get_NOTE_FIFT14() return pressed('note_fift14');
	private function get_NOTE_FIFT15() return pressed('note_fift15');

	private function get_NOTE_SIXT1() return pressed('note_sixt1');
	private function get_NOTE_SIXT2() return pressed('note_sixt2');
	private function get_NOTE_SIXT3() return pressed('note_sixt3');
	private function get_NOTE_SIXT4() return pressed('note_sixt4');
	private function get_NOTE_SIXT5() return pressed('note_sixt5');
	private function get_NOTE_SIXT6() return pressed('note_sixt6');
	private function get_NOTE_SIXT7() return pressed('note_sixt7');
	private function get_NOTE_SIXT8() return pressed('note_sixt8');
	private function get_NOTE_SIXT9() return pressed('note_sixt9');
	private function get_NOTE_SIXT10() return pressed('note_sixt10');
	private function get_NOTE_SIXT11() return pressed('note_sixt11');
	private function get_NOTE_SIXT12() return pressed('note_sixt12');
	private function get_NOTE_SIXT13() return pressed('note_sixt13');
	private function get_NOTE_SIXT14() return pressed('note_sixt14');
	private function get_NOTE_SIXT15() return pressed('note_sixt15');
	private function get_NOTE_SIXT16() return pressed('note_sixt16');

	private function get_NOTE_SEVT1() return pressed('note_sevt1');
	private function get_NOTE_SEVT2() return pressed('note_sevt2');
	private function get_NOTE_SEVT3() return pressed('note_sevt3');
	private function get_NOTE_SEVT4() return pressed('note_sevt4');
	private function get_NOTE_SEVT5() return pressed('note_sevt5');
	private function get_NOTE_SEVT6() return pressed('note_sevt6');
	private function get_NOTE_SEVT7() return pressed('note_sevt7');
	private function get_NOTE_SEVT8() return pressed('note_sevt8');
	private function get_NOTE_SEVT9() return pressed('note_sevt9');
	private function get_NOTE_SEVT10() return pressed('note_sevt10');
	private function get_NOTE_SEVT11() return pressed('note_sevt11');
	private function get_NOTE_SEVT12() return pressed('note_sevt12');
	private function get_NOTE_SEVT13() return pressed('note_sevt13');
	private function get_NOTE_SEVT14() return pressed('note_sevt14');
	private function get_NOTE_SEVT15() return pressed('note_sevt15');
	private function get_NOTE_SEVT16() return pressed('note_sevt16');
	private function get_NOTE_SEVT17() return pressed('note_sevt17');

	private function get_NOTE_ATE1() return pressed('note_ate1');
	private function get_NOTE_ATE2() return pressed('note_ate2');
	private function get_NOTE_ATE3() return pressed('note_ate3');
	private function get_NOTE_ATE4() return pressed('note_ate4');
	private function get_NOTE_ATE5() return pressed('note_ate5');
	private function get_NOTE_ATE6() return pressed('note_ate6');
	private function get_NOTE_ATE7() return pressed('note_ate7');
	private function get_NOTE_ATE8() return pressed('note_ate8');
	private function get_NOTE_ATE9() return pressed('note_ate9');
	private function get_NOTE_ATE10() return pressed('note_ate10');
	private function get_NOTE_ATE11() return pressed('note_ate11');
	private function get_NOTE_ATE12() return pressed('note_ate12');
	private function get_NOTE_ATE13() return pressed('note_ate13');
	private function get_NOTE_ATE14() return pressed('note_ate14');
	private function get_NOTE_ATE15() return pressed('note_ate15');
	private function get_NOTE_ATE16() return pressed('note_ate16');
	private function get_NOTE_ATE17() return pressed('note_ate17');
	private function get_NOTE_ATE18() return pressed('note_ate18');

	public var NOTE_ONE1_R(get, never):Bool;

	public var NOTE_TWO1_R(get, never):Bool;
	public var NOTE_TWO2_R(get, never):Bool;

	public var NOTE_THREE1_R(get, never):Bool;
	public var NOTE_THREE2_R(get, never):Bool;
	public var NOTE_THREE3_R(get, never):Bool;

	public var NOTE_FIVE1_R(get, never):Bool;
	public var NOTE_FIVE2_R(get, never):Bool;
	public var NOTE_FIVE3_R(get, never):Bool;
	public var NOTE_FIVE4_R(get, never):Bool;
	public var NOTE_FIVE5_R(get, never):Bool;

	public var NOTE_SIX1_R(get, never):Bool;
	public var NOTE_SIX2_R(get, never):Bool;
	public var NOTE_SIX3_R(get, never):Bool;
	public var NOTE_SIX4_R(get, never):Bool;
	public var NOTE_SIX5_R(get, never):Bool;
	public var NOTE_SIX6_R(get, never):Bool;

	public var NOTE_SEVEN1_R(get, never):Bool;
	public var NOTE_SEVEN2_R(get, never):Bool;
	public var NOTE_SEVEN3_R(get, never):Bool;
	public var NOTE_SEVEN4_R(get, never):Bool;
	public var NOTE_SEVEN5_R(get, never):Bool;
	public var NOTE_SEVEN6_R(get, never):Bool;
	public var NOTE_SEVEN7_R(get, never):Bool;

	public var NOTE_EIGHT1_R(get, never):Bool;
	public var NOTE_EIGHT2_R(get, never):Bool;
	public var NOTE_EIGHT3_R(get, never):Bool;
	public var NOTE_EIGHT4_R(get, never):Bool;
	public var NOTE_EIGHT5_R(get, never):Bool;
	public var NOTE_EIGHT6_R(get, never):Bool;
	public var NOTE_EIGHT7_R(get, never):Bool;
	public var NOTE_EIGHT8_R(get, never):Bool;

	public var NOTE_NINE1_R(get, never):Bool;
	public var NOTE_NINE2_R(get, never):Bool;
	public var NOTE_NINE3_R(get, never):Bool;
	public var NOTE_NINE4_R(get, never):Bool;
	public var NOTE_NINE5_R(get, never):Bool;
	public var NOTE_NINE6_R(get, never):Bool;
	public var NOTE_NINE7_R(get, never):Bool;
	public var NOTE_NINE8_R(get, never):Bool;
	public var NOTE_NINE9_R(get, never):Bool;

	public var NOTE_TEN1_R(get, never):Bool;
	public var NOTE_TEN2_R(get, never):Bool;
	public var NOTE_TEN3_R(get, never):Bool;
	public var NOTE_TEN4_R(get, never):Bool;
	public var NOTE_TEN5_R(get, never):Bool;
	public var NOTE_TEN6_R(get, never):Bool;
	public var NOTE_TEN7_R(get, never):Bool;
	public var NOTE_TEN8_R(get, never):Bool;
	public var NOTE_TEN9_R(get, never):Bool;
	public var NOTE_TEN10_R(get, never):Bool;

	public var NOTE_ELEV1_R(get, never):Bool;
	public var NOTE_ELEV2_R(get, never):Bool;
	public var NOTE_ELEV3_R(get, never):Bool;
	public var NOTE_ELEV4_R(get, never):Bool;
	public var NOTE_ELEV5_R(get, never):Bool;
	public var NOTE_ELEV6_R(get, never):Bool;
	public var NOTE_ELEV7_R(get, never):Bool;
	public var NOTE_ELEV8_R(get, never):Bool;
	public var NOTE_ELEV9_R(get, never):Bool;
	public var NOTE_ELEV10_R(get, never):Bool;
	public var NOTE_ELEV11_R(get, never):Bool;

	public var NOTE_TWEL1_R(get, never):Bool;
	public var NOTE_TWEL2_R(get, never):Bool;
	public var NOTE_TWEL3_R(get, never):Bool;
	public var NOTE_TWEL4_R(get, never):Bool;
	public var NOTE_TWEL5_R(get, never):Bool;
	public var NOTE_TWEL6_R(get, never):Bool;
	public var NOTE_TWEL7_R(get, never):Bool;
	public var NOTE_TWEL8_R(get, never):Bool;
	public var NOTE_TWEL9_R(get, never):Bool;
	public var NOTE_TWEL10_R(get, never):Bool;
	public var NOTE_TWEL11_R(get, never):Bool;
	public var NOTE_TWEL12_R(get, never):Bool;

	public var NOTE_THIR1_R(get, never):Bool;
	public var NOTE_THIR2_R(get, never):Bool;
	public var NOTE_THIR3_R(get, never):Bool;
	public var NOTE_THIR4_R(get, never):Bool;
	public var NOTE_THIR5_R(get, never):Bool;
	public var NOTE_THIR6_R(get, never):Bool;
	public var NOTE_THIR7_R(get, never):Bool;
	public var NOTE_THIR8_R(get, never):Bool;
	public var NOTE_THIR9_R(get, never):Bool;
	public var NOTE_THIR10_R(get, never):Bool;
	public var NOTE_THIR11_R(get, never):Bool;
	public var NOTE_THIR12_R(get, never):Bool;
	public var NOTE_THIR13_R(get, never):Bool;

	public var NOTE_FORT1_R(get, never):Bool;
	public var NOTE_FORT2_R(get, never):Bool;
	public var NOTE_FORT3_R(get, never):Bool;
	public var NOTE_FORT4_R(get, never):Bool;
	public var NOTE_FORT5_R(get, never):Bool;
	public var NOTE_FORT6_R(get, never):Bool;
	public var NOTE_FORT7_R(get, never):Bool;
	public var NOTE_FORT8_R(get, never):Bool;
	public var NOTE_FORT9_R(get, never):Bool;
	public var NOTE_FORT10_R(get, never):Bool;
	public var NOTE_FORT11_R(get, never):Bool;
	public var NOTE_FORT12_R(get, never):Bool;
	public var NOTE_FORT13_R(get, never):Bool;
	public var NOTE_FORT14_R(get, never):Bool;

	public var NOTE_FIFT1_R(get, never):Bool;
	public var NOTE_FIFT2_R(get, never):Bool;
	public var NOTE_FIFT3_R(get, never):Bool;
	public var NOTE_FIFT4_R(get, never):Bool;
	public var NOTE_FIFT5_R(get, never):Bool;
	public var NOTE_FIFT6_R(get, never):Bool;
	public var NOTE_FIFT7_R(get, never):Bool;
	public var NOTE_FIFT8_R(get, never):Bool;
	public var NOTE_FIFT9_R(get, never):Bool;
	public var NOTE_FIFT10_R(get, never):Bool;
	public var NOTE_FIFT11_R(get, never):Bool;
	public var NOTE_FIFT12_R(get, never):Bool;
	public var NOTE_FIFT13_R(get, never):Bool;
	public var NOTE_FIFT14_R(get, never):Bool;
	public var NOTE_FIFT15_R(get, never):Bool;

	public var NOTE_SIXT1_R(get, never):Bool;
	public var NOTE_SIXT2_R(get, never):Bool;
	public var NOTE_SIXT3_R(get, never):Bool;
	public var NOTE_SIXT4_R(get, never):Bool;
	public var NOTE_SIXT5_R(get, never):Bool;
	public var NOTE_SIXT6_R(get, never):Bool;
	public var NOTE_SIXT7_R(get, never):Bool;
	public var NOTE_SIXT8_R(get, never):Bool;
	public var NOTE_SIXT9_R(get, never):Bool;
	public var NOTE_SIXT10_R(get, never):Bool;
	public var NOTE_SIXT11_R(get, never):Bool;
	public var NOTE_SIXT12_R(get, never):Bool;
	public var NOTE_SIXT13_R(get, never):Bool;
	public var NOTE_SIXT14_R(get, never):Bool;
	public var NOTE_SIXT15_R(get, never):Bool;
	public var NOTE_SIXT16_R(get, never):Bool;

	public var NOTE_SEVT1_R(get, never):Bool;
	public var NOTE_SEVT2_R(get, never):Bool;
	public var NOTE_SEVT3_R(get, never):Bool;
	public var NOTE_SEVT4_R(get, never):Bool;
	public var NOTE_SEVT5_R(get, never):Bool;
	public var NOTE_SEVT6_R(get, never):Bool;
	public var NOTE_SEVT7_R(get, never):Bool;
	public var NOTE_SEVT8_R(get, never):Bool;
	public var NOTE_SEVT9_R(get, never):Bool;
	public var NOTE_SEVT10_R(get, never):Bool;
	public var NOTE_SEVT11_R(get, never):Bool;
	public var NOTE_SEVT12_R(get, never):Bool;
	public var NOTE_SEVT13_R(get, never):Bool;
	public var NOTE_SEVT14_R(get, never):Bool;
	public var NOTE_SEVT15_R(get, never):Bool;
	public var NOTE_SEVT16_R(get, never):Bool;
	public var NOTE_SEVT17_R(get, never):Bool;

	public var NOTE_ATE1_R(get, never):Bool;
	public var NOTE_ATE2_R(get, never):Bool;
	public var NOTE_ATE3_R(get, never):Bool;
	public var NOTE_ATE4_R(get, never):Bool;
	public var NOTE_ATE5_R(get, never):Bool;
	public var NOTE_ATE6_R(get, never):Bool;
	public var NOTE_ATE7_R(get, never):Bool;
	public var NOTE_ATE8_R(get, never):Bool;
	public var NOTE_ATE9_R(get, never):Bool;
	public var NOTE_ATE10_R(get, never):Bool;
	public var NOTE_ATE11_R(get, never):Bool;
	public var NOTE_ATE12_R(get, never):Bool;
	public var NOTE_ATE13_R(get, never):Bool;
	public var NOTE_ATE14_R(get, never):Bool;
	public var NOTE_ATE15_R(get, never):Bool;
	public var NOTE_ATE16_R(get, never):Bool;
	public var NOTE_ATE17_R(get, never):Bool;
	public var NOTE_ATE18_R(get, never):Bool;

	private function get_NOTE_ONE1_R() return justReleased('note_one1');

	private function get_NOTE_TWO1_R() return justReleased('note_two1');
	private function get_NOTE_TWO2_R() return justReleased('note_two2');

	private function get_NOTE_THREE1_R() return justReleased('note_three1');
	private function get_NOTE_THREE2_R() return justReleased('note_three2');
	private function get_NOTE_THREE3_R() return justReleased('note_three3');

	private function get_NOTE_FIVE1_R() return justReleased('note_five1');
	private function get_NOTE_FIVE2_R() return justReleased('note_five2');
	private function get_NOTE_FIVE3_R() return justReleased('note_five3');
	private function get_NOTE_FIVE4_R() return justReleased('note_five4');
	private function get_NOTE_FIVE5_R() return justReleased('note_five5');

	private function get_NOTE_SIX1_R() return justReleased('note_six1');
	private function get_NOTE_SIX2_R() return justReleased('note_six2');
	private function get_NOTE_SIX3_R() return justReleased('note_six3');
	private function get_NOTE_SIX4_R() return justReleased('note_six4');
	private function get_NOTE_SIX5_R() return justReleased('note_six5');
	private function get_NOTE_SIX6_R() return justReleased('note_six6');

	private function get_NOTE_SEVEN1_R() return justReleased('note_seven1');
	private function get_NOTE_SEVEN2_R() return justReleased('note_seven2');
	private function get_NOTE_SEVEN3_R() return justReleased('note_seven3');
	private function get_NOTE_SEVEN4_R() return justReleased('note_seven4');
	private function get_NOTE_SEVEN5_R() return justReleased('note_seven5');
	private function get_NOTE_SEVEN6_R() return justReleased('note_seven6');
	private function get_NOTE_SEVEN7_R() return justReleased('note_seven7');

	private function get_NOTE_EIGHT1_R() return justReleased('note_eight1');
	private function get_NOTE_EIGHT2_R() return justReleased('note_eight2');
	private function get_NOTE_EIGHT3_R() return justReleased('note_eight3');
	private function get_NOTE_EIGHT4_R() return justReleased('note_eight4');
	private function get_NOTE_EIGHT5_R() return justReleased('note_eight5');
	private function get_NOTE_EIGHT6_R() return justReleased('note_eight6');
	private function get_NOTE_EIGHT7_R() return justReleased('note_eight7');
	private function get_NOTE_EIGHT8_R() return justReleased('note_eight8');

	private function get_NOTE_NINE1_R() return justReleased('note_nine1');
	private function get_NOTE_NINE2_R() return justReleased('note_nine2');
	private function get_NOTE_NINE3_R() return justReleased('note_nine3');
	private function get_NOTE_NINE4_R() return justReleased('note_nine4');
	private function get_NOTE_NINE5_R() return justReleased('note_nine5');
	private function get_NOTE_NINE6_R() return justReleased('note_nine6');
	private function get_NOTE_NINE7_R() return justReleased('note_nine7');
	private function get_NOTE_NINE8_R() return justReleased('note_nine8');
	private function get_NOTE_NINE9_R() return justReleased('note_nine9');

	private function get_NOTE_TEN1_R() return justReleased('note_ten1');
	private function get_NOTE_TEN2_R() return justReleased('note_ten2');
	private function get_NOTE_TEN3_R() return justReleased('note_ten3');
	private function get_NOTE_TEN4_R() return justReleased('note_ten4');
	private function get_NOTE_TEN5_R() return justReleased('note_ten5');
	private function get_NOTE_TEN6_R() return justReleased('note_ten6');
	private function get_NOTE_TEN7_R() return justReleased('note_ten7');
	private function get_NOTE_TEN8_R() return justReleased('note_ten8');
	private function get_NOTE_TEN9_R() return justReleased('note_ten9');
	private function get_NOTE_TEN10_R() return justReleased('note_ten10');

	private function get_NOTE_ELEV1_R() return justReleased('note_elev1');
	private function get_NOTE_ELEV2_R() return justReleased('note_elev2');
	private function get_NOTE_ELEV3_R() return justReleased('note_elev3');
	private function get_NOTE_ELEV4_R() return justReleased('note_elev4');
	private function get_NOTE_ELEV5_R() return justReleased('note_elev5');
	private function get_NOTE_ELEV6_R() return justReleased('note_elev6');
	private function get_NOTE_ELEV7_R() return justReleased('note_elev7');
	private function get_NOTE_ELEV8_R() return justReleased('note_elev8');
	private function get_NOTE_ELEV9_R() return justReleased('note_elev9');
	private function get_NOTE_ELEV10_R() return justReleased('note_elev10');
	private function get_NOTE_ELEV11_R() return justReleased('note_elev11');

	private function get_NOTE_TWEL1_R() return justReleased('note_twel1');
	private function get_NOTE_TWEL2_R() return justReleased('note_twel2');
	private function get_NOTE_TWEL3_R() return justReleased('note_twel3');
	private function get_NOTE_TWEL4_R() return justReleased('note_twel4');
	private function get_NOTE_TWEL5_R() return justReleased('note_twel5');
	private function get_NOTE_TWEL6_R() return justReleased('note_twel6');
	private function get_NOTE_TWEL7_R() return justReleased('note_twel7');
	private function get_NOTE_TWEL8_R() return justReleased('note_twel8');
	private function get_NOTE_TWEL9_R() return justReleased('note_twel9');
	private function get_NOTE_TWEL10_R() return justReleased('note_twel10');
	private function get_NOTE_TWEL11_R() return justReleased('note_twel11');
	private function get_NOTE_TWEL12_R() return justReleased('note_twel12');

	private function get_NOTE_THIR1_R() return justReleased('note_thir1');
	private function get_NOTE_THIR2_R() return justReleased('note_thir2');
	private function get_NOTE_THIR3_R() return justReleased('note_thir3');
	private function get_NOTE_THIR4_R() return justReleased('note_thir4');
	private function get_NOTE_THIR5_R() return justReleased('note_thir5');
	private function get_NOTE_THIR6_R() return justReleased('note_thir6');
	private function get_NOTE_THIR7_R() return justReleased('note_thir7');
	private function get_NOTE_THIR8_R() return justReleased('note_thir8');
	private function get_NOTE_THIR9_R() return justReleased('note_thir9');
	private function get_NOTE_THIR10_R() return justReleased('note_thir10');
	private function get_NOTE_THIR11_R() return justReleased('note_thir11');
	private function get_NOTE_THIR12_R() return justReleased('note_thir12');
	private function get_NOTE_THIR13_R() return justReleased('note_thir13');

	private function get_NOTE_FORT1_R() return justReleased('note_fort1');
	private function get_NOTE_FORT2_R() return justReleased('note_fort2');
	private function get_NOTE_FORT3_R() return justReleased('note_fort3');
	private function get_NOTE_FORT4_R() return justReleased('note_fort4');
	private function get_NOTE_FORT5_R() return justReleased('note_fort5');
	private function get_NOTE_FORT6_R() return justReleased('note_fort6');
	private function get_NOTE_FORT7_R() return justReleased('note_fort7');
	private function get_NOTE_FORT8_R() return justReleased('note_fort8');
	private function get_NOTE_FORT9_R() return justReleased('note_fort9');
	private function get_NOTE_FORT10_R() return justReleased('note_fort10');
	private function get_NOTE_FORT11_R() return justReleased('note_fort11');
	private function get_NOTE_FORT12_R() return justReleased('note_fort12');
	private function get_NOTE_FORT13_R() return justReleased('note_fort13');
	private function get_NOTE_FORT14_R() return justReleased('note_fort14');

	private function get_NOTE_FIFT1_R() return justReleased('note_fift1');
	private function get_NOTE_FIFT2_R() return justReleased('note_fift2');
	private function get_NOTE_FIFT3_R() return justReleased('note_fift3');
	private function get_NOTE_FIFT4_R() return justReleased('note_fift4');
	private function get_NOTE_FIFT5_R() return justReleased('note_fift5');
	private function get_NOTE_FIFT6_R() return justReleased('note_fift6');
	private function get_NOTE_FIFT7_R() return justReleased('note_fift7');
	private function get_NOTE_FIFT8_R() return justReleased('note_fift8');
	private function get_NOTE_FIFT9_R() return justReleased('note_fift9');
	private function get_NOTE_FIFT10_R() return justReleased('note_fift10');
	private function get_NOTE_FIFT11_R() return justReleased('note_fift11');
	private function get_NOTE_FIFT12_R() return justReleased('note_fift12');
	private function get_NOTE_FIFT13_R() return justReleased('note_fift13');
	private function get_NOTE_FIFT14_R() return justReleased('note_fift14');
	private function get_NOTE_FIFT15_R() return justReleased('note_fift15');

	private function get_NOTE_SIXT1_R() return justReleased('note_sixt1');
	private function get_NOTE_SIXT2_R() return justReleased('note_sixt2');
	private function get_NOTE_SIXT3_R() return justReleased('note_sixt3');
	private function get_NOTE_SIXT4_R() return justReleased('note_sixt4');
	private function get_NOTE_SIXT5_R() return justReleased('note_sixt5');
	private function get_NOTE_SIXT6_R() return justReleased('note_sixt6');
	private function get_NOTE_SIXT7_R() return justReleased('note_sixt7');
	private function get_NOTE_SIXT8_R() return justReleased('note_sixt8');
	private function get_NOTE_SIXT9_R() return justReleased('note_sixt9');
	private function get_NOTE_SIXT10_R() return justReleased('note_sixt10');
	private function get_NOTE_SIXT11_R() return justReleased('note_sixt11');
	private function get_NOTE_SIXT12_R() return justReleased('note_sixt12');
	private function get_NOTE_SIXT13_R() return justReleased('note_sixt13');
	private function get_NOTE_SIXT14_R() return justReleased('note_sixt14');
	private function get_NOTE_SIXT15_R() return justReleased('note_sixt15');
	private function get_NOTE_SIXT16_R() return justReleased('note_sixt16');

	private function get_NOTE_SEVT1_R() return justReleased('note_sevt1');
	private function get_NOTE_SEVT2_R() return justReleased('note_sevt2');
	private function get_NOTE_SEVT3_R() return justReleased('note_sevt3');
	private function get_NOTE_SEVT4_R() return justReleased('note_sevt4');
	private function get_NOTE_SEVT5_R() return justReleased('note_sevt5');
	private function get_NOTE_SEVT6_R() return justReleased('note_sevt6');
	private function get_NOTE_SEVT7_R() return justReleased('note_sevt7');
	private function get_NOTE_SEVT8_R() return justReleased('note_sevt8');
	private function get_NOTE_SEVT9_R() return justReleased('note_sevt9');
	private function get_NOTE_SEVT10_R() return justReleased('note_sevt10');
	private function get_NOTE_SEVT11_R() return justReleased('note_sevt11');
	private function get_NOTE_SEVT12_R() return justReleased('note_sevt12');
	private function get_NOTE_SEVT13_R() return justReleased('note_sevt13');
	private function get_NOTE_SEVT14_R() return justReleased('note_sevt14');
	private function get_NOTE_SEVT15_R() return justReleased('note_sevt15');
	private function get_NOTE_SEVT16_R() return justReleased('note_sevt16');
	private function get_NOTE_SEVT17_R() return justReleased('note_sevt17');

	private function get_NOTE_ATE1_R() return justReleased('note_ate1');
	private function get_NOTE_ATE2_R() return justReleased('note_ate2');
	private function get_NOTE_ATE3_R() return justReleased('note_ate3');
	private function get_NOTE_ATE4_R() return justReleased('note_ate4');
	private function get_NOTE_ATE5_R() return justReleased('note_ate5');
	private function get_NOTE_ATE6_R() return justReleased('note_ate6');
	private function get_NOTE_ATE7_R() return justReleased('note_ate7');
	private function get_NOTE_ATE8_R() return justReleased('note_ate8');
	private function get_NOTE_ATE9_R() return justReleased('note_ate9');
	private function get_NOTE_ATE10_R() return justReleased('note_ate10');
	private function get_NOTE_ATE11_R() return justReleased('note_ate11');
	private function get_NOTE_ATE12_R() return justReleased('note_ate12');
	private function get_NOTE_ATE13_R() return justReleased('note_ate13');
	private function get_NOTE_ATE14_R() return justReleased('note_ate14');
	private function get_NOTE_ATE15_R() return justReleased('note_ate15');
	private function get_NOTE_ATE16_R() return justReleased('note_ate16');
	private function get_NOTE_ATE17_R() return justReleased('note_ate17');
	private function get_NOTE_ATE18_R() return justReleased('note_ate18');



	// Pressed buttons (others)
	public var ACCEPT(get, never):Bool;
	public var FAVORITE(get, never):Bool;
	public var BAR_LEFT(get, never):Bool;
	public var BAR_RIGHT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;
	public var DODGE(get, never):Bool;
	public var VOLUME_MUTE(get, never):Bool;
	public var VOLUME_UP(get, never):Bool;
	public var VOLUME_DOWN(get, never):Bool;
	public var DEBUG_1(get, never):Bool;
	public var DEBUG_2(get, never):Bool;
	public var DEBUG_3(get, never):Bool;
	public var FULLSCREEN(get, never):Bool;
	public var SCREENSHOT(get, never):Bool;
	public var CONSOLE(get, never):Bool;
	public var TRACEVIEWER(get, never):Bool;
	public var SIDEBAR(get, never):Bool;
	private function get_ACCEPT() return justPressed('accept');
	private function get_FAVORITE() return justPressed('favorite');
	private function get_BAR_LEFT() return justPressed('bar_left');
	private function get_BAR_RIGHT() return justPressed('bar_right');
	private function get_BACK() return justPressed('back');
	private function get_PAUSE() return justPressed('pause');
	private function get_RESET() return justPressed('reset');
	private function get_DODGE() return justPressed('dodge');
	private function get_VOLUME_MUTE() return justPressed('volume_mute');
	private function get_VOLUME_UP() return justPressed('volume_up');
	private function get_VOLUME_DOWN() return justPressed('volume_down');
	private function get_DEBUG_1() return justPressed('debug_1');
	private function get_DEBUG_2() return justPressed('debug_2');
	private function get_DEBUG_3() return justPressed('debug_3');
	private function get_FULLSCREEN() return justPressed('fullscreen');
	private function get_SCREENSHOT() return justPressed('screenshot');
	private function get_CONSOLE() return justPressed('console');
	private function get_TRACEVIEWER() return justPressed('traceviewer');
	private function get_SIDEBAR() return justPressed('sidebar');

	//Gamepad & Keyboard stuff
	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public function justPressed(key:String)
	{
		if (MusicBeatState.revokeControls)
			return false;

		var result:Bool = (FlxG.keys.anyJustPressed(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result || _myGamepadJustPressed(gamepadBinds[key]) == true;
	}

	public function pressed(key:String)
	{
		if (MusicBeatState.revokeControls)
			return false;

		var result:Bool = (FlxG.keys.anyPressed(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result || _myGamepadPressed(gamepadBinds[key]) == true;
	}

	public function justReleased(key:String)
	{
		if (MusicBeatState.revokeControls)
			return false;

		var result:Bool = (FlxG.keys.anyJustReleased(keyboardBinds[key]) == true);
		if(result) controllerMode = false;

		return result || _myGamepadJustReleased(gamepadBinds[key]) == true;
	}

	public var controllerMode:Bool = false;
	private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (MusicBeatState.revokeControls)
			return false;

		if(keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}
	private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (MusicBeatState.revokeControls)
			return false;

		if(keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}
	private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
	{
		if (MusicBeatState.revokeControls)
			return false;

		if(keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustReleased(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}
		return false;
	}

	@:noCompletion
	private function get_requestedInstance():Dynamic
	{
		if (isInSubstate)
			return MusicBeatSubstate.instance;
		else
			return MusicBeatState.getState();
	}

	// IGNORE THESE
	public static var instance:Controls;
	public var isInSubstate:Bool = false; // don't worry about this it becomes true and false on it's own in MusicBeatSubstate
	public var requestedInstance(get, default):Dynamic; // is set to MusicBeatState or MusicBeatSubstate when the constructor is called
	public function new()
	{
		keyboardBinds = if (!MusicBeatState.revokeControls) ClientPrefs.keyBinds else [];
		gamepadBinds = if (!MusicBeatState.revokeControls) ClientPrefs.gamepadBinds else [];
	}
}
