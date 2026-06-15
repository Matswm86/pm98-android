// FUN_0050ccc0  entry=0050ccc0  size=198 bytes

void __fastcall FUN_0050ccc0(undefined4 param_1,undefined4 param_2)

{
  undefined4 in_EAX;
  undefined4 *unaff_EBX;
  undefined4 unaff_EBP;
  int unaff_ESI;
  int unaff_EDI;
  
  *unaff_EBX = in_EAX;
  unaff_EBX[1] = unaff_EBP;
  unaff_EBX[2] = param_1;
  unaff_EBX[3] = param_2;
  FUN_005da180(s_Win_bonus_0065a4c0);
  (**(code **)(*(int *)(&DAT_0066b190)[*(int *)(*(int *)(unaff_EDI + 0x430) + 0x50)] + 0x7c))();
  sprintf(&stack0x00000044,s_for__s_0065a4b8);
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) != 0) {
    FUN_005da180(&stack0x00000044,0x16);
    return;
  }
  FUN_005d9d80(&stack0x00000044);
  return;
}


