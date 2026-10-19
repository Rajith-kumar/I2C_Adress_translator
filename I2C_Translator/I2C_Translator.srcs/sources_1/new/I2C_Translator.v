//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 08.09.2025 18:01:01
//// Design Name: 
//// Module Name: I2C_Translator
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//module I2C_Translator(
//clk,rst,start_req,WDATA,ADDR,RorW,RDATA,SCL_select,RDATA1,ADDR1,RorW1,WDATA1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
//);
        
        
//      input clk,rst,start_req;
//      input [7:0]WDATA;
//      input [6:0]ADDR;
//      input RorW,SCL_select;
//      output [7:0] RDATA1;
//      output [6:0] ADDR1;
//      output RorW1;
//      output [7:0]RDATA,WDATA1;  

//      I2C_Master master(
//      .clk(clk),
//      .rst(rst),
//      .start(start_req),
//      .write_data(WDATA),
//      .addr(ADDR),
//      .RorW(RorW),
//      .read_data(RDATA),
//      .SDA(SDA),
//      .SCL(SCL),
//      .SCL_select(SCL_select)
//      );   
           
//      I2C_Slave slave(
//      .clk(clk),
//      .rst(rst),
//      .SCL_in(SCL),
//      .SDA(SDA),
//      .read_data(RDATA1),
//      .addr(ADDR1),
//      .RorW(RorW1),
//      .write_data(WDATA1)
//      );

//endmodule


module I2C_Translator(
    input        clk,
    input        rst,
    input        start_req,
    input  [31:0] WDATA,
    input  [6:0] ADDR,
    input        RorW,
    input        SCL_select,
    input  [2:0] BYTE_count,
    input [7:0] RDATA1,     // slave-read data
    output [7:0] RDATA,      // master-read data
    
    output [31:0] WDATA1,     // data captured by slave
    output [6:0] ADDR1,
    output       RorW1
);
    // internal I²C wires
    wire SDA;
    wire SCL;

    I2C_Master master (
        .clk(clk),
        .rst(rst),
        .start(start_req),
        .write_data(WDATA),
        .addr(ADDR),
        .RorW(RorW),
        .read_data(RDATA),
        .byte_count(BYTE_count),
        .SDA(SDA),
        .SCL(SCL),
        .SCL_select(SCL_select)
    );

    I2C_Slave slave (
        .clk(clk),
        .rst(rst),
        .SCL_in(SCL),
        .SDA(SDA),
        .read_data(RDATA1),
        .addr(ADDR1),
        .RorW(RorW1),
        .write_data(WDATA1)
    );
endmodule
    