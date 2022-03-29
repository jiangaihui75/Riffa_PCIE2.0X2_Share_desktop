// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : You kaiyuan	v3eduyky@126.com
// File   : ack_ctrl.v
// wechat :	15921999232
// Create : 2020-02-11 12:30:06
// Revise : 2020-02-15 16:13:10
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------
module ack_ctrl(
	input CLK,
	input RST,
	output CHNL_TX_CLK, 
	output CHNL_TX, 
	input CHNL_TX_ACK, 
	output CHNL_TX_LAST, 
	output [31:0] CHNL_TX_LEN, 
	output [30:0] CHNL_TX_OFF, 
	output [64-1:0] CHNL_TX_DATA, 
	output CHNL_TX_DATA_VALID, 
	input CHNL_TX_DATA_REN,
	input	FRAME_END
	);

reg [7:0] tx_cnt;
reg 		chnl_tx_reg;
reg 		chnl_tx_data_valid_reg;
reg [63:0]	chnl_tx_data_reg;

assign CHNL_TX_CLK = CLK;
assign CHNL_TX = chnl_tx_reg;
assign CHNL_TX_DATA_VALID = chnl_tx_data_valid_reg;
assign CHNL_TX_LAST = 1'b1;
assign CHNL_TX_LEN = 8;
assign CHNL_TX_OFF = 0;
assign CHNL_TX_DATA = chnl_tx_data_reg;

always @(posedge CLK) begin
  if (RST == 1'b1) begin
    chnl_tx_reg <= 1'b0;
  end
  else if(CHNL_TX_DATA_REN == 1'b1 && chnl_tx_data_valid_reg == 1'b1 && tx_cnt == 'd3) begin
  	chnl_tx_reg <= 1'b0;
  end
  else if (FRAME_END == 1'b1) begin
    chnl_tx_reg <= 1'b1;
  end
end

always @(posedge CLK) begin
  if (RST == 1'b1) begin
    chnl_tx_data_valid_reg <= 1'b0;
  end
  else if(CHNL_TX_DATA_REN == 1'b1 && chnl_tx_data_valid_reg == 1'b1 && tx_cnt == 'd3)begin
  	chnl_tx_data_valid_reg <= 1'b0;
  end
  else if (chnl_tx_reg == 1'b1 && CHNL_TX_ACK == 1'b1) begin
    chnl_tx_data_valid_reg <= 1'b1;
  end
end

always @(posedge CLK) begin
  if (RST == 1'b1) begin
    tx_cnt <= 'd0;
  end
  else if (CHNL_TX_DATA_REN == 1'b1 && chnl_tx_data_valid_reg == 1'b1 && tx_cnt == 'd3) begin
    tx_cnt <= 'd0;
  end
  else if(CHNL_TX_DATA_REN == 1'b1 && chnl_tx_data_valid_reg == 1'b1) begin
  	tx_cnt <= tx_cnt + 1'b1;
  end
end


always @(posedge CLK) begin
	chnl_tx_data_reg <= 64'h55555555_55555555;
end





endmodule 