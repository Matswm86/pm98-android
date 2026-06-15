// FUN_005db5d0  entry=005db5d0  size=105 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_005db5d0(int param_1,undefined4 param_2,int param_3,int param_4)

{
  undefined4 *puVar1;
  undefined4 *puVar2;
  
  FUN_005ec020(param_2);
  puVar1 = (undefined4 *)(param_3 * 4 + 0x18);
  puVar2 = (undefined4 *)(param_1 + 4 + param_3 * 4);
  for (; param_4 != 0; param_4 = param_4 + -1) {
    *puVar2 = *puVar1;
    puVar1 = puVar1 + 1;
    puVar2 = puVar2 + 1;
  }
  FUN_005ec0e0();
  return;
}


