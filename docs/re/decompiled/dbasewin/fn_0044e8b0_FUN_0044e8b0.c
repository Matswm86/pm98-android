// FUN_0044e8b0  entry=0044e8b0  size=112 bytes

undefined4 __fastcall FUN_0044e8b0(int *param_1)

{
  int *piVar1;
  bool bVar2;
  int iVar3;
  
  FUN_0044e920((int)param_1);
  if ((*param_1 != 0) && (piVar1 = (int *)param_1[1], piVar1 != (int *)0x0)) {
    if ((DAT_0050178c < 1) || (*(int *)(DAT_00501788 + 0x18 + DAT_00501d74 * 0x134) == 0)) {
      bVar2 = false;
    }
    else {
      bVar2 = true;
    }
    if (bVar2) {
      *param_1 = 0;
      iVar3 = (**(code **)(*piVar1 + 0x80))(piVar1,0);
      if (-1 < iVar3) {
        return 1;
      }
    }
    return 0;
  }
  return 1;
}


