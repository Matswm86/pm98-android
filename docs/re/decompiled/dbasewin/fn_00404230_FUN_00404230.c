// FUN_00404230  entry=00404230  size=52 bytes

void __thiscall FUN_00404230(void *this,int *param_1,int *param_2)

{
  int iVar1;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  
  iVar1 = *(int *)((int)this + 0xc);
  iVar2 = param_2[1];
  iVar3 = *param_2;
  iVar4 = *(int *)((int)this + 8);
  iVar5 = *(int *)this;
  param_1[1] = *(int *)((int)this + 4) - iVar2;
  param_1[2] = iVar4 - iVar3;
  *param_1 = iVar5 - iVar3;
  param_1[3] = iVar1 - iVar2;
  return;
}


