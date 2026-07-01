// FUN_0058fb50  entry=0058fb50  size=140 bytes

undefined4 __thiscall FUN_0058fb50(int param_1,uint *param_2)

{
  int iVar1;
  bool bVar2;
  uint uVar3;
  
  iVar1 = *(int *)(param_1 + 0x18c);
  uVar3 = *param_2;
  if ((((((int)uVar3 < *(int *)(iVar1 + 0x1828)) || (*(int *)(iVar1 + 0x1834) < (int)uVar3)) ||
       ((int)param_2[1] < *(int *)(iVar1 + 0x182c))) ||
      ((*(int *)(iVar1 + 0x1838) < (int)param_2[1] || ((int)param_2[2] < *(int *)(iVar1 + 0x1830))))
      ) || (*(int *)(iVar1 + 0x183c) < (int)param_2[2])) {
    bVar2 = false;
  }
  else {
    bVar2 = true;
  }
  if (((bVar2) &&
      (*(int *)(iVar1 + 0x1820) + -0x108000 <
       (int)((uVar3 ^ (int)uVar3 >> 0x1f) - ((int)uVar3 >> 0x1f)))) &&
     (uVar3 = (int)param_2[1] >> 0x1f, (int)((param_2[1] ^ uVar3) - uVar3) < 0x1428f5)) {
    return 1;
  }
  return 0;
}


