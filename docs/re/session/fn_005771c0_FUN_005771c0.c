// FUN_005771c0  entry=005771c0  size=84 bytes

undefined4 __thiscall FUN_005771c0(undefined2 *param_1,uint *param_2)

{
  undefined1 uVar1;
  uint uVar2;
  undefined1 *puVar3;
  
  *param_1 = 0;
  *param_1 = *(undefined2 *)*param_2;
  uVar2 = *param_2;
  puVar3 = (undefined1 *)(uVar2 + 2);
  *param_2 = (uint)puVar3;
  uVar1 = *puVar3;
  *param_2 = uVar2 + 3;
  *(undefined1 *)(param_1 + 1) = uVar1;
  if ((param_2[1] != 0) && (*param_2 <= param_2[2] + param_2[1])) {
    return 1;
  }
  return 0;
}


