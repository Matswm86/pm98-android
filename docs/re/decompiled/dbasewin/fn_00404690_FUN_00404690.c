// FUN_00404690  entry=00404690  size=415 bytes

undefined4 __thiscall FUN_00404690(void *this,int *param_1,int param_2,uint param_3)

{
  int *piVar1;
  int iVar2;
  uint uVar3;
  int *piVar4;
  undefined4 uVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  int iVar9;
  uint uVar10;
  int local_20;
  int local_1c;
  int local_18 [2];
  undefined1 local_10 [16];
  
  uVar3 = FUN_004512f0(param_3,0x4f612c,0x100,-1);
  piVar1 = param_1 + 2;
  local_20 = param_1[2] - *param_1;
  local_1c = param_2;
  uVar10 = uVar3;
  piVar4 = (int *)FUN_00404140(param_1,local_18,&local_20);
  piVar4 = (int *)FUN_00404830(local_10,param_1,piVar4);
  uVar5 = FUN_0044ed40(this,*piVar4,piVar4[1],piVar4[2],piVar4[3],uVar10);
  if ((char)uVar5 != '\0') {
    FUN_00404120(&local_20,*param_1 + param_2,param_1[3]);
    uVar10 = uVar3;
    piVar4 = (int *)FUN_00404830(local_10,param_1,&local_20);
    uVar5 = FUN_0044ed40(this,*piVar4,piVar4[1],piVar4[2],piVar4[3],uVar10);
    if ((char)uVar5 != '\0') {
      FUN_00404120(&local_20,(*piVar1 + *param_1) - *piVar1,param_1[3] + -param_2);
      uVar10 = uVar3;
      piVar4 = (int *)FUN_00404830(local_10,piVar1,&local_20);
      uVar5 = FUN_0044ed40(this,*piVar4,piVar4[1],piVar4[2],piVar4[3],uVar10);
      if ((char)uVar5 != '\0') {
        iVar7 = *piVar1;
        iVar2 = param_1[3];
        iVar9 = iVar7 + -param_2;
        iVar6 = (iVar2 - param_1[3]) + param_1[1];
        iVar8 = iVar7;
        if (iVar9 <= iVar7) {
          iVar8 = iVar9;
        }
        if (iVar7 <= iVar9) {
          iVar7 = iVar9;
        }
        iVar9 = iVar2;
        if (iVar6 <= iVar2) {
          iVar9 = iVar6;
        }
        if (iVar6 < iVar2) {
          iVar6 = iVar2;
        }
        uVar5 = FUN_0044ed40(this,iVar8,iVar9,iVar7,iVar6,uVar3);
        if ((char)uVar5 != '\0') {
          return 1;
        }
      }
    }
  }
  return 0;
}


