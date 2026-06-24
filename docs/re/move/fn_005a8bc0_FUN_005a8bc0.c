// FUN_005a8bc0  entry=005a8bc0  size=824 bytes

void __thiscall FUN_005a8bc0(int param_1,int *param_2)

{
  int *piVar1;
  bool bVar2;
  short sVar3;
  int iVar4;
  uint uVar5;
  undefined4 *puVar6;
  int iVar7;
  uint uVar8;
  int local_c;
  int local_8;
  
  if ((DAT_0067460c & 1) == 0) {
    DAT_00674420 = -0xccc;
    DAT_0067441c = -0xccc;
    DAT_00674418 = -0xccc;
    DAT_0067460c = DAT_0067460c | 1;
    DAT_0067442c = 0xccc;
    DAT_00674428 = 0xccc;
    DAT_00674424 = 0xccc;
    FUN_00605ff0(&DAT_005a8f10);
  }
  if ((DAT_0067460c & 2) == 0) {
    DAT_0067460c = DAT_0067460c | 2;
    DAT_00674618 = -0x20000;
    DAT_00674614 = -0x20000;
    DAT_00674610 = -0x20000;
    DAT_00674624 = 0x20000;
    DAT_00674620 = 0x20000;
    DAT_0067461c = 0x20000;
    FUN_00605ff0(&DAT_005a8f00);
  }
  piVar1 = (int *)(param_1 + 4);
  FUN_00590aa0(*param_2 - *piVar1,param_2[1] - *(int *)(param_1 + 8),
               param_2[2] - *(int *)(param_1 + 0xc));
  iVar4 = *(int *)(param_1 + 0x68) * 6;
  iVar7 = *(int *)(param_1 + 0x68) * -6;
  if (((((iVar7 < local_c) && (local_c < iVar4)) && (iVar7 < local_8)) &&
      ((local_8 < iVar4 && (iVar7 < 0)))) && (0 < iVar4)) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if (bVar2) {
    *(undefined4 *)(param_1 + 0x6c) = 0;
  }
  if (((DAT_00674418 < local_c) && (local_c < DAT_00674424)) &&
     ((DAT_0067441c < local_8 &&
      (((local_8 < DAT_00674428 && (DAT_00674420 < 0)) && (0 < DAT_0067442c)))))) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  iVar4 = local_8;
  iVar7 = local_c;
  if (bVar2) {
    iVar4 = *(int *)(param_1 + 0x18c);
    *(undefined4 *)(param_1 + 0x6c) = 0;
    *(undefined4 *)(param_1 + 0x68) = 0;
    if (*(int *)(iVar4 + 0x43c) == param_1) {
      FUN_00590aa0(*(int *)(iVar4 + 0x1240) - *piVar1,
                   *(int *)(iVar4 + 0x1244) - *(int *)(param_1 + 8),
                   *(int *)(iVar4 + 0x1248) - *(int *)(param_1 + 0xc));
      iVar4 = local_8;
      iVar7 = local_c;
    }
    else {
      iVar4 = *(int *)(param_1 + 400);
      FUN_00590aa0(*(int *)(iVar4 + 4) - *piVar1,*(int *)(iVar4 + 8) - *(int *)(param_1 + 8),
                   *(int *)(iVar4 + 0xc) - *(int *)(param_1 + 0xc));
      iVar4 = local_8;
      iVar7 = local_c;
    }
  }
  if (((DAT_00674418 < iVar7) && (iVar7 < DAT_00674424)) &&
     (((DAT_0067441c < iVar4 && ((iVar4 < DAT_00674428 && (DAT_00674420 < 0)))) &&
      (0 < DAT_0067442c)))) {
    bVar2 = true;
  }
  else {
    bVar2 = false;
  }
  if (bVar2) {
    return;
  }
  param_2 = (int *)FUN_005ee080(iVar7,iVar4);
  if (*(int *)(param_1 + 0x6c) != 0) {
    if ((((DAT_00674610 < iVar7) && (iVar7 < DAT_0067461c)) && (DAT_00674614 < iVar4)) &&
       (((iVar4 < DAT_00674620 && (DAT_00674618 < 0)) && (0 < DAT_00674624)))) {
      bVar2 = true;
    }
    else {
      bVar2 = false;
    }
    if ((bVar2) &&
       (uVar5 = (uint)(short)(((short)param_2 - *(short *)(param_1 + 0x34)) + -0x8000),
       uVar8 = (int)uVar5 >> 0x1f, (int)((uVar5 ^ uVar8) - uVar8) < 0x2000)) {
      puVar6 = (undefined4 *)FUN_00590ae0(&local_c,piVar1);
      sVar3 = FUN_005ee080(*puVar6,puVar6[1]);
      uVar5 = (uint)(short)(sVar3 - *(short *)(param_1 + 0x34));
      uVar8 = (int)uVar5 >> 0x1f;
      if (((int)((uVar5 ^ uVar8) - uVar8) < 0x238e) &&
         ((param_1 != *(int *)(*(int *)(param_1 + 400) + 0x40) && (*(int *)(param_1 + 0x90) < 0x78))
         )) {
        param_2 = (int *)((int)param_2 + -0x8000);
        *(int *)(param_1 + 0x6c) = -*(int *)(param_1 + 0x6c);
        iVar4 = *(int *)(param_1 + 0x90) + 1;
      }
      else {
        if (*(int *)(param_1 + 0x90) == 0) goto LAB_005a8ee2;
        iVar4 = *(int *)(param_1 + 0x90) + -1;
      }
      *(int *)(param_1 + 0x90) = iVar4;
    }
  }
LAB_005a8ee2:
  FUN_005a8f20(param_2);
  return;
}


