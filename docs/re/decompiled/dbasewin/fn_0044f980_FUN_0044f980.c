// FUN_0044f980  entry=0044f980  size=68 bytes

void __thiscall FUN_0044f980(void *this,int *param_1)

{
  int iVar1;
  
  iVar1 = *(int *)this;
  if (*(int *)this <= *param_1) {
    iVar1 = *param_1;
  }
  *(int *)this = iVar1;
  iVar1 = *(int *)((int)this + 4);
  if (*(int *)((int)this + 4) <= param_1[1]) {
    iVar1 = param_1[1];
  }
  *(int *)((int)this + 4) = iVar1;
  iVar1 = *(int *)((int)this + 8);
  if (param_1[2] <= *(int *)((int)this + 8)) {
    iVar1 = param_1[2];
  }
  *(int *)((int)this + 8) = iVar1;
  iVar1 = param_1[3];
  if (*(int *)((int)this + 0xc) < param_1[3]) {
    iVar1 = *(int *)((int)this + 0xc);
  }
  *(int *)((int)this + 0xc) = iVar1;
  return;
}


