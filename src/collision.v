`default_nettype none

module collision(
    input wire clk,
    input wire rst,
    input wire update,
    input wire rotate,
    input wire mirror,
    input wire [2:0] init_vx,
    input wire [2:0] init_vy,
    input wire [2:0] init_w,
    input wire [1:0] phi,
    input wire round_dir,
    output wire [5:0] vxt,
    output wire [5:0] vyt,
    output wire [5:0] wt,
    output wire [2:0] impact
);

reg [2:0] vx;
reg [2:0] vy;
reg [2:0] w;

wire ds = rotate ? ~phi[1] : phi[1];
wire dm = ds ^ ~phi[0];
wire vs = rotate ? (mirror ? ~vx[2] : vx[2]) : (mirror ? ~vy[2] : vy[2]);
wire [1:0] vm = rotate ? vx[1:0] : vy[1:0];
wire ws = w[2];
wire [1:0] wm = w[1:0];

wire vnc = (vm == 0 && wm != 0) || (vm == 1 && wm == 3);
wire wnc = (wm == 0 && vm != 0) || (wm == 1 && vm == 3);
wire ign = (dm && vnc) ? (ws ^ ds) : vs;

wire rxc = ds ^ vs ^ ws;
wire vxc = dm && wm == 0 && vm >= 2;
wire wxc = dm && vm == 0 && wm >= 2;
wire bz = vm == 0 && wm == 0;
wire [1:0] vwm = vm + wm;

wire [1:0] vmn = rxc ? (vxc ? 2'd1 : 2'd0) : (wxc ? (wm - 2'd2) : (bz ? 2'd0 : (vwm - 2'd1)));
wire [1:0] wmn = rxc ? (vxc ? (vm - 2'd2) : (bz ? 2'd0 : (vwm - 2'd1))) : (wxc ? 2'd1 : 2'd0);
wire vsn = (dm || vnc) ? (~ws ^ ds) : ~vs;
wire wsn = (dm || wnc) ? (~vs ^ ds) : ws;

wire [2:0] vn = {vsn ^ mirror, (bz || round_dir) ? vmn : (vmn + 2'd1)};
wire [2:0] wn = ign ? w : {wsn, (bz || !round_dir) ? wmn : (wmn + 2'd1)};
wire [2:0] vxn = (ign || !rotate) ? vx : vn;
wire [2:0] vyn = (ign || rotate) ? vy : vn;

always @(posedge clk) begin
    if(rst) begin
        vx <= init_vx;
        vy <= init_vy;
        w <= init_w;
    end else if(update) begin
        vx <= vxn;
        vy <= vyn;
        w <= wn;
    end
end

assign vxt = vx[2] ? {1'b1, ~vx[1], vx[1]|~vx[0], vx[1]&~vx[0], vx[1]|vx[0], vx[1]&vx[0]} : {1'b0, vx[1], ~vx[1], vx[0], vx[1]^vx[0], vx[1]&vx[0]};
assign vyt = vy[2] ? {1'b1, ~vy[1], vy[1]|~vy[0], vy[1]&~vy[0], vy[1]|vy[0], vy[1]&vy[0]} : {1'b0, vy[1], ~vy[1], vy[0], vy[1]^vy[0], vy[1]&vy[0]};
assign wt = w[2] ? {1'b1, ~w[1], w[1]|~w[0], w[1]&~w[0], w[1]|w[0], w[1]&w[0]} : {1'b0, w[1], ~w[1], w[0], w[1]^w[0], w[1]&w[0]};
assign impact = (ign || !update) ? 3'b0 : {vwm, 1'b1};

endmodule
