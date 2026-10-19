`timescale 1ns/1ps

module tb_I2C_Translator;

    
    reg         clk;
    reg         rst;
    reg         start_req;
    reg  [31:0]  WDATA;
    reg  [6:0]  ADDR;
    reg         RorW;       
    reg         SCL_select; 
    reg  [2:0]  BYTE_count; 
    reg  [7:0]  RDATA1;      

    wire [7:0]  RDATA;       
    
    wire [31:0]  WDATA1;      
    wire [6:0]  ADDR1;
    wire        RorW1;

   
    wire SDA;
    wire SCL;
    pullup (SDA);
    pullup (SCL);

    
    I2C_Translator dut (
        .clk(clk),
        .rst(rst),
        .start_req(start_req),
        .WDATA(WDATA),
        .ADDR(ADDR),
        .RorW(RorW),
        .RDATA(RDATA),
        .SCL_select(SCL_select),
        .BYTE_count(BYTE_count),
        .RDATA1(RDATA1),
        .ADDR1(ADDR1),
        .RorW1(RorW1),
        .WDATA1(WDATA1)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        
        rst = 1;
        start_req = 0;
        WDATA = 32'h00000000;
        ADDR  = 7'b1001000;   
        RorW  = 1'b0;
        SCL_select = 1'b0;
        #50;                 
        rst = 0;


//        @(negedge clk);
//        RDATA1 = 8'hAB; 
//        ADDR  = 7'b1001001;
//        RorW  = 1'b1;         
//        start_req = 1'b1;
//        @(negedge clk);
//        start_req = 1'b0; 




//       FOR WRITE
        @(negedge clk);
        WDATA = 32'hCDBBA5AB; 
        BYTE_count = 3'b100;       
        RorW  = 1'b0;         
        start_req = 1'b1;
        @(negedge clk);
        start_req = 1'b0;     

        
        #566000;

        
        @(negedge clk);
        ADDR  = 7'b1001001;
        WDATA = 32'hB381A134;
        RorW  = 1'b0;         
        start_req = 1'b1;
        @(negedge clk);
        start_req = 1'b0;

       
        #5000;

        
        $stop;
    end

   

endmodule



//`timescale 1ns/1ps

//module tb_i2c_slave_read_only;

//    // System clock for the slave's internal logic
//    reg clk = 0;
//    reg rst = 1;

//    // Bidirectional I²C wires with pull-ups
//    wire SCL;
//    wire SDA;
//    pullup(SCL);
//    pullup(SDA);

//    // External-master drivers (open-drain style: 0 = pull low, 1 = release)
//    reg scl_drv = 1;
//    reg sda_drv = 1;
//    assign SCL = (scl_drv==0) ? 1'b0 : 1'bz;
//    assign SDA = (sda_drv==0) ? 1'b0 : 1'bz;

//    // DUT: your clock-stretching slave
//    I2C_Slave_Stretch dut (
//        .clk(clk),
//        .rst(rst),
//        .SCL(SCL),
//        .SDA(SDA),
//        .read_data(8'hA5),   // the byte slave will send
//        .addr(), .RorW(), .write_data()
//    );

//    // Slave system clock
//    always #5 clk = ~clk;   // 100 MHz

//    //---------------- I²C helper tasks -----------------
//    task i2c_start;
//        begin
//            sda_drv <= 1; scl_drv <= 1; #200;
//            sda_drv <= 0;               #200; // SDA low while SCL high
//            scl_drv <= 0;               #200;
//        end
//    endtask

//    task i2c_stop;
//        begin
//            sda_drv <= 0;               #100;
//            scl_drv <= 1;               #200;
//            sda_drv <= 1;               #200;
//        end
//    endtask

//    // send one byte, return ACK bit
//    task i2c_write_byte(input [7:0] data);
//        integer i;
//        begin
//            for (i=7; i>=0; i=i-1) begin
//                sda_drv <= data[i]; #100;
//                scl_drv <= 1; #200;  // clock high
//                scl_drv <= 0; #100;
//            end
//            // release for ACK
//            sda_drv <= 1; #100;
//            scl_drv <= 1; #200;
//            scl_drv <= 0; #100;
//        end
//    endtask

//    // read one byte, handle clock stretching
//    task i2c_read_byte(output [7:0] data);
//        integer i;
//        begin
//            data = 8'h00;
//            sda_drv <= 1; // release SDA
//            for (i=7; i>=0; i=i-1) begin
//                #100;
//                scl_drv <= 1;                 // request clock high
//                while (SCL === 1'b0) #50;     // wait if slave stretches
//                #100;
//                data[i] = SDA;                // sample bit
//                scl_drv <= 0; #100;
//            end
//            // NACK to end read
//            sda_drv <= 1; #100;
//            scl_drv <= 1; #200;
//            scl_drv <= 0; #100;
//        end
//    endtask

//    //---------------- Test sequence --------------------
//    initial begin
//        #1000; rst = 0;

//        i2c_start();
        
//        i2c_write_byte({7'h55,1'b1});

//        reg [7:0] rbyte;
//        i2c_read_byte(rbyte);
//        $display("Slave returned: 0x%02h", rbyte);

//        i2c_stop();

//        #500;
//        $finish;
//    end

//endmodule
