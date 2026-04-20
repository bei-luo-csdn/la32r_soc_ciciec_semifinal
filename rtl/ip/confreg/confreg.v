/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/
`define CONFREG_INT_ADDR    16'hf000 //1f20_f000
`define TIMER_ADDR          16'hf100 //1f20_f100
`define DIGITAL_ADDR        16'hf200 //1f20_f200
`define LED_ADDR            16'hf300 //1f20_f300
`define SWITCH_ADDR         16'hf400 //1f20_f400
`define SIMU_FLAG_ADDR      16'hf500 //1f20_f500 

module confreg #(
    parameter   SIMULATION=1'b0
)
(
    input           aclk,
    input           aresetn,

    input           cpu_clk,
    input           cpu_resetn,

    input  [4 :0]   s_awid,
    input  [31:0]   s_awaddr,
    input  [7 :0]   s_awlen,
    input  [2 :0]   s_awsize,
    input  [1 :0]   s_awburst,
    input           s_awlock,
    input  [3 :0]   s_awcache,
    input  [2 :0]   s_awprot,
    input           s_awvalid,
    output          s_awready,
    input  [4 :0]   s_wid,
    input  [31:0]   s_wdata,
    input  [3 :0]   s_wstrb,
    input           s_wlast,
    input           s_wvalid,
    output reg      s_wready,
    output [4 :0]   s_bid,
    output [1 :0]   s_bresp,
    output reg      s_bvalid,
    input           s_bready,
    input  [4 :0]   s_arid,
    input  [31:0]   s_araddr,
    input  [7 :0]   s_arlen,
    input  [2 :0]   s_arsize,
    input  [1 :0]   s_arburst,
    input           s_arlock,
    input  [3 :0]   s_arcache,
    input  [2 :0]   s_arprot,
    input           s_arvalid,
    output          s_arready,
    output [4 :0]   s_rid,
    output reg [31:0]   s_rdata,
    output [1 :0]   s_rresp,
    output reg      s_rlast,
    output reg      s_rvalid,
    input           s_rready,

    output     [15:0] led,
    output      [7:0] dpy0,
    output      [7:0] dpy1,
    input      [31:0] switch,
    input      [3 :0] touch_btn,
    input             dma_finish,
    input             fft_finish,
    output  [31:0]    confreg_int
);

wire [3:0] touch_btn_data;//按键中断信号，上升沿触发
reg  [31:0] led_data;
wire [31:0] switch_data;
reg  [31:0] simu_flag;

reg [31:0] confreg_int_en,confreg_int_edge,confreg_int_pol,confreg_int_clr,confreg_int_set;
wire [31:0] confreg_int_state;

reg [31:0] sys_timer,sys_timer_cmp;
reg sys_timer_en;
reg timer_int;//定时器中断信号，高电平触发

reg [31:0] digital_ctrl;
reg [31:0] digital_data;


reg busy,write,R_or_W;

wire ar_enter = s_arvalid & s_arready;
wire r_retire = s_rvalid & s_rready & s_rlast;
wire aw_enter = s_awvalid & s_awready;
wire w_enter  = s_wvalid & s_wready & s_wlast;
wire b_retire = s_bvalid & s_bready;

assign s_arready = ~busy & (!R_or_W| !s_awvalid);
assign s_awready = ~busy & ( R_or_W| !s_arvalid);

always@(posedge aclk)
    if(~aresetn) busy <= 1'b0;
    else if(ar_enter|aw_enter) busy <= 1'b1;
    else if(r_retire|b_retire) busy <= 1'b0;

reg [4 :0] buf_id;
reg [31:0] buf_addr;
reg [7 :0] buf_len;
reg [2 :0] buf_size;
reg [1 :0] buf_burst;
reg        buf_lock;
reg [3 :0] buf_cache;
reg [2 :0] buf_prot;

