// FUN_00404830  entry=00404830  size=72 bytes

void __thiscall FUN_00404830(void *this,int *param_1,int *param_2)

{
  int iVar1;
  
  iVar1 = *param_1;
  if (*param_2 <= *param_1) {
    iVar1 = *param_2;
  }
  *(int *)this = iVar1;
  iVar1 = *param_1;
  if (*param_1 <= *param_2) {
    iVar1 = *param_2;
  }
  *(int *)((int)this + 8) = iVar1;
  iVar1 = param_1[1];
  if (param_2[1] <= param_1[1]) {
    iVar1 = param_2[1];
  }
  *(int *)((int)this + 4) = iVar1;
  iVar1 = param_1[1];
  if (param_1[1] <= param_2[1]) {
    iVar1 = param_2[1];
  }
  *(int *)((int)this + 0xc) = iVar1;
  return;
}


