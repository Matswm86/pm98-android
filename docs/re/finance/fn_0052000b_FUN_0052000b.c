// FUN_0052000b  entry=0052000b  size=120 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_0052000b(undefined4 param_1,undefined4 *param_2)

{
  undefined4 in_EAX;
  undefined4 uVar1;
  undefined4 *puVar2;
  undefined4 unaff_EBP;
  int unaff_ESI;
  undefined4 unaff_EDI;
  int in_stack_00000048;
  undefined1 *puVar3;
  
  *param_2 = in_EAX;
  param_2[1] = unaff_EDI;
  param_2[2] = param_1;
  param_2[3] = unaff_EBP;
  FUN_005da180(s_PRICE_OF_BOARD_0065b67c);
  FUN_005d9d30();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_TICKET_PRICE_0065b66c);
  }
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_SPONSOR_BOARDS_0065b65c);
  }
  FUN_005d9d30();
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) & 0xfffffff7;
  FUN_00585ee0();
  uVar1 = FUN_00579390();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(uVar1);
  }
  FUN_00585ee0();
  uVar1 = FUN_00579390();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(uVar1);
  }
  FUN_005d9d50();
  FUN_00437020();
  FUN_005d9d30();
  FUN_00436fd0();
  FUN_004ca3c0();
  FUN_00437020();
  FUN_005d9d30();
  FUN_00436fb0();
  FUN_00436fd0();
  puVar3 = &stack0x0000005c;
  uVar1 = (**(code **)(*DAT_0066b1e0 + 8))(puVar3);
  FUN_004ca3c0(uVar1,puVar3);
  if ((*(int *)(*(int *)(in_stack_00000048 + 0x1e0) + 0x20) == 0) &&
     (*(int *)(*(int *)(in_stack_00000048 + 0x1e0) + 0x1c) != 0)) {
    FUN_00437020();
    FUN_005d9d30();
    uVar1 = FUN_0058dc90();
    FUN_00436fb0();
    puVar2 = (undefined4 *)FUN_00436fd0();
    FUN_004ca3c0(uVar1,*puVar2);
    FUN_005d9d50();
    FUN_005d9d30();
    FUN_00436fb0();
    puVar2 = (undefined4 *)FUN_00436fd0();
    FUN_004ca3c0(s_You_have_an_offer_to_sell_all_th_0065b608,*puVar2);
  }
  FUN_00436fb0();
  FUN_0043c970();
  return;
}


