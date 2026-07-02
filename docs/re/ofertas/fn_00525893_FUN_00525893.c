// FUN_00525893  entry=00525893  size=357 bytes

void __fastcall FUN_00525893(undefined4 param_1,undefined4 *param_2)

{
  undefined4 in_EAX;
  undefined4 unaff_EBP;
  int unaff_ESI;
  undefined4 unaff_EDI;
  
  *param_2 = in_EAX;
  param_2[1] = param_1;
  param_2[2] = unaff_EDI;
  param_2[3] = unaff_EBP;
  FUN_005da180(s_CLUB_OFFER_0065b7cc);
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_YEARLY_WAGE_0065b7c0);
  }
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) == 0) {
    FUN_005d9d80();
  }
  else {
    FUN_005da180(s_YEARS_0065a4d4);
  }
  if ((*(uint *)(unaff_ESI + 0x144) >> 3 & 1) != 0) {
    FUN_005da180(s_CLAUSES_0065b7b8);
    return;
  }
  FUN_005d9d80();
  return;
}


