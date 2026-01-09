# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set General_Configuration [ipgui::add_page $IPINST -name "General Configuration"]
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${General_Configuration}
  ipgui::add_param $IPINST -name "CRC_WIDTH" -parent ${General_Configuration}
  ipgui::add_param $IPINST -name "PULSE_FREQ_HZ" -parent ${General_Configuration}


}

proc update_PARAM_VALUE.CRC_WIDTH { PARAM_VALUE.CRC_WIDTH } {
	# Procedure called to update CRC_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CRC_WIDTH { PARAM_VALUE.CRC_WIDTH } {
	# Procedure called to validate CRC_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.PULSE_FREQ_HZ { PARAM_VALUE.PULSE_FREQ_HZ } {
	# Procedure called to update PULSE_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.PULSE_FREQ_HZ { PARAM_VALUE.PULSE_FREQ_HZ } {
	# Procedure called to validate PULSE_FREQ_HZ
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.CRC_WIDTH { MODELPARAM_VALUE.CRC_WIDTH PARAM_VALUE.CRC_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CRC_WIDTH}] ${MODELPARAM_VALUE.CRC_WIDTH}
}

proc update_MODELPARAM_VALUE.PULSE_FREQ_HZ { MODELPARAM_VALUE.PULSE_FREQ_HZ PARAM_VALUE.PULSE_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.PULSE_FREQ_HZ}] ${MODELPARAM_VALUE.PULSE_FREQ_HZ}
}

