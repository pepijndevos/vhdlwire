module bram(input clk, wren, oen,
            input [10:0] rdaddress,
            input [10:0] wraddress,
            input [7:0] data_in,
            output reg [7:0] data_out);

parameter bits = 11;

reg [7:0] memory [0:(1<<bits)-1];

always @(posedge clk)
  if (wren == 1'b1)
    memory[wraddress] <= data_in;

always @(posedge clk)
  if (oen == 1'b1)
    data_out <= memory[rdaddress];


endmodule
