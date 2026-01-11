# BiSS Bridge 🌉

Project 2 of CAS Microelectronics Digital HS25 at FHNW

This project is used to read out a BiSS sensor (e.g. iC-MU 150) using a ZYBO Z7 board.
A custom IP Package for BiSS can also be found under `4_vivado/ip`

## Project team

- Matthias Schär
- Timon Burkard

# BiSS IP Package


## Configuration
The package found under `4_vivado/ip/biss_driver` can be configured in several ways.

- **Driver Clock Frequency [Hz]**: Set this to the clock provided to the driver on the `clk` and `m_axis_aclk` pins.
- **Number of Data Bits**: The number of bits output by the BiSS sensor. This must match the sensor's configuration!
- **Sampling frequency [Hz]**: This setting is used to determine how many samples are retrieved from the sensor per second.
- **BiSS Clock Frequency [Hz]**: Set the BiSS MA signal clock frequency. Check sensor datasheet for maximum allowed clock. Depending on your setup, the clock might need to be lowered, e.g. if your signal has suboptimal integrity.

## Use as is 👌
In order to use the BiSS package as is, do the following:
- Copy the content of `4_vivado/ip` into your project
- Add the location in your project as IP repository
- Voilà - you can add the block `BiSS_Driver` to your BD

## Repackaging 🛠️
If you feel like extending the BiSS Driver, you may do so by executing these steps:
- Optional: Customise RTL sources
- Optional: Reflect changes in `4_vivado/ip/biss_driver/scripts/package.tcl`
- Open a new vivado instance
- TCL Console: Navigate to the folder of your `package.tcl` script
- Run `source package.tcl` script
- If everything goes well, vivado flickers around for a bit, shows a status bar and closes the project after some time. If the project is not closed, check the tcl console output for debugging.

💡 Note: In order to be able to use the xtools IP Packager, you must recursively check out the xtools repo under `4_vivado/ip/biss_driver/scripts/`!

Follow the chapter "Update IP Package" to have the changes reflected in your project.

## Update IP Package 🔄
After repackaging or updating the IP Core, you have to manually upgrade your package in vivado. In order to do so, follow these instructions:

- Navigate to settings->Project Settings->IP->Repository, click "Refresh All"
- Open the Reports view and click "rerun"
- Select "BiSS Driver" and click "upgrade ip"
