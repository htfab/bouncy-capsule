`default_nettype none

module kinematics(
    input wire clk,
    input wire rst,
    input wire update,
    input wire [9:0] init_x,
    input wire [9:0] init_y,
    input wire [6:0] init_phi,
    input wire [5:0] vx,
    input wire [5:0] vy,
    input wire [5:0] w,
    output wire [2:0] phi_hi,
    output reg [9:0] center_x,
    output reg [9:0] center_y,
    output reg [5:0] dx,
    output reg [5:0] dy,
    output reg [11:0] dx_s,
    output reg [10:0] dx_dy,
    output reg [11:0] dy_s
);

reg [1:0] center_x_lo;
reg [1:0] center_y_lo;
reg [10:0] phi;
reg [3:0] state;
reg overflow;

assign phi_hi = phi[10:8];

wire [10:0] sine;
sine_table i_sine_table(
    .in(phi[7:3]^{(5){phi[8]}}),
    .out(sine)
);

always @(posedge clk) begin
    if(rst) begin
        center_x <= init_x;
        center_x_lo <= 2'b0;
        center_y <= init_y;
        center_y_lo <= 2'b0;
        phi <= {init_phi, 4'b0};
        state <= 1;
    end else if(update) begin
        {center_x, center_x_lo} <= {center_x, center_x_lo} + {{(6){vx[5]}}, vx};
        {center_y, center_y_lo} <= {center_y, center_y_lo} + {{(6){vy[5]}}, vy};
        phi <= phi + {{(5){w[5]}}, w};
        state <= 1;
    end else if(state == 1 || state == 5) begin
        dy_s <= {1'b0, sine};
        dy <= 0;
        dx_dy <= 0;
        overflow <= 0;
        state <= state + 1;
    end else if(state == 2 || state == 6) begin
        if(phi[9]^phi[8]) dy_s <= -dy_s;
        state <= state + 1;
    end else if(state == 3 || state == 8) begin
        if(overflow) begin
            dy <= dy - 1;
            dx_dy <= dx_dy - {5'b0, dx};
            state <= state + 1;
        end else begin
            dy <= dy + 1;
            dx_dy <= dx_dy + {5'b0, dx};
            {overflow, dy_s} <= {1'b0, dy_s} + {6'b0, dy, 1'b1};
        end
    end else if(state == 4) begin
        dx <= dy;
        state <= 5;
    end else if(state == 7) begin
        dx_s <= -dy_s;
        dy_s <= -dy_s;
        state <= 8;
    end else if(state == 9) begin
        dy_s <= -dx_s;
        state <= 0;
    end
end

endmodule
