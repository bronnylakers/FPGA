`timescale 1ns / 1ps

//-----------------------------------------------------------------------------
// FND 컨트롤러: idle→설정→동작→타임아웃 0 깜빡임→idle
//-----------------------------------------------------------------------------
module fnd_controller(
    input        i_clk,
    input        i_reset,
    input  [6:0] sec_data,
    input  [6:0] min_data,
    input        s_tick,        // 1초 펄스
    input        operating,     // 동작 중 플래그
    output [3:0] an,            // 자릿수 선택 (active low)
    output [6:0] seg_data       // 7-세그먼트 패턴 (gfedcba)
);

    // 1) 타임아웃 검출 및 3회 깜빡임 카운터
    reg [1:0] timeout_count;
    reg       timeout_active;
    reg       prev_operating;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            timeout_count  <= 2'd0;
            timeout_active <= 1'b0;
            prev_operating <= 1'b0;
        end else begin
            prev_operating <= operating;
            // 동작 종료 감지
            if (!operating && prev_operating) begin
                timeout_active <= 1'b1;
                timeout_count  <= 2'd0;
            end
            // 타임아웃 중 1초마다 카운트, 3회 후 해제
            else if (timeout_active && s_tick) begin
                if (timeout_count < 2'd2)
                    timeout_count <= timeout_count + 1'b1;
                else
                    timeout_active <= 1'b0;
            end
            // 동작 재시작 시 해제
            if (operating)
                timeout_active <= 1'b0;
        end
    end

    // 2) 내부 신호 및 서브모듈
    wire [1:0] digit_sel;
    wire [3:0] d1, d10, d100, d1000;
    wire [6:0] c1, c10, c100, c1000;

    fnd_digit_select u_sel(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .sel(digit_sel)
    );

    bin2bcd u_b2b(
        .sec_data(sec_data),
        .min_data(min_data),
        .digit_1(d1),
        .digit_10(d10),
        .digit_100(d100),
        .digit_1000(d1000)
    );

    circle_data u_circle(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .s_tick(s_tick),
        .circle_1(c1),
        .circle_10(c10),
        .circle_100(c100),
        .circle_1000(c1000)
    );

    fnd_digit_display u_disp(
        .i_clk(i_clk),
        .i_reset(i_reset),
        .s_tick(s_tick),
        .operating(operating),
        .timeout_active(timeout_active),
        .digit_sel(digit_sel),
        .digit_1(d1),
        .digit_10(d10),
        .digit_100(d100),
        .digit_1000(d1000),
        .circle_1(c1),
        .circle_10(c10),
        .circle_100(c100),
        .circle_1000(c1000),
        .an(an),
        .seg(seg_data)
    );

endmodule

//-----------------------------------------------------------------------------
// 1ms마다 4자리 스캔 신호 생성
//-----------------------------------------------------------------------------
module fnd_digit_select(
    input        i_clk,
    input        i_reset,
    output reg [1:0] sel
);
    reg [16:0] counter;
    parameter MAX_COUNT = 100_000; // 1ms @100MHz

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            counter <= 0;
            sel     <= 0;
        end else if (counter == MAX_COUNT-1) begin
            counter <= 0;
            sel     <= sel + 1;
        end else begin
            counter <= counter + 1;
        end
    end
endmodule

//-----------------------------------------------------------------------------
// 7bit 분·초 데이터를 4자리 BCD로 변환
//-----------------------------------------------------------------------------
module bin2bcd(
    input  [6:0] sec_data,
    input  [6:0] min_data,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
    assign digit_1    = sec_data % 10;
    assign digit_10   = (sec_data / 10) % 10;
    assign digit_100  = min_data % 10;
    assign digit_1000 = (min_data / 10) % 10;
endmodule

//-----------------------------------------------------------------------------
// 12스텝 원(circle) 애니메이션 (7bit)
//-----------------------------------------------------------------------------
module circle_data(
    input        i_clk,
    input        i_reset,
    input        s_tick,
    output reg [6:0] circle_1,
    output reg [6:0] circle_10,
    output reg [6:0] circle_100,
    output reg [6:0] circle_1000
);
  reg [3:0] ani_circle=0; // 12주기로 계속 돌아야 한다.
    always @(posedge i_clk or posedge i_reset) begin
        if(i_reset) begin
            circle_1 <= 8'b1111_1111;
            circle_10 <= 8'b1111_1111;
            circle_100 <= 8'b1111_1111;
            circle_1000 <= 8'b1111_1111;
            ani_circle <=0;
        end else if (s_tick) begin
            // 0 -> 1 ->,,, -> 11 ->0 순환
            if(ani_circle == 4'd11)
                ani_circle <= 0;
            else 
                ani_circle <= ani_circle +1; // 근데 ani_circle은 12개만 사용
        end
            case(ani_circle)
                4'd0 : begin circle_1 <= 8'b1111_1011;
                             circle_10 <= 8'b1111_1111;
                             circle_100 <= 8'b1111_1111;
                             circle_1000 <= 8'b1111_1111; end
                4'd1 : begin circle_1 <= 8'b1111_1001;
                             circle_10 <= 8'b1111_1111;
                             circle_100 <= 8'b1111_1111;
                             circle_1000 <= 8'b1111_1111; end
                4'd2 : begin circle_1 <= 8'b1111_1000;
                             circle_10 <= 8'b1111_1111;
                             circle_100 <= 8'b1111_1111;
                             circle_1000 <= 8'b1111_1111; end // 1변경
                4'd3 : begin circle_1 <= 8'b1111_1000;
                             circle_10 <= 8'b1111_1110;
                             circle_100 <= 8'b1111_1111;
                             circle_1000 <= 8'b1111_1111; end // 10 변경
                4'd4 : begin circle_1 <= 8'b1111_1000;
                             circle_10 <= 8'b1111_1110;
                             circle_100 <= 8'b1111_1110;
                             circle_1000 <= 8'b1111_1111; end // 100 변경
                4'd5 : begin circle_1 <= 8'b1111_1000;
                             circle_10 <= 8'b1111_1110;
                             circle_100 <= 8'b1111_1110;
                             circle_1000 <= 8'b1111_1110; end 
                4'd6 : begin circle_1 <= 8'b1111_1000;
                             circle_10 <= 8'b1111_1110;
                             circle_100 <= 8'b1111_1110;
                             circle_1000 <= 8'b1101_1110; end
                4'd7 : begin circle_1 <= 8'b1111_1000;
                             circle_10 <= 8'b1111_1110;
                             circle_100 <= 8'b1111_1110;
                             circle_1000 <= 8'b1100_1110; end
                4'd8 : begin circle_1 <= 8'b1111_1000;
                             circle_10 <= 8'b1111_1110;
                             circle_100 <= 8'b1111_1110;
                             circle_1000 <= 8'b1100_0110; end // 1000변경

                4'd9 : begin circle_100 <= 8'b1111_0110; end
                4'd10 : begin circle_10 <= 8'b1111_0110; end
                4'd11 : begin circle_1 <= 8'b1111_0000; end
                endcase
        end
endmodule
//-----------------------------------------------------------------------------
// 운영/타임아웃/idle에 따라 7bit FND 제어
//-----------------------------------------------------------------------------
module fnd_digit_display(
    input        i_clk,
    input        i_reset,
    input        s_tick,
    input        operating,
    input        timeout_active,
    input  [1:0] digit_sel,
    input  [3:0] digit_1,
    input  [3:0] digit_10,
    input  [3:0] digit_100,
    input  [3:0] digit_1000,
    input  [6:0] circle_1,
    input  [6:0] circle_10,
    input  [6:0] circle_100,
    input  [6:0] circle_1000,
    output reg [3:0] an,
    output reg [6:0] seg
);
    reg [3:0] bcd;
    reg       switch_fnd;

    // 1초마다 circle↔numeric 토글
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) switch_fnd <= 1'b0;
        else if (s_tick) switch_fnd <= ~switch_fnd;
    end

    // 자리 선택 마스크 (active low)
    wire [3:0] an_mask = ~(4'b0001 << digit_sel);

    always @(*) begin
        an = an_mask;
        if (timeout_active) begin
            // 타임아웃 3회 깜빡임: 항상 '0'
            seg = 7'b1000000;
        end else if (operating) begin
            if (!switch_fnd) begin
                // circle 애니메이션
                case (digit_sel)
                    2'd0: seg = circle_1;
                    2'd1: seg = circle_10;
                    2'd2: seg = circle_100;
                    2'd3: seg = circle_1000;
                endcase
            end else begin
                // 남은 시간 숫자 표시
                case (digit_sel)
                    2'd0: bcd = digit_1;
                    2'd1: bcd = digit_10;
                    2'd2: bcd = digit_100;
                    2'd3: bcd = digit_1000;
                endcase
                case (bcd)
                    4'd0: seg = 7'b1000000;
                    4'd1: seg = 7'b1111001;
                    4'd2: seg = 7'b0100100;
                    4'd3: seg = 7'b0110000;
                    4'd4: seg = 7'b0011001;
                    4'd5: seg = 7'b0010010;
                    4'd6: seg = 7'b0000010;
                    4'd7: seg = 7'b1111000;
                    4'd8: seg = 7'b0000000;
                    4'd9: seg = 7'b0010000;
                    default: seg = 7'b1111111;
                endcase
            end
        end else begin
            // idle: 설정된 숫자(초·분)가 0일 때는 '0000' 표시
            case (digit_sel)
                2'd0: bcd = digit_1;
                2'd1: bcd = digit_10;
                2'd2: bcd = digit_100;
                2'd3: bcd = digit_1000;
            endcase
            case (bcd)
                4'd0: seg = 7'b1000000;
                4'd1: seg = 7'b1111001;
                4'd2: seg = 7'b0100100;
                4'd3: seg = 7'b0110000;
                4'd4: seg = 7'b0011001;
                4'd5: seg = 7'b0010010;
                4'd6: seg = 7'b0000010;
                4'd7: seg = 7'b1111000;
                4'd8: seg = 7'b0000000;
                4'd9: seg = 7'b0010000;
                default: seg = 7'b1000000;
            endcase
        end
    end

endmodule
