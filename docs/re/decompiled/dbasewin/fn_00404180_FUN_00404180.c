// FUN_00404180  entry=00404180  size=80 bytes

void __thiscall FUN_00404180(void *this,int *param_1,int *param_2)

{
  int iVar1;
  int iVar2;
  
  iVar2 = *param_1;
  if (*param_2 + iVar2 <= iVar2) {
    iVar2 = *param_2 + iVar2;
  }
  *(int *)this = iVar2;
  iVar2 = *param_1;
  if (iVar2 <= *param_2 + iVar2) {
    iVar2 = *param_2 + iVar2;
  }
  *(int *)((int)this + 8) = iVar2;
  iVar2 = param_1[1];
  if (param_2[1] + iVar2 <= iVar2) {
    iVar2 = param_2[1] + iVar2;
  }
  *(int *)((int)this + 4) = iVar2;
  iVar2 = param_1[1];
  iVar1 = param_2[1] + iVar2;
  if (param_2[1] + iVar2 < iVar2) {
    iVar1 = iVar2;
  }
  *(int *)((int)this + 0xc) = iVar1;
  return;
}


