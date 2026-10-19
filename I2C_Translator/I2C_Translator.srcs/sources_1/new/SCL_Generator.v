// control bit SCL_select
//if SCL_select is 1 then 400KHz other wise 100KHz, by using muxes

module SCL_Generator(clk_in,rst,clk_out,SCL_select);  

    input clk_in,rst,SCL_select;
    output clk_out;
    
    wire clk_out1,clk_out2,clk_out3,clk_out4,clk_out2_1; 
    wire clk_in1;
     
    assign clk_in1 = (SCL_select)? 1'b0 : clk_in; 
    assign clk_out2_1 = (SCL_select)? clk_in : clk_out2;
    
    
    modulo_2 m1(.clk_in(clk_in1),.rst(rst),.clk_out(clk_out1));
    modulo_2 m2(.clk_in(clk_out1),.rst(rst),.clk_out(clk_out2));
    
    modulo_5 m3(.clk_in(clk_out2_1),.rst(rst),.clk_out(clk_out3));
    
    modulo_5 m4(.clk_in(clk_out3),.rst(rst),.clk_out(clk_out4));
    
    modulo_5 m5(.clk_in(clk_out4),.rst(rst),.clk_out(clk_out));
    
endmodule

module modulo_2(clk_in,rst,clk_out);
    input clk_in,rst;
    output reg clk_out;

always@(posedge clk_in or posedge rst)begin
    if(rst)begin
        clk_out <= 1'b0;
        
    end
    
    else begin
        if(clk_out == 1'b0) clk_out <= 1'b1;
        else clk_out <= 1'b0;
    end
end
   
   
endmodule

module modulo_5(clk_out, rst,clk_in);
    input rst, clk_in;
    output clk_out;
    wire y1, y2, q0bar, q1bar, q0, q1, q2, din,w,w1,w2,w3,D;
    assign q0bar = ~q0;
    assign y1 = q0 & (~D);
    assign y2 = q1 & (~D);
    assign y3 = q2;
    assign q1bar = ~q1;
    assign q2bar = ~q2;
    assign D = (~q2) & q1 & (~q0);

    and a1(w, q1, q2);
    and a2(w1, q1bar, q2bar);
    and(w2,w,q0bar);

    or o3(w3 , w1,w2);
    assign din = w3 | D;    
    
    DFF d1(clk_in, din, q0, rst);
    DFF d2(clk_in, y1, q1, rst);
    DFF d4(clk_in, y2, q2, rst);
    DFF_negedge d3(clk_in, y3, q3, rst);
    or o1(clk_out, q2, q3); 
endmodule  
module DFF(clk, d, q, reset);
    input clk, d, reset;
    output q;
    reg q;
    
    always @(posedge clk or posedge reset)
    begin
        if(reset)
            q <= 1'b0;
        else 
            q <= d;
    end
endmodule



module DFF_negedge(clk, d, q, reset);
    input clk, d, reset;
    output q;
    reg q;
    
    always @(negedge clk or posedge reset)
    begin
        if(reset)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule
// SCL_Generator Done----------------------------------------------
