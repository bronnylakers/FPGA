`timescale 1ns / 1ps

//-----------------------------------------------------------------------------
// clock_setting: “0000”(idle) → 분·초 설정 → start 누르면 카운트다운 → 완료 시 운영 종료
//-----------------------------------------------------------------------------
module clock_setting(
    input           i_clk,
    input           i_reset,
    input           i_btn_sec,
    input           i_btn_min,
    input           i_btn_start,
    input           s_tick,        // 1초 펄스
    output  [6:0]   sec_seg,       // FND에 뿌릴 초 단위 BCD
    output  [6:0]   min_seg,       // FND에 뿌릴 분 단위 BCD
    output  reg     operating,      // 동작 중
    output sec_evt,
    output min_evt,
    output start_evt
);

    // 내부 카운터
    reg [6:0] sec_count;
    reg [6:0] min_count;

    // 버튼 에지 검출용 이전 상태
    reg prev_btn_sec, prev_btn_min, prev_btn_start;
    wire sec_edge   = i_btn_sec   & ~prev_btn_sec;
    wire min_edge   = i_btn_min   & ~prev_btn_min;
    wire start_edge = i_btn_start & ~prev_btn_start;
    
    // 에지 신호를 외부로 뿌려주기
    assign sec_evt   = sec_edge;
    assign min_evt   = min_edge;
    assign start_evt = start_edge;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            sec_count      <= 7'd0;
            min_count      <= 7'd0;
            operating      <= 1'b0;
            prev_btn_sec   <= 1'b0;
            prev_btn_min   <= 1'b0;
            prev_btn_start <= 1'b0;
        end else begin
            // 이전 버튼 상태 갱신
            prev_btn_sec   <= i_btn_sec;
            prev_btn_min   <= i_btn_min;
            prev_btn_start <= i_btn_start;

            if (!operating) begin
                // idle 상태: 분·초 설정만
                if (sec_edge) begin
                    // 10초씩 증가, 60초 이상이면 분으로 이동
                    if (sec_count + 7'd10 >= 7'd60) begin
                        sec_count <= sec_count + 7'd10 - 7'd60;
                        min_count <= min_count + 7'd1;
                    end else
                        sec_count <= sec_count + 7'd10;
                end
                if (min_edge) begin
                    // 1분씩 증가
                    min_count <= min_count + 7'd1;
                end
                // start 누르고 시간이 0이 아닐 때만 동작 시작
                if (start_edge && (sec_count != 0 || min_count != 0)) begin
                    operating <= 1'b1;
                end
            end else begin
                // operating 상태: 1초마다 카운트다운
                if (s_tick) begin
                    if (sec_count != 0) begin
                        sec_count <= sec_count - 7'd1;
                    end else if (min_count != 0) begin
                        sec_count <= 7'd59;
                        min_count <= min_count - 7'd1;
                    end
                end
                // 분·초 모두 0이 되면 동작 종료
                if (sec_count == 0 && min_count == 0) begin
                    operating <= 1'b0;
                end
            end
        end
    end

    assign sec_seg = sec_count;
    assign min_seg = min_count;

endmodule
