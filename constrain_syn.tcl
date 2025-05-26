set setup_uncertainty 0.2
set hold_uncertainty 0.2

set CLOCK_PERIOD_REFCLK [expr 1000 / 33.0 ]

create_clock -name ref_clk -period ${CLOCK_PERIOD_REFCLK} [get_pins PAD_CLK_IN/XC]

set_clock_uncertainty [expr ${setup_uncertainty}] -setup [get_clocks [all_clocks]]
set_clock_uncertainty [expr ${hold_uncertainty}]  -hold  [get_clocks [all_clocks]]

set_load 10 [all_outputs]
set_input_transition 1.0 [all_inputs]

set baseram_input_ports  [get_ports "base_ram_*" -filter port_direction=~*in*]
set baseram_output_ports [get_ports "base_ram_*" -filter port_direction=~*out*]

set extram_input_ports  [get_ports "ext_ram_*" -filter port_direction=~*in*]
set extram_output_ports [get_ports "ext_ram_*" -filter port_direction=~*out*]

set_input_delay -clock ref_clk -max [expr 10  + 0.5 ] $baseram_input_ports
set_input_delay -clock ref_clk -min [expr 2.5 + 0.5 ] $baseram_input_ports

set_input_delay -clock ref_clk -max [expr 10  + 0.5 ] $extram_input_ports
set_input_delay -clock ref_clk -min [expr 2.5 + 0.5 ] $extram_input_ports

set_output_delay -clock ref_clk -max [expr 2  + 0.1 ] $baseram_output_ports
set_output_delay -clock ref_clk -min [expr -1 - 0.1 ] $baseram_output_ports

set_output_delay -clock ref_clk -max [expr 2  + 0.1 ] $extram_output_ports
set_output_delay -clock ref_clk -min [expr -1 - 0.1 ] $extram_output_ports

set FIX_DELAY 0.1

set_input_delay -clock ref_clk ${FIX_DELAY} [get_ports touch_btn[*]]
set_input_delay -clock ref_clk ${FIX_DELAY} [get_ports dip_sw[*]]
set_output_delay -clock ref_clk ${FIX_DELAY} [get_ports leds[*]]
set_output_delay -clock ref_clk ${FIX_DELAY} [get_ports dpy0[*]]
set_output_delay -clock ref_clk ${FIX_DELAY} [get_ports dpy1[*]]
set_input_delay -clock ref_clk ${FIX_DELAY} [get_ports UART_RX]
set_input_delay -clock ref_clk ${FIX_DELAY} [get_ports UART_TX]
set_output_delay -clock ref_clk ${FIX_DELAY} [get_ports UART_RX]
set_output_delay -clock ref_clk ${FIX_DELAY} [get_ports UART_TX]

set_dont_touch_network [get_clocks ref_clk]
