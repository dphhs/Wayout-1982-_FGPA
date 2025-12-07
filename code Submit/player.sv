

module player(
    input   wire logic clk,             // clock
    input   wire logic rstn,            // reset
    input   wire logic [3:0] key_pressed,

    output  wire logic refresh,
    // input wire logic map;
    output  wire logic signed [5:0] px,
    output  wire logic signed [5:0] py,
    output  wire logic [1:0] direction
);
    // Setting Parameter
    parameter
        H       =   13'd400,
        W       =   13'd400,

        x_width =   5,
        y_width =   5,

        displace =  13'd10,
        east    =   2'b00,
        north   =   2'b01,
        west    =   2'b10,
        south   =   2'b11;

       // Player and Map Parameter
    parameter
        row0  = 11'b11111111111,
        row1  = 11'b10001000001,
        row2  = 11'b11101010101,
        row3  = 11'b10100010101,
        row4  = 11'b10111011101,
        row5  = 11'b10001000001,
        row6  = 11'b10111001101,
        row7  = 11'b10000000001,
        row8  = 11'b10111010101,
        row9  = 11'b10100010001,
        row10 = 11'b10101000111,
        row11 = 11'b10001110001,
        row12 = 11'b10101111101,
        row13 = 11'b10100010001,
        row14 = 11'b10111010111,
        row15 = 11'b10001000101,
        row16 = 11'b11101111101,
        row17 = 11'b10001000101,
        row18 = 11'b10111010101,
        row19 = 11'b10000010001,
        row20 = 11'b11111111111,

        init_px =   5'd1,
        init_py =   5'd1;

    // Change to Input later==============
        logic [0:10] map [0:20]; // 21 rows, 11 bits each row

        // Initial Map
        always_ff @(posedge clk) begin
            if (!rstn) begin
                //px <= init_px;
                //py <= init_py;
                map[0] <= row0;
                map[1] <= row1;
                map[2] <= row2;
                map[3] <= row3;
                map[4] <= row4;
                map[5] <= row5;
                map[6] <= row6;
                map[7] <= row7;
                map[8] <= row8;
                map[9] <= row9;
                map[10] <= row10;
                map[11] <= row11;
                map[12] <= row12;
                map[13] <= row13;
                map[14] <= row14;
                map[15] <= row15;
                map[16] <= row16;
                map[17] <= row17;
                map[18] <= row18;
                map[19] <= row19;
                map[20] <= row20;
            end
        end

    assign refresh = (key_pressed[0] | key_pressed[1] | key_pressed[2] | key_pressed[3]);

    // Declare signed variables
    logic signed [5:0] forward_x, forward_y;

    // Initial Map
    always_ff @(posedge clk) begin
        if (!rstn) begin
            px <= 6'sd5;
            py <= 6'sd2;
            direction <= 2'b11;
        end else if (key_pressed[3]) begin
            direction <= direction + 1;
        end else if (key_pressed[2]) begin
            direction <= direction - 1;
        end else if (key_pressed[1]) begin
            if (map[py + forward_y][px + forward_x] == 0) begin
                px <= px + forward_x;
                py <= py + forward_y;
            end else begin
                px <= px;
                py <= py;
            end
        end else if (key_pressed[0]) begin
            if (map[py - forward_y][px - forward_x] == 0) begin
                px <= px - forward_x;
                py <= py - forward_y;
            end else begin
                px <= px;
                py <= py;
            end
        end
        // No explicit else needed - values hold by default
    end

    always_comb begin
        if (direction == east) begin
            forward_x = 1;  forward_y = 0;
        end else if (direction == north) begin
            forward_x = 0;  forward_y = -1;
        end else if (direction == west) begin
            forward_x = -1; forward_y = 0;
        end else begin  // south
            forward_x = 0;  forward_y = 1;
        end
    end

endmodule