always@(posedge aclk)
    if(~aresetn) begin
        R_or_W      <= 1'b0;
        buf_id      <= 'b0;
        buf_addr    <= 'b0;
        buf_len     <= 'b0;
        buf_size    <= 'b0;
        buf_burst   <= 'b0;
        buf_lock    <= 'b0;
        buf_cache   <= 'b0;
        buf_prot    <= 'b0;
    end
    else
    if(ar_enter | aw_enter) begin
        R_or_W      <= ar_enter;
        buf_id      <= ar_enter ? s_arid   : s_awid   ;
        buf_addr    <= ar_enter ? s_araddr : s_awaddr ;
        buf_len     <= ar_enter ? s_arlen  : s_awlen  ;
        buf_size    <= ar_enter ? s_arsize : s_awsize ;
        buf_burst   <= ar_enter ? s_arburst: s_awburst;
        buf_lock    <= ar_enter ? s_arlock : s_awlock ;
        buf_cache   <= ar_enter ? s_arcache: s_awcache;
        buf_prot    <= ar_enter ? s_arprot : s_awprot ;
    end

always@(posedge aclk)
    if(~aresetn) write <= 1'b0;
    else if(aw_enter) write <= 1'b1;
    else if(ar_enter)  write <= 1'b0;

always@(posedge aclk)
    if(~aresetn) s_wready <= 1'b0;
    else if(aw_enter) s_wready <= 1'b1;
    else if(w_enter & s_wlast) s_wready <= 1'b0;

