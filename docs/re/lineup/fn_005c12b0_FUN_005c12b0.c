// FUN_005c12b0  entry=005c12b0  size=63 bytes

undefined4 __thiscall FUN_005c12b0(int param_1,int param_2)

{
  char cVar1;
  
  if (param_2 == -1) {
    param_2 = *(int *)(param_1 + 0x70);
  }
  cVar1 = FUN_005c0fd0(param_2);
  if (cVar1 != '\0') {
    return *(undefined4 *)
            (*(int *)(param_1 + 0x360 + param_2 * 8) + 0x80 + *(int *)(param_1 + 0x74) * 0x94);
  }
  return 0;
}


