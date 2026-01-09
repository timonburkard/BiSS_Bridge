###################################################################################################
#  Copyright (c) 2025 by Oliver Bründler
###################################################################################################

###################################################################################################
# IP Packager Configuraton
###################################################################################################

set root_dir [file normalize [file join [file dirname [info script]] ".."]];    # IPI root directory.

###################################################################################################
# Import IP Packager Package (including Xilinx Help infrastructure)
###################################################################################################

# pkg_path must point to the app directory (folder which contains the "xtools" directory).
set pkg_path                            $root_dir/scripts;
lappend auto_path                       [file join $pkg_path "xtools"]
::tclapp::support::appinit::load_app    $pkg_path "::xtools::ip_packager" "ip_packager"
::rdi::set_help_config                  -expose_namespace "ip_packager"

###################################################################################################
# Create Package Project
###################################################################################################

ip_packager::create_package_project         -prj_name           "packager_prj" \
                                            -root_dir           $root_dir \
                                            -top_file           "hdl/biss_bridge_top.vhd" \
                                            -library            "prj_lib" \
                                            -part               "xc7z020iclg400-1L"

###################################################################################################
# Identification
###################################################################################################

ip_packager::set_identification             -vendor             "FHNW" \
                                            -name               "biss_driver" \
                                            -library            "User" \
                                            -version            1.0 \
                                            -display_name       "BiSS Driver" \
                                            -display_vendor     "FHNW"

###################################################################################################
# Add Source Files
###################################################################################################
ip_packager::add_design_sources	            -files              [list \
                                                                   "hdl/biss_bridge_pkg.vhd" \
                                                                   "hdl/control.vhd" \
                                                                   "hdl/data_checker.vhd" \
                                                                   "hdl/data_provider.vhd" \
                                                                   "hdl/data_reader.vhd" \
																] \
											-library            "prj_lib"

###################################################################################################
# Customization Paramenters
###################################################################################################
ip_packager::set_param_config	            -param_name         "DATA_WIDTH"
ip_packager::set_param_config	            -param_name         "CRC_WIDTH"
ip_packager::set_param_config	            -param_name         "PULSE_FREQ_HZ"

ip_packager::add_axis_interface             -interface_name     "m_axis"
ip_packager::add_clock_interface            -interface_name     "clk"         -freq_hz 50000000
ip_packager::add_clock_interface            -interface_name     "m_axis_aclk" -freq_hz 50000000
ip_packager::associate_interface_clock      -interface_name     "m_axis"      -clock "m_axis_aclk"

###################################################################################################
# Customization GUI
###################################################################################################
ip_packager::gui_set_parent                 "root"

ip_packager::gui_add_page                   -page_name          "General Configuration" \
                                            -display_name       "General Configuration"

ip_packager::gui_add_param                  -param_name "DATA_WIDTH" -display_name "Number of Data Bits:"
ip_packager::gui_add_param                  -param_name "CRC_WIDTH" -display_name "Number of CRC Bits:"
ip_packager::gui_add_param                  -param_name "PULSE_FREQ_HZ" -display_name "Sampling frequency:"

# grouping works as expected
#ip_packager::gui_set_parent     "General Configuration"
#ip_packager::gui_add_group                  -group_name "LED0"        -display_name "LED 0"
#ip_packager::gui_add_param                  -param_name "period_led0" -display_name "Blink pattern length"
#ip_packager::gui_add_param                  -param_name "ontime_led0" -display_name "On time at start of pattern"
#
# grouping does not work here!
#ip_packager::gui_set_parent     "General Configuration"
#ip_packager::gui_add_group                  -group_name "LED1"        -display_name "LED 1"
#ip_packager::gui_add_param                  -param_name "period_led1" -display_name "Blink pattern length"
#ip_packager::gui_add_param                  -param_name "ontime_led1" -display_name "On time at start of pattern"
#
#ip_packager::gui_set_parent     "General Configuration"
#ip_packager::gui_add_group                  -group_name "LED2"        -display_name "LED 2"
#ip_packager::gui_add_param                  -param_name "period_led2" -display_name "Blink pattern length"
#ip_packager::gui_add_param                  -param_name "ontime_led2" -display_name "On time at start of pattern"

###################################################################################################
# Optional Ports
###################################################################################################
#ip_packager::set_port_enablement            -port_name "*_1" -dependency "\$number_of_led > 1"
#ip_packager::set_port_enablement            -port_name "*_2" -dependency "\$number_of_led > 2"

###################################################################################################
# Review and Package
###################################################################################################
ip_packager::synth_package_project
ip_packager::save_package_project
ip_packager::close_package_project          -delete             "true"




