module image_ctrl(
	input 			CLK,
	input 			RST,
	output 			CHNL_RX_CLK,
	input 			CHNL_RX,
	output 			CHNL_RX_ACK,
	input 			CHNL_RX_LAST,
	input 	[31:0] 	CHNL_RX_LEN,		//像素的个数 计数单位为DW
	input 	[30:0] 	CHNL_RX_OFF,
	input 	[63:0]	CHNL_RX_DATA,
	input 			CHNL_RX_DATA_VALID,
	output 			CHNL_RX_DATA_REN,
	input			CONF_END,			//配置结束信号
	input 	[31:0] 	WIDTH,				//配置的宽度 计数单位为DW
	input 	[31:0] 	HEIGHT,				//配置的长度 计数单位为DW	
	output 			FRAME_END,			//帧结束信号
	output 			WR_EN,
	output 	[127:0] WR_DATA
);
	parameter	BURST_LEN = 'd64;
	
	reg		[31:0]		len_reg_32bit;     	// 寄存CHNL_RX_LEN --- DW的数量
	reg		[31:0]		len_reg_64bit;		// 寄存CHNL_RX_LEN >>1 ---CHNL_RX_DATA的数量
	reg					frame_valid;		// 帧有效信号，代表发送过来的是一帧像素
	reg					CHNL_RX_ACK_r;
	reg					CHNL_RX_r1;
	reg					CHNL_RX_r2;
	wire				fifo_almost_full;	//fifo要满的信号
	reg		[31:0]		rx_cnt;				//计算PCIE已经传输了几个DATA过来
	wire				fifo_wr_en;
	wire	[31:0]		fifo_wr_data;
	reg					fifo_rd_en;
	reg		[10:0]		rd_cnt;				//来计算已经从fifo读出多少个128bit数
	reg					frame_end;
	wire 	[10:0]		rd_data_count;		//用来拉高fifo_rd_en
	wire	[12:0]		wr_data_count;		//用来控制fifo_almost_full
	wire	[35:0]		pixel_per_one_frame;
	reg					CHNL_RX_DATA_REN_r;
	
	assign	FRAME_END = frame_end;
	assign CHNL_RX_CLK = CLK;
	assign	fifo_wr_en = (frame_valid & CHNL_RX_DATA_VALID & CHNL_RX_DATA_REN)?1'b1:1'b0;
	assign	fifo_wr_data = {CHNL_RX_DATA[23:19],CHNL_RX_DATA[15:10],CHNL_RX_DATA[7:3],CHNL_RX_DATA[55:51],CHNL_RX_DATA[47:42],CHNL_RX_DATA[39:35]};
	assign	fifo_almost_full = (wr_data_count >= 'd4000)?1'b1:1'b0;
	assign  CHNL_RX_ACK = CHNL_RX_ACK_r;
	assign	CHNL_RX_DATA_REN = CHNL_RX_DATA_REN_r;
	assign	WR_EN = fifo_rd_en;

	mult_us18x18 mult_us18x18_inst (
  .CLK(CLK),  // input wire CLK
  .A(WIDTH[17:0]),      // input wire [17 : 0] A
  .B(HEIGHT[17:0]),      // input wire [17 : 0] B
  .P(pixel_per_one_frame)      // output wire [35 : 0] P
);
//CHNL_RX_r1 CHNL_RX_r2
	always@(posedge CLK)begin
		if(RST == 1'b1)begin
			CHNL_RX_r1 <= 1'b0;
			CHNL_RX_r2 <= 1'b0;
		end
		else begin
			CHNL_RX_r1 <= CHNL_RX;
			CHNL_RX_r2 <= CHNL_RX_r1;
		end
	end
	
//len_reg_32bit
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			len_reg_32bit <= 'd0;
		else if(CHNL_RX == 1'b1 & CHNL_RX_r1 == 1'b0)
			len_reg_32bit <= CHNL_RX_LEN;
	end
//len_reg_64bit
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			len_reg_64bit <= 'd0;
		else if(CHNL_RX == 1'b1 & CHNL_RX_r1 == 1'b0)
			len_reg_64bit <= CHNL_RX_LEN >> 1;
	end
//frame_valid
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			frame_valid <= 1'b0;
		else if(CHNL_RX_r1 == 1'b1 & CHNL_RX == 1'b0)
			frame_valid <= 1'b0;			
		else if(CHNL_RX_r1 == 1'b1 & CHNL_RX_r2 == 1'b0 & len_reg_32bit == pixel_per_one_frame)
			frame_valid <= 1'b1;
	end
//CNHL_RX_ACK_r
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			CHNL_RX_ACK_r <= 1'b0;
		else if(CHNL_RX_r1 == 1'b1 & CHNL_RX == 1'b0)
			CHNL_RX_ACK_r <= 1'b0;
		else if(CHNL_RX == 1'b1 & CHNL_RX_r1 == 1'b0)
			CHNL_RX_ACK_r <= 1'b1;			
	end
//CHNL_RX_DATA_REN
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			CHNL_RX_DATA_REN_r <= 1'b0;
		else if(rx_cnt[1:0] == 'd3 & fifo_almost_full == 1'b1)
			CHNL_RX_DATA_REN_r <= 1'b0;
		else if(CHNL_RX_DATA_VALID == 1'b1 & CHNL_RX_DATA_REN_r == 1'b1 & rx_cnt == len_reg_64bit -1)
			CHNL_RX_DATA_REN_r <= 1'b0;
		else if(CHNL_RX == 1'b1 & CHNL_RX_r1 == 1'b0)
			CHNL_RX_DATA_REN_r <= 1'b1;	
		else if(CHNL_RX_DATA_REN_r == 1'b0 & CHNL_RX_DATA_VALID == 1'b1 & fifo_almost_full == 1'b0)
			CHNL_RX_DATA_REN_r <= 1'b1;		
	end
//rx_cnt
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			rx_cnt  <= 'd0;
		else if(rx_cnt == (len_reg_64bit -1) & CHNL_RX_DATA_VALID == 1'b1 & CHNL_RX_DATA_REN == 1'b1)
			rx_cnt <= 'd0;
		else if(CHNL_RX_DATA_VALID == 1'b1 & CHNL_RX_DATA_REN == 1'b1)
			rx_cnt <= rx_cnt + 1'b1;
	end
//fifo_rd_en
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			fifo_rd_en <= 1'b0;
		else if(rd_cnt ==( BURST_LEN -1'b1 ) & fifo_rd_en == 1'b1)
			fifo_rd_en <= 1'b0;			
		else if(rd_data_count >= BURST_LEN)
			fifo_rd_en <= 1'b1;
	end
//rd_cnt
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			rd_cnt	<= 'd0;
		else if(rd_cnt ==( BURST_LEN -1'b1 ) & fifo_rd_en == 1'b1)
			rd_cnt <= 1'b0;
		else if(fifo_rd_en == 1'b1)
			rd_cnt <= rd_cnt + 1'b1;
	end
//frame_end
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			frame_end <= 1'b0;
		else if(CHNL_RX_DATA_REN == 1'b1 & CHNL_RX_DATA_VALID == 1'b1 & rx_cnt == (len_reg_64bit - 1))
			frame_end <= 1'b1;
		else 
			frame_end <= 1'b0;
	end
	
	

asfifo_wr32x4096_rd128x1024 your_instance_name (
  .wr_clk(CLK),                // input wire wr_clk
  .rd_clk(CLK),                // input wire rd_clk
  .din(fifo_wr_data),                      // input wire [31 : 0] din
  .wr_en(fifo_wr_en),                  // input wire wr_en
  .rd_en(fifo_rd_en),                  // input wire rd_en
  .dout(WR_DATA),                    // output wire [127 : 0] dout
  .full(),                    // output wire full
  .empty(),                  // output wire empty
  .rd_data_count(rd_data_count),  // output wire [10 : 0] rd_data_count
  .wr_data_count(wr_data_count)  // output wire [12 : 0] wr_data_count
);

wire	[511:0]		probe0;
assign	probe0 = {
	CHNL_RX,
	frame_valid,
	CHNL_RX_DATA,
	CHNL_RX_DATA_VALID,
	CHNL_RX_DATA_REN,
	rx_cnt,
	fifo_almost_full,
	fifo_wr_en,
	WR_EN,
	rd_cnt,
	WR_DATA,
	FRAME_END
};
ila_0 image_ctrl_ila (
	.clk(CLK), // input wire clk


	.probe0(probe0) // input wire [255:0] probe0
);

endmodule