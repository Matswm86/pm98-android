// FUN_0043d240  entry=0043d240  size=131 bytes

undefined4 __thiscall FUN_0043d240(void *this,int *param_1,undefined4 param_2,undefined4 param_3)

{
  char cVar1;
  int iVar2;
  int *piVar3;
  undefined4 extraout_ECX;
  void *pvVar4;
  undefined4 uVar5;
  ushort uVar6;
  undefined4 uVar7;
  undefined4 local_8 [2];
  
  uVar7 = param_3;
  pvVar4 = this;
  uVar5 = param_3;
  FUN_004042e0(&stack0xffffffe4,&param_2);
  uVar6 = (ushort)uVar5;
  iVar2 = FUN_00404d70(param_1);
  iVar2 = -iVar2;
  piVar3 = (int *)FUN_00404d90((int)param_1);
  cVar1 = FUN_00404da0(this,piVar3,iVar2,pvVar4,uVar6);
  if (cVar1 != '\0') {
    uVar5 = extraout_ECX;
    FUN_004042e0(&stack0xffffffe4,&param_2);
    uVar6 = (ushort)uVar7;
    iVar2 = FUN_00404d80((int)param_1);
    iVar2 = iVar2 + -1;
    piVar3 = (int *)FUN_00404270(param_1,local_8);
    cVar1 = FUN_00404e00(this,piVar3,iVar2,uVar5,uVar6);
    if (cVar1 != '\0') {
      return 1;
    }
  }
  return 0;
}


