// FUN_005b3c10  entry=005b3c10  size=78 bytes

undefined4 __thiscall FUN_005b3c10(int param_1,int param_2,int param_3,int param_4)

{
  int iVar1;
  
  iVar1 = *(int *)(*(int *)(param_1 + 0x184) + 0x30c);
  if ((iVar1 != 0) && (param_2 = param_3, iVar1 != 2)) {
    param_2 = param_4;
  }
  iVar1 = FUN_005ec250();
  iVar1 = iVar1 * 1000 + (iVar1 * 1000 >> 0x1f & 0x7fffU);
  return CONCAT31((int3)(iVar1 >> 0x17),iVar1 >> 0xf < param_2);
}


