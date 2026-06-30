// FUN_0044f9d0  entry=0044f9d0  size=51 bytes

void __thiscall FUN_0044f9d0(void *this,int *param_1)

{
  *(int *)this = *(int *)this + *param_1;
  *(int *)((int)this + 4) = *(int *)((int)this + 4) + param_1[1];
  *(int *)((int)this + 8) = *(int *)((int)this + 8) + *param_1;
  *(int *)((int)this + 0xc) = *(int *)((int)this + 0xc) + param_1[1];
  return;
}


