// FUN_005a8ac0  entry=005a8ac0  size=254 bytes

void __thiscall FUN_005a8ac0(int param_1,undefined4 param_2,int param_3)

{
  int iVar1;
  int iVar2;
  
  if (param_1 == *(int *)(*(int *)(param_1 + 400) + 0x40)) {
    param_3 = (param_3 * 0x4b) / 100;
  }
  iVar1 = *(int *)(param_1 + 0x18c);
  iVar2 = *(int *)(iVar1 + 0x448);
  if (((((iVar2 == 2) || (iVar2 == 3)) || (iVar2 == 4)) || ((iVar2 == 5 || (iVar2 == 7)))) &&
     (((*(byte *)(iVar1 + 0x461) & 0x40) == 0 ||
      (*(int *)(param_1 + 0x2b8) != *(int *)(*(int *)(iVar1 + 0x444) + 0x2b8))))) {
    *(undefined4 *)(param_1 + 0x6c) = 0;
    FUN_005a8f20(param_2);
    return;
  }
  *(int *)(param_1 + 0x6c) =
       (((*(int *)(param_1 + 0x70) * *(int *)(param_1 + 0x3ac)) / 15000) * param_3) / 100 +
       *(int *)(param_1 + 0x3a8);
  FUN_005a8f20(param_2);
  return;
}


