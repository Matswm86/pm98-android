// FUN_005beb90  entry=005beb90  size=42 bytes

void __thiscall FUN_005beb90(int param_1,LPCSTR param_2)

{
  undefined4 uVar1;
  
  lstrcpyA((LPSTR)(param_1 + 0x2dc),param_2);
  uVar1 = FUN_005e4590(param_2);
  *(undefined4 *)(param_1 + 0x3dc) = uVar1;
  return;
}


