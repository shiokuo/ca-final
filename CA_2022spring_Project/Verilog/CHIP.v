// Your code
module CHIP(clk,
            rst_n,
            // For mem_D
            mem_wen_D,
            mem_addr_D,
            mem_wdata_D,
            mem_rdata_D,
            // For mem_I
            mem_addr_I,
            mem_rdata_I);

    input         clk, rst_n ;
    // For mem_D
    output        mem_wen_D  ;
    output [31:0] mem_addr_D ;
    output [31:0] mem_wdata_D;
    input  [31:0] mem_rdata_D;
    // For mem_I
    output [31:0] mem_addr_I ;
    input  [31:0] mem_rdata_I;
    
    //---------------------------------------//
    // Do not modify this part!!!            //
    // Exception: You may change wire to reg //
    reg    [31:0] PC          ;              //
    wire   [31:0] PC_nxt      ;              //
    wire          regWrite    ;              //
    wire   [ 4:0] rs1, rs2, rd;              //
    wire   [31:0] rs1_data    ;              //
    wire   [31:0] rs2_data    ;              //
    wire   [31:0] rd_data     ;              //
    //---------------------------------------//

    // Todo: other wire/reg
    wire [6:0] opcode;
    wire [2:0] func3;
    wire [6:0] func7;
    reg Branch, MemRead, MemtoReg, MemWrite, ALUSrc, AUIPC;
    reg[2:0] Jump;
    reg[3:0] ALUOp;
    reg[31:0] imm;
    wire [31:0] AluIna, AluInb;
    wire [4:0] shamt;// ALU input 2 & slli/srli shift amount
    reg [1:0] hold, hold_nxt;
    wire [31:0] AluResult;
    wire Zero; //ALU
    wire valid;
    wire [3:0] ALU_CTRL; //ALU CONTROL SIGNAL
    wire PCSrc; //mux of pc
    reg [31:0] Jump_dest;
    wire [63:0] muldivout;
    

    //---------------------------------------//
    // Do not modify this part!!!            //
    reg_file reg0(                           //
        .clk(clk),                           //
        .rst_n(rst_n),                       //
        .wen(regWrite),                      //
        .a1(rs1),                            //
        .a2(rs2),                            //
        .aw(rd),                             //
        .d(rd_data),                         //
        .q1(rs1_data),                       //
        .q2(rs2_data));                      //
    //---------------------------------------//

    // Todo: any combinational/sequential circuit
    //register file input
    always @(*) begin
        rs1 = mem_rdata_I[19:15];
        rs2 = mem_rdata_I[24:20];
        rd = mem_rdata_I[11:7];
    end
    //------------------ID-------------------
    assign opcode = mem_rdata_I[6:0];
    assign func7  = mem_rdata_I[31:25];
    assign func3  = mem_rdata_I[14:12];
    always @(*) begin
        case (opcode)
            7'b0010111:begin //auipc
                Branch     = 0;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 0;
                ALUSrc     = 1;
                AUIPC      = 1;
                Jump       = 2'd0;
                ALUOp      = 4'b0000;
                regWrite   = 1;
                imm        = {mem_rdata_I[31:12], 12'b0};
            end
            7'b1101111:begin //jal
                Branch     = 0;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 0;
                ALUSrc     = 0;
                AUIPC      = 0;
                Jump       = 2'd1;
                ALUOp      = 4'b0000;
                regWrite   = 1;
                imm        = {{11{mem_rdata_I[31]}}, mem_rdata_I[31], mem_rdata_I[19:12], mem_rdata_I[20], mem_rdata_I[30:21], 1'b0};
            end
            7'b1100111:begin //jalr
                Branch     = 0;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 0;
                ALUSrc     = 1;
                AUIPC      = 0;
                Jump       = 2'd2;
                ALUOp      = 4'b0000;
                regWrite   = 1;
                imm        = {{20{mem_rdata_I[31]}}, mem_rdata_I[31:20]};
            end
            7'b1100011:begin //beq
                Branch     = 1;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 0;
                ALUSrc     = 0;
                AUIPC      = 0;
                Jump       = 2'd0;
                ALUOp      = 4'b1000;
                regWrite   = 0;
                imm        = {{19{mem_rdata_I[31]}}, mem_rdata_I[31], mem_rdata_I[7], mem_rdata_I[30:25],mem_rdata_I[11:8], 1'b0};
            end
            7'b1100011:begin //bge
                Branch     = 1;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 0;
                ALUSrc     = 0;
                AUIPC      = 0;
                Jump       = 2'd0;
                ALUOp      = 4'b1000;
                regWrite   = 0;
                imm        = {{19{mem_rdata_I[31]}}, mem_rdata_I[31], mem_rdata_I[7], mem_rdata_I[30:25],mem_rdata_I[11:8], 1'b0};
            end
            7'b0000011:begin //lw
                Branch     = 0;
                MemRead    = 1;
                MemtoReg   = 1;
                MemWrite   = 0;
                ALUSrc     = 1;
                AUIPC      = 0;
                Jump       = 2'd0;
                ALUOp      = 4'b0000;
                regWrite   = 1;
                imm        = {{20{mem_rdata_I[31]}}, mem_rdata_I[31:20]};
            end
            7'b0100011:begin //sw
                Branch     = 0;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 1;
                ALUSrc     = 1;
                AUIPC      = 0;
                Jump       = 2'd0;
                ALUOp      = 4'b0000;
                regWrite   = 0;
                imm        = {{20{mem_rdata_I[31]}}, mem_rdata_I[31:25], mem_rdata_I[11:7]};
            end
            7'b0010011:begin //slti, addi, slli, srli
                Branch     = 0;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 0;
                ALUSrc     = 1;
                AUIPC      = 0;
                Jump       = 2'd0;
                regWrite   = 1;
                imm        = {{20{mem_rdata_I[31]}}, mem_rdata_I[31:20]};
                case (func3)
                    3'b000:begin //addi
                        ALUOp = 4'b0000;
                    end
                    3'b010:begin //slti
                        ALUOp = 4'b0010;
                    end
                    3'b001:begin //slli
                        ALUOp = 4'b0001;
                    end
                    3'b101:begin //srli
                        ALUOp = 4'b0101;
                    end
                    default : ALUOp = 4'b0000;
                endcase
            end
            7'b0110011:begin //add,sub,xor,mul
                Branch     = 0;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 0;
                ALUSrc     = 0;
                AUIPC      = 0;
                Jump       = 2'd0;
                imm        = 32'b0;
                case(func7)
                    7'b0000000:begin
                        case(func3)
                            3'b000:begin //add
                                ALUOp    = 4'b0000;
                                regWrite = 1;
                            end
                            3'b100:begin //xor //TODOOOOOOOOOOOOOO
                                ALUOp    = 4'b0011;
                                regWrite = 1;
                            end
                            default:begin 
                                ALUOp = 4'b0000;
                                regWrite = 0;
                            end
                        endcase
                    end
                    7'b0100000:begin //sub
                        ALUOp    = 4'b1000;
                        regWrite = 1;
                    end
                    7'b0000001:begin //mul
                        ALUOp    = 4'b1111;
                        regWrite = (hold == 2'd2 && ready) ? (1):(0);;
                    end
                    default:begin 
                        ALUOp = 4'b0000;
                        regWrite = 0;
                    end
                endcase
            end
            default: begin
                Branch     = 0;
                MemRead    = 0;
                MemtoReg   = 0;
                MemWrite   = 0;
                ALUSrc     = 0;
                AUIPC      = 0;
                Jump       = 2'd0;
                ALUOp      = 4'b0000;
                regWrite   = 0;
                imm        = 32'b0;
            end
        endcase
    end
    assign ALU_CTRL = (Branch)?4'b1000:((MemRead || MemWrite)? 4'b0000 : ALUOp);
    assign PCSrc = (Branch & Zero && func3 == 3'b000)||(Branch & AluResult[31] && func3 == 3'b100);// func3 = 000 => BEQ, func3 = 100 => BLT
    assign valid = (ALUOp == 4'b1111 && hold == 2'd0);
    assign shamt = mem_rdata_I[24:20];
    always@ (*) begin
        case (Jump)
            2'd1:begin //jal
                Jump_dest = PC + imm;
            end
            2'd2: begin //jalr
                Jump_dest = rs1_data + imm;
            end
            default: begin
                Jump_dest = 32'd0;
            end
        endcase
    end
    //-------------IF----------
    //TODO
    //-------------EX----------
    assign AluIna = (AUIPC)?(PC):(rs1_data);
    assign AluInb = (ALUSrc)?(imm):(rs2_data);
    ALU alu(
        .inA(AluIna), 
        .inB(AluInb), 
        .control(ALU_ctrl)
        .shift_amount(shamt), 
        .alu_out(AluResult), 
        .zero(Zero), 
    );
    mulDiv mudi(
        .clk(clk),
        .rst_n(rst_n),
        .valid(valid),
        .mode(ALU_CTRL), // mode: 1111: mulu, 1110: divu, 1100: and, 1010: or
        .ready(ready),
        .in_A(AluIna),
        .in_B(AluInb),
        .out(muldivout)
    );
    //------------MEM----------
    //TODO
    //-------------WB----------
    //TODO

            

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 32'h00010000; // Do not modify this value!!!
            
        end
        else begin
            PC <= PC_nxt;
            
        end
    end
endmodule

module reg_file(clk, rst_n, wen, a1, a2, aw, d, q1, q2);

    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth

    input clk, rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] d;
    input [addr_width-1:0] a1, a2, aw;

    output [BITS-1:0] q1, q2;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign q1 = mem[a1];
    assign q2 = mem[a2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (aw == i)) ? d : mem[i];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1) begin
                case(i)
                    32'd2: mem[i] <= 32'hbffffff0;
                    32'd3: mem[i] <= 32'h10008000;
                    default: mem[i] <= 32'h0;
                endcase
            end
        end
        else begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end
    end
endmodule



module mulDiv(clk, rst_n, valid, ready, mode, in_A, in_B, out);
    // Todo: your HW2
    input         clk, rst_n;
    input         valid;
    input  [3:0]  mode; // mode: 1111: mulu, 1110: divu, 1100: and, 1010: or
    output        ready;
    input  [31:0] in_A, in_B;
    output [63:0] out;

    // Definition of states
    localparam IDLE = 3'd0;
    localparam MUL  = 3'd1;
    localparam DIV  = 3'd2;
    localparam AND = 3'd3;
    localparam AVG = 3'd4;
    localparam OUT  = 3'd5;

    // Todo: Wire and reg if needed
    reg  [ 2:0] state, state_nxt;
    reg  [ 4:0] counter, counter_nxt;
    reg  [63:0] shreg, shreg_nxt;
    reg  [31:0] alu_in, alu_in_nxt;
    reg  [32:0] alu_out;

    // Todo: Instatiate any primitives if needed

    // Todo 5: Wire assignments
    assign out = shreg;
    assign ready = (state == OUT);
    // Combinational always block
    // Todo 1: Next-state logic of state machine
    always @(*) begin
        case(state)
            IDLE: begin
                if (valid) begin
                    case (mode)
                        4'b1111 : state_nxt = MUL;
                        4'b1110 : state_nxt = DIV;
                        4'b1100 : state_nxt = AND;
                        4'b1010 : state_nxt = AVG;
                        default:state_nxt = IDLE;
                    endcase
                end
                else state_nxt = IDLE;
            end
            MUL : state_nxt = (counter == 5'd31) ? OUT : MUL;
            DIV : state_nxt = (counter == 5'd31) ? OUT : DIV;
            AND : state_nxt = OUT;
            AVG : state_nxt = OUT;
            OUT : state_nxt = IDLE;
            default : state_nxt = IDLE;
        endcase
    end
    // Todo 2: Counter
    always @(posedge clk) begin
        case(state)
            MUL:  if (counter < 5'd31) counter_nxt = counter + 5'd1;
            DIV:  if (counter < 5'd31) counter_nxt = counter + 5'd1;
        default : counter_nxt = 5'd0;
        endcase
        counter = counter_nxt;
    end
    // ALU input
    always @(*) begin
        case(state)
            IDLE: begin
                if (valid) alu_in_nxt = in_B;
                else       alu_in_nxt = 0;
            end
            OUT : alu_in_nxt = 0;
            default: alu_in_nxt = alu_in;
        endcase
    end

    // Todo 3: ALU output
    always @(*) begin
        case (state)
            MUL: begin 
                if (shreg[0]) alu_out = alu_in + shreg[63:32];
                else alu_out = shreg[63:32];
            end
            DIV: alu_out = (shreg[63:32] > alu_in) ? (shreg[63:32] - alu_in):(shreg[63:32]);
            AND: alu_out = shreg[31:0] & alu_in;
            AVG: alu_out = (shreg[31:0] + alu_in)>>1;
            default: alu_out = shreg[63:32];
        endcase
    end
    // Todo 4: Shift register
    always @(*) begin
        case (state)
            MUL: begin
                shreg_nxt = {alu_out,shreg[31:1]};
            end
            AND:begin
                shreg_nxt = {31'd0,alu_out};
            end
            AVG:begin
                shreg_nxt = {31'd0,alu_out};
            end
            DIV:begin
                if (counter ==  5'd31) begin
                    shreg_nxt[63] = 0;
                    shreg_nxt[62:32] = alu_out[30:0];
                    shreg_nxt[31:1] = shreg[30:0];
                    shreg_nxt[0] = (shreg[63:32] > alu_in);
                end
                else begin
                    shreg_nxt[63:33] = alu_out[30:0];
                    shreg_nxt[32:1] = shreg[31:0];
                    shreg_nxt[0] = (shreg[63:32] > alu_in);
                end
            end 
            IDLE: begin
                if (valid) begin
                    case (mode)
                        4'b1111 :begin 
                            shreg_nxt[31:0] = in_A;//state_nxt = MUL
                            shreg_nxt[63:32] = 0;
                        end
                        4'b1110 :begin 
                            shreg_nxt[0] = 0;
                            shreg_nxt[32:1] = in_A;//state_nxt = DIV
                            shreg_nxt[63:33] = 0;
                        end
                        4'b1100 :begin 
                            shreg_nxt[31:0] = in_A;//state_nxt = AND
                            shreg_nxt[63:32] = 0;
                        end
                        4'b1010 :begin 
                            shreg_nxt[31:0] = in_A;//state_nxt = OR
                            shreg_nxt[63:32] = 0;
                        end
                        default shreg_nxt[63:0] = shreg[63:0];
                    endcase
                end
                else shreg_nxt[63:0] = 0;
            end
            default: shreg_nxt[63:0] = shreg[63:0];
        endcase
    end
    // Todo: Sequential always block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end
        else begin
            alu_in <= alu_in_nxt;
            shreg[63:0] <= shreg_nxt[63:0];
            state <= state_nxt;

        end
    end
endmodule

// the ALU, use 32 bits input inA, inB, and 4 bits control signal(generate by the ALU_control).
module ALU (inA, inB, shift_amount, alu_out, zero, control); 
	input [31:0] inA, inB;
    input [3:0] control;
    input [4:0] shift_amount;
	output [31:0] alu_out;
	output zero;

	reg zero;
	reg [31:0] alu_out;
	always @ (*) begin
        
        case (control) // instruction[30, 14-12]
            //add
            4'b0000:begin  
                alu_out <= inA + inB; 
                zero <= 1'b0;
            end
            // sub and beq
            4'b1000:begin 
                alu_out <= inA - inB;  // sub
                zero <= (inA == inB) ? 1: 0;  // check if inA and inB are equal
            end
            // slti
            4'b0010: begin
                alu_out <= ($signed(inA) < $signed(inB)) ? 32'b1: 32'b0;
                zero <= 0;
            end
            // slli
            4'b0001: begin
                alu_out <= inA << shift_amount;
                zero <= 1'b0;
            end
            // srli
            4'b0101: begin
                alu_out <= inA >> shift_amount;
                zero <= 1'b0;
            end
            //xor //TODOOOOOOOOOOOOOOOOOOOOOOOO
            4'b0011: begin
                alu_out <= inA ^ inB;
            end
            default:begin 
                alu_out <= 32'b0; 
                zero <= 1'b0;
            end
        endcase
	end
endmodule