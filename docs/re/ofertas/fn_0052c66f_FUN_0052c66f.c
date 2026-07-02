// FUN_0052c66f  entry=0052c66f  size=1198 bytes

void __fastcall FUN_0052c66f(undefined4 param_1,undefined4 *param_2)

{
  uint uVar1;
  undefined4 in_EAX;
  int iVar2;
  undefined4 unaff_EBP;
  int unaff_ESI;
  undefined4 unaff_EDI;
  int in_stack_00000050;
  
  *param_2 = in_EAX;
  param_2[1] = unaff_EDI;
  param_2[2] = param_1;
  param_2[3] = unaff_EBP;
  FUN_005da180(s_CLUB_OFFER_0065b7cc);
  FUN_005d9d30();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_CLUB_FEE_0065be64);
  }
  FUN_005d9d30();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_YEARLY_WAGE_0065b7c0);
  }
  FUN_005d9d30();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_YEARS_0065a4d4);
  }
  FUN_005d9d30();
  uVar1 = *(uint *)(unaff_ESI + 0x144);
  *(uint *)(unaff_ESI + 0x144) = uVar1 | 0x20;
  if ((uVar1 & 8) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_Free_if_relegated_0065be50);
  }
  lstrcpyA(&stack0x00000054,s_Matches_to_renew_0065be3c);
  iVar2 = lstrlenA(&stack0x00000054);
  lstrcpyA(&stack0x00000054 + iVar2,&DAT_00666f70);
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(&stack0x00000054);
  }
  if ((~(byte)(*(uint *)(in_stack_00000050 + 0x4728) >> 7) & 1) == 0) {
    FUN_005d9d30();
  }
  lstrcpyA(&stack0x00000054,s_Scoring_bonus_0065be2c);
  iVar2 = lstrlenA(&stack0x00000054);
  lstrcpyA(&stack0x00000054 + iVar2,&DAT_00666f70);
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(&stack0x00000054);
  }
  FUN_005d9d30();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_House_and_car_0065be1c);
  }
  *(uint *)(unaff_ESI + 0x144) = *(uint *)(unaff_ESI + 0x144) & 0xffffffdf;
  FUN_005d9d50();
  *(undefined1 *)(unaff_ESI + 0x14c) = 1;
  FUN_005d9d30();
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) != 0) {
    FUN_005da180(s_OFFER_0065bc80);
    return;
  }
  FUN_005d9d80();
  return;
}


