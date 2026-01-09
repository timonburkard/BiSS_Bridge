# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set General_Configuration [ipgui::add_page $IPINST -name "General Configuration"]
  #Adding Group
  set global [ipgui::add_group $IPINST -name "global" -parent ${General_Configuration} -display_name {Global Settings}]
  ipgui::add_param $IPINST -name "CLK_FREQ_HZ" -parent ${global}

  #Adding Group
  set data [ipgui::add_group $IPINST -name "data" -parent ${General_Configuration} -display_name {Data Settings}]
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${data}

  #Adding Group
  set timing [ipgui::add_group $IPINST -name "timing" -parent ${General_Configuration} -display_name {Timing Settings}]
  ipgui::add_param $IPINST -name "SAMPLE_FREQ_HZ" -parent ${timing}
  ipgui::add_param $IPINST -name "BISS_MA_FREQ_HZ" -parent ${timing}



}

proc update_PARAM_VALUE.BISS_MA_FREQ_HZ { PARAM_VALUE.BISS_MA_FREQ_HZ } {
	# Procedure called to update BISS_MA_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BISS_MA_FREQ_HZ { PARAM_VALUE.BISS_MA_FREQ_HZ } {
	# Procedure called to validate BISS_MA_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.CLK_FREQ_HZ { PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to update CLK_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CLK_FREQ_HZ { PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to validate CLK_FREQ_HZ
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.SAMPLE_FREQ_HZ { PARAM_VALUE.SAMPLE_FREQ_HZ } {
	# Procedure called to update SAMPLE_FREQ_HZ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SAMPLE_FREQ_HZ { PARAM_VALUE.SAMPLE_FREQ_HZ } {
	# Procedure called to validate SAMPLE_FREQ_HZ
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.BISS_MA_FREQ_HZ { MODELPARAM_VALUE.BISS_MA_FREQ_HZ PARAM_VALUE.BISS_MA_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BISS_MA_FREQ_HZ}] ${MODELPARAM_VALUE.BISS_MA_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.SAMPLE_FREQ_HZ { MODELPARAM_VALUE.SAMPLE_FREQ_HZ PARAM_VALUE.SAMPLE_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SAMPLE_FREQ_HZ}] ${MODELPARAM_VALUE.SAMPLE_FREQ_HZ}
}

proc update_MODELPARAM_VALUE.CLK_FREQ_HZ { MODELPARAM_VALUE.CLK_FREQ_HZ PARAM_VALUE.CLK_FREQ_HZ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLK_FREQ_HZ}] ${MODELPARAM_VALUE.CLK_FREQ_HZ}
}

