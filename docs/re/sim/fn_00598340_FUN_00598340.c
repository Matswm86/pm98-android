// FUN_00598340  entry=00598340  size=170 bytes

undefined4 __fastcall FUN_00598340(int param_1)

{
  int iVar1;
  char cVar2;
  int iVar3;
  
  iVar1 = *(int *)(param_1 + 0x1a2c);
  if (((iVar1 == 1) && (iVar1 = *(int *)(param_1 + 0x1a30), iVar1 == 0)) &&
     (iVar1 = *(int *)(param_1 + 0x1a38), iVar1 == 0)) {
    cVar2 = '\x01';
  }
  else {
    cVar2 = '\0';
  }
  if (cVar2 == '\0') goto LAB_005983e5;
  iVar3 = *(int *)(param_1 + 0x1820);
  if (*(uint *)(param_1 + 0x1664) == (*(uint *)(param_1 + 0x19a0) & 1)) {
    iVar3 = -iVar3;
  }
  iVar1 = ((-1 < *(int *)(param_1 + 0x1614)) - 1 & 0xfffffffe) + 1;
  if (iVar1 == ((-1 < iVar3) - 1 & 0xfffffffe) + 1) {
    iVar1 = 0;
    if (*(int *)(param_1 + 0x1650) != 0) goto LAB_005983e5;
    iVar1 = FUN_005ec250();
    iVar1 = (int)(iVar1 * 1000 + (iVar1 * 1000 >> 0x1f & 0x7fffU)) >> 0xf;
    if (499 < iVar1) goto LAB_005983e5;
  }
  cVar2 = '\0';
LAB_005983e5:
  return CONCAT31((int3)((uint)iVar1 >> 8),cVar2);
}


