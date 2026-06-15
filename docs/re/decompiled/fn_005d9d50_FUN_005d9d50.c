// FUN_005d9d50  entry=005d9d50  size=42 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005d9d50(int param_1,LPCSTR param_2)

{
  undefined4 uVar1;
  
  lstrcpyA((LPSTR)(param_1 + 0x120),param_2);
  uVar1 = FUN_005e43d0((LPSTR)(param_1 + 0x120));
  *(undefined4 *)(param_1 + 0x140) = uVar1;
  return;
}


