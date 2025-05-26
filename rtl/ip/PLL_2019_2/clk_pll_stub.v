// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Mon May 26 21:11:21 2025
// Host        : LAPTOP-6IH8TGB8 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/spf/Documents/GitHub/la32r_soc_ciciec_semifinal/rtl/ip/PLL_2019_2/clk_pll_stub.v
// Design      : clk_pll
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_pll(cpu_clk, sys_clk, resetn, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="cpu_clk,sys_clk,resetn,locked,clk_in1" */;
  output cpu_clk;
  output sys_clk;
  input resetn;
  output locked;
  input clk_in1;
endmodule
