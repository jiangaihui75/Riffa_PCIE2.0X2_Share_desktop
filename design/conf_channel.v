module conf_channel#(
	parameter C_PCI_DATA_WIDTH = 9'd64
)
(
	input 	CLK,
	input 	RST,
	output 	CHNL_RX_CLK, 
	input 	CHNL_RX, 
	output 	CHNL_RX_ACK, 
	input 	CHNL_RX_LAST, 
	input [31:0] CHNL_RX_LEN, 
	input [30:0] CHNL_RX_OFF, 
	input [C_PCI_DATA_WIDTH-1:0] CHNL_RX_DATA, 
	input CHNL_RX_DATA_VALID, 
	output CHNL_RX_DATA_REN,
	
	output CHNL_TX_CLK, 
	output CHNL_TX, 
	input CHNL_TX_ACK, 
	output CHNL_TX_LAST, 
	output [31:0] CHNL_TX_LEN, 
	output [30:0] CHNL_TX_OFF, 
	output [C_PCI_DATA_WIDTH-1:0] CHNL_TX_DATA, 	
	output CHNL_TX_DATA_VALID, 
	input CHNL_TX_DATA_REN,
	output	[31:0]	WIDTH,
	output	[31:0]	HEIGHT,
	output			CONF_END
);
	reg			CHNL_RX_reg;
	reg [31:0] 	len_reg;
	reg	[31:0]	rx_cnt;
	reg 		CHNL_RX_ACK_r;
	reg	[31:0]	width;
	reg	[31:0]	height;
	reg			conf_end;
	reg			CHNL_RX_ACK_reg1;
	reg			height_flag;
	
	assign CHNL_RX_ACK = CHNL_RX_ACK_r;
	assign CHNL_RX_DATA_REN = CHNL_RX_ACK_r;
	assign CHNL_TX_CLK = CLK;
	assign CHNL_RX_CLK = CLK;
	assign WIDTH = width;
	assign HEIGHT = height;
	assign CONF_END = conf_end;
	
	always@(posedge CLK)begin
		CHNL_RX_ACK_reg1 <= CHNL_RX_ACK_r;
	end
	
	always@(posedge CLK)begin
		CHNL_RX_reg <= CHNL_RX;	
	end
	
	//len_reg
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			len_reg <= 'd0;
		else if(CHNL_RX == 1'b1)
			len_reg <= CHNL_RX_LEN >> 1;
		else if(conf_end == 1'b1)
			len_reg <= 'd0;
	end
	
	//rx_cnt
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			rx_cnt  <= 'd0;
		else if(rx_cnt == (len_reg -1) & CHNL_RX_DATA_VALID == 1'b1 & CHNL_RX_DATA_REN == 1'b1)
			rx_cnt <= 'd0;
		else if(CHNL_RX_DATA_VALID == 1'b1 & CHNL_RX_DATA_REN == 1'b1)
			rx_cnt <= rx_cnt + 1'b1;
	end
	
	//CHNL_RX_ACK
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			CHNL_RX_ACK_r <= 1'b0;
		else if(rx_cnt == (len_reg -1) & CHNL_RX_DATA_VALID == 1'b1 & CHNL_RX_DATA_REN == 1'b1)
			CHNL_RX_ACK_r <= 1'b0;
		else if(CHNL_RX == 1'b1 & CHNL_RX_reg == 1'b0)
			CHNL_RX_ACK_r <= 1'b1;	
	end

	//width
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			width <= 'd0;
		else if(len_reg == 'd4 & rx_cnt == 'd0 &  CHNL_RX_DATA_VALID & CHNL_RX_DATA_REN)
			if(CHNL_RX_DATA[31:0] == 32'h01010101)
				width <= CHNL_RX_DATA[63:32];
	end
	//height_flag
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			height_flag <= 1'b0;
		else if(len_reg == 'd4 & rx_cnt == 'd0 &  CHNL_RX_DATA_VALID & CHNL_RX_DATA_REN)
			if(CHNL_RX_DATA[31:0] == 32'h01010101)
				height_flag <= 1'b1;
			else 
				height_flag <= 1'b0;
		else if(conf_end == 1'b1)
			height_flag <= 1'b0;
		else 
			height_flag <= height_flag;
	end
	
	//height
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			height <= 'd0;
		else if(len_reg == 'd4 & rx_cnt == 'd1 &  CHNL_RX_DATA_VALID & CHNL_RX_DATA_REN & height_flag == 1'b1)
			height <= CHNL_RX_DATA[31:0];
	end
	
	//conf_end
	always@(posedge CLK or negedge RST)begin
		if(RST == 1'b1)
			conf_end <= 1'b0;
		else if(CHNL_RX_ACK == 1'B0 & CHNL_RX_ACK_reg1 == 1'b1)
			conf_end <= 1'b1;
		else 
			conf_end <= 1'b0;
	end

	

endmodule