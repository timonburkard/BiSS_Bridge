#include "sleep.h"
#include "xaxidma.h"
#include "xil_cache.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xuartps.h"
#include <string.h>
#include <stdio.h>


/*
 * Simple bare-metal example:
 * - Starts an S2MM (device-to-memory) DMA transfer into DDR
 * - Waits for completion (polling)
 * - Invalidates data cache for the receive buffer
 * - Sends the received bytes over the UART
 *
 * Assumptions: AXI DMA is in Simple mode, AXI stream width = 32 bits.
 */

#define DMA_DEV_ID XPAR_AXIDMA_0_DEVICE_ID
#define UART_DEV_ID XPAR_XUARTPS_0_DEVICE_ID
#define RX_BUFFER_BASE (XPAR_PS7_DDR_0_S_AXI_BASEADDR + 0x01000000)
#define TRANSFER_LEN 256 /* bytes per transfer; adjust as needed */
#define OUTPUT_PERIOD_MS 100

typedef union {
	u32 raw;
	struct {
		u32 position : 29;
		u32 crc_fail_bit : 1;
		u32 warning_bit : 1;
		u32 error_bit : 1;
	} fields;
} BissPacket;

int main(void) {
  XAxiDma AxiDma;
  XAxiDma_Config *CfgPtr;
  XUartPs Uart;
  XUartPs_Config *UartCfg;
  u8 *RxBuffer = (u8 *)RX_BUFFER_BASE;
  int Status;

  /* Enable data cache; we'll use cache maintenance around DMA buffer */
  Xil_DCacheEnable();

  /* Initialize UART */
  UartCfg = XUartPs_LookupConfig(UART_DEV_ID);
  if (!UartCfg) {
    /* Early debugger attachment point: set this to 0 from the debugger to continue */
    volatile int wait_for_debug = 1;
    printf("Started - attach debugger now if needed, then set wait_for_debug=0\r\n");
    while (wait_for_debug) {
      /* spin here until debugger clears the variable */
    }

    printf("Starting DMA->UART example\r\n");
    return XST_FAILURE;
  }
  Status = XUartPs_CfgInitialize(&Uart, UartCfg, UartCfg->BaseAddress);
  if (Status != XST_SUCCESS) {
    //xil_printf("UART init failed\r\n");
    return XST_FAILURE;
  }

  printf("Starting DMA->UART example\r\n");

  /* Initialize DMA */
  CfgPtr = XAxiDma_LookupConfig(DMA_DEV_ID);
  if (!CfgPtr) {
    printf("DMA lookup config failed\r\n");
    return XST_FAILURE;
  }
  Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
  if (Status != XST_SUCCESS) {
    printf("DMA init failed\r\n");
    return XST_FAILURE;
  }

  if (XAxiDma_HasSg(&AxiDma)) {
    printf("DMA configured in Scatter-Gather mode; example expects Simple mode\r\n");
    return XST_FAILURE;
  }

  /* print CSV header */
  printf("position, error_bit, warning_bit, crc_failed_bit");

  while (1) {
    /* Prepare buffer (optional) */
    memset(RxBuffer, 0, TRANSFER_LEN);

    /* If cache is enabled, ensure buffer is not stale in cache */
    Xil_DCacheFlushRange((UINTPTR)RxBuffer, TRANSFER_LEN);

    /* Start S2MM transfer (device -> memory) */
    Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)RxBuffer, TRANSFER_LEN,
                                    XAXIDMA_DEVICE_TO_DMA);
    if (Status != XST_SUCCESS) {
      printf("DMA transfer start failed\r\n");
      return XST_FAILURE;
    }

    /* Poll until DMA finished */
    while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA))
      ;

    /* Invalidate cache so CPU reads fresh data */
    Xil_DCacheInvalidateRange((UINTPTR)RxBuffer, TRANSFER_LEN);

    /* Process and Output Data */
    u32 *RxBuffer32 = (u32 *)RxBuffer;

    /* output the most recent packet */
    BissPacket packet;
    packet.raw = *RxBuffer32;
    /* CSV Format: position, error_bit, warning_bit, crc_fail_bit */
    printf("%d, %d, %d, %d\r\n", (int)packet.fields.position, (int)packet.fields.error_bit, (int)packet.fields.warning_bit, (int) packet.fields.crc_fail_bit);

    /* Wait for next cycle */
    usleep(OUTPUT_PERIOD_MS * 1000);
  }

  return 0;
}
