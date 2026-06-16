// FUN_005beb60  entry=005beb60  size=42 bytes

void __thiscall FUN_005beb60(int param_1,LPCSTR param_2)

{
  undefined4 uVar1;
  
  lstrcpyA((LPSTR)(param_1 + 0x25c),param_2);
  uVar1 = FUN_005e4590(param_2);
  *(undefined4 *)(param_1 + 0x3d8) = uVar1;
  return;
}


