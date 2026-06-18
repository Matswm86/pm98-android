// FUN_005b04e0  entry=005b04e0  size=189 bytes

undefined4 __thiscall FUN_005b04e0(int param_1,uint *param_2)

{
  int iVar1;
  uint uVar2;
  bool bVar3;
  uint uVar4;
  
  iVar1 = *(int *)(param_1 + 0x18c);
  uVar2 = *param_2;
  if ((((((int)uVar2 < *(int *)(iVar1 + 0x1828)) || (*(int *)(iVar1 + 0x1834) < (int)uVar2)) ||
       ((int)param_2[1] < *(int *)(iVar1 + 0x182c))) ||
      ((*(int *)(iVar1 + 0x1838) < (int)param_2[1] || ((int)param_2[2] < *(int *)(iVar1 + 0x1830))))
      ) || (*(int *)(iVar1 + 0x183c) < (int)param_2[2])) {
    bVar3 = false;
  }
  else {
    bVar3 = true;
  }
  if (((bVar3) &&
      (*(int *)(iVar1 + 0x1820) + -0x108000 <
       (int)((uVar2 ^ (int)uVar2 >> 0x1f) - ((int)uVar2 >> 0x1f)))) &&
     (uVar4 = (int)param_2[1] >> 0x1f, (int)((param_2[1] ^ uVar4) - uVar4) < 0x1428f5)) {
    bVar3 = true;
  }
  else {
    bVar3 = false;
  }
  if ((bVar3) &&
     (((-1 < (int)uVar2) - 1 & 0xfffffffe) + 1 !=
      ((-1 < *(int *)(param_1 + 0x3a4)) - 1 & 0xfffffffe) + 1)) {
    return 1;
  }
  return 0;
}


