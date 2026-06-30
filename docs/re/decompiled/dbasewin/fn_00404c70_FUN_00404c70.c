// FUN_00404c70  entry=00404c70  size=242 bytes

undefined4 __thiscall FUN_00404c70(void *this,int *param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  int iVar2;
  int *piVar3;
  undefined4 extraout_ECX;
  undefined4 extraout_ECX_00;
  undefined4 extraout_ECX_01;
  void *pvVar4;
  undefined4 uVar5;
  ushort uVar6;
  undefined4 uVar7;
  undefined4 uVar8;
  undefined4 local_10 [2];
  undefined1 local_8 [8];
  
  uVar8 = param_3;
  pvVar4 = this;
  uVar5 = param_3;
  FUN_004042e0(&stack0xffffffdc,&param_2);
  uVar6 = (ushort)uVar5;
  iVar2 = FUN_00404d70(param_1);
  piVar3 = (int *)FUN_004076c0(param_1);
  cVar1 = FUN_004048d0(this,piVar3,iVar2,pvVar4,uVar6);
  if (cVar1 != '\0') {
    uVar5 = extraout_ECX;
    uVar7 = uVar8;
    FUN_004042e0(&stack0xffffffdc,&param_2);
    uVar6 = (ushort)uVar7;
    iVar2 = FUN_00404d80((int)param_1);
    iVar2 = 1 - iVar2;
    piVar3 = (int *)FUN_00404290(param_1,local_10);
    cVar1 = FUN_00404980(this,piVar3,iVar2,uVar5,uVar6);
    if (cVar1 != '\0') {
      uVar5 = extraout_ECX_00;
      uVar7 = uVar8;
      FUN_004042e0(&stack0xffffffdc,&param_2);
      uVar6 = (ushort)uVar7;
      iVar2 = FUN_00404d70(param_1);
      iVar2 = 1 - iVar2;
      piVar3 = (int *)FUN_00404d90((int)param_1);
      cVar1 = FUN_00404da0(this,piVar3,iVar2,uVar5,uVar6);
      if (cVar1 != '\0') {
        uVar5 = extraout_ECX_01;
        FUN_004042e0(&stack0xffffffdc,&param_2);
        uVar6 = (ushort)uVar8;
        iVar2 = FUN_00404d80((int)param_1);
        iVar2 = iVar2 + -2;
        piVar3 = (int *)FUN_00404120(local_8,param_1[2],param_1[1] + 1);
        cVar1 = FUN_00404e00(this,piVar3,iVar2,uVar5,uVar6);
        if (cVar1 != '\0') {
          return 1;
        }
      }
    }
  }
  return 0;
}


