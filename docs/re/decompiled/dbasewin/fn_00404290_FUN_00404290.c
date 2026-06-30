// FUN_00404290  entry=00404290  size=17 bytes

void __thiscall FUN_00404290(void *this,undefined4 *param_1)

{
  undefined4 uVar1;
  
  uVar1 = *(undefined4 *)((int)this + 0xc);
  *param_1 = *(undefined4 *)this;
  param_1[1] = uVar1;
  return;
}


