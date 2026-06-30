// FUN_0043d2d0  entry=0043d2d0  size=228 bytes

undefined4 __thiscall FUN_0043d2d0(void *this,int *param_1,uint param_2)

{
  int iVar1;
  uint uVar2;
  int *piVar3;
  undefined4 uVar4;
  int iVar5;
  int iVar6;
  int iVar7;
  uint uVar8;
  int local_20;
  int local_1c;
  undefined1 local_10 [16];
  
  uVar2 = FUN_004512f0(param_2,0x4f612c,0x100,-1);
  local_20 = (param_1[2] + *param_1) - param_1[2];
  local_1c = param_1[3] + -1;
  uVar8 = uVar2;
  piVar3 = (int *)FUN_00404830(local_10,param_1 + 2,&local_20);
  uVar4 = FUN_0044ed40(this,*piVar3,piVar3[1],piVar3[2],piVar3[3],uVar8);
  if ((char)uVar4 != '\0') {
    iVar6 = param_1[2];
    iVar1 = param_1[3];
    iVar7 = iVar6 + -1;
    iVar5 = (param_1[1] - param_1[3]) + iVar1;
    local_20 = iVar6;
    if (iVar7 <= iVar6) {
      local_20 = iVar7;
    }
    if (iVar6 <= iVar7) {
      iVar6 = iVar7;
    }
    iVar7 = iVar1;
    if (iVar5 <= iVar1) {
      iVar7 = iVar5;
    }
    if (iVar5 < iVar1) {
      iVar5 = iVar1;
    }
    uVar4 = FUN_0044ed40(this,local_20,iVar7,iVar6,iVar5,uVar2);
    if ((char)uVar4 != '\0') {
      return 1;
    }
  }
  return 0;
}


