// SLAVE :
//    1. Wait for start condition, that is when SCL is high there will be a 1->0 transition of SDA.
//    2. Then sample the bits to form the address at every rising edge of the SCL, after sampling the 7 bits
//       then store into the address register.
//    3. Sample the 8th bit and store in the RorW bit.
//    4. Give the Acknowledgement at falling edge of the SCL after sampling all 8 bits.
//    5. based on RorW bit go to the read or write operation.
//    6. in write operation sample the 8 bits of data.
//    7. check the stop condition (SDA goes 0 -> 1 when SCL is high) and goto stop or shifting.
//    8. in read operation send the data at every falling edge of the SCL.
//    9. By checking the Acknowledgement from the master and go to stop or data shifting.



//problems

// Ack giving is not correct it is late


module I2C_Slave(clk,rst,SCL_in,SDA,read_data,addr,RorW,write_data);
    input clk,rst,SCL_in;
    inout SDA;
    input [7:0]read_data;
    output reg [6:0]addr;
    output reg RorW;
    output reg [31:0]write_data;
    
    
    reg [2:0]state;
    reg SDA_out,SDA_out_en;
    reg [3:0]counter;
    reg [7:0]shift_reg;
    reg [2:0]byte_count;             // updated
    
    parameter [2:0] IDLE = 3'b000;
    parameter [2:0] ADDRESS_SHIFTING = 3'b001;
    parameter [2:0] ADDRESS_ACK = 3'b010;
    parameter [2:0] WDATA_SHIFTING = 3'b011;
    parameter [2:0] WDATA_ACK = 3'b100;
    parameter [2:0] RDATA_SHIFTING = 3'b101;
    parameter [2:0] RDATA_ACK = 3'b110;
    parameter [2:0] STOP = 3'b111;
    
    
    // Should not use the posedge and negedge of same clk in module , it will not be synthesizable.
    // should take the strobes.
    reg sda_sync1,sda_sync2;
    reg scl_sync1,scl_sync2;  // taking two flipflops to avoid the metastability conditions
    wire SCL_Rise,SCL_Fall;
    
    always@(posedge clk)begin
        sda_sync1 <= SDA;
        sda_sync2 <= sda_sync1;
        scl_sync1 <= SCL_in;
        scl_sync2 <= scl_sync1;
    
    end
    
    assign SCL_Rise = scl_sync1 & (~scl_sync2);
    assign SCL_Fall = (~scl_sync1) & scl_sync2;
    
    //FSM Logic
    wire start_condition;
    wire stop_condition;
    
    assign start_condition = scl_sync2 & sda_sync2 & ~SDA;
    assign stop_condition  = scl_sync2 & ~sda_sync2 & SDA;
    
    
    always @(posedge clk or posedge rst)begin
        
        if(rst)begin
            SDA_out <= 0;
            SDA_out_en <= 0;
            addr <= 7'b00000000;
            RorW <= 1'b0;
            write_data <= 32'h00000000;
            state <= IDLE;
            counter <= 4'b0000;
            shift_reg <= 8'b00000000;
            byte_count <= 3'b000;
        end
        
        else begin
        
            case(state)
                
                IDLE : begin
                    SDA_out <= 0;
                    SDA_out_en <= 0;
                    byte_count <= 3'b000;