wire [31:0] rdata_d =   buf_addr[15:0] == (`CONFREG_INT_ADDR + 16'h0)     ? confreg_int_en        : 
                        buf_addr[15:0] == (`CONFREG_INT_ADDR + 16'h4)     ? confreg_int_edge      : 
                        buf_addr[15:0] == (`CONFREG_INT_ADDR + 16'h8)     ? confreg_int_pol       : 
                        buf_addr[15:0] == (`CONFREG_INT_ADDR + 16'hc)     ? confreg_int_clr       : 
                        buf_addr[15:0] == (`CONFREG_INT_ADDR + 16'h10)    ? confreg_int_set       : 
                        buf_addr[15:0] == (`CONFREG_INT_ADDR + 16'h14)    ? confreg_int_state     : 
                        buf_addr[15:0] == (`TIMER_ADDR + 16'h0)           ? sys_timer             : 
                        buf_addr[15:0] == (`TIMER_ADDR + 16'h4)           ? sys_timer_cmp         :
                        buf_addr[15:0] == (`TIMER_ADDR + 16'h8)           ? sys_timer_en          :
                        buf_addr[15:0] == (`DIGITAL_ADDR + 16'h0)         ? digital_ctrl          :
                        buf_addr[15:0] == (`DIGITAL_ADDR + 16'h4)         ? digital_data          :
                        buf_addr[15:0] == `LED_ADDR                       ? led_data              :
                        buf_addr[15:0] == `SWITCH_ADDR                    ? switch_data           :
                        buf_addr[15:0] == `SIMU_FLAG_ADDR                 ? simu_flag             :
                        32'd0;

always@(posedge aclk)
    if(~aresetn) begin
        s_rdata  <= 'b0;
        s_rvalid <= 1'b0;
        s_rlast  <= 1'b0;
    end
    else if(busy & !write & !r_retire)
    begin
        s_rdata <= rdata_d;
        s_rvalid <= 1'b1;
        s_rlast <= 1'b1; 
    end
    else if(r_retire)
    begin
        s_rvalid <= 1'b0;
    end

always@(posedge aclk)   
    if(~aresetn) s_bvalid <= 1'b0;
    else if(w_enter) s_bvalid <= 1'b1;
    else if(b_retire) s_bvalid <= 1'b0;

assign s_rid   = buf_id;
assign s_bid   = buf_id;
assign s_bresp = 2'b0;
assign s_rresp = 2'b0;


//-------------------------------{touch_btn}begin----------------------------//
assign touch_btn_data = touch_btn;

    // genvar i;
    // generate for(i=0;i<4;i=i+1) begin: generate_btn_debounce
    //     key_debounce u_key_debounce(
    //         .sys_clk(aclk),
    //         .key(touch_btn[i]),
    //         .key_out(touch_btn_data[i])
    //     );
    // end
    // endgenerate





//--------------------------------{touch_btn}end-----------------------------//

//-------------------------------{timer}begin----------------------------//

wire write_timer_cmp = w_enter & (buf_addr[15:0]==`TIMER_ADDR+16'h4);
wire write_timer_en  = w_enter & (buf_addr[15:0]==`TIMER_ADDR+16'h8);

always @(posedge aclk) begin
    if(!aresetn) begin
        sys_timer_cmp <= 32'h0;
    end
    else if (write_timer_cmp) begin
        sys_timer_cmp <= s_wdata;
    end
end

always @(posedge aclk) begin
    if(!aresetn) begin
        sys_timer_en <= 1'b0;
    end
    else if (write_timer_en) begin
        sys_timer_en <= s_wdata[0];
    end
end

always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        sys_timer <= 32'h0;
        timer_int <= 1'b0;
    end
    else if (sys_timer_en) begin
        if (sys_timer >= sys_timer_cmp - 1) begin
            sys_timer <= 32'h0;
            timer_int <= 1'b1;
        end else begin
            sys_timer <= sys_timer + 1'b1;
        end
    end
    else begin
        sys_timer <= 32'h0;
        timer_int <= 1'b0;
    end
end
//--------------------------------{timer}end-----------------------------//

//--------------------------------{led}begin-----------------------------//
//led display
//led_data[31:0]
wire write_led = w_enter & (buf_addr[15:0]==`LED_ADDR);
assign led = led_data[15:0];
always @(posedge aclk)
begin
    if(!aresetn)
    begin
        led_data <= 32'h0;
    end
    else if(write_led)
    begin
        led_data <= s_wdata[31:0];
    end
end
//---------------------------------{led}end------------------------------//

//-------------------------------{switch}begin---------------------------//
//switch data
//switch_data[31:0]
assign switch_data = switch;
//--------------------------------{switch}end----------------------------//


//---------------------------{digital number}begin-----------------------//
wire write_digital_ctrl   = w_enter & (buf_addr[15:0]==`DIGITAL_ADDR + 16'h0);
wire write_digital_data   = w_enter & (buf_addr[15:0]==`DIGITAL_ADDR + 16'h4);

always @(posedge aclk) begin
    if(!aresetn) begin
        digital_ctrl <= 32'd0;
    end
    else if (write_digital_ctrl) begin
        digital_ctrl <= s_wdata;
    end
end

always @(posedge aclk) begin
    if(!aresetn) begin
        digital_data <= 32'd0;
    end
    else if (write_digital_data) begin
        digital_data <= s_wdata;
    end
end

wire [31:0] digital_data_in = digital_data;
digitaltube_controller  u_digitaltube_controller (
    .control_reg             ( digital_ctrl   ),
    .clk                     ( aclk           ),
    .rst_n                   ( aresetn         ),

    .dpy0                    ( dpy0          ),
    .dpy1                    ( dpy1          ),

    .data_reg                ( digital_data_in      )
);

//----------------------------{digital number}end------------------------//

//--------------------------{simulation flag}begin-----------------------//
always @(posedge aclk)
begin
    if(!aresetn) begin
        simu_flag <= {32{SIMULATION}};
    end
    else begin
        simu_flag <= {32{SIMULATION}};
    end
end
//---------------------------{simulation flag}end------------------------//

//-------------------------------{int_ctrl}begin----------------------------//
//add your code
wire [31:0] write_confreg_int_en  = w_enter & (buf_addr[15:0]==`CONFREG_INT_ADDR + 16'h0);
wire [31:0] write_confreg_int_edge = w_enter & (buf_addr[15:0]==`CONFREG_INT_ADDR + 16'h4);
wire [31:0] write_confreg_int_pol  = w_enter & (buf_addr[15:0]==`CONFREG_INT_ADDR + 16'h8);
wire [31:0] write_confreg_int_clr  = w_enter & (buf_addr[15:0]==`CONFREG_INT_ADDR + 16'hC);
wire [31:0] write_confreg_int_state = w_enter & (buf_addr[15:0]==`CONFREG_INT_ADDR + 16'h10);

always @(posedge aclk) begin
    if(!aresetn) begin
        confreg_int_en <= 32'd0;
        confreg_int_edge <= 32'd0;
        confreg_int_pol <= 32'd0;
    end
    else begin
         if (write_confreg_int_en) begin
        confreg_int_en <= s_wdata;
         end
         if (write_confreg_int_edge) begin
        confreg_int_edge <= s_wdata;
         end
         if (write_confreg_int_pol) begin
        confreg_int_pol <= s_wdata;
         end
    end
end
// 中断控制器
my_int_ctrl #(.N(32)) u_my_int_ctrl (
    .sys_clk       ( aclk          ),
    .sys_resetn    ( aresetn       ),
    .cpu_clk       ( cpu_clk       ),
    .cpu_resetn    ( cpu_resetn    ),

    .int_en        (confreg_int_en[31:0]), // 这里是中断使能
    .int_edge      (32'h0), // 这里是中断边沿触发
    .int_pol       (32'h0), // 这里是中断极性
    .int_in        ({ 27'd0, touch_btn_data[3:0], timer_int}),// 4'h0本来是touch_btn_data，但目前只支持电平触发
    .int_state     (confreg_int_state), // 中断状态输出
    .int_out       (confreg_int) // 中断输出
);

//--------------------------------{int_ctrl}end-----------------------------//

endmodule

// 实现一个bit中断处理
// 输出中断状态
module my_int_ctrl_one(
    input clk,
    input resetn,
    
    input int_en, // 中断有效
    input int_edge, // 中断边沿触发
    input int_pol, // 中断极性(1:高电平/上升沿触发)
    input int_in,
    input int_clr,
    input int_set,
    output int_state,// 为1表示对应位的中断有效
    output int_out
);
    // 同步 int_in 到 clk 域
    reg int_in_sync1, int_in_sync2;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            int_in_sync1 <= 1'b0;
            int_in_sync2 <= 1'b0;
        end else begin
            int_in_sync1 <= int_in;
            int_in_sync2 <= int_in_sync1;
        end
    end
    wire int_in_sync = int_in_sync2;

    // 边沿检测（寄存器上一拍）
    reg int_in_r;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) int_in_r <= 1'b0;
        else int_in_r <= int_in_sync;
    end
    wire rise = int_in_sync && !int_in_r;
    wire fall = !int_in_sync && int_in_r;
    wire edge_detected = (int_pol ? rise : fall);

    // 电平触发条件
    wire level_active = (int_pol ? int_in_sync : !int_in_sync);

    // 中断请求锁存
    reg int_req;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            int_req <= 1'b0;
        end else begin
            if (int_set)               // 软件置位优先
                int_req <= 1'b1;
            else if (int_clr)          // 软件清除
                int_req <= 1'b0;
            else if (int_edge) begin
                if (edge_detected)
                    int_req <= 1'b1;   // 边沿触发锁存
            end else begin
                int_req <= level_active; // 电平触发直接跟随
            end
        end
    end

    assign int_state = int_req;
    assign int_out   = int_req & int_en;
endmodule
//中断控制器
module my_int_ctrl #(parameter N=32)(
    input sys_clk,
    input sys_resetn,
    input cpu_clk,
    input cpu_resetn,// 需要cdc处理，因为中断在sys时钟域产生，但需要传输到cpu

    input [N-1:0] int_en,
    input [N-1:0] int_edge, // 中断边沿触发
    input [N-1:0] int_pol, // 中断极性
    input [N-1:0] int_in,
    input [N-1:0] int_clr, // 中断清除
    input [N-1:0] int_set,          // 新增
    output [N-1:0] int_state,
    output [N-1:0] int_out,         // 新增：32位中断输出
    output int_out_or_sync          // 新增：同步后的单比特中断
);
    genvar i;
    generate for(i=0;i<N;i=i+1) begin: int_ctrl
        my_int_ctrl_one u_int_ctrl_one (
            .clk      (sys_clk),
            .resetn   (sys_resetn),
            .int_en   (int_en[i]),
            .int_edge (int_edge[i]),
            .int_pol  (int_pol[i]),
            .int_in   (int_in[i]),
            .int_clr  (int_clr[i]),
            .int_set  (int_set[i]),
            .int_state(int_state[i]),
            .int_out  (int_out[i])
        );
    end
    endgenerate

    // 或运算后同步到 cpu 时钟域
    wire int_out_or = |int_out;
    reg [1:0] int_out_or_sync_r;
    always @(posedge cpu_clk or negedge cpu_resetn) begin
        if (!cpu_resetn)
            int_out_or_sync_r <= 2'b0;
        else
            int_out_or_sync_r <= {int_out_or_sync_r[0], int_out_or};
    end
    assign int_out_or_sync = int_out_or_sync_r[1];
endmodule
