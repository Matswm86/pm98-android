// FUN_00574c1f  entry=00574c1f  size=137 bytes

void __fastcall FUN_00574c1f(undefined4 param_1,undefined4 *param_2)

{
  undefined4 in_EAX;
  int unaff_EBX;
  undefined4 unaff_EBP;
  undefined4 unaff_ESI;
  int unaff_EDI;
  
  *param_2 = in_EAX;
  param_2[1] = unaff_EBP;
  param_2[2] = unaff_ESI;
  param_2[3] = param_1;
  FUN_005da180(s_ASSISTANT_00661dfc);
  if (*(int *)(unaff_EBX + 0x54) != 0) {
    *(uint *)(unaff_EDI + 0x144) = *(uint *)(unaff_EDI + 0x144) & 0xfffffff7;
    FUN_00512bc0();
  }
  return;
}


