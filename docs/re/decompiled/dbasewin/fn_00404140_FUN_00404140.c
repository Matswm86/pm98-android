// FUN_00404140  entry=00404140  size=32 bytes

void __thiscall FUN_00404140(void *this,int *param_1,int *param_2)

{
  int iVar1;
  int iVar2;
  
  iVar1 = *(int *)((int)this + 4);
  iVar2 = param_2[1];
  *param_1 = *(int *)this + *param_2;
  param_1[1] = iVar1 + iVar2;
  return;
}