//                    addr <= 7'b00000000;
//                    RorW <= 1'b0;
//                    write_data <= 8'b00000000;
                    counter <= 4'b0000;
                    if(start_condition)begin
                        state <= ADDRESS_SHIFTING;
                    
                    end
                
                end
               
               ADDRESS_SHIFTING : begin
                     SDA_out_en <= 1'b0;
                    if(SCL_Rise)begin // sample the data at posedge of SCL
                        shift_reg <= {shift_reg[6:0],SDA};
                        if(counter == 4'b0111)begin
//                            addr <= {shift_reg[6:1],SDA};
                            addr <= shift_reg[6:0];
                            counter <= 4'b1000;          
                        end
                        else if(counter == 4'b1000)begin
                            
                            counter <= 4'b0000;
                        end
                        else begin
                        
                            counter <= counter + 1;
                        end
                   
                    end
                    if(SCL_Fall)begin
                        if(counter == 4'b1000)begin
                                state <= ADDRESS_ACK;
                                if(addr == 7'b1001000 || addr == 7'b1001001)begin
                                    if(SCL_Fall)begin
                                        RorW <= SDA;
                                        SDA_out_en <= 1'b1;
                                        SDA_out <= 1'b0;
                        end
                      end
                     end
                    end
                 end
               
               ADDRESS_ACK : begin
                    counter <= 4'b0000;
                    if(addr == 7'b1001000 || addr == 7'b1001001)begin
//                        if(SCL_Fall)begin
                        
//                            SDA_out_en <= 1'b1;
//                            SDA_out <= 1'b0;
//                        end
                     
                    
                        if(SCL_Rise)begin
                        
                            if(RorW == 1'b0)begin
                                state <= WDATA_SHIFTING;
                                counter <= 4'b0000;
                            end
                            else begin
                                state <= RDATA_SHIFTING;
                                shift_reg <= read_data;
                                counter <= 4'b0000;
                            
                            end
                      end
                            
                    end
                    else begin                                          
                        if(SCL_Fall)begin
                            SDA_out_en <= 1'b1;
                            SDA_out <= 1'b1;
                        end
                    end
               end
               
             WDATA_SHIFTING : begin
                  if(stop_condition)begin
                        state <= STOP;
                  end
                  else begin
                     SDA_out_en <= 1'b0;
                    if(SCL_Rise)begin    // sample at rising edge
                        shift_reg <= {shift_reg[6:0],SDA};
                        
//                        if(counter == 4'b0111)begin
//                            byte_count = byte_count + 1;
//                            counter <= 4'b1000;
//                        end
                    
                        if(counter == 4'b1000)begin
                             
//                            write_data <= shift_reg;
                            counter <= 4'b0000;
                        end
                        else begin
                            counter <= counter + 1;
                        end
                        
                    end
                  if(SCL_Fall)begin
//                    if(counter == 4'b0111)begin
//                        byte_count <= byte_count + 1;
//                        counter <= 4'b1000;
//                    end
                    if(counter == 4'b1000)begin
                        state <= WDATA_ACK;
//                        write_data <= shift_reg;
                            if(byte_count == 0)
                              write_data[7:0] <= shift_reg;
                            else if(byte_count == 1)
                              write_data[15:8] <= shift_reg;
                            else if(byte_count == 2)
                              write_data[23:16] <= shift_reg;
                            else if(byte_count == 3)
                              write_data[32:24] <= shift_reg; 
                        byte_count <= byte_count + 1;
                        SDA_out_en <= 1'b1;  // after recieving the data slave needs to send the ack;
                        SDA_out <= 1'b0;
                    end
                  
                end
             end
            end 
       
            
             WDATA_ACK : begin
                    counter <= 4'b0000;
                    
//                    if(SCL_Fall)begin
                            
//                            SDA_out_en <= 1'b1;  // after recieving the data slave needs to send the ack;
//                            SDA_out <= 1'b0;
//                        end
                    if(SCL_Fall)begin           //updated
                        SDA_out_en <= 1'b0;
                        if(stop_condition == 1 /*|| SDA*/)begin
                            state <= STOP;
                        end
                        else begin
                            
                            state <= WDATA_SHIFTING;
                        end
                    end    
//                    else begin
//                        if(SCL_Fall)begin
                            
                            
//                        end
//                    end
              
             end
             
             RDATA_SHIFTING : begin
                    
                    //send the data  at falling edge
                    if(SCL_Fall)begin
                         SDA_out_en <= 1'b1; // take the control over SDA line
                         SDA_out <= shift_reg[7];
                         shift_reg <= {shift_reg[6:0],1'b0};
                         
                    end   
                    if(SCL_Rise)begin
                        
                        if(counter == 4'b1000)begin
                            counter <= 4'b0000;
                            state <= RDATA_ACK;
                            SDA_out_en <= 1'b0;
                        end
                        else begin
                            counter <= counter + 1;
                        end
                        
                    end   
             
             end
             
             
             RDATA_ACK : begin
                    
                    counter <= 4'b0000;
                    if(SCL_Fall)begin
                        SDA_out_en <= 1'b0;  // release the SDA line because , now acceprting the ack from master
                    
                    end
                    if(SCL_Rise)begin
                    
                        if(SDA == 1'b0)begin
                            counter <= 4'b0000;
                            state <= RDATA_SHIFTING;
                            
                        end
                        else begin
                        
                            state <= STOP;
                        end
                    end
             end
             
             STOP : begin
                    counter <= 4'b0000;
                    state <= IDLE;
                
             end
            endcase
        
        end
        
    end
    assign SDA = SDA_out_en ? SDA_out : 1'bz;
endmodule





//// I2C Slave with clock stretching for read operations
//module I2C_Slave (
//    input  wire        clk,       
//    input  wire        rst,
//    inout  wire        SCL,      
//    inout  wire        SDA,
//    input  wire [7:0]  read_data, 
//    output reg  [6:0]  addr,
//    output reg         RorW,
//    output reg  [31:0] write_data
//);

  
//    reg SDA_out, SDA_out_en;
//    reg SCL_out_en;         
//    reg [2:0] state;
//    reg [3:0] counter;
//    reg [7:0] shift_reg;
//    reg [2:0] byte_count;

    
//    localparam [2:0] IDLE            = 3'b000,
//                     ADDRESS_SHIFT   = 3'b001,
//                     ADDRESS_ACK     = 3'b010,
//                     WDATA_SHIFT     = 3'b011,
//                     WDATA_ACK       = 3'b100,
//                     RDATA_SHIFT     = 3'b101,
//                     RDATA_ACK       = 3'b110,
//                     STOP            = 3'b111;

//    // ----------------------------------------------------
//    // Synchronizers for SCL/SDA sampling
//    // ----------------------------------------------------
//    reg sda_meta, sda_sync;
//    reg scl_meta, scl_sync;
//    always @(posedge clk) begin
//        sda_meta <= SDA;
//        sda_sync <= sda_meta;
//        scl_meta <= SCL;
//        scl_sync <= scl_meta;
//    end
//    wire SCL_Rise =  scl_meta & ~scl_sync;
//    wire SCL_Fall = ~scl_meta &  scl_sync;

//    // Start/Stop detect
//    wire start_condition =  scl_sync & sda_sync & ~SDA;
//    wire stop_condition  =  scl_sync & ~sda_sync &  SDA;

//    // ----------------------------------------------------
//    // Internal "data-fetch" handshake
//    // ----------------------------------------------------
//    // Pretend we launch an internal master transaction
//    // when external master issues a read. The signal
//    // internal_busy is a placeholder for your real logic.
//    reg internal_busy;
//    wire stretch_req = internal_busy;  // high while we need time

//    // ----------------------------------------------------
//    // Main FSM
//    // ----------------------------------------------------
//    always @(posedge clk or posedge rst) begin
//        if (rst) begin
//            state       <= IDLE;
//            SDA_out     <= 1'b0;
//            SDA_out_en  <= 1'b0;
//            SCL_out_en  <= 1'b0;
//            addr        <= 7'd0;
//            RorW        <= 1'b0;
//            write_data  <= 32'd0;
//            counter     <= 4'd0;
//            byte_count  <= 3'd0;
//            internal_busy <= 1'b0;
//            shift_reg   <= 8'd0;
//        end
//        else begin
//            case (state)
//            IDLE: begin
//                SDA_out_en <= 0;
//                SCL_out_en <= 0;
//                byte_count <= 0;
//                counter    <= 0;
//                if (start_condition)
//                    state <= ADDRESS_SHIFT;
//            end

//            ADDRESS_SHIFT: begin
//                SDA_out_en <= 0;
//                if (SCL_Rise) begin
//                    shift_reg <= {shift_reg[6:0], SDA};
//                    counter   <= counter + 1;
//                    if (counter == 4'd7) begin
//                        addr   <= {shift_reg[6:0], SDA};
//                        counter<= 0;
//                        state  <= ADDRESS_ACK;
//                    end
//                end
//            end

//            ADDRESS_ACK: begin
//                // Capture R/W bit at last bit of address byte
//                if (SCL_Fall) begin
//                    RorW       <= SDA;
//                    SDA_out_en <= 1;
//                    SDA_out    <= 0;   // ACK
//                end
//                if (SCL_Rise) begin
//                    SDA_out_en <= 0;
//                    if (RorW == 0)
//                        state <= WDATA_SHIFT;
//                    else begin
//                        // *** Clock Stretch Trigger ***
//                        internal_busy <= 1'b1;   // launch internal read
//                        state         <= RDATA_SHIFT;
//                    end
//                end
//            end

//            // ---------- Write Path ----------
//            WDATA_SHIFT: begin
//                if (stop_condition) state <= STOP;
//                else if (SCL_Rise) begin
//                    shift_reg <= {shift_reg[6:0], SDA};
//                    counter   <= counter + 1;
//                    if (counter == 4'd8) begin
//                        counter <= 0;
//                        // store into write_data
//                        case (byte_count)
//                            0: write_data[7:0]   <= shift_reg;
//                            1: write_data[15:8]  <= shift_reg;
//                            2: write_data[23:16] <= shift_reg;
//                            3: write_data[31:24] <= shift_reg;
//                        endcase
//                        byte_count <= byte_count + 1;
//                        SDA_out_en <= 1; SDA_out <= 0; // ACK
//                        state <= WDATA_ACK;
//                    end
//                end
//            end

//            WDATA_ACK: begin
//                if (SCL_Fall) SDA_out_en <= 0;
//                if (SCL_Rise) state <= WDATA_SHIFT;
//            end

//            // ---------- Read Path with Clock Stretch ----------
//            RDATA_SHIFT: begin
//                // If internal read still running -> stretch
//                if (stretch_req) begin
//                    SCL_out_en <= 1;  // Hold SCL low
//                end
//                else begin
//                    SCL_out_en <= 0;  // Release SCL
//                    // shift data out bit by bit
//                    if (SCL_Fall) begin
//                        SDA_out_en <= 1;
//                        SDA_out    <= shift_reg[7];
//                        shift_reg  <= {shift_reg[6:0],1'b0};
//                    end
//                    if (SCL_Rise) begin
//                        counter <= counter + 1;
//                        if (counter == 4'd8) begin
//                            counter <= 0;
//                            SDA_out_en <= 0;
//                            state <= RDATA_ACK;
//                        end
//                    end
//                end
//            end

//            RDATA_ACK: begin
//                if (SCL_Rise) begin
//                    if (SDA == 0) state <= RDATA_SHIFT; // master wants more
//                    else state <= STOP;
//                end
//            end

//            STOP: begin
//                SCL_out_en <= 0;
//                SDA_out_en <= 0;
//                state <= IDLE;
//            end
//            endcase

//            // *** Example internal-master completion ***
//            // Replace this with your real handshake
//            if (internal_busy && /* your done condition */ 1'b0)
//                internal_busy <= 1'b0;
//        end
//    end

//    // ----------------------------------------------------
//    // Open-drain outputs
//    // ----------------------------------------------------
//    assign SDA = SDA_out_en ? SDA_out : 1'bz;
//    assign SCL = SCL_out_en ? 1'b0   : 1'bz;

//endmodule



