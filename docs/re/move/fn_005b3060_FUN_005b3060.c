// FUN_005b3060  entry=005b3060  size=320 bytes

undefined4 __fastcall FUN_005b3060(int param_1)

{
  char cVar1;
  int iVar2;
  int local_c;
  undefined4 local_8;
  undefined4 local_4;
  
  if (*(int *)(param_1 + 0x13c) != 3) {
    if ((((((-1 < *(int *)(param_1 + 4)) - 1 & 0xfffffffe) + 1 ==
           ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1) &&
         (*(int *)(param_1 + 0x14c) < 0x1e)) && (0x7ffff < *(int *)(param_1 + 0x17c))) &&
       (cVar1 = FUN_005b3c10(0x14,300,800), cVar1 != '\0')) {
      *(undefined4 *)(param_1 + 0x144) = 0;
      iVar2 = FUN_005ec250();
      *(undefined4 *)(param_1 + 0x13c) = 3;
      *(int *)(param_1 + 0x148) =
           ((int)(iVar2 * 0xa0 + (iVar2 * 0xa0 >> 0x1f & 0x7fffU)) >> 0xf) + 0x1e;
    }
    if (*(int *)(param_1 + 0x13c) != 3) {
      return 0;
    }
  }
  if (((((-1 < *(int *)(param_1 + 4)) - 1 & 0xfffffffe) + 1 ==
        ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1) &&
      (0x7ffff < *(int *)(param_1 + 0x17c))) &&
     (iVar2 = *(int *)(param_1 + 0x144), *(int *)(param_1 + 0x144) = iVar2 + 1,
     iVar2 <= *(int *)(param_1 + 0x148))) {
    local_8 = *(undefined4 *)(param_1 + 8);
    local_c = -*(int *)(param_1 + 0x3a4);
    local_4 = 0;
    FUN_005a89c0(&local_c,9);
    return 1;
  }
  *(undefined4 *)(param_1 + 0x13c) = 0;
  return 0;
}


