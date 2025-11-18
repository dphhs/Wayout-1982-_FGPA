`default_nettype none
`include "params.vh"

module player_sprite #(
    parameter ARROW_SIZE = 8   // length of arrow in pixels
)(
    input  wire [10:0] x,          // current VGA pixel x
    input  wire [10:0] y,          // current VGA pixel y
    input  wire [10:0] player_px,  // player center x in pixels
    input  wire [10:0] player_py,  // player center y in pixels
    input  wire [1:0]  dir,        // uses `DIR_EAST, `DIR_NORTH, ...
    output reg         pixel_on    // 1 if this pixel is part of the arrow
);

    // dx, dy relative to player center
    wire signed [11:0] dx = $signed({1'b0, x}) - $signed({1'b0, player_px});
    wire signed [11:0] dy = $signed({1'b0, y}) - $signed({1'b0, player_py});

    // Local coordinates: fwd = "forward", side = "sideways"
    reg signed [11:0] fwd;
    reg signed [11:0] side;

    always @* begin
        // Map (dx,dy) → (fwd,side) based on direction
        case (dir)
            `DIR_EAST: begin
                // Facing right: forward is +x, side is y
                fwd  = dx;
                side = dy;
            end

            `DIR_WEST: begin
                // Facing left: forward is -x, side is y
                fwd  = -dx;
                side = dy;
            end

            `DIR_NORTH: begin
                // Facing up: forward is -y, side is x
                fwd  = -dy;
                side = dx;
            end

            `DIR_SOUTH: begin
                // Facing down: forward is +y, side is x
                fwd  = dy;
                side = dx;
            end

            default: begin
                fwd  = 12'sd0;
                side = 12'sd0;
            end
        endcase

        // Default: pixel off
        pixel_on = 1'b0;

        // Draw a triangle that extends from the player outward along +fwd.
        // fwd ranges from 0 at the player center to ARROW_SIZE at the tip.
        //
        // Condition:
        //   0 <= fwd <= ARROW_SIZE
        //   |side| <= (ARROW_SIZE - fwd)
        //
        if (fwd >= 0 && fwd <= ARROW_SIZE) begin
            if ((side <=  (ARROW_SIZE - fwd)) &&
                (side >= -(ARROW_SIZE - fwd))) begin
                pixel_on = 1'b1;
            end
        end
    end

endmodule



