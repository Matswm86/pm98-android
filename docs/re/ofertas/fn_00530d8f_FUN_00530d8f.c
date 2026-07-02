// FUN_00530d8f  entry=00530d8f  size=328 bytes

void __fastcall FUN_00530d8f(undefined4 *param_1,undefined4 param_2)

{
  undefined4 uVar1;
  int in_EAX;
  uint unaff_EBX;
  int unaff_ESI;
  
  *param_1 = param_2;
  param_1[1] = *(undefined4 *)(in_EAX + 4);
  uVar1 = *(undefined4 *)(in_EAX + 0xc);
  param_1[2] = *(undefined4 *)(in_EAX + 8);
  param_1[3] = uVar1;
  FUN_005da180(s_CLUB_OFFERS_0065bf88);
  FUN_005d9d50();
  FUN_005d9d30();
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) | 0x20;
  FUN_00436fb0();
  FUN_00436fd0();
  FUN_004ca3c0();
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) & unaff_EBX;
  FUN_00437020();
  FUN_005d9d30();
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) | 0x40;
  FUN_00436fb0();
  FUN_00436fd0();
  FUN_004ca3c0();
  return;
}


