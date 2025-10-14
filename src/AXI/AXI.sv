//////////////////////////////////////////////////////////////////////
//          ██╗       ██████╗   ██╗  ██╗    ██████╗            		//
//          ██║       ██╔══█║   ██║  ██║    ██╔══█║            		//
//          ██║       ██████║   ███████║    ██████║            		//
//          ██║       ██╔═══╝   ██╔══██║    ██╔═══╝            		//
//          ███████╗  ██║  	    ██║  ██║    ██║  	           		//
//          ╚══════╝  ╚═╝  	    ╚═╝  ╚═╝    ╚═╝  	           		//
//                                                             		//
// 	2024 Advanced VLSI System Design, advisor: Lih-Yih, Chiou		//
//                                                             		//
//////////////////////////////////////////////////////////////////////
//                                                             		//
// 	Author:			TZUNG-JIN, TSAI (Leo)				  	   		//
//	Filename:		AXI.sv			                            	//
//	Description:	Top module of AXI interconnect (AXI 總線主模組)
// 	Version:		1.0	    								   		//
//////////////////////////////////////////////////////////////////////
`include "AXI_define.svh"  // 引入 AXI 介面參數定義 (ID, ADDR, DATA 位寬等)
/*
`define AXI_ID_BITS 4
`define AXI_IDS_BITS 8
`define AXI_ADDR_BITS 32
`define AXI_LEN_BITS 4
`define AXI_SIZE_BITS 3
`define AXI_DATA_BITS 32
`define AXI_STRB_BITS 4
`define AXI_LEN_ONE 4'h0
`define AXI_SIZE_BYTE 3'b000
`define AXI_SIZE_HWORD 3'b001
`define AXI_SIZE_WORD 3'b010
`define AXI_BURST_INC 2'h1
`define AXI_STRB_WORD 4'b1111
`define AXI_STRB_HWORD 4'b0011
`define AXI_STRB_BYTE 4'b0001
`define AXI_RESP_OKAY 2'h0
`define AXI_RESP_SLVERR 2'h2
`define AXI_RESP_DECERR 2'h3
*/

module AXI(
	input ACLK,               // AXI global clock (AXI 全域時脈)
	input ARESETn,            // AXI active-low reset (低態有效重置信號)

	// ============================================================
	// SLAVE INTERFACE FOR MASTERS (主端訪問從端介面)
	// Each master (M0, M1) communicates through these slave interfaces
	// 每個 Master (M0, M1) 都透過下列介面與 AXI 匯流排互動
	// ============================================================

	// ---------------------------
	// WRITE ADDRESS CHANNEL
	// ---------------------------
	input [`AXI_ID_BITS-1:0]   AWID_M1,     // Write transaction ID (寫入事務 ID)
	input [`AXI_ADDR_BITS-1:0] AWADDR_M1,   // Write address (寫入位址)
	input [`AXI_LEN_BITS-1:0]  AWLEN_M1,    // Burst length (突發長度)
	input [`AXI_SIZE_BITS-1:0] AWSIZE_M1,   // Burst size (每次傳輸的資料寬度)
	input [1:0]                AWBURST_M1,  // Burst type (突發型態, e.g. INCR/FIXED)
	input                      AWVALID_M1,  // Address valid (位址有效)
	output logic               AWREADY_M1,  // Address ready (位址就緒, 從端已接收)

	// ---------------------------
	// WRITE DATA CHANNEL
	// ---------------------------
	input [`AXI_DATA_BITS-1:0] WDATA_M1,    // Write data (寫入資料)
	input [`AXI_STRB_BITS-1:0] WSTRB_M1,    // Write strobes (寫入遮罩)
	input                      WLAST_M1,    // Last beat indicator (最後一筆資料)
	input                      WVALID_M1,   // Write data valid (資料有效)
	output logic               WREADY_M1,   // Write data ready (資料就緒)

	// ---------------------------
	// WRITE RESPONSE CHANNEL
	// ---------------------------
	output logic [`AXI_ID_BITS-1:0] BID_M1,  // Response ID (回應對應 ID)
	output logic [1:0]              BRESP_M1,// Response status (回應狀態: OKAY/SLVERR)
	output logic                    BVALID_M1,// Response valid (回應有效)
	input                           BREADY_M1,// Response ready (主端就緒, 可接收回應)

	// ---------------------------
	// READ ADDRESS CHANNEL (MASTER 0)
	// ---------------------------
	input [`AXI_ID_BITS-1:0]   ARID_M0,     // Read transaction ID (讀取事務 ID)
	input [`AXI_ADDR_BITS-1:0] ARADDR_M0,   // Read address (讀取位址)
	input [`AXI_LEN_BITS-1:0]  ARLEN_M0,    // Burst length (突發長度)
	input [`AXI_SIZE_BITS-1:0] ARSIZE_M0,   // Burst size (每次傳輸大小)
	input [1:0]                ARBURST_M0,  // Burst type (突發型態)
	input                      ARVALID_M0,  // Read address valid (位址有效)
	output logic               ARREADY_M0,  // Read address ready (位址就緒)

	// ---------------------------
	// READ DATA CHANNEL (MASTER 0)
	// ---------------------------
	output logic [`AXI_ID_BITS-1:0] RID_M0,  // Read response ID (回傳 ID)
	output logic [`AXI_DATA_BITS-1:0] RDATA_M0, // Read data (讀出資料)
	output logic [1:0]              RRESP_M0,  // Read response code (回應代碼)
	output logic                    RLAST_M0,  // Last data beat (最後一筆)
	output logic                    RVALID_M0, // Read valid (讀取有效)
	input                           RREADY_M0, // Read ready (主端可接收資料)

	// ---------------------------
	// READ ADDRESS CHANNEL (MASTER 1)
	// ---------------------------
	input [`AXI_ID_BITS-1:0]   ARID_M1,     // Read transaction ID (讀取事務 ID)
	input [`AXI_ADDR_BITS-1:0] ARADDR_M1,   // Read address (讀取位址)
	input [`AXI_LEN_BITS-1:0]  ARLEN_M1,    // Burst length (突發長度)
	input [`AXI_SIZE_BITS-1:0] ARSIZE_M1,   // Burst size (每次傳輸大小)
	input [1:0]                ARBURST_M1,  // Burst type (突發型態)
	input                      ARVALID_M1,  // Read address valid (位址有效)
	output logic               ARREADY_M1,  // Read address ready (位址就緒)

	// ---------------------------
	// READ DATA CHANNEL (MASTER 1)
	// ---------------------------
	output logic [`AXI_ID_BITS-1:0] RID_M1,   // Read response ID (回傳 ID)
	output logic [`AXI_DATA_BITS-1:0] RDATA_M1,// Read data (讀出資料)
	output logic [1:0]              RRESP_M1, // Read response code (回應代碼)
	output logic                    RLAST_M1, // Last beat indicator (最後一筆資料)
	output logic                    RVALID_M1,// Read valid (讀取有效)
	input                           RREADY_M1,// Read ready (主端可接收)

	// ============================================================
	// MASTER INTERFACE FOR SLAVES (連接各個從端的主端介面)
	// Each slave S0, S1 connects to AXI interconnect as target
	// 每個從端 (S0, S1) 由此處 AXI 主介面連接
	// ============================================================

	// ---------------------------
	// WRITE ADDRESS CHANNEL (SLAVE 0)
	// ---------------------------
	output logic [`AXI_IDS_BITS-1:0] AWID_S0,   // Write transaction ID to slave (寫入事務 ID)
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S0, // Write address (寫入位址)
	output logic [`AXI_LEN_BITS-1:0]  AWLEN_S0,  // Burst length (突發長度)
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S0, // Burst size (突發寬度)
	output logic [1:0]                AWBURST_S0,// Burst type (突發型態)
	output logic                      AWVALID_S0,// Address valid (位址有效)
	input                             AWREADY_S0,// Address ready (從端就緒)

	// ---------------------------
	// WRITE DATA CHANNEL (SLAVE 0)
	// ---------------------------
	output logic [`AXI_DATA_BITS-1:0] WDATA_S0,  // Write data (寫入資料)
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S0,  // Write strobes (資料遮罩)
	output logic                      WLAST_S0,  // Last data (最後一筆)
	output logic                      WVALID_S0, // Write data valid (資料有效)
	input                             WREADY_S0, // Write ready (從端可接收)

	// ---------------------------
	// WRITE RESPONSE CHANNEL (SLAVE 0)
	// ---------------------------
	input [`AXI_IDS_BITS-1:0] BID_S0,   // Response ID (回應 ID)
	input [1:0]              BRESP_S0,  // Write response (回應狀態)
	input                    BVALID_S0, // Response valid (回應有效)
	output logic             BREADY_S0, // Response ready (主端可接收)

	
		// ---------------------------
	// WRITE ADDRESS CHANNEL (SLAVE 1)
	// ---------------------------
	output logic [`AXI_IDS_BITS-1:0] AWID_S1,   // Write transaction ID to slave1 (寫入事務 ID)
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S1, // Write address (寫入位址)
	output logic [`AXI_LEN_BITS-1:0]  AWLEN_S1,  // Burst length (突發長度)
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S1, // Burst size (突發寬度)
	output logic [1:0]                AWBURST_S1,// Burst type (突發型態)
	output logic                      AWVALID_S1,// Address valid (位址有效)
	input                             AWREADY_S1,// Address ready (從端就緒)

	// ---------------------------
	// WRITE DATA CHANNEL (SLAVE 1)
	// ---------------------------
	output logic [`AXI_DATA_BITS-1:0] WDATA_S1,  // Write data (寫入資料)
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S1,  // Write strobes (資料遮罩)
	output logic                      WLAST_S1,  // Last beat indicator (最後一筆)
	output logic                      WVALID_S1, // Write data valid (資料有效)
	input                             WREADY_S1, // Write ready (從端可接收)

	// ---------------------------
	// WRITE RESPONSE CHANNEL (SLAVE 1)
	// ---------------------------
	input [`AXI_IDS_BITS-1:0] BID_S1,   // Write response ID (回應 ID)
	input [1:0]              BRESP_S1,  // Write response (回應狀態)
	input                    BVALID_S1, // Response valid (回應有效)
	output logic             BREADY_S1, // Response ready (主端可接收)

	// ---------------------------
	// READ ADDRESS CHANNEL (SLAVE 0)
	// ---------------------------
	output logic [`AXI_IDS_BITS-1:0] ARID_S0,    // Read transaction ID (讀取事務 ID)
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S0, // Read address (讀取位址)
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_S0,  // Burst length (突發長度)
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S0, // Burst size (突發寬度)
	output logic [1:0]                ARBURST_S0,// Burst type (突發型態)
	output logic                      ARVALID_S0,// Read address valid (位址有效)
	input                             ARREADY_S0,// Read address ready (從端就緒)

	// ---------------------------
	// READ DATA CHANNEL (SLAVE 0)
	// ---------------------------
	input [`AXI_IDS_BITS-1:0] RID_S0,   // Read response ID (回應 ID)
	input [`AXI_DATA_BITS-1:0] RDATA_S0,// Read data (讀出資料)
	input [1:0]                RRESP_S0,// Read response code (回應代碼)
	input                      RLAST_S0,// Last beat indicator (最後一筆)
	input                      RVALID_S0,// Read data valid (資料有效)
	output logic               RREADY_S0,// Read ready (主端可接收)

	// ---------------------------
	// READ ADDRESS CHANNEL (SLAVE 1)
	// ---------------------------
	output logic [`AXI_IDS_BITS-1:0] ARID_S1,    // Read transaction ID (讀取事務 ID)
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S1, // Read address (讀取位址)
	output logic [`AXI_LEN_BITS-1:0]  ARLEN_S1,  // Burst length (突發長度)
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S1, // Burst size (突發寬度)
	output logic [1:0]                ARBURST_S1,// Burst type (突發型態)
	output logic                      ARVALID_S1,// Read address valid (位址有效)
	input                             ARREADY_S1,// Read address ready (從端就緒)

	// ---------------------------
	// READ DATA CHANNEL (SLAVE 1)
	// ---------------------------
	input [`AXI_IDS_BITS-1:0] RID_S1,   // Read response ID (回應 ID)
	input [`AXI_DATA_BITS-1:0] RDATA_S1,// Read data (讀出資料)
	input [1:0]                RRESP_S1,// Read response code (回應代碼)
	input                      RLAST_S1,// Last beat indicator (最後一筆)
	input                      RVALID_S1,// Read data valid (資料有效)
	output logic               RREADY_S1 // Read ready (主端可接收)
);

	// ================================================================
	// Internal signal declaration (內部訊號宣告區)
	// These control master/slave selection and read/write FSM states
	// 用於控制主從端選擇與讀寫狀態機運作
	// ================================================================

	logic pre_rmaster_r;               // Previous read master selection (前一次讀取主端選擇)
	logic rmaster_sel;                 // Current read master selector (當前讀取主端選擇)
	logic rmaster_dat_sel;             // Data-phase read master select (資料階段主端選擇)
	logic [1:0] rslave_sel;            // Current read slave select (當前讀取從端選擇)
	logic [1:0] rslave_dat_sel;        // Data-phase read slave select (資料階段從端選擇)
	logic cs, ns;                      // FSM states for read channel (讀取通道狀態機: current / next)
	logic cs_w, ns_w;                  // FSM states for write channel (寫入通道狀態機: current / next)
	logic cs_0, cs_1, ns_0, ns_1;      // Unused placeholders for sub-FSMs (預留變數)
	logic [1:0] wslave_sel;            // Write slave selection (寫入從端選擇)
	logic [1:0] wslave_dat_sel;        // Data-phase write slave select (資料階段從端選擇)

	// Registers for capturing read address channel information (暫存主端讀取命令)
	logic [`AXI_ID_BITS-1:0]   ARID_M0_reg;
	logic [`AXI_ADDR_BITS-1:0] ARADDR_M0_reg;
	logic [`AXI_LEN_BITS-1:0]  ARLEN_M0_reg;
	logic [`AXI_SIZE_BITS-1:0] ARSIZE_M0_reg;
	logic [1:0]                ARBURST_M0_reg;
	logic                      ARVALID_M0_reg;
	logic                      ARREADY_S0_reg, ARREADY_S1_reg;

	logic [`AXI_ID_BITS-1:0]   ARID_M1_reg;
	logic [`AXI_ADDR_BITS-1:0] ARADDR_M1_reg;
	logic [`AXI_LEN_BITS-1:0]  ARLEN_M1_reg;
	logic [`AXI_SIZE_BITS-1:0] ARSIZE_M1_reg;
	logic [1:0]                ARBURST_M1_reg;
	logic                      ARVALID_M1_reg;

	// ================================================================
	// Read / Write state machine (讀寫狀態機)
	// Handles transaction control between masters and slaves
	// 管理主從端之間的傳輸握手與仲裁
	// ================================================================
	always_ff @(posedge ACLK or negedge ARESETn) begin
		if (!ARESETn) begin
			cs   <= 1'b0;   // Reset read-FSM state (重設讀取狀態機)
			cs_w <= 1'b0;   // Reset write-FSM state (重設寫入狀態機)
		end else begin
			cs   <= ns;     // Update read FSM to next state (更新至下一狀態)
			cs_w <= ns_w;   // Update write FSM to next state (更新至下一狀態)
		end
	end

	// ================================================================
	// FSM Next-State Logic (讀寫狀態機次狀態判斷)
	// ------------------------------------------------
	// Controls transaction flow:
	//   - Read FSM (cs/ns) handles AR/R channels
	//   - Write FSM (cs_w/ns_w) handles AW/W/B channels
	// ================================================================
	always_comb begin
		// -----------------------------
		// Read channel FSM (讀取通道)
		// -----------------------------
		case(cs)
			1'b0 : begin
				// Idle state → check if any master starts read
				// 閒置狀態：檢查是否有 master 發出讀取要求
				ns = (ARVALID_M0 || ARVALID_M1);
			end
			1'b1 : begin
				// Busy state → wait until last data transferred
				// 工作狀態：等待資料傳輸完成
				ns = ~(
					((!rmaster_dat_sel) && RREADY_M0 && RVALID_M0 && RLAST_M0) || 
					(RLAST_M1 && RREADY_M1 && RVALID_M1 && rmaster_dat_sel)
				);
			end
		endcase

		// -----------------------------
		// Write channel FSM (寫入通道)
		// -----------------------------
		case(cs_w)
			1'b0 : begin
				// Idle → start when AW handshake occurs
				// 閒置狀態：AWVALID/AWREADY 為高時啟動
				ns_w = (AWVALID_M1 && AWREADY_M1);
			end 
			1'b1 : begin
				// Busy → stay until write response accepted
				// 工作狀態：等待 BVALID/BREADY 完成
				ns_w = ~(BREADY_M1 && BVALID_M1);
			end
		endcase
	end

	// ================================================================
	// Read Master Selection (讀取主端選擇)
	// ------------------------------------------------
	// Arbitrates between M0 / M1 read requests
	// 在多個 master 之間進行仲裁 (取交替或固定優先順序)
	// ================================================================
	always_comb begin : master_select
		case(cs)
			1'b0 : begin
				case({ARVALID_M0, ARVALID_M1})
					2'b11 : rmaster_sel = ~pre_rmaster_r; // Alternate if both valid (雙方同時要求則交替)
					2'b10 : rmaster_sel = 1'b0;           // Only M0 active
					2'b01 : rmaster_sel = 1'b1;           // Only M1 active
					2'b00 : rmaster_sel = pre_rmaster_r;  // No request → hold previous
				endcase
			end 
			1'b1 : begin
				// During data phase, hold previous master
				// 資料傳輸期間維持原主端選擇
				rmaster_sel = pre_rmaster_r;
			end 
		endcase
	end

	// ================================================================
	// Read Slave Selection (讀取從端選擇邏輯)
	// ------------------------------------------------
	// Determine which slave (S0 / S1) is targeted based on address
	// 依據地址範圍決定目標從端 (地址高 16 位 = 0000 或 0001)
	// ================================================================
	always_comb begin
		case(cs)
			1'b0 : begin			
				// During address phase (位址階段)
				if ((rmaster_sel && ARVALID_M1) && (ARADDR_M1[31:16] == 16'h0000 || ARADDR_M1[31:16] == 16'h0001)) begin
					rslave_sel = ARADDR_M1[17:16]; // Select slave by addr[17:16]
				end else if ((!rmaster_sel) && ARVALID_M0 && (ARADDR_M0[31:16] == 16'h0000 || ARADDR_M0[31:16] == 16'h0001)) begin
					rslave_sel = ARADDR_M0[17:16];
				end else begin
					rslave_sel = 2'd2; // invalid / unmapped region (無效地址)
				end
			end
			1'b1 : begin
				// During data phase (資料階段)
				if ((rmaster_dat_sel && ARVALID_M1) && (ARADDR_M1[31:16] == 16'h0000 || ARADDR_M1[31:16] == 16'h0001)) begin
					rslave_sel = ARADDR_M1[17:16];
				end else if ((!rmaster_dat_sel) && ARVALID_M0 && (ARADDR_M0[31:16] == 16'h0000 || ARADDR_M0[31:16] == 16'h0001)) begin
					rslave_sel = ARADDR_M0[17:16];
				end else begin
					rslave_sel = 2'd2; // invalid / unmapped region
				end
			end
		endcase

		// ============================================================
		// Write Slave Selection (寫入從端選擇邏輯)
		// Determine target slave based on AWADDR[17:16]
		// ============================================================
		if (AWVALID_M1 && (AWADDR_M1[31:16] == 16'h0000 || AWADDR_M1[31:16] == 16'h0001)) begin
			wslave_sel = AWADDR_M1[17:16];
		end else begin
			wslave_sel = 2'd2; // invalid / unmapped
		end
	end

	// ================================================================
	// Register Pipeline for Selection Signals (寄存器管線暫存)
	// ------------------------------------------------
	// Keeps track of which master/slave is active across phases
	// 保存讀寫主從端的選擇狀態 (交握時鎖存)
	// ================================================================
	always_ff @(posedge ACLK or negedge ARESETn) begin
		if (!ARESETn) begin
			pre_rmaster_r   <= 1'b0;   // Previous read master (初始化)
			rslave_dat_sel  <= 2'd0;   // Latched slave ID (讀取資料階段從端)
			rmaster_dat_sel <= 1'b0;   // Latched read master (讀取資料階段主端)
			wslave_dat_sel  <= 2'd0;   // Latched write slave (寫入資料階段從端)
		end else begin
			case(cs)
				1'b0 : begin
					// Latch selections when read starts (當讀取開始時鎖存選擇)
					if (ARVALID_M0 || ARVALID_M1) begin
						rslave_dat_sel  <= rslave_sel;
						rmaster_dat_sel <= rmaster_sel;
					end 
				end
				1'b1 : begin
					// After transfer complete, store last master as previous
					// 傳輸結束後記錄上一次的主端
					pre_rmaster_r <= rmaster_sel;
				end
			endcase

			// Latch write slave during AW phase (鎖存寫入從端)
			if (AWVALID_M1)
				wslave_dat_sel <= wslave_sel;
			else
				wslave_dat_sel <= wslave_dat_sel;
		end
	end



	// ================================================================
	// Read Channel Routing (讀取通道路由邏輯)
	// ------------------------------------------------
	// Connects AR/R channels between masters and slaves
	// 根據選擇信號動態連線 master 與 slave 的 AR/R 通道
	// ================================================================
	always_comb begin
		case(cs)
		// ------------------------------------------------------------
		// Address phase (位址階段)
		// ------------------------------------------------------------
		1'b0 : begin
			// ========== Master0 → Slave1 ==========
			if (rslave_sel == 2'd1 && (!rmaster_sel)) begin
				// connect M0 read to S1
				ARID_S0     = 8'd0;
				ARADDR_S0   = 32'd0;
				ARLEN_S0    = 4'd0;
				ARSIZE_S0   = 3'd0;
				ARBURST_S0  = 2'd0;
				ARVALID_S0  = 1'b0;
				ARREADY_M1  = 1'b0;

				ARID_S1     = {4'd0, ARID_M0};
				ARADDR_S1   = ARADDR_M0;
				ARLEN_S1    = ARLEN_M0;
				ARSIZE_S1   = ARSIZE_M0;
				ARBURST_S1  = ARBURST_M0;
				ARVALID_S1  = ARVALID_M0;
				ARREADY_M0  = ARREADY_S1; // handshake pass-through
			end 
			// ========== Master1 → Slave1 ==========
			else if (rslave_sel == 2'd1 && rmaster_sel) begin
				ARID_S0     = 8'd0;
				ARADDR_S0   = 32'd0;
				ARLEN_S0    = 4'd0;
				ARSIZE_S0   = 3'd0;
				ARBURST_S0  = 2'd0;
				ARVALID_S0  = 1'b0;
				ARREADY_M0  = 1'b0;

				ARID_S1     = {4'd0, ARID_M1};
				ARADDR_S1   = ARADDR_M1;
				ARLEN_S1    = ARLEN_M1;
				ARSIZE_S1   = ARSIZE_M1;
				ARBURST_S1  = ARBURST_M1;
				ARVALID_S1  = ARVALID_M1;
				ARREADY_M1  = ARREADY_S1;
			end 
			// ========== Master1 → Slave0 ==========
			else if (rslave_sel == 2'd0 && rmaster_sel) begin
				ARID_S0     = {4'd0, ARID_M1};
				ARADDR_S0   = ARADDR_M1;
				ARLEN_S0    = ARLEN_M1;
				ARSIZE_S0   = ARSIZE_M1;
				ARBURST_S0  = ARBURST_M1;
				ARVALID_S0  = ARVALID_M1;
				ARREADY_M0  = 1'b0;

				ARID_S1     = 8'd0;
				ARADDR_S1   = 32'd0;
				ARLEN_S1    = 4'd0;
				ARSIZE_S1   = 3'd0;
				ARBURST_S1  = 2'd0;
				ARVALID_S1  = 1'b0;
				ARREADY_M1  = ARREADY_S0;
			end 
			// ========== Master0 → Slave0 ==========
			else if (rslave_sel == 2'd0 && (!rmaster_sel)) begin
				ARID_S0     = {4'd0, ARID_M0};
				ARADDR_S0   = ARADDR_M0;
				ARLEN_S0    = ARLEN_M0;
				ARSIZE_S0   = ARSIZE_M0;
				ARBURST_S0  = ARBURST_M0;
				ARVALID_S0  = ARVALID_M0;
				ARREADY_M0  = ARREADY_S0;

				ARID_S1     = 8'd0;
				ARADDR_S1   = 32'd0;
				ARLEN_S1    = 4'd0;
				ARSIZE_S1   = 3'd0;
				ARBURST_S1  = 2'd0;
				ARVALID_S1  = 1'b0;
				ARREADY_M1  = 1'b0;
			end 
			// ========== No valid transaction ==========
			else begin
				// Default all signals to zero to avoid X propagation (避免未知值)
				ARID_S0     = 8'd0;
				ARADDR_S0   = 32'd0;
				ARLEN_S0    = 4'd0;
				ARSIZE_S0   = 3'd0;
				ARBURST_S0  = 2'd0;
				ARVALID_S0  = 1'b0;
				ARREADY_M0  = 1'b0;
				ARID_S1     = 8'd0;
				ARADDR_S1   = 32'd0;
				ARLEN_S1    = 4'd0;
				ARSIZE_S1   = 3'd0;
				ARBURST_S1  = 2'd0;
				ARVALID_S1  = 1'b0;
				ARREADY_M1  = 1'b0;
			end

			// ------------------------------
			// Default read data/reset values
			// ------------------------------
			RID_M0   = 4'd0;   // no response
			RDATA_M0 = 32'd0;
			RRESP_M0 = 2'd0;
			RLAST_M0 = 1'b0;
			RVALID_M0= 1'b0;
			RREADY_S0= 1'b0;

			RID_M1   = 4'd0;
			RDATA_M1 = 32'd0;
			RRESP_M1 = 2'd0;
			RLAST_M1 = 1'b0;
			RVALID_M1= 1'b0;
			RREADY_S1= 1'b0;
		end

		// ------------------------------------------------------------
		// Data phase (資料階段)
		// ------------------------------------------------------------
		1'b1 : begin
			// ========== Master0 ← Slave1 ==========
			if (rslave_dat_sel == 2'd1 && (!rmaster_dat_sel)) begin
				ARID_S0     = 8'd0;
				ARADDR_S0   = 32'd0;
				ARLEN_S0    = 4'd0;
				ARSIZE_S0   = 3'd0;
				ARBURST_S0  = 2'd0;
				ARVALID_S0  = 1'b0;
				ARREADY_M1  = 1'b0;

				ARID_S1     = {4'd0, ARID_M0};
				ARADDR_S1   = ARADDR_M0;
				ARLEN_S1    = ARLEN_M0;
				ARSIZE_S1   = ARSIZE_M0;
				ARBURST_S1  = ARBURST_M0;
				ARVALID_S1  = ARVALID_M0;
				ARREADY_M0  = ARREADY_S1;

				// Route data back to Master0 from Slave1
				RID_M0      = RID_S1[3:0];
				RDATA_M0    = RDATA_S1;
				RRESP_M0    = RRESP_S1;
				RLAST_M0    = RLAST_S1;
				RVALID_M0   = RVALID_S1;
				RREADY_S1   = RREADY_M0;

				RID_M1      = 4'd0;
				RDATA_M1    = 32'd0;
				RRESP_M1    = 2'd0;
				RLAST_M1    = 1'b0;
				RVALID_M1   = 1'b0;
				RREADY_S0   = 1'b0;
			end 
			// ========== Master1 ← Slave1 ==========
			else if (rslave_dat_sel == 2'd1 && rmaster_dat_sel) begin
				ARID_S0     = 8'd0;
				ARADDR_S0   = 32'd0;
				ARLEN_S0    = 4'd0;
				ARSIZE_S0   = 3'd0;
				ARBURST_S0  = 2'd0;
				ARVALID_S0  = 1'b0;
				ARREADY_M0  = 1'b0;

				ARID_S1     = {4'd0, ARID_M1};
				ARADDR_S1   = ARADDR_M1;
				ARLEN_S1    = ARLEN_M1;
				ARSIZE_S1   = ARSIZE_M1;
				ARBURST_S1  = ARBURST_M1;
				ARVALID_S1  = ARVALID_M1;
				ARREADY_M1  = ARREADY_S1;

				RID_M0      = 4'd0;
				RDATA_M0    = 32'd0;
				RRESP_M0    = 2'd0;
				RLAST_M0    = 1'b0;
				RVALID_M0   = 1'b0;
				RREADY_S0   = 1'b0;

				RID_M1      = RID_S1[3:0];
				RDATA_M1    = RDATA_S1;
				RRESP_M1    = RRESP_S1;
				RLAST_M1    = RLAST_S1;
				RVALID_M1   = RVALID_S1;
				RREADY_S1   = RREADY_M1;
			end 
				// ========== Master1 ← Slave0 ==========
			else if (rslave_dat_sel == 2'd0 && rmaster_dat_sel) begin
				ARID_S0     = {4'd0, ARID_M1};
				ARADDR_S0   = ARADDR_M1;
				ARLEN_S0    = ARLEN_M1;
				ARSIZE_S0   = ARSIZE_M1;
				ARBURST_S0  = ARBURST_M1;
				ARVALID_S0  = ARVALID_M1;
				ARREADY_M0  = 1'b0;

				ARID_S1     = 8'd0;
				ARADDR_S1   = 32'd0;
				ARLEN_S1    = 4'd0;
				ARSIZE_S1   = 3'd0;
				ARBURST_S1  = 2'd0;
				ARVALID_S1  = 1'b0;
				ARREADY_M1  = ARREADY_S0;

				// Route data back to Master1 from Slave0
				RID_M0      = 4'd0;
				RDATA_M0    = 32'd0;
				RRESP_M0    = 2'd0;
				RLAST_M0    = 1'b0;
				RVALID_M0   = 1'b0;
				RREADY_S1   = 1'b0;

				RID_M1      = RID_S0[3:0];
				RDATA_M1    = RDATA_S0;
				RRESP_M1    = RRESP_S0;
				RLAST_M1    = RLAST_S0;
				RVALID_M1   = RVALID_S0;
				RREADY_S0   = RREADY_M1;
			end 
			// ========== Master0 ← Slave0 ==========
			else if (rslave_dat_sel == 2'd0 && (!rmaster_dat_sel)) begin
				ARID_S0     = {4'd0, ARID_M0};
				ARADDR_S0   = ARADDR_M0;
				ARLEN_S0    = ARLEN_M0;
				ARSIZE_S0   = ARSIZE_M0;
				ARBURST_S0  = ARBURST_M0;
				ARVALID_S0  = ARVALID_M0;
				ARREADY_M0  = ARREADY_S0;

				ARID_S1     = 8'd0;
				ARADDR_S1   = 32'd0;
				ARLEN_S1    = 4'd0;
				ARSIZE_S1   = 3'd0;
				ARBURST_S1  = 2'd0;
				ARVALID_S1  = 1'b0;
				ARREADY_M1  = 1'b0;

				// Route data back to Master0 from Slave0
				RID_M0      = RID_S0[3:0];
				RDATA_M0    = RDATA_S0;
				RRESP_M0    = RRESP_S0;
				RLAST_M0    = RLAST_S0;
				RVALID_M0   = RVALID_S0;
				RREADY_S0   = RREADY_M0;

				RID_M1      = 4'd0;
				RDATA_M1    = 32'd0;
				RRESP_M1    = 2'd0;
				RLAST_M1    = 1'b0;
				RVALID_M1   = 1'b0;
				RREADY_S1   = 1'b0;
			end 
			// ========== Invalid or unmapped case ==========
			else begin
				// Fallback: no valid connection (無效交易)
				ARID_S0     = 8'd0;  ARADDR_S0 = 32'd0; ARLEN_S0 = 4'd0;
				ARSIZE_S0   = 3'd0;  ARBURST_S0= 2'd0;  ARVALID_S0= 1'b0; ARREADY_M0=1'b0;
				ARID_S1     = 8'd0;  ARADDR_S1 = 32'd0; ARLEN_S1 = 4'd0;
				ARSIZE_S1   = 3'd0;  ARBURST_S1= 2'd0;  ARVALID_S1= 1'b0; ARREADY_M1=1'b0;

				// send “slave error” responses
				RID_M0      = 4'd0;  RDATA_M0 = 32'd0; RRESP_M0 = 2'b11; RLAST_M0=1'b0; RVALID_M0=1'b0; RREADY_S0=1'b0;
				RID_M1      = 4'd0;  RDATA_M1 = 32'd0; RRESP_M1 = 2'b11; RLAST_M1=1'b0; RVALID_M1=1'b0; RREADY_S1=1'b0;
			end
		end
	end

	// ================================================================
	// Write Channel Routing (寫入通道路由邏輯)
	// ------------------------------------------------
	// Connects AW/W/B channels between Master1 and Slaves
	// Master 1 為唯一寫入來源，依 AWADDR 決定 S0 或 S1 目標
	// ================================================================
	always_comb begin
		case(cs_w)
		// ------------------------------------------------------------
		// Address phase (位址階段)
		// ------------------------------------------------------------
		1'b0 : begin
			// ------------------------------
			// AW: Address routing
			// ------------------------------
			if (wslave_sel == 2'd1) begin
				// write → Slave 1
				AWID_S1    = {4'd0, AWID_M1};
				AWADDR_S1  = AWADDR_M1;
				AWLEN_S1   = AWLEN_M1;
				AWSIZE_S1  = AWSIZE_M1;
				AWBURST_S1 = AWBURST_M1;
				AWVALID_S1 = AWVALID_M1;
				AWREADY_M1 = AWREADY_S1;

				AWID_S0    = 8'd0; AWADDR_S0=32'd0; AWLEN_S0=4'd0;
				AWSIZE_S0  = 3'd0; AWBURST_S0=2'd0; AWVALID_S0=1'b0;
			end else if (wslave_sel == 2'd0) begin
				// write → Slave 0
				AWID_S0    = {4'd0, AWID_M1};
				AWADDR_S0  = AWADDR_M1;
				AWLEN_S0   = AWLEN_M1;
				AWSIZE_S0  = AWSIZE_M1;
				AWBURST_S0 = AWBURST_M1;
				AWVALID_S0 = AWVALID_M1;
				AWREADY_M1 = AWREADY_S0;

				AWID_S1    = 8'd0; 
				AWADDR_S1=32'd0; 
				AWLEN_S1=4'd0;
				AWSIZE_S1  = 3'd0; 
				AWBURST_S1=2'd0; 
				AWVALID_S1=1'b0;
			end else begin
				// no valid target (無效目標)
				AWID_S1=8'd0;
				AWADDR_S1=32'd0;
				AWLEN_S1=4'd0;
				AWSIZE_S1=3'd0;
				AWBURST_S1=2'd0;
				AWVALID_S1=1'b0;
				AWID_S0=8'd0;
				AWADDR_S0=32'd0;
				AWLEN_S0=4'd0;
				AWSIZE_S0=3'd0;
				AWBURST_S0=2'd0;
				AWVALID_S0=1'b0;
				AWREADY_M1 = 1'b0;
			end

			// ------------------------------
			// W: Write data routing
			// ------------------------------
			if (AWVALID_M1 && AWREADY_M1 && (wslave_sel == 2'd0)) begin
				WDATA_S0 = WDATA_M1;
				WLAST_S0 = WLAST_M1;
				WVALID_S0 = WVALID_M1;
				WREADY_M1 = WREADY_S0;
				WSTRB_S0 = WSTRB_M1;
				WDATA_S1 = 32'd0;
				WLAST_S1 = 1'b0;
				WVALID_S1 = 1'b0;
				WSTRB_S1 = 4'd0;
			end else if (AWVALID_M1 && AWREADY_M1 && (wslave_sel == 2'd1)) begin
				WDATA_S1 = WDATA_M1;
				WLAST_S1 = WLAST_M1;
				WVALID_S1 = WVALID_M1;
				WREADY_M1 = WREADY_S1;
				WSTRB_S1 = WSTRB_M1;
				WSTRB_S0 = 4'd0;
				WDATA_S0 = 32'd0;
				WLAST_S0 = 1'b0;
				WVALID_S0 = 1'b0;
			end else begin
				// default zero when idle
				WDATA_S1=32'd0;
				WLAST_S1=1'b0;
				WVALID_S1=1'b0;
				WDATA_S0=32'd0;
				WLAST_S0=1'b0;
				WVALID_S0=1'b0;
				WREADY_M1=1'b0;
				WSTRB_S0=4'd0;
				WSTRB_S1=4'd0;
			end

			// No response yet in address phase
			BREADY_S0 = 1'b0; BREADY_S1 = 1'b0;
			BID_M1 = 4'd0; BRESP_M1 = 2'd0; BVALID_M1 = 1'b0;
		end

		// ------------------------------------------------------------
		// Data / Response phase (資料與回應階段)
		// ------------------------------------------------------------
		1'b1 : begin
			if (wslave_dat_sel == 2'd0) begin
				// write to S0
				WDATA_S0 = WDATA_M1;
				WLAST_S0 = WLAST_M1;
				WVALID_S0 = WVALID_M1;
				WREADY_M1 = WREADY_S0;
				WSTRB_S0 = WSTRB_M1;
				WDATA_S1 = 32'd0;
				WLAST_S1=1'b0;
				WVALID_S1=1'b0;
				WSTRB_S1=4'd0;

				// handle response
				BREADY_S1 = 1'b0;
				BREADY_S0 = BREADY_M1;
				BID_M1 = BID_S0[3:0];
				BRESP_M1 = BRESP_S0;
				BVALID_M1 = BVALID_S0;

				// re-drive AW signals for timing alignment
				AWID_S0 = {4'd0,AWID_M1};
				AWADDR_S0 = AWADDR_M1;
				AWLEN_S0 = AWLEN_M1;
				AWSIZE_S0 = AWSIZE_M1;
				AWBURST_S0 = AWBURST_M1;
				AWVALID_S0 = AWVALID_M1;
				AWREADY_M1 = AWREADY_S0;
				AWID_S1 = 8'd0;
				AWADDR_S1 = 32'd0;
				AWLEN_S1 = 4'd0;
				AWSIZE_S1 = 3'd0;
				AWBURST_S1 = 2'd0;
				AWVALID_S1 = 1'b0;
			end else if (wslave_dat_sel == 2'd1) begin
				// write to S1
				WDATA_S1 = WDATA_M1;
				WLAST_S1 = WLAST_M1;
				WVALID_S1 = WVALID_M1;
				WREADY_M1 = WREADY_S1;
				WSTRB_S1 = WSTRB_M1;
				WSTRB_S0 = 4'd0;
				WDATA_S0 = 32'd0;
				WLAST_S0 =1'b0;
				WVALID_S0 =1'b0;

				BREADY_S1 = BREADY_M1;
				BREADY_S0 = 1'b0;
				BID_M1 = BID_S1[3:0];
				BRESP_M1 = BRESP_S1;
				BVALID_M1 = BVALID_S1;

				AWID_S1 = {4'd0,AWID_M1};
				AWADDR_S1 = AWADDR_M1;
				AWLEN_S1 = AWLEN_M1;
				AWSIZE_S1 = AWSIZE_M1;
				AWBURST_S1 = AWBURST_M1;
				AWVALID_S1 = AWVALID_M1;
				AWREADY_M1 = AWREADY_S1;
				AWID_S0 = 8'd0;
				AWADDR_S0 = =32'd0;
				AWLEN_S0 = 4'd0;
				AWSIZE_S0 = 3'd0;
				AWBURST_S0 = 2'd0;
				AWVALID_S0 = 1'b0;
			end else begin
				// invalid case: clear outputs
				BREADY_S0 = 1'b0;
				BREADY_S1 = 1'b0;
				BID_M1 = 4'd0;
				BRESP_M1 = 2'd0;
				BVALID_M1 = 1'b0;
				WDATA_S1 = 32'd0;
				WLAST_S1 = 1'b0;
				WVALID_S1 = 1'b0;
				WREADY_M1 = 1'b0;
				WDATA_S0 = 32'd0;
				WLAST_S0 = 1'b0;
				WVALID_S0 = 1'b0;
				WSTRB_S0 = 4'd0;
				WSTRB_S1 = 4'd0;
				AWID_S1 = 8'd0;
				AWADDR_S1 = 32'd0;
				AWLEN_S1 = 4'd0;
				AWSIZE_S1 = 3'd0;
				AWBURST_S1 = 2'd0;
				AWVALID_S1 = 1'b0;
				AWID_S0 = 8'd0;
				AWADDR_S0 = 32'd0;
				AWLEN_S0 = 4'd0;
				AWSIZE_S0 = 3'd0;
				AWBURST_S0 = 2'd0;
				AWVALID_S0 = 1'b0;
				AWREADY_M1 = 1'b0;
			end
		end
	end

	endmodule
