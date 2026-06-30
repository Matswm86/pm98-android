// FUN_00404200  entry=00404200  size=47 bytes

void __thiscall FUN_00404200(void *this,int *param_1,int param_2)

{
  int iVar1;
  int iVar2;
  int iVar3;
  
  iVar1 = *(int *)this;
  iVar2 = *(int *)((int)this + 4);
  iVar3 = *(int *)((int)this + 0xc);
  param_1[2] = *(int *)((int)this + 8) - param_2;
  param_1[3] = iVar3 - param_2;
  param_1[1] = iVar2 + param_2;
  *param_1 = param_2 + iVar1;
  return;
}


