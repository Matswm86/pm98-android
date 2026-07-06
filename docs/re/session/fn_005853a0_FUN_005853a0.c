// FUN_005853a0  entry=005853a0  size=48 bytes

void __thiscall FUN_005853a0(undefined1 *param_1,undefined4 *param_2)

{
  undefined1 uVar1;
  
  uVar1 = *(undefined1 *)*param_2;
  *param_2 = (undefined1 *)*param_2 + 1;
  *param_1 = uVar1;
  uVar1 = *(undefined1 *)*param_2;
  *param_2 = (undefined1 *)*param_2 + 1;
  param_1[1] = uVar1;
  uVar1 = *(undefined1 *)*param_2;
  *param_2 = (undefined1 *)*param_2 + 1;
  param_1[2] = uVar1;
  uVar1 = *(undefined1 *)*param_2;
  *param_2 = (undefined1 *)*param_2 + 1;
  param_1[3] = uVar1;
  return;
}


